variable "apps" {
  description = "List of Databricks Apps to create"
  type = list(object({
    name              = string
    description       = optional(string)
    source_code_path  = optional(string)
    deployment_mode   = optional(string)
  }))
  default = []
}

