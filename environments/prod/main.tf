locals {
  common_tags = {
    "ManagedBy"   = "Terraform"
    "Owner"       = "TodoAppTeam"
    "Environment" = "production"
  }
  # Generate unique suffix for globally unique resources
  unique_suffix = substr(sha256("prod-todoapp"), 0, 8)
}

# Get current tenant and client info
data "azurerm_client_config" "current" {}

module "rg" {
  source      = "../../modules/azurerm_resource_group"
  rg_name     = "rg-prod-todoapp-${local.unique_suffix}"
  rg_location = "centralindia"
  rg_tags     = local.common_tags
}

module "acr" {
  depends_on = [module.rg]
  source     = "../../modules/azurerm_container_registry"
  acr_name   = "acrprod${local.unique_suffix}"
  rg_name    = "rg-prod-todoapp-${local.unique_suffix}"
  location   = "centralindia"
  tags       = local.common_tags
}

module "key_vault" {
  depends_on = [module.rg]
  source     = "../../modules/azurerm_key_vault"
  kv_name    = "kv-prod-${local.unique_suffix}"
  rg_name    = "rg-prod-todoapp-${local.unique_suffix}"
  location   = "centralindia"
  tags       = local.common_tags
}

module "sql_server" {
  depends_on                 = [module.rg, module.key_vault]
  source                     = "../../modules/azurerm_sql_server"
  sql_server_name            = "sql-prod-${local.unique_suffix}"
  rg_name                    = "rg-prod-todoapp-${local.unique_suffix}"
  location                   = "centralindia"
  admin_username             = "devopsadmin"
  admin_password             = "P@ssw0rd@789"
  key_vault_id               = module.key_vault.key_vault_id
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  key_vault_access_policy    = module.key_vault.access_policy
  security_alert_emails      = ["admin@todoapp.com"]
  enable_private_endpoint    = false
  enable_storage_analytics   = true
  tags                       = local.common_tags
}

module "sql_db" {
  depends_on  = [module.sql_server]
  source      = "../../modules/azurerm_sql_database"
  sql_db_name = "sqldb-prod-todoapp"
  server_id   = module.sql_server.server_id
  max_size_gb = "10"
  tags        = local.common_tags
}

module "aks" {
  depends_on = [module.rg]
  source     = "../../modules/azurerm_kubernetes_cluster"
  aks_name   = "aks-prod-${local.unique_suffix}"
  location   = "centralindia"
  rg_name    = "rg-prod-todoapp-${local.unique_suffix}"
  dns_prefix = "aks-prod-${local.unique_suffix}"
  tags       = local.common_tags
}
