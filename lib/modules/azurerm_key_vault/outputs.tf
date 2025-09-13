output "key_vault_id" {
  value = azurerm_key_vault.key_vault.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.key_vault.vault_uri
}

output "access_policy" {
  value = azurerm_key_vault.key_vault.access_policy
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
