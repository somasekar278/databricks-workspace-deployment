variable "workspace_url" {
  description = "Databricks workspace URL"
  type        = string
}

variable "sql_warehouse_id" {
  description = "SQL Warehouse ID for executing queries"
  type        = string
}

variable "databricks_cli_profile" {
  description = "Databricks CLI profile to use"
  type        = string
  default     = "DEFAULT"
}

variable "depends_on_resources" {
  description = "Resources that must be created before tables"
  type        = list(any)
  default     = []
}

