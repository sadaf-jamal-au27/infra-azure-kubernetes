data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "aks" {
  name                      = var.aks_name
  location                  = var.location
  resource_group_name       = var.rg_name
  dns_prefix                = var.dns_prefix
  private_cluster_enabled   = true       # CKV_AZURE_115 - Enable private cluster
  local_account_disabled    = true       # CKV_AZURE_141
  sku_tier                  = "Standard" # CKV_AZURE_170
  automatic_upgrade_channel = "stable"   # CKV_AZURE_171

  api_server_access_profile {
    authorized_ip_ranges = ["10.0.0.0/8"] # CKV_AZURE_6 - Restrict to private networks
  }

  default_node_pool {
    name                         = "default"
    node_count                   = var.node_count
    vm_size                      = var.vm_size
    max_pods                     = 110         # CKV_AZURE_168
    only_critical_addons_enabled = true        # CKV_AZURE_232
    os_disk_type                 = "Ephemeral" # CKV_AZURE_109 - Use ephemeral OS disks
    os_disk_size_gb              = 100         # Required for ephemeral disks, must be <= cache size
    host_encryption_enabled      = true        # CKV_AZURE_227 - Enable host encryption

    # Note: disk_encryption_set_id is not directly supported in default_node_pool
    # This would require creating a separate azurerm_kubernetes_cluster_node_pool resource
  }

  network_profile {
    network_plugin = "azure" # CKV2_AZURE_29
    network_policy = "azure" # CKV_AZURE_7
  }

  identity {
    type = "SystemAssigned"
  }

  azure_policy_enabled = true # CKV_AZURE_116

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = [] # Can be populated with specific admin groups later
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id # CKV_AZURE_4
    }
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true # CKV_AZURE_172
  }

  # Add disk encryption set for CKV_AZURE_117 (if provided)
  disk_encryption_set_id = var.disk_encryption_set_id

  tags = var.tags
}