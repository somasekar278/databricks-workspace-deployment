# Create Unity Catalog catalogs
resource "databricks_catalog" "this" {
  for_each    = { for c in var.catalogs : c.name => c }
  metastore_id = var.metastore_id
  name        = each.value.name
  comment     = each.value.comment
  
  properties = {
    purpose = "Managed by Terraform"
  }
}

# Create schemas within catalogs
resource "databricks_schema" "this" {
  for_each = merge([
    for catalog in var.catalogs : {
      for schema in catalog.schemas :
      "${catalog.name}.${schema.name}" => {
        catalog_name = catalog.name
        schema_name  = schema.name
        comment      = schema.comment
        volumes      = schema.volumes
      }
    }
  ]...)

  catalog_name = each.value.catalog_name
  name         = each.value.schema_name
  comment      = each.value.comment

  properties = {
    purpose = "Managed by Terraform"
  }

  depends_on = [databricks_catalog.this]
}

# Create volumes within schemas
resource "databricks_volume" "this" {
  for_each = merge([
    for catalog in var.catalogs : merge([
      for schema in catalog.schemas : {
        for volume in schema.volumes :
        "${catalog.name}.${schema.name}.${volume.name}" => {
          catalog_name     = catalog.name
          schema_name      = schema.name
          volume_name      = volume.name
          volume_type      = volume.volume_type
          comment          = volume.comment
          storage_location = volume.storage_location
        }
      }
    ]...)
  ]...)

  catalog_name     = each.value.catalog_name
  schema_name      = each.value.schema_name
  name             = each.value.volume_name
  volume_type      = each.value.volume_type
  comment          = each.value.comment
  storage_location = each.value.storage_location

  depends_on = [databricks_schema.this]
}

