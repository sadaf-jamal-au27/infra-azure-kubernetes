resource "azurerm_mssql_server" "sql_server" {
  name                          = var.sql_server_name
  resource_group_name           = var.rg_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.admin_username
  administrator_login_password  = var.admin_password
  minimum_tls_version           = "1.2"
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
  name                            = "${replace(var.sql_server_name, "-", "")}audit"
  resource_group_name             = var.rg_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  # Customer Managed Key encryption - CKV2_AZURE_1
  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.audit_key.id
    user_assigned_identity_id = azurerm_user_assigned_identity.audit_identity.id
  }

  # Identity for accessing Key Vault
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.audit_identity.id]
  }

  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }

  sas_policy {
    expiration_period = "01.12:00:00"
  }

  tags = var.tags
}

# User Assigned Identity for audit storage account
resource "azurerm_user_assigned_identity" "audit_identity" {
  name                = "${var.sql_server_name}-audit-identity"
  resource_group_name = var.rg_name
  location            = var.location

  tags = var.tags
}

# Key Vault Key for audit storage encryption
resource "azurerm_key_vault_key" "audit_key" {
  name         = "${var.sql_server_name}-audit-key"
  key_vault_id = var.key_vault_id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  tags = var.tags

  depends_on = [var.key_vault_access_policy]
}

# Key Vault access policy for the audit storage identity
resource "azurerm_key_vault_access_policy" "audit_policy" {
  key_vault_id = var.key_vault_id
  tenant_id    = var.tenant_id
  object_id    = azurerm_user_assigned_identity.audit_identity.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]

  depends_on = [azurerm_user_assigned_identity.audit_identity]
}

data "azurerm_client_config" "current" {}
