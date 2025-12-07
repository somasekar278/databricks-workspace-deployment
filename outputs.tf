output "workspace_id" {
  description = "ID of the created Databricks workspace"
  value       = databricks_mws_workspaces.this.workspace_id
}

output "workspace_url" {
  description = "URL of the created Databricks workspace"
  value       = databricks_mws_workspaces.this.workspace_url
}

output "workspace_status" {
  description = "Status of the Databricks workspace"
  value       = databricks_mws_workspaces.this.workspace_status
}

output "workspace_token" {
  description = "Token for accessing the workspace (sensitive)"
  value       = databricks_mws_workspaces.this.token[0].token_value
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.databricks_vpc[0].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = var.use_existing_vpc ? var.existing_subnet_ids : aws_subnet.private[*].id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = var.use_existing_vpc ? var.existing_security_group_ids[0] : aws_security_group.databricks_sg[0].id
}

output "root_storage_bucket" {
  description = "Name of the root storage S3 bucket"
  value       = aws_s3_bucket.root_storage.bucket
}

output "cross_account_role_arn" {
  description = "ARN of the cross-account IAM role"
  value       = aws_iam_role.cross_account_role.arn
}

output "metastore_id" {
  description = "Unity Catalog metastore ID (created or used)"
  value       = var.create_uc_metastore ? (length(databricks_metastore.this) > 0 ? databricks_metastore.this[0].id : null) : (var.uc_metastore_id != "" ? var.uc_metastore_id : null)
}

output "metastore_storage_bucket" {
  description = "S3 bucket for Unity Catalog metastore storage (if created)"
  value       = var.create_uc_metastore ? aws_s3_bucket.metastore[0].bucket : null
}

output "metastore_role_arn" {
  description = "IAM role ARN for Unity Catalog metastore (if created)"
  value       = var.create_uc_metastore ? aws_iam_role.metastore[0].arn : null
}

output "metastore_assignment" {
  description = "Information about Unity Catalog metastore assignment"
  value = local.should_attach_metastore ? {
    metastore_id = local.metastore_id_to_use
    workspace_id = databricks_mws_workspaces.this.workspace_id
    attached     = true
    created      = var.create_uc_metastore
  } : null
}

output "service_principals" {
  description = "Created service principals with their application IDs"
  value = var.create_service_principals ? [
    for idx, sp in databricks_service_principal.this : {
      name           = sp.display_name
      application_id = sp.application_id
      admin          = var.service_principals[idx].admin
    }
  ] : []
}

output "users" {
  description = "Created users in the workspace"
  value       = module.users.users
}

output "groups" {
  description = "Created groups in the workspace"
  value       = module.users.groups
}

output "catalogs" {
  description = "Created Unity Catalog catalogs"
  value       = module.unity_catalog.catalogs
}

output "schemas" {
  description = "Created Unity Catalog schemas"
  value       = module.unity_catalog.schemas
}

output "volumes" {
  description = "Created Unity Catalog volumes"
  value       = module.unity_catalog.volumes
}

output "lakebase_database_instances" {
  description = "Created Lakebase database instances"
  value       = module.lakebase.database_instances
}

output "lakebase_database_catalogs" {
  description = "Created Lakebase database catalogs"
  value       = module.lakebase.database_catalogs
}

output "apps" {
  description = "Created Databricks Apps"
  value       = module.apps.apps
}

output "app_urls" {
  description = "Databricks App URLs"
  value       = module.apps.app_urls
}

output "sql_warehouse_id" {
  description = "SQL Warehouse ID for fraud analytics"
  value       = databricks_sql_endpoint.fraud_dashboard.id
}

output "sql_warehouse_jdbc_url" {
  description = "JDBC URL for SQL Warehouse"
  value       = databricks_sql_endpoint.fraud_dashboard.jdbc_url
}

output "fraud_tables_created" {
  description = "Status of fraud dashboard tables creation"
  value       = module.fraud_tables.tables_created
}

output "fraud_tables_seeded" {
  description = "Status of fraud dashboard tables seeding"
  value       = module.fraud_tables.tables_seeded
}

