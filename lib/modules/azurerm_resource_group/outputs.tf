output "rg_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "rg_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.rg.location
}

output "rg_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.rg.id
}
