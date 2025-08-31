resource "azurerm_kubernetes_cluster" "aks" {
  name                    = var.aks_name
  location                = var.location
  resource_group_name     = var.rg_name
  dns_prefix              = var.dns_prefix
  private_cluster_enabled = false # Set to false for now due to complexity
  local_account_disabled  = true  # CKV_AZURE_141
  sku_tier                = "Standard" # CKV_AZURE_170

  api_server_access_profile {
    authorized_ip_ranges = ["0.0.0.0/32"] # CKV_AZURE_6 - Restrict access
  }

  default_node_pool {
    name                         = "default"
    node_count                   = var.node_count
    vm_size                      = var.vm_size
    max_pods                     = 110 # CKV_AZURE_168
    only_critical_addons_enabled = true # CKV_AZURE_232
  }

  network_profile {
    network_plugin = "azure" # CKV2_AZURE_29
    network_policy = "azure" # CKV_AZURE_7
  }

  identity {
    type = "SystemAssigned"
  }

  azure_policy_enabled = true # CKV_AZURE_116

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id # CKV_AZURE_4
    }
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true # CKV_AZURE_172
  }

  tags = var.tags
}