variable "sql_server_name" {}
variable "rg_name" {}
variable "location" {}
variable "admin_username" {}
variable "admin_password" {}
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