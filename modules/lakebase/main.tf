# Create Lakebase Database Instances
resource "databricks_database_instance" "this" {
  for_each = { for i in var.database_instances : i.name => i }

  name                   = each.value.name
  capacity               = each.value.capacity
  enable_pg_native_login = each.value.enable_pg_native_login
}

# Create/Register Database Catalogs (which can also create databases)
resource "databricks_database_database_catalog" "this" {
  for_each = { for c in var.database_catalogs : c.name => c }

  name                          = each.value.name
  database_instance_name        = each.value.database_instance_name
  database_name                 = each.value.database_name
  create_database_if_not_exists = each.value.create_database_if_not_exists

  depends_on = [databricks_database_instance.this]
}
