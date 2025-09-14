locals {
  common_tags = {
    "ManagedBy"   = "Terraform"
    "Owner"       = "TodoAppTeam"
    "Environment" = "staging"
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
  rg_name     = "rg-staging-todoapp-${local.unique_suffix}"
  rg_location = "centralindia"
  rg_tags     = local.common_tags
}

module "key_vault" {
  depends_on = [module.rg]
  source     = "../../modules/azurerm_key_vault"
  kv_name    = "kv-staging-${local.unique_suffix}"
  rg_name    = "rg-staging-todoapp-${local.unique_suffix}"
  location   = "centralindia"
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
    "58.84.60.35/32" # Development IP
  ]
}

module "storage_account" {
  depends_on               = [module.key_vault]
  source                   = "../../modules/azurerm_storage_account"
  sa_name                  = "sastaging${local.unique_suffix}"
  rg_name                  = "rg-staging-todoapp-${local.unique_suffix}"
  location                 = "centralindia"
  key_vault_id             = module.key_vault.key_vault_id
  tenant_id                = data.azurerm_client_config.current.tenant_id
  key_vault_access_policy  = module.key_vault.access_policy
  enable_storage_analytics = true
  tags                     = local.common_tags
}

module "acr" {
  depends_on = [module.rg]
  source     = "../../modules/azurerm_container_registry"
  acr_name   = "acrsta${local.unique_suffix}"
  rg_name    = "rg-staging-todoapp-${local.unique_suffix}"
  location   = "centralindia"
  tags       = local.common_tags
}

module "sql_server" {
  depends_on               = [module.rg, module.key_vault]
  source                   = "../../modules/azurerm_sql_server"
  sql_server_name          = "sql-staging-${local.unique_suffix}"
  rg_name                  = "rg-staging-todoapp-${local.unique_suffix}"
  location                 = "centralindia"
  admin_username           = "devopsadmin"
  admin_password           = "P@ssw0rd@456"
  key_vault_id             = module.key_vault.key_vault_id
  tenant_id                = data.azurerm_client_config.current.tenant_id
  key_vault_access_policy  = module.key_vault.access_policy
  enable_storage_analytics = true
  tags                     = local.common_tags
}

module "sql_db" {
  depends_on  = [module.sql_server]
  source      = "../../modules/azurerm_sql_database"
  sql_db_name = "sqldb-staging-todoapp"
  server_id   = module.sql_server.server_id
  max_size_gb = "5"
  tags        = local.common_tags
}

module "aks" {
  depends_on = [module.rg]
  source     = "../../modules/azurerm_kubernetes_cluster"
  aks_name   = "aks-staging-${local.unique_suffix}"
  location   = "centralindia"
  rg_name    = "rg-staging-todoapp-${local.unique_suffix}"
  dns_prefix = "aks-staging-${local.unique_suffix}"
  tags       = local.common_tags
}
