variable "sa_name" {}
variable "rg_name" {}
variable "location" {}
variable "tags" {}

# Key Vault variables for CMK encryption
variable "key_vault_id" {
  description = "The ID of the Key Vault to use for encryption keys"
  type        = string
}

variable "tenant_id" {
  description = "The tenant ID for Azure AD"
  type        = string
}

variable "key_vault_access_policy" {
  description = "Dependency on key vault access policy"
  default     = null
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for Storage Account"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "enable_storage_analytics" {
  description = "Enable Storage Analytics for queue service logging (CKV_AZURE_33)"
  type        = bool
  default     = false
}

variable "enable_customer_managed_key" {
  description = "Enable customer managed key encryption (disable for free subscription compatibility)"
  type        = bool
  default     = false
}