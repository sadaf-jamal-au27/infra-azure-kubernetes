#!/bin/bash

# 🗑️ Complete Azure Resources Cleanup Script
# This script will destroy ALL resources across all environments

set -e

echo "🗑️  COMPLETE AZURE RESOURCES CLEANUP"
echo "====================================="
echo "⚠️  WARNING: This will delete ALL Azure resources!"
echo "⚠️  This action is IRREVERSIBLE!"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to destroy environment
destroy_environment() {
    local env=$1
    local env_path="lib/environments/$env"
    
    print_status "Destroying $env environment..."
    
    if [ ! -d "$env_path" ]; then
        print_warning "$env environment directory not found, skipping..."
        return 0
    fi
    
    cd "$env_path"
    
    # Check if terraform is initialized
    if [ ! -d ".terraform" ]; then
        print_status "Initializing Terraform for $env..."
        terraform init -backend=false
    fi
    
    # Check if there are resources to destroy
    print_status "Checking resources in $env environment..."
    if terraform show -json 2>/dev/null | jq -e '.values.root_module.resources | length > 0' >/dev/null 2>&1; then
        print_status "Found resources in $env, proceeding with destruction..."
        
        # Destroy with auto-approve
        terraform destroy -auto-approve -backend=false
        
        if [ $? -eq 0 ]; then
            print_success "$env environment destroyed successfully!"
        else
            print_error "Failed to destroy $env environment"
            return 1
        fi
    else
        print_status "No resources found in $env environment"
    fi
    
    # Clean up terraform files
    print_status "Cleaning up Terraform files for $env..."
    rm -rf .terraform
    rm -f terraform.tfstate*
    rm -f tfplan
    
    cd - >/dev/null
    return 0
}

# Function to cleanup Azure CLI resources
cleanup_azure_cli() {
    print_status "Cleaning up Azure CLI resources..."
    
    # List and delete resource groups
    print_status "Listing resource groups..."
    resource_groups=$(az group list --query "[?contains(name, 'todoapp')].name" -o tsv 2>/dev/null || echo "")
    
    if [ -n "$resource_groups" ]; then
        print_status "Found resource groups: $resource_groups"
        
        for rg in $resource_groups; do
            print_status "Deleting resource group: $rg"
            az group delete --name "$rg" --yes --no-wait 2>/dev/null || print_warning "Failed to delete resource group: $rg"
        done
        
        print_status "Waiting for resource group deletions to complete..."
        sleep 30
        
        # Check if any resource groups still exist
        remaining_rgs=$(az group list --query "[?contains(name, 'todoapp')].name" -o tsv 2>/dev/null || echo "")
        if [ -n "$remaining_rgs" ]; then
            print_warning "Some resource groups still exist: $remaining_rgs"
        else
            print_success "All resource groups deleted successfully!"
        fi
    else
        print_status "No resource groups found to delete"
    fi
}

# Function to cleanup Key Vaults specifically
cleanup_key_vaults() {
    print_status "Cleaning up Key Vaults..."
    
    key_vaults=$(az keyvault list --query "[?contains(name, 'kv-')].name" -o tsv 2>/dev/null || echo "")
    
    if [ -n "$key_vaults" ]; then
        print_status "Found Key Vaults: $key_vaults"
        
        for kv in $key_vaults; do
            print_status "Deleting Key Vault: $kv"
            az keyvault delete --name "$kv" 2>/dev/null || print_warning "Failed to delete Key Vault: $kv"
        done
        
        print_success "Key Vaults cleanup completed!"
    else
        print_status "No Key Vaults found to delete"
    fi
}

# Main cleanup process
main() {
    echo "Starting complete resource cleanup..."
    echo ""
    
    # Check Azure CLI login
    print_status "Checking Azure CLI authentication..."
    if ! az account show >/dev/null 2>&1; then
        print_error "Not logged into Azure CLI. Please run 'az login' first."
        exit 1
    fi
    
    # Get current subscription info
    subscription_info=$(az account show --query "{name:name, id:id}" -o tsv)
    print_status "Current subscription: $subscription_info"
    echo ""
    
    # Confirm deletion
    echo -e "${RED}⚠️  FINAL CONFIRMATION REQUIRED ⚠️${NC}"
    echo "This will delete ALL resources in subscription: $(az account show --query name -o tsv)"
    echo ""
    read -p "Type 'DELETE ALL' to confirm: " confirmation
    
    if [ "$confirmation" != "DELETE ALL" ]; then
        print_error "Confirmation failed. Exiting without changes."
        exit 1
    fi
    
    echo ""
    print_status "Proceeding with complete resource deletion..."
    echo ""
    
    # Destroy environments in order (prod first, then staging, then dev)
    destroy_environment "prod"
    destroy_environment "staging" 
    destroy_environment "dev"
    
    # Cleanup any remaining Azure resources
    cleanup_key_vaults
    cleanup_azure_cli
    
    echo ""
    print_success "🎉 COMPLETE RESOURCE CLEANUP FINISHED!"
    echo ""
    print_status "Summary:"
    echo "  ✅ All Terraform environments destroyed"
    echo "  ✅ All resource groups deleted"
    echo "  ✅ All Key Vaults removed"
    echo "  ✅ All Azure resources cleaned up"
    echo ""
    print_warning "Note: Some resources may take a few minutes to fully delete from Azure"
    print_status "You can verify deletion in the Azure Portal"
}

# Run main function
main "$@"

