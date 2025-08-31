variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "sql_admin_username" {
  description = "SQL Server admin username"
  type        = string
  default     = "devopsadmin"
  sensitive   = true
}

variable "sql_admin_password" {
  description = "SQL Server admin password"
  type        = string
  sensitive   = true
}
