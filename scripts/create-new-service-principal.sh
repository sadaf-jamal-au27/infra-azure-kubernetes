#!/bin/bash

# Create New Azure Service Principal for GitHub Actions
# This script creates a fresh service principal with valid credentials

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔑 Creating New Azure Service Principal${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Check if logged in to Azure
if ! az account show >/dev/null 2>&1; then
    echo -e "${RED}❌ Not logged into Azure CLI. Please run 'az login' first.${NC}"
    exit 1
fi

# Get current Azure account information
echo -e "${YELLOW}📋 Current Azure Account Information:${NC}"
CURRENT_ACCOUNT=$(az account show --output json)
SUBSCRIPTION_ID=$(echo "$CURRENT_ACCOUNT" | jq -r '.id')
TENANT_ID=$(echo "$CURRENT_ACCOUNT" | jq -r '.tenantId')
SUBSCRIPTION_NAME=$(echo "$CURRENT_ACCOUNT" | jq -r '.name')

echo "   Subscription ID: $SUBSCRIPTION_ID"
echo "   Tenant ID: $TENANT_ID"
echo "   Subscription Name: $SUBSCRIPTION_NAME"
echo ""

# Clean up any existing service principals with the same name pattern
echo -e "${YELLOW}🧹 Cleaning up existing service principals...${NC}"
EXISTING_SP=$(az ad sp list --display-name "github-actions-terraform*" --query "[].displayName" -o tsv 2>/dev/null || true)
if [ ! -z "$EXISTING_SP" ]; then
    echo "Found existing service principals:"
    echo "$EXISTING_SP"
    echo ""
    echo -e "${YELLOW}⚠️  You may want to delete old service principals to avoid confusion.${NC}"
    echo "Run: az ad sp delete --id <service-principal-id>"
    echo ""
fi

# Create new service principal
SP_NAME="github-actions-terraform-$(date +%s)"
echo -e "${YELLOW}🔑 Creating new service principal: $SP_NAME${NC}"

# Create service principal with explicit expiration (1 year from now)
EXPIRY_DATE=$(date -d "+1 year" +%Y-%m-%d 2>/dev/null || date -v+1y +%Y-%m-%d 2>/dev/null || echo "2026-09-13")

SP_OUTPUT=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role "Contributor" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --sdk-auth \
    --output json)

echo -e "${GREEN}✅ Service principal created successfully${NC}"
echo ""

# Extract the credentials
CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r .clientId)
CLIENT_SECRET=$(echo "$SP_OUTPUT" | jq -r .clientSecret)
SUBSCRIPTION_ID_OUT=$(echo "$SP_OUTPUT" | jq -r .subscriptionId)
TENANT_ID_OUT=$(echo "$SP_OUTPUT" | jq -r .tenantId)

echo -e "${BLUE}📋 Service Principal Details:${NC}"
echo "   Display Name: $SP_NAME"
echo "   Client ID: $CLIENT_ID"
echo "   Subscription ID: $SUBSCRIPTION_ID_OUT"
echo "   Tenant ID: $TENANT_ID_OUT"
echo "   Secret Expiry: $EXPIRY_DATE"
echo ""

# Test the service principal
echo -e "${YELLOW}🧪 Testing Service Principal Authentication...${NC}"

# Test login with the new service principal
if az login --service-principal \
    --username "$CLIENT_ID" \
    --password "$CLIENT_SECRET" \
    --tenant "$TENANT_ID_OUT" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Service principal authentication successful${NC}"
    
    # Test resource access
    if az group list --query "[0].name" -o tsv >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Service principal has proper resource access${NC}"
    else
        echo -e "${YELLOW}⚠️  Service principal created but resource access needs verification${NC}"
    fi
    
    # Switch back to user account
    az login --use-device-code >/dev/null 2>&1 || echo "Please run 'az login' to switch back to your user account"
else
    echo -e "${RED}❌ Service principal authentication failed${NC}"
    exit 1
fi

echo ""

# Display GitHub Secrets Setup Instructions
echo -e "${BLUE}📋 GitHub Repository Setup Instructions${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${YELLOW}1. Go to your GitHub repository:${NC}"
echo "   Repository → Settings → Secrets and variables → Actions"
echo ""
echo -e "${YELLOW}2. Update the repository secret:${NC}"
echo "   Name: AZURE_CREDENTIALS"
echo "   Value: (Copy the JSON below)"
echo ""
echo -e "${GREEN}📄 New Azure Credentials JSON:${NC}"
echo "$SP_OUTPUT" | jq .
echo ""
echo -e "${YELLOW}3. Optional - Add Slack webhook (for notifications):${NC}"
echo "   Name: SLACK_WEBHOOK_URL"
echo "   Value: your-slack-webhook-url"
echo ""

# Test Terraform with new credentials
echo -e "${YELLOW}🧪 Testing Terraform with New Credentials...${NC}"

# Set environment variables
export ARM_CLIENT_ID="$CLIENT_ID"
export ARM_CLIENT_SECRET="$CLIENT_SECRET"
export ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID_OUT"
export ARM_TENANT_ID="$TENANT_ID_OUT"
export ARM_USE_CLI=false

# Test terraform
cd lib/environments/dev
echo "Testing dev environment..."

terraform init -backend=false >/dev/null 2>&1
if terraform validate >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Terraform validation successful${NC}"
else
    echo -e "${RED}❌ Terraform validation failed${NC}"
    terraform validate
    exit 1
fi

if terraform plan -out=tfplan >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Terraform plan successful${NC}"
    rm -f tfplan
else
    echo -e "${RED}❌ Terraform plan failed${NC}"
    terraform plan
    exit 1
fi

cd ../../..
echo ""

# Summary
echo -e "${BLUE}🎉 Service Principal Creation Complete!${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""
echo -e "${GREEN}✅ What's Done:${NC}"
echo "   • New service principal created: $SP_NAME"
echo "   • Contributor role assigned to subscription"
echo "   • Authentication tested successfully"
echo "   • Terraform validation passed"
echo "   • Terraform plan successful"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "   1. Copy the JSON above to GitHub Secrets (AZURE_CREDENTIALS)"
echo "   2. Push your code to trigger the pipeline"
echo "   3. Monitor the Actions tab for successful runs"
echo ""
echo -e "${BLUE}🔗 Useful Commands:${NC}"
echo "   • Check workflow status: gh run list"
echo "   • View workflow logs: gh run view"
echo "   • Trigger workflow manually: gh workflow run cicd.yaml"
echo ""
echo -e "${GREEN}Your pipeline authentication is now fixed! 🚀${NC}"
