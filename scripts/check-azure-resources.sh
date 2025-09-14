#!/bin/bash

# Azure Resource Checker by Environment
# This script helps you check Azure resources organized by environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
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
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Function to check if Azure CLI is logged in
check_azure_login() {
    if ! az account show &>/dev/null; then
        print_error "Not logged into Azure CLI. Please run: az login"
        exit 1
    fi
    
    local subscription=$(az account show --query name -o tsv)
    local tenant=$(az account show --query tenantId -o tsv)
    
    print_success "Logged into Azure CLI"
    print_info "Subscription: $subscription"
    print_info "Tenant ID: $tenant"
    echo
}

# Function to get environment-specific resource groups
get_env_resource_groups() {
    local env=$1
    az group list --query "[?contains(name, '$env')].{Name:name, Location:location, Tags:tags}" -o table
}

# Function to check resources in a resource group
check_resources_in_rg() {
    local rg_name=$1
    local env=$2
    
    print_header "Resources in Resource Group: $rg_name"
    
    # Check different resource types
    echo -e "${PURPLE}📦 Container Registry (ACR):${NC}"
    az acr list -g "$rg_name" --query "[].{Name:name, Location:location, SKU:sku.name, LoginServer:loginServer}" -o table 2>/dev/null || echo "No ACR found"
    
    echo -e "\n${PURPLE}☸️  Kubernetes Clusters (AKS):${NC}"
    az aks list -g "$rg_name" --query "[].{Name:name, Location:location, NodeCount:agentPoolProfiles[0].count, VMSize:agentPoolProfiles[0].vmSize, Status:provisioningState}" -o table 2>/dev/null || echo "No AKS found"
    
    echo -e "\n${PURPLE}🗄️  SQL Servers:${NC}"
    az sql server list -g "$rg_name" --query "[].{Name:name, Location:location, Version:version, State:state}" -o table 2>/dev/null || echo "No SQL Servers found"
    
    echo -e "\n${PURPLE}💾 SQL Databases:${NC}"
    az sql db list -g "$rg_name" --query "[].{Name:name, Server:serverName, ServiceObjective:currentServiceObjectiveName, MaxSize:maxSizeBytes}" -o table 2>/dev/null || echo "No SQL Databases found"
    
    echo -e "\n${PURPLE}🔐 Key Vaults:${NC}"
    az keyvault list -g "$rg_name" --query "[].{Name:name, Location:location, VaultURI:vaultUri, Enabled:enabledForDeployment}" -o table 2>/dev/null || echo "No Key Vaults found"
    
    echo -e "\n${PURPLE}💿 Storage Accounts:${NC}"
    az storage account list -g "$rg_name" --query "[].{Name:name, Location:location, SKU:sku.name, Kind:kind, AccessTier:accessTier}" -o table 2>/dev/null || echo "No Storage Accounts found"
    
    echo -e "\n${PURPLE}🆔 Managed Identities:${NC}"
    az identity list -g "$rg_name" --query "[].{Name:name, Location:location, PrincipalId:principalId}" -o table 2>/dev/null || echo "No Managed Identities found"
    
    echo
}

# Function to check environment-specific resources
check_environment() {
    local env=$1
    
    print_header "Checking $env Environment"
    
    # Get resource groups for this environment
    local rgs=$(az group list --query "[?contains(name, '$env')].name" -o tsv)
    
    if [ -z "$rgs" ]; then
        print_warning "No resource groups found for $env environment"
        return
    fi
    
    print_info "Found resource groups for $env:"
    echo "$rgs"
    echo
    
    # Check each resource group
    for rg in $rgs; do
        check_resources_in_rg "$rg" "$env"
    done
}

# Function to show resource costs (if Cost Management is enabled)
show_costs() {
    print_header "Resource Costs by Environment"
    
    local envs=("dev" "staging" "prod")
    
    for env in "${envs[@]}"; do
        echo -e "${PURPLE}💰 $env Environment Costs:${NC}"
        # Note: This requires Cost Management to be set up
        az consumption usage list --billing-period-name $(az billing period list --query "[0].name" -o tsv) --query "[?contains(instanceName, '$env')].{Resource:instanceName, Cost:pretaxCost, Currency:currency}" -o table 2>/dev/null || echo "Cost data not available (requires Cost Management setup)"
        echo
    done
}

# Function to check security and compliance
check_security() {
    print_header "Security & Compliance Check"
    
    # Check Key Vault access policies
    echo -e "${PURPLE}🔐 Key Vault Security:${NC}"
    az keyvault list --query "[].{Name:name, EnabledForDeployment:enabledForDeployment, EnabledForDiskEncryption:enabledForDiskEncryption, SoftDeleteRetentionDays:softDeleteRetentionInDays}" -o table
    
    # Check SQL Server security
    echo -e "\n${PURPLE}🗄️  SQL Server Security:${NC}"
    az sql server list --query "[].{Name:name, PublicNetworkAccess:publicNetworkAccess, MinimalTlsVersion:minimalTlsVersion}" -o table
    
    # Check Storage Account security
    echo -e "\n${PURPLE}💿 Storage Account Security:${NC}"
    az storage account list --query "[].{Name:name, HttpsOnly:enableHttpsTrafficOnly, AllowBlobPublicAccess:allowBlobPublicAccess}" -o table
    
    echo
}

# Function to show resource health
check_resource_health() {
    print_header "Resource Health Status"
    
    # Check AKS cluster health
    echo -e "${PURPLE}☸️  AKS Cluster Health:${NC}"
    az aks list --query "[].{Name:name, ResourceGroup:resourceGroup, Status:provisioningState, NodeCount:agentPoolProfiles[0].count}" -o table 2>/dev/null || echo "No AKS clusters found"
    
    # Check SQL Database status
    echo -e "\n${PURPLE}💾 SQL Database Status:${NC}"
    az sql db list --query "[].{Name:name, Server:serverName, Status:status, ServiceObjective:currentServiceObjectiveName}" -o table 2>/dev/null || echo "No SQL databases found"
    
    echo
}

# Main function
main() {
    print_header "Azure Resource Checker by Environment"
    
    # Check Azure login
    check_azure_login
    
    # Parse command line arguments
    if [ $# -eq 0 ]; then
        # No arguments - check all environments
        local envs=("dev" "staging" "prod")
        
        for env in "${envs[@]}"; do
            check_environment "$env"
        done
        
        check_security
        check_resource_health
        show_costs
        
    elif [ "$1" = "dev" ] || [ "$1" = "staging" ] || [ "$1" = "prod" ]; then
        # Check specific environment
        check_environment "$1"
        check_security
        check_resource_health
        
    elif [ "$1" = "security" ]; then
        # Check security only
        check_security
        
    elif [ "$1" = "health" ]; then
        # Check health only
        check_resource_health
        
    elif [ "$1" = "costs" ]; then
        # Check costs only
        show_costs
        
    else
        echo "Usage: $0 [dev|staging|prod|security|health|costs]"
        echo ""
        echo "Examples:"
        echo "  $0                    # Check all environments"
        echo "  $0 dev               # Check dev environment only"
        echo "  $0 staging           # Check staging environment only"
        echo "  $0 prod              # Check prod environment only"
        echo "  $0 security          # Check security settings only"
        echo "  $0 health            # Check resource health only"
        echo "  $0 costs             # Check costs only"
        exit 1
    fi
    
    print_success "Azure resource check completed!"
}

# Run main function with all arguments
main "$@"
