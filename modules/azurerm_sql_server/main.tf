resource "azurerm_mssql_server" "sql_server" {
  name                         = var.sql_server_name
  resource_group_name          = var.rg_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
  minimum_tls_version          = "1.2"
  public_network_access_enabled = false # CKV_AZURE_113

  azuread_administrator {
    login_username = "azuread-admin"
    object_id      = data.azurerm_client_config.current.object_id
  }

  tags = var.tags
}

# Add auditing for compliance
resource "azurerm_mssql_server_extended_auditing_policy" "sql_audit" {
  server_id                               = azurerm_mssql_server.sql_server.id
  storage_endpoint                        = azurerm_storage_account.audit_storage.primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.audit_storage.primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 90 # CKV_AZURE_24
}

# Storage account for auditing
resource "azurerm_storage_account" "audit_storage" {
  name                     = "${replace(var.sql_server_name, "-", "")}audit"
  resource_group_name      = var.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = var.tags
}

data "azurerm_client_config" "current" {}
