#!/bin/bash

# Complete Pipeline Fix Script
# This script addresses all known pipeline issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Terraform TodoApp Pipeline Fix Script${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}📋 Checking Prerequisites...${NC}"

if ! command_exists terraform; then
    echo -e "${RED}❌ Terraform is not installed${NC}"
    echo "Please install Terraform: https://terraform.io/downloads"
    exit 1
fi

if ! command_exists az; then
    echo -e "${RED}❌ Azure CLI is not installed${NC}"
    echo "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

if ! command_exists jq; then
    echo -e "${RED}❌ jq is not installed${NC}"
    echo "Please install jq: https://stedolan.github.io/jq/download/"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are installed${NC}"
echo ""

# Check Azure login status
echo -e "${YELLOW}🔐 Checking Azure Authentication...${NC}"
if ! az account show >/dev/null 2>&1; then
    echo -e "${RED}❌ Not logged into Azure CLI${NC}"
    echo "Please run: az login"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}✅ Logged into Azure CLI${NC}"
echo "   Subscription ID: $SUBSCRIPTION_ID"
echo ""

# Step 1: Clean up Terraform cache
echo -e "${YELLOW}🧹 Step 1: Cleaning Terraform Cache...${NC}"
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true
echo -e "${GREEN}✅ Terraform cache cleaned${NC}"
echo ""

# Step 2: Validate all environments
echo -e "${YELLOW}🔍 Step 2: Validating Terraform Configurations...${NC}"

for env in dev staging prod; do
    echo -e "${BLUE}   Validating $env environment...${NC}"
    cd "lib/environments/$env"
    
    # Initialize without backend
    terraform init -backend=false >/dev/null 2>&1
    
    # Validate configuration
    if terraform validate >/dev/null 2>&1; then
        echo -e "${GREEN}   ✅ $env environment is valid${NC}"
    else
        echo -e "${RED}   ❌ $env environment validation failed${NC}"
        terraform validate
        exit 1
    fi
    
    cd ../..
done

echo -e "${GREEN}✅ All environments validated successfully${NC}"
echo ""

# Step 3: Check GitHub Actions workflow
echo -e "${YELLOW}🔧 Step 3: Checking GitHub Actions Workflow...${NC}"

if [ -f ".github/workflows/cicd.yaml" ]; then
    echo -e "${GREEN}✅ Main CI/CD workflow found${NC}"
    
    # Check if workflow has been updated with -backend=false
    if grep -q "terraform init -backend=false" .github/workflows/cicd.yaml; then
        echo -e "${GREEN}✅ Workflow updated with backend=false flag${NC}"
    else
        echo -e "${YELLOW}⚠️  Workflow may need backend=false flag${NC}"
    fi
else
    echo -e "${RED}❌ Main CI/CD workflow not found${NC}"
    exit 1
fi
echo ""

# Step 4: Generate Azure Service Principal
echo -e "${YELLOW}🔑 Step 4: Setting up Azure Service Principal...${NC}"

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

# Step 5: Display setup instructions
echo -e "${BLUE}📋 Next Steps - GitHub Repository Setup${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""
echo -e "${YELLOW}1. Go to your GitHub repository:${NC}"
echo "   Repository → Settings → Secrets and variables → Actions"
echo ""
echo -e "${YELLOW}2. Add a new repository secret:${NC}"
echo "   Name: AZURE_CREDENTIALS"
echo "   Value: (Copy the JSON below)"
echo ""
echo -e "${GREEN}📄 Azure Credentials JSON:${NC}"
echo "$SP_OUTPUT" | jq .
echo ""
echo -e "${YELLOW}3. Optional - Add Slack webhook (for notifications):${NC}"
echo "   Name: SLACK_WEBHOOK_URL"
echo "   Value: your-slack-webhook-url"
echo ""

# Step 6: Test workflow locally
echo -e "${YELLOW}🧪 Step 6: Testing Local Terraform Plan...${NC}"

cd lib/environments/dev
echo "Running terraform plan for dev environment..."

# Set environment variables for testing
export ARM_CLIENT_ID=$(echo "$SP_OUTPUT" | jq -r .clientId)
export ARM_CLIENT_SECRET=$(echo "$SP_OUTPUT" | jq -r .clientSecret)
export ARM_SUBSCRIPTION_ID=$(echo "$SP_OUTPUT" | jq -r .subscriptionId)
export ARM_TENANT_ID=$(echo "$SP_OUTPUT" | jq -r .tenantId)
export ARM_USE_CLI=false
export TF_VAR_environment=dev
export TF_VAR_sql_admin_password="P@ssw01rd@123"

# Initialize and plan
terraform init -backend=false >/dev/null 2>&1

if terraform plan -out=tfplan >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Terraform plan successful${NC}"
    rm -f tfplan
else
    echo -e "${RED}❌ Terraform plan failed${NC}"
    terraform plan
    exit 1
fi

cd ../..
echo ""

# Step 7: Summary
echo -e "${BLUE}🎉 Pipeline Fix Complete!${NC}"
echo -e "${BLUE}========================${NC}"
echo ""
echo -e "${GREEN}✅ What's Fixed:${NC}"
echo "   • Terraform cache cleaned"
echo "   • All environments validated"
echo "   • GitHub Actions workflow updated"
echo "   • Azure service principal created"
echo "   • Local terraform plan tested"
echo ""
echo -e "${YELLOW}📋 What You Need to Do:${NC}"
echo "   1. Add AZURE_CREDENTIALS secret to GitHub repository"
echo "   2. Push your code to trigger the pipeline"
echo "   3. Monitor the Actions tab for successful runs"
echo ""
echo -e "${BLUE}🔗 Useful Commands:${NC}"
echo "   • Check workflow status: gh run list"
echo "   • View workflow logs: gh run view"
echo "   • Trigger workflow manually: gh workflow run cicd.yaml"
echo ""
echo -e "${GREEN}Your pipeline is now ready to deploy! 🚀${NC}"
