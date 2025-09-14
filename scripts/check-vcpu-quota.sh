#!/bin/bash

# Script to check Azure vCPU quota and suggest optimal VM sizes

set -e

echo "🔍 Checking Azure vCPU Quota and VM Size Options"
echo "================================================"

# Get current subscription info
CURRENT_ACCOUNT=$(az account show -o json)
SUBSCRIPTION_ID=$(echo "$CURRENT_ACCOUNT" | jq -r .id)
TENANT_ID=$(echo "$CURRENT_ACCOUNT" | jq -r .tenantId)

echo "📋 Current Azure Account:"
echo "   Subscription ID: $SUBSCRIPTION_ID"
echo "   Tenant ID: $TENANT_ID"
echo ""

# Check quota for Central India region
echo "🔍 Checking vCPU quota for Central India region..."
QUOTA_INFO=$(az vm list-usage --location "centralindia" --query "[?name.value=='cores'].{Name:name.value, Current:currentValue, Limit:limit}" -o table)

echo "📊 Current vCPU Quota in Central India:"
echo "$QUOTA_INFO"
echo ""

# Get current quota values
CURRENT_VCPU=$(az vm list-usage --location "centralindia" --query "[?name.value=='cores'].currentValue" -o tsv)
LIMIT_VCPU=$(az vm list-usage --location "centralindia" --query "[?name.value=='cores'].limit" -o tsv)
AVAILABLE_VCPU=$((LIMIT_VCPU - CURRENT_VCPU))

echo "📈 Quota Summary:"
echo "   Current vCPUs used: $CURRENT_VCPU"
echo "   Total vCPU limit: $LIMIT_VCPU"
echo "   Available vCPUs: $AVAILABLE_VCPU"
echo ""

# Suggest VM sizes based on available quota
echo "💡 Recommended VM Sizes for AKS:"
echo ""

if [ $AVAILABLE_VCPU -ge 2 ]; then
    echo "✅ Standard_B2s (2 vCPUs, 4GB RAM) - RECOMMENDED"
    echo "   - Minimal production-ready size"
    echo "   - Good for small workloads"
    echo "   - Cost-effective"
    echo ""
fi

if [ $AVAILABLE_VCPU -ge 1 ]; then
    echo "⚠️  Standard_B1s (1 vCPU, 1GB RAM) - MINIMAL"
    echo "   - Absolute minimum for AKS"
    echo "   - May have performance issues"
    echo "   - Only for testing/development"
    echo ""
fi

if [ $AVAILABLE_VCPU -eq 0 ]; then
    echo "❌ No vCPUs available - Need quota increase"
    echo ""
    echo "🚀 To request quota increase:"
    echo "   1. Go to Azure Portal"
    echo "   2. Navigate to Subscriptions → Your Subscription"
    echo "   3. Go to Usage + quotas"
    echo "   4. Search for 'cores' in Central India"
    echo "   5. Click 'Request increase'"
    echo "   6. Request at least 4-6 vCPUs for AKS"
    echo ""
    echo "📞 Alternative: Contact Azure Support"
    echo "   - Support can expedite quota increases"
    echo "   - Usually processed within 24-48 hours"
    echo ""
fi

# Show current AKS configuration
echo "🔧 Current AKS Configuration:"
echo "   VM Size: Standard_B2s (2 vCPUs)"
echo "   Node Count: 1"
echo "   Total vCPUs needed: 2"
echo ""

# Suggest alternatives
echo "🛠️  Alternative Solutions:"
echo ""
echo "1. 📉 Reduce VM Size (if quota allows):"
echo "   - Change to Standard_B1s (1 vCPU)"
echo "   - Update variables.tf"
echo ""
echo "2. 🚫 Temporarily Disable AKS:"
echo "   - Comment out AKS module in main.tf"
echo "   - Deploy other resources first"
echo "   - Enable AKS after quota increase"
echo ""
echo "3. 🔄 Use Different Region:"
echo "   - Deploy AKS in a region with available quota"
echo "   - Update location in main.tf"
echo ""
echo "4. 📈 Request Quota Increase:"
echo "   - Request 4-6 vCPUs for Central India"
echo "   - Usually approved within 24-48 hours"
echo ""

# Check if we can proceed with current quota
if [ $AVAILABLE_VCPU -ge 2 ]; then
    echo "✅ You have enough quota to proceed with AKS deployment!"
    echo "   Current configuration should work."
elif [ $AVAILABLE_VCPU -ge 1 ]; then
    echo "⚠️  You can proceed with minimal AKS configuration."
    echo "   Consider requesting quota increase for better performance."
else
    echo "❌ Insufficient quota for AKS deployment."
    echo "   You need to request quota increase first."
fi
