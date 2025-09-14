locals {
  common_tags = {
    "ManagedBy"   = "Terraform"
    "Owner"       = "TodoAppTeam"
    "Environment" = "dev"
  }
  # Generate unique suffix for globally unique resources
  unique_suffix = substr(sha256("${random_id.unique.hex}"), 0, 8)
}

resource "random_id" "unique" {
  byte_length = 4
}

# Get current tenant and client info
data "azurerm_client_config" "current" {}

module "rg" {
  source      = "../../modules/azurerm_resource_group"
  rg_name     = "rg-dev-todoapp-${local.unique_suffix}"
  rg_location = "westus2" # Changed from eastus to westus2 for better free tier support
  rg_tags     = local.common_tags
}

module "key_vault" {
  depends_on = [module.rg]
  source     = "../../modules/azurerm_key_vault"
  kv_name    = "kv-dev-${local.unique_suffix}"
  rg_name    = "rg-dev-todoapp-${local.unique_suffix}"
  location   = "westus2" # Changed from eastus to westus2
  tags       = local.common_tags

  # Allow specific IP ranges for CI/CD deployment
  allowed_ips = [
    "20.55.0.0/16",  # GitHub Actions - West US 2
    "13.64.0.0/16",  # GitHub Actions - East US
    "13.65.0.0/16",  # GitHub Actions - East US 2  
    "20.42.0.0/16",  # GitHub Actions - Central US
    "52.140.0.0/16", # GitHub Actions - Azure DevOps
    "52.234.0.0/16", # GitHub Actions - Additional range
    "52.237.0.0/16", # GitHub Actions - Additional range
    "52.250.0.0/16", # GitHub Actions - Additional range
    "20.106.0.0/16", # GitHub Actions - Additional range
    "20.112.0.0/16", # GitHub Actions - Additional range
    "20.120.0.0/16", # GitHub Actions - Additional range
    "20.150.0.0/16", # GitHub Actions - Additional range
    "64.236.0.0/16", # GitHub Actions - Additional range (covers 64.236.200.101)
    "64.237.0.0/16", # GitHub Actions - Additional range
    "64.238.0.0/16", # GitHub Actions - Additional range
    "57.151.0.0/16", # GitHub Actions - Additional range (covers 57.151.137.147)
    "48.214.0.0/16", # GitHub Actions - Additional range
    "40.74.0.0/16",  # GitHub Actions - Additional range
    "20.84.0.0/16",  # GitHub Actions - Additional range
    "58.84.60.35/32" # Development IP
  ]

  # Temporarily enable public access for development deployment
  enable_public_access = true
}

module "storage_account" {
  depends_on               = [module.key_vault]
  source                   = "../../modules/azurerm_storage_account"
  sa_name                  = "sadev${local.unique_suffix}"
  rg_name                  = "rg-dev-todoapp-${local.unique_suffix}"
  location                 = "westus2" # Changed from eastus to westus2
  key_vault_id             = module.key_vault.key_vault_id
  tenant_id                = data.azurerm_client_config.current.tenant_id
  key_vault_access_policy  = module.key_vault.access_policy
  enable_storage_analytics = false # Disable for development to avoid Azure CLI dependency
  tags                     = local.common_tags
}

module "acr" {
  depends_on = [module.rg]
  source     = "../../modules/azurerm_container_registry"
  acr_name   = "acrdev${local.unique_suffix}"
  rg_name    = "rg-dev-todoapp-${local.unique_suffix}"
  location   = "westus2" # Changed from eastus to westus2
  tags       = local.common_tags
}

module "sql_server" {
  depends_on              = [module.rg, module.key_vault]
  source                  = "../../modules/azurerm_sql_server"
  sql_server_name         = "sql-dev-${local.unique_suffix}"
  rg_name                 = "rg-dev-todoapp-${local.unique_suffix}"
  location                = "westus2" # Changed from eastus to westus2
  admin_username          = "devopsadmin"
  admin_password          = var.sql_admin_password # Use variable instead of hardcoded password
  key_vault_id            = module.key_vault.key_vault_id
  tenant_id               = data.azurerm_client_config.current.tenant_id
  key_vault_access_policy = module.key_vault.access_policy
  tags                    = local.common_tags
}

module "sql_db" {
  depends_on  = [module.sql_server]
  source      = "../../modules/azurerm_sql_database"
  sql_db_name = "sqldb-dev-todoapp"
  server_id   = module.sql_server.server_id
  max_size_gb = "2"
  tags        = local.common_tags
}

module "aks" {
  depends_on = [module.rg]
  source     = "../../modules/azurerm_kubernetes_cluster"
  aks_name   = "aks-dev-${local.unique_suffix}"
  location   = "westus2" # Changed from eastus to westus2
  rg_name    = "rg-dev-todoapp-${local.unique_suffix}"
  dns_prefix = "aks-dev-${local.unique_suffix}"
  tags       = local.common_tags
}
