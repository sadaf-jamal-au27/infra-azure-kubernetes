resource "azurerm_mssql_database" "sql_db" {
  name           = var.sql_db_name
  server_id      = var.server_id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = var.max_size_gb
  sku_name       = "S0" # Standard tier - compatible with all subscriptions
  enclave_type   = "VBS"
  zone_redundant = false # Disabled for compatibility with all Azure subscriptions
  ledger_enabled = true  # CKV_AZURE_224

  # Backup configuration to comply with bc-azure-229 policy
  short_term_retention_policy {
    retention_days = 7
  }

  tags = var.tags
}
