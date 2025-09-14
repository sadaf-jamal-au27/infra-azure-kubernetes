data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "key_vault" {
  name                        = var.kv_name
  location                    = var.location
  resource_group_name         = var.rg_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 90        # CKV_AZURE_42 - Increased from 7
  purge_protection_enabled    = true      # CKV_AZURE_110
  sku_name                    = "premium" # Changed to premium for HSM support
  # Disable public access only if private endpoint is enabled (production)
  public_network_access_enabled = var.enable_private_endpoint ? false : true # CKV_AZURE_189

  network_acls {
    default_action = var.enable_public_access ? "Allow" : "Deny" # Conditional access for deployment
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ips # CKV_AZURE_109 - Use firewall rules
  }

  tags = var.tags
}

# Access policy for current user/service principal
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Restore",
    "Recover",
    "UnwrapKey",
    "WrapKey",
    "Purge",
    "Encrypt",
    "Decrypt",
    "Sign",
    "Verify",
    "GetRotationPolicy", # CKV2_AZURE_32
    "SetRotationPolicy"  # CKV2_AZURE_32
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
  ]

  storage_permissions = [
    "Get",
    "List",
    "Delete",
    "Set",
    "Update",
    "RegenerateKey",
    "SetSAS",
    "ListSAS",
    "GetSAS",
    "DeleteSAS"
  ]
}

# Access policy for service principal (used in CI/CD pipeline)
resource "azurerm_key_vault_access_policy" "service_principal" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = "5c44e5ba-ac35-4f81-a473-e4c37c732dce" # Service principal object ID from error

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Restore",
    "Recover",
    "UnwrapKey",
    "WrapKey",
    "Purge",
    "Encrypt",
    "Decrypt",
    "Sign",
    "Verify",
    "GetRotationPolicy",
    "SetRotationPolicy"
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
  ]

  storage_permissions = [
    "Get",
    "List",
    "Delete",
    "Set",
    "Update",
    "RegenerateKey",
    "SetSAS",
    "ListSAS",
    "GetSAS",
    "DeleteSAS"
  ]
}

# Private Endpoint for Key Vault - CKV2_AZURE_32
resource "azurerm_private_endpoint" "key_vault_pe" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.kv_name}-pe"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.kv_name}-psc"
    private_connection_resource_id = azurerm_key_vault.key_vault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = var.tags
}
