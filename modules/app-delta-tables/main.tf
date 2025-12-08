# Terraform module to create operational Delta tables in Unity Catalog
# Used by the fraud case management application for CRUD operations

# Execute schema creation SQL
resource "null_resource" "create_app_delta_tables" {
  # Trigger on SQL file changes
  triggers = {
    schema_file = filemd5("${path.root}/sql/app_delta_schema.sql")
    seed_file   = filemd5("${path.root}/sql/app_delta_seed.sql")
    python_script = filemd5("${path.module}/create_delta_tables.py")
  }

  # Execute Python script to create tables using REST API (reliable for headless execution)
  provisioner "local-exec" {
    command = <<-EOT
      export DATABRICKS_CLIENT_ID="${var.databricks_client_id}"
      export DATABRICKS_CLIENT_SECRET="${var.databricks_client_secret}"
      
      python3 ${path.module}/create_delta_tables_rest.py \
        "${var.workspace_url}" \
        "${var.sql_warehouse_id}" \
        "${path.root}/sql/app_delta_schema.sql"
    EOT
  }
}

# Execute data seeding SQL
resource "null_resource" "seed_app_delta_tables" {
  # Trigger on seed file changes
  triggers = {
    seed_file = filemd5("${path.root}/sql/app_delta_seed.sql")
    python_script = filemd5("${path.module}/seed_delta_tables.py")
  }

  provisioner "local-exec" {
    command = <<-EOT
      export DATABRICKS_CLIENT_ID="${var.databricks_client_id}"
      export DATABRICKS_CLIENT_SECRET="${var.databricks_client_secret}"
      
      python3 ${path.module}/seed_delta_tables_rest.py \
        "${var.workspace_url}" \
        "${var.sql_warehouse_id}" \
        "${path.root}/sql/app_delta_seed.sql"
    EOT
  }

  depends_on = [null_resource.create_app_delta_tables]
}

