output "catalogs" {
  description = "Created catalogs"
  value = {
    for k, v in databricks_catalog.this : k => {
      id           = v.id
      name         = v.name
      metastore_id = v.metastore_id
    }
  }
}

output "schemas" {
  description = "Created schemas"
  value = {
    for k, v in databricks_schema.this : k => {
      id           = v.id
      name         = v.name
      catalog_name = v.catalog_name
      full_name    = "${v.catalog_name}.${v.name}"
    }
  }
}

output "volumes" {
  description = "Created volumes"
  value = {
    for k, v in databricks_volume.this : k => {
      id          = v.id
      name        = v.name
      volume_type = v.volume_type
      full_name   = "${v.catalog_name}.${v.schema_name}.${v.name}"
    }
  }
}

