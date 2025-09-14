output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.rg.rg_name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.key_vault.key_vault_uri
}

output "storage_account_name" {
  description = "Storage account name"
  value       = module.storage_account.storage_account_name
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = module.acr.login_server
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "sql_server_fqdn" {
  description = "SQL Server FQDN"
  value       = module.sql_server.server_fqdn
}

output "app_url" {
  description = "Application URL"
  value       = "https://${module.aks.cluster_name}.eastus.cloudapp.azure.com"
}
