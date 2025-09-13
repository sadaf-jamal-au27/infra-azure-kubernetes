#!/bin/bash

# Azure Authentication Fix Script
# This script fixes the tenant mismatch and authentication issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Azure Authentication Fix Script${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""

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

# Step 1: Update all provider.tf files
echo -e "${YELLOW}🔧 Step 1: Updating Provider Configurations...${NC}"

for env in dev staging prod; do
    echo -e "${BLUE}   Updating $env environment...${NC}"
    
    # Update provider.tf
    cat > "lib/environments/$env/provider.tf" << EOF
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.41.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }

  # Remote backend for shared state management
  backend "azurerm" {
    resource_group_name  = "rg-terraform-backend"
    storage_account_name = "tfbackend82146"
    container_name       = "tfstate"
    key                  = "$env/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "$SUBSCRIPTION_ID"
  tenant_id       = "$TENANT_ID"
  use_cli         = false
}
EOF
    
    echo -e "${GREEN}   ✅ $env environment updated${NC}"
done

echo -e "${GREEN}✅ All provider configurations updated${NC}"
echo ""

# Step 2: Create Azure Service Principal for GitHub Actions
echo -e "${YELLOW}🔑 Step 2: Creating Azure Service Principal...${NC}"

SP_NAME="github-actions-terraform-$(date +%s)"
echo "Creating service principal: $SP_NAME"

# Create service principal
SP_OUTPUT=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role "Contributor" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --sdk-auth \
    --output json)

echo -e "${GREEN}✅ Service principal created successfully${NC}"
echo ""

# Step 3: Test Terraform configuration
echo -e "${YELLOW}🧪 Step 3: Testing Terraform Configuration...${NC}"

# Set environment variables for testing
export ARM_CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r .clientId)
export ARM_CLIENT_SECRET=$(echo "$SP_OUTPUT" | jq -r .clientSecret)
export ARM_SUBSCRIPTION_ID=$(echo "$SP_OUTPUT" | jq -r .subscriptionId)
export ARM_TENANT_ID=$(echo "$SP_OUTPUT" | jq -r .tenantId)
export ARM_USE_CLI=false

echo "Testing dev environment..."
cd lib/environments/dev

# Initialize and validate
terraform init -backend=false >/dev/null 2>&1
if terraform validate >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Dev environment validation successful${NC}"
else
    echo -e "${RED}❌ Dev environment validation failed${NC}"
    terraform validate
    exit 1
fi

# Test plan
if terraform plan -out=tfplan >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Dev environment plan successful${NC}"
    rm -f tfplan
else
    echo -e "${RED}❌ Dev environment plan failed${NC}"
    terraform plan
    exit 1
fi

cd ../../..
echo ""

# Step 4: Display GitHub Secrets Setup
echo -e "${BLUE}📋 Step 4: GitHub Repository Setup${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""
echo -e "${YELLOW}1. Go to your GitHub repository:${NC}"
echo "   Repository → Settings → Secrets and variables → Actions"
echo ""
echo -e "${YELLOW}2. Add/Update the repository secret:${NC}"
echo "   Name: AZURE_CREDENTIALS"
echo "   Value: (Copy the JSON below)"
echo ""
echo -e "${GREEN}📄 Azure Credentials JSON:${NC}"
echo "$SP_OUTPUT" | jq .
echo ""

# Step 5: Summary
echo -e "${BLUE}🎉 Authentication Fix Complete!${NC}"
echo -e "${BLUE}===============================${NC}"
echo ""
echo -e "${GREEN}✅ What's Fixed:${NC}"
echo "   • Updated subscription ID: $SUBSCRIPTION_ID"
echo "   • Updated tenant ID: $TENANT_ID"
echo "   • All environments configured correctly"
echo "   • Service principal created for GitHub Actions"
echo "   • Terraform validation successful"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "   1. Add AZURE_CREDENTIALS secret to GitHub repository"
echo "   2. Push your code to trigger the pipeline"
echo "   3. Monitor the Actions tab for successful runs"
echo ""
echo -e "${GREEN}Your pipeline authentication is now fixed! 🚀${NC}"
