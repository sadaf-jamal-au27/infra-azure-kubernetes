#!/bin/bash

# Complete setup script for Terraform backend and state management
# This script sets up everything needed for proper state management

echo "🚀 Setting up Terraform Backend and State Management"
echo "=================================================="

# Variables
BACKEND_RG="rg-terraform-backend"
BACKEND_SA="tfbackend$(date +%s | tail -c 6)"  # Unique suffix
LOCATION="centralindia"
SUBSCRIPTION_ID="8cbf7ca1-02c5-4b17-aa60-0a669dc6f870"

# Step 1: Create backend infrastructure
echo "📦 Creating backend infrastructure..."

# Create resource group for Terraform backend
az group create \
  --name $BACKEND_RG \
  --location $LOCATION

# Create storage account for backend
az storage account create \
  --name $BACKEND_SA \
  --resource-group $BACKEND_RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2

# Create container for state files
az storage container create \
  --name tfstate \
  --account-name $BACKEND_SA \
  --auth-mode login

echo "✅ Backend infrastructure created:"
echo "   Resource Group: $BACKEND_RG"
echo "   Storage Account: $BACKEND_SA"
echo "   Container: tfstate"

# Step 2: Update provider.tf files
echo "📝 Updating provider.tf files with backend configuration..."

# Dev environment
cat > lib/environments/dev/provider.tf << EOF
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
    resource_group_name  = "$BACKEND_RG"
    storage_account_name = "$BACKEND_SA"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "$SUBSCRIPTION_ID"
  use_cli = false
}
EOF

# Staging environment
cat > lib/environments/staging/provider.tf << EOF
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
    resource_group_name  = "$BACKEND_RG"
    storage_account_name = "$BACKEND_SA"
    container_name       = "tfstate"
    key                  = "staging/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "$SUBSCRIPTION_ID"
  use_cli = false
}
EOF

# Production environment
cat > lib/environments/prod/provider.tf << EOF
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
    resource_group_name  = "$BACKEND_RG"
    storage_account_name = "$BACKEND_SA"
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "$SUBSCRIPTION_ID"
  use_cli = false
}
EOF

echo "✅ Provider files updated with remote backend configuration"

# Step 3: Initialize Terraform with remote backend
echo "🔧 Initializing Terraform with remote backend..."

cd lib/environments/dev
terraform init
cd ../..

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "✅ Backend Storage Account: $BACKEND_SA"
echo "✅ All environments configured for remote state"
echo "✅ Dev environment initialized"
echo ""
echo "📋 Next Steps:"
echo "1. Commit and push the updated provider.tf files"
echo "2. Use only 'git push' to deploy (never terraform apply locally)"
echo "3. Pipeline will use the shared remote state"
echo ""
echo "⚠️  Important: Save this storage account name for future reference!"
echo "   Storage Account: $BACKEND_SA"
