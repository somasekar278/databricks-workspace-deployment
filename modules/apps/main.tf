# Create Databricks Apps
resource "databricks_app" "this" {
  for_each = { for app in var.apps : app.name => app }

  name        = each.value.name
  description = lookup(each.value, "description", null)

  # Note: The databricks_app resource creates the app
  # Deployment is handled via the Databricks CLI or UI
  # Terraform manages the app lifecycle (create, update, delete)
}

