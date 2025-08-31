resource "azurerm_mssql_database" "sql_db" {
  name           = var.sql_db_name
  server_id      = var.server_id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = var.max_size_gb
  sku_name       = "P1" # Change to Premium tier for zone redundancy support
  enclave_type   = "VBS"
  zone_redundant = true # CKV_AZURE_229 - Enable zone redundancy
  ledger_enabled = true # CKV_AZURE_224

  tags = var.tags
}
