variable "aks_name" {}
variable "location" {}
variable "rg_name" {}
variable "dns_prefix" {}
variable "node_count" {
  default = 1
}
variable "vm_size" {
  description = "VM size for AKS nodes"
  default     = "Standard_D4s_v3" # VM size with sufficient cache for ephemeral OS disks (200GB cache)
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
