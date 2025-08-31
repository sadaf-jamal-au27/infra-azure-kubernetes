#!/bin/bash

# Bootstrap script to create Terraform backend storage
# This creates the Azure Storage Account needed for remote state

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Bootstrapping Terraform Backend Storage...${NC}"

# Check if required environment variables are set
if [[ -z "$ARM_SUBSCRIPTION_ID" ]]; then
    echo -e "${RED}❌ ARM_SUBSCRIPTION_ID environment variable is required${NC}"
    exit 1
fi

# Parameters
ENVIRONMENT=${1:-"dev"}
LOCATION=${2:-"centralindia"}
RESOURCE_GROUP_NAME="rg-tfstate-${ENVIRONMENT}"
STORAGE_ACCOUNT_NAME="satfstate${ENVIRONMENT}001"
CONTAINER_NAME="tfstate"

echo -e "${YELLOW}📋 Configuration:${NC}"
echo "  Environment: $ENVIRONMENT"
echo "  Location: $LOCATION"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
echo "  Container: $CONTAINER_NAME"
echo ""

# Check if logged in to Azure
if ! az account show &>/dev/null; then
    echo -e "${RED}❌ Not logged in to Azure. Please run 'az login' first.${NC}"
    exit 1
fi

# Set the subscription
echo -e "${YELLOW}🔧 Setting subscription...${NC}"
az account set --subscription "$ARM_SUBSCRIPTION_ID"

# Create resource group if it doesn't exist
echo -e "${YELLOW}🏗️  Creating resource group...${NC}"
if az group show --name "$RESOURCE_GROUP_NAME" &>/dev/null; then
    echo -e "${GREEN}✅ Resource group already exists${NC}"
else
    az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"
    echo -e "${GREEN}✅ Resource group created${NC}"
fi

# Create storage account if it doesn't exist
echo -e "${YELLOW}💾 Creating storage account...${NC}"
if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
    echo -e "${GREEN}✅ Storage account already exists${NC}"
else
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku "Standard_LRS" \
        --kind "StorageV2" \
        --min-tls-version "TLS1_2" \
        --allow-blob-public-access false \
        --encryption-services "blob" \
        --encryption-services "file"
    
    echo -e "${GREEN}✅ Storage account created${NC}"
fi

# Get storage account key
echo -e "${YELLOW}🔑 Getting storage account key...${NC}"
STORAGE_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP_NAME" --account-name "$STORAGE_ACCOUNT_NAME" --query '[0].value' -o tsv)

# Create storage container if it doesn't exist
echo -e "${YELLOW}📦 Creating storage container...${NC}"
if az storage container show --name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT_NAME" --account-key "$STORAGE_KEY" &>/dev/null; then
    echo -e "${GREEN}✅ Storage container already exists${NC}"
else
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --account-key "$STORAGE_KEY" \
        --public-access "off"
    
    echo -e "${GREEN}✅ Storage container created${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Backend bootstrap completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Backend Configuration:${NC}"
echo "  resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "  storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "  container_name       = \"$CONTAINER_NAME\""
echo "  key                  = \"${ENVIRONMENT}.terraform.tfstate\""
echo ""
echo -e "${YELLOW}💡 You can now run 'terraform init' in the $ENVIRONMENT environment.${NC}"
