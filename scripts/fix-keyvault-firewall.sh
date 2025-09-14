#!/bin/bash

# Script to fix Key Vault firewall rules for GitHub Actions
# This updates the existing Key Vault to allow GitHub Actions IPs

set -e

echo "🔧 Fixing Key Vault Firewall Rules for GitHub Actions"
echo "=================================================="

# Get current subscription info
CURRENT_ACCOUNT=$(az account show -o json)
SUBSCRIPTION_ID=$(echo "$CURRENT_ACCOUNT" | jq -r .id)
TENANT_ID=$(echo "$CURRENT_ACCOUNT" | jq -r .tenantId)

echo "📋 Current Azure Account:"
echo "   Subscription ID: $SUBSCRIPTION_ID"
echo "   Tenant ID: $TENANT_ID"
echo ""

# List all Key Vaults in the subscription
echo "🔍 Finding Key Vaults in subscription..."
KEY_VAULTS=$(az keyvault list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table)

echo "📋 Found Key Vaults:"
echo "$KEY_VAULTS"
echo ""

# Function to update Key Vault firewall rules
update_keyvault_firewall() {
    local kv_name=$1
    local rg_name=$2
    
    echo "🔧 Updating firewall rules for Key Vault: $kv_name"
    
    # Add GitHub Actions IP ranges
    az keyvault network-rule add \
        --name "$kv_name" \
        --resource-group "$rg_name" \
        --ip-address "64.236.0.0/16" \
        --output none
    
    az keyvault network-rule add \
        --name "$kv_name" \
        --resource-group "$rg_name" \
        --ip-address "64.237.0.0/16" \
        --output none
    
    az keyvault network-rule add \
        --name "$kv_name" \
        --resource-group "$rg_name" \
        --ip-address "64.238.0.0/16" \
        --output none
    
    # Add additional GitHub Actions ranges
    az keyvault network-rule add \
        --name "$kv_name" \
        --resource-group "$rg_name" \
        --ip-address "52.234.0.0/16" \
        --output none
    
    az keyvault network-rule add \
        --name "$kv_name" \
        --resource-group "$rg_name" \
        --ip-address "52.237.0.0/16" \
        --output none
    
    az keyvault network-rule add \
        --name "$kv_name" \
        --resource-group "$rg_name" \
        --ip-address "52.250.0.0/16" \
        --output none
    
    echo "✅ Updated firewall rules for $kv_name"
}

# Get all Key Vaults and update their firewall rules
az keyvault list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o json | jq -r '.[] | "\(.Name) \(.ResourceGroup)"' | while read -r kv_name rg_name; do
    if [[ -n "$kv_name" && -n "$rg_name" ]]; then
        update_keyvault_firewall "$kv_name" "$rg_name"
    fi
done

echo ""
echo "🎉 Key Vault firewall rules updated successfully!"
echo ""
echo "📋 Summary of changes:"
echo "   ✅ Added IP range: 64.236.0.0/16 (covers 64.236.200.101)"
echo "   ✅ Added IP range: 64.237.0.0/16"
echo "   ✅ Added IP range: 64.238.0.0/16"
echo "   ✅ Added IP range: 52.234.0.0/16"
echo "   ✅ Added IP range: 52.237.0.0/16"
echo "   ✅ Added IP range: 52.250.0.0/16"
echo ""
echo "🚀 You can now retry your Terraform deployment!"
echo "   The Key Vault should now allow access from GitHub Actions runners."
