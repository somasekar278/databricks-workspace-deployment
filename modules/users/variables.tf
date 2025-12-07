variable "users" {
  description = "List of users to create in Databricks"
  type = list(object({
    user_name    = string
    display_name = string
    groups       = list(string)
  }))
  default = []
}

variable "groups" {
  description = "List of groups to create in Databricks"
  type = list(object({
    display_name = string
  }))
  default = []
}

variable "workspace_id" {
  description = "Databricks workspace ID"
  type        = number
}

