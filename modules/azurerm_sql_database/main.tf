resource "azurerm_mssql_database" "sql_db" {
  name           = var.sql_db_name
  server_id      = var.server_id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = var.max_size_gb
  sku_name       = "S0"
  enclave_type   = "VBS"
  zone_redundant = true # CKV_AZURE_229
  ledger_enabled = true # CKV_AZURE_224

  tags = var.tags
}
