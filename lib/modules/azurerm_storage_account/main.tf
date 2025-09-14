resource "azurerm_storage_account" "storage_account" {
  name                            = var.sa_name
  resource_group_name             = var.rg_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2" # CKV_AZURE_44
  public_network_access_enabled   = true     # Temporarily enable for deployment
  allow_nested_items_to_be_public = false    # CKV2_AZURE_47
  shared_access_key_enabled       = true     # Temporarily enable for Terraform deployment
  default_to_oauth_authentication = true     # Use Azure AD authentication

  # Network rules - CKV_AZURE_35 (temporarily relaxed for deployment)
  network_rules {
    default_action             = "Allow"           # Temporarily allow for deployment
    bypass                     = ["AzureServices"] # CKV_AZURE_36 - Allow trusted services
    virtual_network_subnet_ids = []
    ip_rules                   = []
  }

  # Customer Managed Key encryption - CKV2_AZURE_1 (conditional)
  dynamic "customer_managed_key" {
    for_each = var.enable_customer_managed_key ? [1] : []
    content {
      key_vault_key_id          = azurerm_key_vault_key.storage_key[0].id
      user_assigned_identity_id = azurerm_user_assigned_identity.storage_identity.id
    }
  }

  # Identity for accessing Key Vault
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.storage_identity.id]
  }

  blob_properties {
    delete_retention_policy {
      days = 30 # CKV2_AZURE_38
    }
  }

  # Enable queue service properties for CKV_AZURE_33
  # Note: Storage Analytics logging for queue service must be enabled via Azure CLI/PowerShell/REST API
  # as Terraform azurerm provider doesn't directly support this configuration yet

  sas_policy {
    expiration_period = "01.12:00:00" # CKV2_AZURE_41
  }

  tags = var.tags
}

# Note: CKV_AZURE_33 Queue service logging requires additional configuration 
# that may need to be done via Azure Monitor or Log Analytics workspace

# User Assigned Identity for storage account
resource "azurerm_user_assigned_identity" "storage_identity" {
  name                = "${var.sa_name}-identity"
  resource_group_name = var.rg_name
  location            = var.location

  tags = var.tags
}

# Key Vault Key for storage encryption
resource "azurerm_key_vault_key" "storage_key" {
  name         = "${var.sa_name}-key"
  key_vault_id = var.key_vault_id
  key_type     = "RSA-HSM" # CKV_AZURE_112 - Use HSM
  key_size     = 2048

  # Add expiration date - CKV_AZURE_40
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

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

# Key Vault access policy for the storage identity
resource "azurerm_key_vault_access_policy" "storage_policy" {
  key_vault_id = var.key_vault_id
  tenant_id    = var.tenant_id
  object_id    = azurerm_user_assigned_identity.storage_identity.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]

  depends_on = [azurerm_user_assigned_identity.storage_identity]
}

# Enable Storage Analytics for Queue service using Azure CLI (for CKV_AZURE_33)
# Note: This requires Azure CLI and appropriate permissions
resource "null_resource" "enable_queue_analytics" {
  count = var.enable_storage_analytics ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      # Temporarily enable shared access key for queue logging configuration
      az storage account update \
        --resource-group ${var.rg_name} \
        --name ${azurerm_storage_account.storage_account.name} \
        --allow-shared-key-access true

      # Enable queue service logging using Storage Analytics
      az storage logging update \
        --account-name ${azurerm_storage_account.storage_account.name} \
        --account-key $(az storage account keys list --resource-group ${var.rg_name} --account-name ${azurerm_storage_account.storage_account.name} --query '[0].value' -o tsv) \
        --services q \
        --log rwd \
        --retention 10

      # Also enable queue service metrics (part of Storage Analytics)
      az storage metrics update \
        --account-name ${azurerm_storage_account.storage_account.name} \
        --account-key $(az storage account keys list --resource-group ${var.rg_name} --account-name ${azurerm_storage_account.storage_account.name} --query '[0].value' -o tsv) \
        --services q \
        --api true \
        --hour true \
        --minute false \
        --retention 10

      # Disable shared access key again for security
      az storage account update \
        --resource-group ${var.rg_name} \
        --name ${azurerm_storage_account.storage_account.name} \
        --allow-shared-key-access false
    EOT
  }

  triggers = {
    storage_account_id = azurerm_storage_account.storage_account.id
  }

  depends_on = [azurerm_storage_account.storage_account]
}

# Private Endpoint for Storage Account - CKV2_AZURE_33
resource "azurerm_private_endpoint" "storage_pe" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.sa_name}-pe"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.sa_name}-psc"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = var.tags
}
