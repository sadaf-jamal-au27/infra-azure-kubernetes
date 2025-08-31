locals {
  common_tags = {
    "ManagedBy"   = "Terraform"
    "Owner"       = "TodoAppTeam"
    "Environment" = "staging"
  }
}

module "rg" {
  source      = "../../modules/azurerm_resource_group"
  rg_name     = "rg-staging-todoapp"
  rg_location = "centralindia"
  rg_tags     = local.common_tags
}

module "acr" {
  depends_on = [module.rg]
  source     = "../../modules/azurerm_container_registry"
  acr_name   = "acrstatodoapp"
  rg_name    = "rg-staging-todoapp"
  location   = "centralindia"
  tags       = local.common_tags
}

module "sql_server" {
  depends_on      = [module.rg]
  source          = "../../modules/azurerm_sql_server"
  sql_server_name = "sql-staging-todoapp"
  rg_name         = "rg-staging-todoapp"
  location        = "centralindia"
  admin_username  = "devopsadmin"
  admin_password  = "P@ssw0rd@456"
  tags            = local.common_tags
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
  aks_name   = "aks-staging-todoapp"
  location   = "centralindia"
  rg_name    = "rg-staging-todoapp"
  dns_prefix = "aks-staging-todoapp"
  tags       = local.common_tags
}
