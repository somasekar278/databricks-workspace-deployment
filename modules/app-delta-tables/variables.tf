variable "workspace_url" {
  description = "Databricks workspace URL"
  type        = string
}

variable "sql_warehouse_id" {
  description = "SQL Warehouse ID for executing table creation"
  type        = string
}

variable "databricks_client_id" {
  description = "Databricks Service Principal Client ID for authentication"
  type        = string
}

variable "databricks_client_secret" {
  description = "Databricks Service Principal Client Secret for authentication"
  type        = string
  sensitive   = true
}

