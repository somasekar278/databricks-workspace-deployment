variable "catalogs" {
  description = "List of Unity Catalog catalogs to create"
  type = list(object({
    name    = string
    comment = optional(string)
    schemas = optional(list(object({
      name    = string
      comment = optional(string)
      volumes = optional(list(object({
        name         = string
        volume_type  = optional(string, "MANAGED")
        comment      = optional(string)
        storage_location = optional(string)
      })), [])
    })), [])
  }))
  default = []
}

variable "metastore_id" {
  description = "Unity Catalog metastore ID"
  type        = string
}

variable "workspace_id" {
  description = "Databricks workspace ID"
  type        = number
}

