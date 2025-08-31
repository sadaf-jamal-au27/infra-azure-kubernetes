output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "fqdn" {
  description = "The FQDN of the Azure Kubernetes Managed Cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "kube_config" {
  description = "Raw Kubernetes config to be used by kubectl and other compatible tools"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "node_resource_group" {
  description = "The auto-generated Resource Group which contains the resources for this Managed Kubernetes Cluster"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}
