#!/bin/bash

# Script to help request Azure vCPU quota increase

set -e

echo "📈 Azure vCPU Quota Increase Request Helper"
echo "=========================================="

# Get current subscription info
CURRENT_ACCOUNT=$(az account show -o json)
SUBSCRIPTION_ID=$(echo "$CURRENT_ACCOUNT" | jq -r .id)
SUBSCRIPTION_NAME=$(echo "$CURRENT_ACCOUNT" | jq -r .name)

echo "📋 Current Azure Account:"
echo "   Subscription ID: $SUBSCRIPTION_ID"
echo "   Subscription Name: $SUBSCRIPTION_NAME"
echo ""

# Check current quota
echo "🔍 Current vCPU Quota in Central India:"
CURRENT_VCPU=$(az vm list-usage --location "centralindia" --query "[?name.value=='cores'].currentValue" -o tsv)
LIMIT_VCPU=$(az vm list-usage --location "centralindia" --query "[?name.value=='cores'].limit" -o tsv)

echo "   Current vCPUs used: $CURRENT_VCPU"
echo "   Total vCPU limit: $LIMIT_VCPU"
echo "   Available vCPUs: $((LIMIT_VCPU - CURRENT_VCPU))"
echo ""

# Calculate recommended quota
RECOMMENDED_QUOTA=$((LIMIT_VCPU + 6))
echo "💡 Recommended quota increase:"
echo "   Current limit: $LIMIT_VCPU vCPUs"
echo "   Recommended: $RECOMMENDED_QUOTA vCPUs"
echo "   Additional needed: $((RECOMMENDED_QUOTA - LIMIT_VCPU)) vCPUs"
echo ""

echo "🚀 How to Request Quota Increase:"
echo "================================"
echo ""
echo "Method 1: Azure Portal (Recommended)"
echo "1. 🌐 Go to Azure Portal: https://portal.azure.com"
echo "2. 🔍 Search for 'Subscriptions'"
echo "3. 📋 Select your subscription: $SUBSCRIPTION_NAME"
echo "4. 📊 Go to 'Usage + quotas'"
echo "5. 🔍 Search for 'cores' in Central India region"
echo "6. ➕ Click 'Request increase'"
echo "7. 📝 Fill in the form:"
echo "   - Current limit: $LIMIT_VCPU"
echo "   - New limit: $RECOMMENDED_QUOTA"
echo "   - Reason: 'AKS cluster deployment for TodoApp infrastructure'"
echo "8. 📤 Submit the request"
echo ""

echo "Method 2: Azure CLI (Alternative)"
echo "1. 📝 Create a quota increase request file:"
echo "   File: quota-request.json"
echo "   Content:"
echo "   {"
echo "     \"properties\": {"
echo "       \"limit\": $RECOMMENDED_QUOTA,"
echo "       \"name\": {"
echo "         \"value\": \"cores\""
echo "       },"
echo "       \"unit\": \"Count\""
echo "     }"
echo "   }"
echo ""
echo "2. 🚀 Submit the request:"
echo "   az support tickets create \\"
echo "     --ticket-name \"vCPU Quota Increase for AKS\" \\"
echo "     --description \"Request to increase vCPU quota for AKS cluster deployment\" \\"
echo "     --problem-classification \"/providers/Microsoft.Support/services/quota_service_guid/problem_types/quota_service_problem_type_guid\" \\"
echo "     --severity \"minimal\" \\"
echo "     --contact-method \"email\" \\"
echo "     --contact-email \"your-email@domain.com\" \\"
echo "     --contact-name \"Your Name\" \\"
echo "     --contact-phone \"+1234567890\""
echo ""

echo "Method 3: Contact Azure Support"
echo "1. 📞 Call Azure Support"
echo "2. 🎯 Explain: 'Need vCPU quota increase for AKS deployment'"
echo "3. 📊 Provide:"
echo "   - Subscription ID: $SUBSCRIPTION_ID"
echo "   - Region: Central India"
echo "   - Current limit: $LIMIT_VCPU vCPUs"
echo "   - Requested limit: $RECOMMENDED_QUOTA vCPUs"
echo "   - Reason: AKS cluster deployment"
echo ""

echo "⏰ Expected Timeline:"
echo "   - Standard requests: 24-48 hours"
echo "   - Expedited requests: 4-8 hours"
echo "   - Emergency requests: 1-2 hours"
echo ""

echo "📋 What to Include in Your Request:"
echo "   - Business justification: 'AKS cluster for TodoApp infrastructure'"
echo "   - Current usage: $CURRENT_VCPU vCPUs"
echo "   - Requested increase: $((RECOMMENDED_QUOTA - LIMIT_VCPU)) vCPUs"
echo "   - Region: Central India"
echo "   - VM series: Standard_B series (for AKS nodes)"
echo "   - Timeline: 'ASAP for production deployment'"
echo ""

echo "🔄 After Quota Increase:"
echo "1. ✅ Verify quota increase in Azure Portal"
echo "2. 🔧 Uncomment AKS modules in main.tf files"
echo "3. 🚀 Retry Terraform deployment"
echo "4. 🎉 AKS cluster will deploy successfully"
echo ""

echo "💡 Alternative Solutions (if quota increase is delayed):"
echo "1. 🗑️  Delete unused resources to free up vCPUs"
echo "2. 🔄 Use different region with available quota"
echo "3. 📉 Use smaller VM sizes (if quota allows)"
echo "4. ⏸️  Deploy AKS later after quota increase"
echo ""

echo "🎯 Next Steps:"
echo "1. 📈 Request quota increase using one of the methods above"
echo "2. ⏳ Wait for approval (usually 24-48 hours)"
echo "3. 🔧 Uncomment AKS modules in main.tf files"
echo "4. 🚀 Retry Terraform deployment"
echo "5. 🎉 AKS cluster will deploy successfully"
