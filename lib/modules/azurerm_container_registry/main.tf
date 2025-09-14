resource "azurerm_container_registry" "acr" {
  name                          = var.acr_name
  resource_group_name           = var.rg_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false # CKV_AZURE_139
  zone_redundancy_enabled       = true  # CKV_AZURE_233
  data_endpoint_enabled         = true  # CKV_AZURE_237
  trust_policy_enabled          = true  # CKV_AZURE_164
  quarantine_policy_enabled     = true  # CKV_AZURE_166

  # Enable retention policy - CKV_AZURE_167
  retention_policy_in_days = 7

  georeplications {
    location                = "westus2"
    zone_redundancy_enabled = true
  }

  tags = var.tags
}
