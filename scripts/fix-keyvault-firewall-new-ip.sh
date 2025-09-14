#!/bin/bash

# Fix Key Vault Firewall for New GitHub Actions IP Range
# This script adds the new IP range 57.151.0.0/16 to existing Key Vaults

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Azure CLI is logged in
check_azure_login() {
    if ! az account show &>/dev/null; then
        print_error "Not logged into Azure CLI. Please run: az login"
        exit 1
    fi
    
    local subscription=$(az account show --query name -o tsv)
    print_success "Logged into Azure CLI"
    print_info "Subscription: $subscription"
    echo
}

# Function to add IP range to Key Vault network ACLs
add_ip_to_keyvault() {
    local kv_name=$1
    local ip_range=$2
    
    print_info "Adding IP range $ip_range to Key Vault: $kv_name"
    
    # Get current network ACLs
    local current_ips=$(az keyvault network-rule list --name "$kv_name" --query "ipRules[].value" -o tsv 2>/dev/null || echo "")
    
    # Check if IP range already exists
    if echo "$current_ips" | grep -q "$ip_range"; then
        print_warning "IP range $ip_range already exists in $kv_name"
        return 0
    fi
    
    # Add the new IP range
    if az keyvault network-rule add --name "$kv_name" --ip-address "$ip_range" 2>/dev/null; then
        print_success "Successfully added $ip_range to $kv_name"
    else
        print_error "Failed to add $ip_range to $kv_name"
        return 1
    fi
}

# Function to update all Key Vaults
update_all_keyvaults() {
    print_header "Updating Key Vault Firewall Rules"
    
    # Get all Key Vaults
    local keyvaults=$(az keyvault list --query "[].name" -o tsv)
    
    if [ -z "$keyvaults" ]; then
        print_warning "No Key Vaults found in the subscription"
        return 0
    fi
    
    print_info "Found Key Vaults:"
    echo "$keyvaults"
    echo
    
    # IP ranges to add
    local ip_ranges=(
        "57.151.0.0/16"  # New GitHub Actions range (covers 57.151.137.147)
    )
    
    # Update each Key Vault
    for kv in $keyvaults; do
        print_info "Processing Key Vault: $kv"
        
        for ip_range in "${ip_ranges[@]}"; do
            add_ip_to_keyvault "$kv" "$ip_range"
        done
        
        echo
    done
}

# Function to show current Key Vault network rules
show_keyvault_rules() {
    print_header "Current Key Vault Network Rules"
    
    local keyvaults=$(az keyvault list --query "[].name" -o tsv)
    
    for kv in $keyvaults; do
        print_info "Key Vault: $kv"
        az keyvault network-rule list --name "$kv" --query "ipRules[].value" -o table 2>/dev/null || echo "No network rules found"
        echo
    done
}

# Main function
main() {
    print_header "Key Vault Firewall Fix for New GitHub Actions IP"
    
    # Check Azure login
    check_azure_login
    
    # Show current rules
    show_keyvault_rules
    
    # Update all Key Vaults
    update_all_keyvaults
    
    # Show updated rules
    print_header "Updated Key Vault Network Rules"
    show_keyvault_rules
    
    print_success "Key Vault firewall update completed!"
    print_info "The new IP range 57.151.0.0/16 has been added to all Key Vaults"
    print_info "This should resolve the 403 Forbidden error for IP 57.151.137.147"
}

# Run main function
main "$@"
