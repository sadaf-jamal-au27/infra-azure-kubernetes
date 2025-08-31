data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "key_vault" {
  name                        = var.kv_name
  location                    = var.location
  resource_group_name         = var.rg_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 90   # CKV_AZURE_42 - Increased from 7
  purge_protection_enabled    = true # CKV_AZURE_110
  # Temporarily enable public access for development with IP restrictions
  public_network_access_enabled = true
  tags                          = var.tags
  sku_name                      = "premium" # Changed to premium for HSM support

  network_acls {
    default_action = "Deny" # CKV_AZURE_109
    bypass         = "AzureServices"
    # Allow access from current development IP
    ip_rules = ["58.84.60.35/32"]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

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
}
