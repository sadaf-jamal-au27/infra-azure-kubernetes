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

variable "security_alert_emails" {
  description = "List of email addresses to send security alerts to"
  type        = list(string)
  default     = []
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for SQL Server and Audit Storage"
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