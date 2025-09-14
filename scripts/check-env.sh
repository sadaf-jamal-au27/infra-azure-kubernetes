#!/bin/bash

# Quick Environment Checker
# Usage: ./scripts/check-env.sh [dev|staging|prod]

set -e

ENV=${1:-dev}

echo "🔍 Checking $ENV environment resources..."

# Check if logged into Azure
if ! az account show &>/dev/null; then
    echo "❌ Please login to Azure CLI first: az login"
    exit 1
fi

echo "✅ Azure CLI authenticated"
echo "📋 Subscription: $(az account show --query name -o tsv)"
echo

# Find resource groups for this environment
echo "🏗️  Resource Groups for $ENV:"
az group list --query "[?contains(name, '$ENV')].{Name:name, Location:location}" -o table
echo

# Get the main resource group (assuming naming convention)
MAIN_RG=$(az group list --query "[?contains(name, 'rg-$ENV')].name" -o tsv | head -1)

if [ -z "$MAIN_RG" ]; then
    echo "⚠️  No main resource group found for $ENV environment"
    echo "   Looking for pattern: rg-$ENV-*"
    exit 1
fi

echo "🎯 Main Resource Group: $MAIN_RG"
echo

# Check AKS
echo "☸️  AKS Clusters:"
az aks list -g "$MAIN_RG" --query "[].{Name:name, Status:provisioningState, NodeCount:agentPoolProfiles[0].count, VMSize:agentPoolProfiles[0].vmSize}" -o table 2>/dev/null || echo "No AKS clusters found"
echo

# Check ACR
echo "📦 Container Registry:"
az acr list -g "$MAIN_RG" --query "[].{Name:name, LoginServer:loginServer, SKU:sku.name}" -o table 2>/dev/null || echo "No ACR found"
echo

# Check SQL
echo "🗄️  SQL Server & Database:"
az sql server list -g "$MAIN_RG" --query "[].{Name:name, Version:version, State:state}" -o table 2>/dev/null || echo "No SQL Servers found"
az sql db list -g "$MAIN_RG" --query "[].{Name:name, Server:serverName, ServiceObjective:currentServiceObjectiveName}" -o table 2>/dev/null || echo "No SQL Databases found"
echo

# Check Key Vault
echo "🔐 Key Vault:"
az keyvault list -g "$MAIN_RG" --query "[].{Name:name, VaultURI:vaultUri, Enabled:enabledForDeployment}" -o table 2>/dev/null || echo "No Key Vaults found"
echo

# Check Storage
echo "💿 Storage Accounts:"
az storage account list -g "$MAIN_RG" --query "[].{Name:name, SKU:sku.name, Kind:kind}" -o table 2>/dev/null || echo "No Storage Accounts found"
echo

echo "✅ Environment check completed for $ENV!"
