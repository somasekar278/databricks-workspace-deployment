variable "source_catalog" {
  description = "Unity Catalog name containing source Delta tables"
  type        = string
  default     = "afc-mvp"
}

variable "source_schema" {
  description = "Schema name containing source Delta tables"
  type        = string
  default     = "fraud-investigation"
}

variable "lakebase_catalog_name" {
  description = "Unity Catalog database catalog name for Lakebase"
  type        = string
}

variable "target_schema" {
  description = "Target schema name in Lakebase for synced tables"
  type        = string
  default     = "fraud_management"
}

