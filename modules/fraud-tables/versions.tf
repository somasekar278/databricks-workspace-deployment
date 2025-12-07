terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.30"
    }
  }
  required_version = ">= 1.0"
}

