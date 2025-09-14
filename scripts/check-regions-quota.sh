#!/bin/bash

# Script to check vCPU quota across multiple Azure regions

set -e

echo "🌍 Checking vCPU Quota Across Azure Regions"
echo "=========================================="

# Get current subscription info
CURRENT_ACCOUNT=$(az account show -o json)
SUBSCRIPTION_ID=$(echo "$CURRENT_ACCOUNT" | jq -r .id)

echo "📋 Subscription: $SUBSCRIPTION_ID"
echo ""

# List of regions to check (major Azure regions)
REGIONS=(
    "eastus"
    "eastus2" 
    "westus"
    "westus2"
    "centralus"
    "southcentralus"
    "northcentralus"
    "westcentralus"
    "canadacentral"
    "canadaeast"
    "westeurope"
    "northeurope"
    "uksouth"
    "ukwest"
    "francecentral"
    "francesouth"
    "germanywestcentral"
    "switzerlandnorth"
    "norwayeast"
    "swedencentral"
    "italynorth"
    "polandcentral"
    "austriaeast"
    "belgiumcentral"
    "spaincentral"
    "portugalcentral"
    "denmarkeast"
    "finlandcentral"
    "czechrepubliccentral"
    "hungarycentral"
    "slovakiacentral"
    "sloveniacentral"
    "croatia"
    "romaniaeast"
    "bulgaria"
    "greece"
    "turkey"
    "israel"
    "southafricanorth"
    "southafricawest"
    "uaenorth"
    "uaecentral"
    "qatar"
    "kuwait"
    "bahrain"
    "oman"
    "saudiarabia"
    "japanwest"
    "japaneast"
    "koreacentral"
    "koreasouth"
    "southeastasia"
    "eastasia"
    "australiaeast"
    "australiasoutheast"
    "australiacentral"
    "australiacentral2"
    "newzealand"
    "brazilsouth"
    "brazilsoutheast"
    "chile"
    "colombia"
    "mexico"
    "peru"
    "argentina"
    "uruguay"
    "paraguay"
    "bolivia"
    "ecuador"
    "venezuela"
    "guyana"
    "suriname"
    "frenchguiana"
    "centralindia"
    "southindia"
    "westindia"
    "japaneast"
    "japanwest"
    "koreacentral"
    "koreasouth"
    "southeastasia"
    "eastasia"
    "australiaeast"
    "australiasoutheast"
    "australiacentral"
    "australiacentral2"
    "newzealand"
    "brazilsouth"
    "brazilsoutheast"
    "chile"
    "colombia"
    "mexico"
    "peru"
    "argentina"
    "uruguay"
    "paraguay"
    "bolivia"
    "ecuador"
    "venezuela"
    "guyana"
    "suriname"
    "frenchguiana"
)

echo "🔍 Checking vCPU quota in multiple regions..."
echo ""

# Function to check quota for a region
check_region_quota() {
    local region=$1
    local current=$(az vm list-usage --location "$region" --query "[?name.value=='cores'].currentValue" -o tsv 2>/dev/null || echo "0")
    local limit=$(az vm list-usage --location "$region" --query "[?name.value=='cores'].limit" -o tsv 2>/dev/null || echo "0")
    local available=$((limit - current))
    
    if [ $available -ge 2 ]; then
        echo "✅ $region: $available vCPUs available (limit: $limit, used: $current)"
        return 0
    elif [ $available -ge 1 ]; then
        echo "⚠️  $region: $available vCPUs available (limit: $limit, used: $current)"
        return 1
    else
        echo "❌ $region: $available vCPUs available (limit: $limit, used: $current)"
        return 2
    fi
}

# Check regions and collect results
GOOD_REGIONS=()
WARNING_REGIONS=()
BAD_REGIONS=()

for region in "${REGIONS[@]}"; do
    if check_region_quota "$region"; then
        GOOD_REGIONS+=("$region")
    elif [ $? -eq 1 ]; then
        WARNING_REGIONS+=("$region")
    else
        BAD_REGIONS+=("$region")
    fi
done

echo ""
echo "📊 Summary Results:"
echo "=================="

if [ ${#GOOD_REGIONS[@]} -gt 0 ]; then
    echo "✅ Regions with 2+ vCPUs available (Good for AKS):"
    for region in "${GOOD_REGIONS[@]}"; do
        echo "   - $region"
    done
    echo ""
fi

if [ ${#WARNING_REGIONS[@]} -gt 0 ]; then
    echo "⚠️  Regions with 1 vCPU available (Minimal AKS):"
    for region in "${WARNING_REGIONS[@]}"; do
        echo "   - $region"
    done
    echo ""
fi

if [ ${#BAD_REGIONS[@]} -gt 0 ]; then
    echo "❌ Regions with 0 vCPUs available:"
    echo "   (${#BAD_REGIONS[@]} regions checked)"
    echo ""
fi

# Show top 5 recommendations
echo "🎯 Top 5 Recommended Regions for AKS:"
echo "======================================"
if [ ${#GOOD_REGIONS[@]} -gt 0 ]; then
    for i in {0..4}; do
        if [ $i -lt ${#GOOD_REGIONS[@]} ]; then
            region=${GOOD_REGIONS[$i]}
            available=$(az vm list-usage --location "$region" --query "[?name.value=='cores'].limit" -o tsv)
            current=$(az vm list-usage --location "$region" --query "[?name.value=='cores'].currentValue" -o tsv)
            available=$((available - current))
            echo "$((i+1)). $region - $available vCPUs available"
        fi
    done
else
    echo "❌ No regions found with sufficient vCPU quota"
fi

echo ""
echo "🛠️  How to Change Region:"
echo "========================"
echo "1. Edit lib/environments/*/main.tf files"
echo "2. Change location from 'centralindia' to your chosen region"
echo "3. Example:"
echo "   location = \"eastus\"  # Instead of centralindia"
echo ""

echo "💡 Alternative VM Sizes (if quota is limited):"
echo "============================================="
echo "Standard_B1s: 1 vCPU, 1GB RAM (Minimal)"
echo "Standard_B1ms: 1 vCPU, 2GB RAM (Better)"
echo "Standard_B2s: 2 vCPUs, 4GB RAM (Recommended)"
echo "Standard_B2ms: 2 vCPUs, 8GB RAM (Good)"
echo ""

echo "🚀 Next Steps:"
echo "=============="
if [ ${#GOOD_REGIONS[@]} -gt 0 ]; then
    echo "1. Choose a region from the 'Good' list above"
    echo "2. Update location in main.tf files"
    echo "3. Uncomment AKS modules"
    echo "4. Deploy infrastructure"
else
    echo "1. Request quota increase for Central India"
    echo "2. Or choose a region from the 'Warning' list"
    echo "3. Use minimal VM size (Standard_B1s)"
fi
