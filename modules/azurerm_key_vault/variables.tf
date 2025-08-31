variable "kv_name" {}
variable "location" {}
variable "rg_name" {}
variable "tags" {}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for Key Vault"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "allowed_ips" {
  description = "List of allowed IP addresses for Key Vault access"
  type        = list(string)
  default     = []
}

variable "enable_public_access" {
  description = "Enable public network access for Key Vault (disable for production)"
  type        = bool
  default     = false
}
