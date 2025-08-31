resource "azurerm_storage_account" "storage_account" {
  name                            = var.sa_name
  resource_group_name             = var.rg_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2"   # CKV_AZURE_44
  public_network_access_enabled   = false     # CKV_AZURE_59, CKV_AZURE_190
  allow_nested_items_to_be_public = false     # CKV2_AZURE_47
  shared_access_key_enabled       = false     # CKV2_AZURE_40

  blob_properties {
    delete_retention_policy {
      days = 30 # CKV2_AZURE_38
    }
  }

  sas_policy {
    expiration_period = "01.12:00:00" # CKV2_AZURE_41
  }

  tags = var.tags
}
