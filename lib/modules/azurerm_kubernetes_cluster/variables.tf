variable "aks_name" {}
variable "location" {}
variable "rg_name" {}
variable "dns_prefix" {}
variable "node_count" {
  default = 1 # Minimal node count for free subscription
}
variable "vm_size" {
  description = "VM size for AKS nodes"
  default     = "Standard_B2als_v2" # Meets minimum requirements (2 vCPUs, 4GB RAM)
}
variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for monitoring"
  type        = string
  default     = null
}

variable "disk_encryption_set_id" {
  description = "The ID of the Disk Encryption Set to use for disk encryption"
  type        = string
  default     = null
}

variable "tags" {}
