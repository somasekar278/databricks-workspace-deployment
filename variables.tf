# AWS Configuration
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

# Databricks Account Configuration
variable "databricks_account_id" {
  description = "Databricks account ID (required)"
  type        = string
}

# Workspace Configuration
variable "workspace_name" {
  description = "Name of the Databricks workspace"
  type        = string
}

variable "workspace_deployment_name" {
  description = "Deployment name for the workspace (must be unique across all workspaces, lowercase alphanumeric and hyphens only)"
  type        = string
}

variable "workspace_prefix" {
  description = "Prefix for resource names"
  type        = string
}

# VPC Configuration
variable "use_existing_vpc" {
  description = "Whether to use an existing VPC instead of creating a new one"
  type        = bool
  default     = false
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC (only used if creating new VPC)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr_blocks" {
  description = "CIDR blocks for private subnets (only used if creating new VPC)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "existing_vpc_id" {
  description = "ID of existing VPC (only used if use_existing_vpc is true)"
  type        = string
  default     = ""
}

variable "existing_subnet_ids" {
  description = "List of existing subnet IDs (only used if use_existing_vpc is true)"
  type        = list(string)
  default     = []
}

variable "existing_security_group_ids" {
  description = "List of existing security group IDs (only used if use_existing_vpc is true)"
  type        = list(string)
  default     = []
}

# Unity Catalog Configuration
variable "create_uc_metastore" {
  description = "Whether to create a new Unity Catalog metastore (true) or use an existing one (false)"
  type        = bool
  default     = false
}

variable "uc_metastore_id" {
  description = "Unity Catalog metastore ID to attach to the workspace (only used if create_uc_metastore is false, leave empty to skip metastore attachment)"
  type        = string
  default     = ""
}

variable "uc_metastore_name" {
  description = "Name for the Unity Catalog metastore (only used if create_uc_metastore is true)"
  type        = string
  default     = "unity-catalog-metastore"
}

variable "default_catalog_name" {
  description = "Default catalog name for Unity Catalog"
  type        = string
  default     = "main"
}

# Service Principal Configuration
variable "create_service_principals" {
  description = "Whether to create service principals for workspace management"
  type        = bool
  default     = false
}

variable "service_principals" {
  description = "List of service principals to create with their configurations"
  type = list(object({
    name        = string
    description = string
    admin       = bool # Whether to grant workspace admin privileges
  }))
  default = []
}

# User Management
variable "users" {
  description = "List of users to create in the workspace"
  type = list(object({
    user_name    = string
    display_name = string
    groups       = list(string)
  }))
  default = []
}

variable "groups" {
  description = "List of groups to create in the workspace"
  type = list(object({
    display_name = string
  }))
  default = []
}

# Unity Catalog Objects
variable "catalogs" {
  description = "List of Unity Catalog catalogs to create with their schemas and volumes"
  type = list(object({
    name    = string
    comment = optional(string)
    schemas = optional(list(object({
      name    = string
      comment = optional(string)
      volumes = optional(list(object({
        name             = string
        volume_type      = optional(string, "MANAGED")
        comment          = optional(string)
        storage_location = optional(string)
      })), [])
    })), [])
  }))
  default = []
}

# Lakebase Configuration
variable "lakebase_database_instances" {
  description = "List of Lakebase database instances to create"
  type = list(object({
    name                   = string
    capacity               = string           # e.g., "CU_2", "CU_4", "CU_8", "CU_16"
    enable_pg_native_login = optional(bool, true)
  }))
  default = []
}

variable "lakebase_database_catalogs" {
  description = "List of database catalogs to create/register in Lakebase instances"
  type = list(object({
    name                          = string
    database_instance_name        = string
    database_name                 = string
    create_database_if_not_exists = optional(bool, true)
  }))
  default = []
}

# Apps Configuration
variable "apps" {
  description = "List of Databricks Apps to create"
  type = list(object({
    name              = string
    description       = optional(string)
    source_code_path  = optional(string)
    deployment_mode   = optional(string, "SNAPSHOT")
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "Development"
  }
}

# Databricks CLI Configuration
variable "databricks_cli_profile" {
  description = "Databricks CLI profile to use for SQL execution"
  type        = string
  default     = "DEFAULT"
}

