data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "key_vault" {
  name                        = var.kv_name
  location                    = var.location
  resource_group_name         = var.rg_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 90   # CKV_AZURE_42 - Increased from 7
  purge_protection_enabled    = true  # CKV_AZURE_110
  public_network_access_enabled = false # CKV_AZURE_189
  tags                        = var.tags
  sku_name                    = "standard"

  network_acls {
    default_action = "Deny"  # CKV_AZURE_109
    bypass         = "AzureServices"
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}
