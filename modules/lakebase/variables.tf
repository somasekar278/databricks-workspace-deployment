variable "database_instances" {
  description = "List of Lakebase database instances to create"
  type = list(object({
    name                   = string
    capacity               = string           # e.g., "CU_2", "CU_4", "CU_8", "CU_16"
    enable_pg_native_login = optional(bool, true)
  }))
  default = []
}

variable "database_catalogs" {
  description = "List of database catalogs to create/register in Lakebase instances"
  type = list(object({
    name                          = string
    database_instance_name        = string
    database_name                 = string
    create_database_if_not_exists = optional(bool, true)
  }))
  default = []
}

