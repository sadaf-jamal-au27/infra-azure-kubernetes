#!/bin/bash

# Script to import existing resources into Terraform state
# Use this if you already created resources locally and want to manage them via pipeline

# Set variables
RESOURCE_GROUP="rg-dev-todoapp-f7aabf0c"  # Update with your actual RG name
UNIQUE_SUFFIX="f7aabf0c"                   # Update with your actual suffix

echo "🔄 Importing existing Azure resources into Terraform state..."

# Navigate to dev environment
cd environments/dev

# Initialize Terraform with remote backend
terraform init

# Import Resource Group
echo "Importing Resource Group..."
terraform import module.rg.azurerm_resource_group.rg "/subscriptions/a72674d0-171e-41fb-bed8-d50db63bc0b4/resourceGroups/${RESOURCE_GROUP}"

# Import Key Vault
echo "Importing Key Vault..."
terraform import module.key_vault.azurerm_key_vault.key_vault "/subscriptions/a72674d0-171e-41fb-bed8-d50db63bc0b4/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.KeyVault/vaults/kv-dev-${UNIQUE_SUFFIX}"

# Import Storage Account
echo "Importing Storage Account..."
terraform import module.storage_account.azurerm_storage_account.storage_account "/subscriptions/a72674d0-171e-41fb-bed8-d50db63bc0b4/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/sadev${UNIQUE_SUFFIX}"

# Import Container Registry
echo "Importing Container Registry..."
terraform import module.acr.azurerm_container_registry.acr "/subscriptions/a72674d0-171e-41fb-bed8-d50db63bc0b4/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerRegistry/registries/acrdev${UNIQUE_SUFFIX}"

# Import SQL Server
echo "Importing SQL Server..."
terraform import module.sql_server.azurerm_mssql_server.sql_server "/subscriptions/a72674d0-171e-41fb-bed8-d50db63bc0b4/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Sql/servers/sql-dev-${UNIQUE_SUFFIX}"

# Import SQL Database
echo "Importing SQL Database..."
terraform import module.sql_db.azurerm_mssql_database.sql_db "/subscriptions/a72674d0-171e-41fb-bed8-d50db63bc0b4/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Sql/servers/sql-dev-${UNIQUE_SUFFIX}/databases/sqldb-dev-todoapp"

# Import AKS Cluster
echo "Importing AKS Cluster..."
terraform import module.aks.azurerm_kubernetes_cluster.aks "/subscriptions/a72674d0-171e-41fb-bed8-d50db63bc0b4/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/aks-dev-${UNIQUE_SUFFIX}"

echo "✅ Import completed! Run 'terraform plan' to verify state matches configuration."
echo "⚠️  You may need to update the UNIQUE_SUFFIX and resource names above to match your actual resources."
