output "server_id" {
  description = "The ID of the SQL Server"
  value       = azurerm_mssql_server.sql_server.id
}

output "server_name" {
  description = "The name of the SQL Server"
  value       = azurerm_mssql_server.sql_server.name
}

output "server_fqdn" {
  description = "The fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}

output "administrator_login" {
  description = "The administrator login name for the SQL Server"
  value       = azurerm_mssql_server.sql_server.administrator_login
}
