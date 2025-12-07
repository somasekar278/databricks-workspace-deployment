output "apps" {
  description = "Map of created Databricks Apps"
  value = {
    for name, app in databricks_app.this : name => {
      id                         = app.id
      name                       = app.name
      description                = app.description
      url                        = app.url
      app_status                 = try(app.app_status, null)
      compute_status             = try(app.compute_status, null)
      service_principal_id       = try(app.service_principal_id, null)
      service_principal_name     = try(app.service_principal_name, null)
      default_source_code_path   = try(app.default_source_code_path, null)
    }
  }
}

output "app_urls" {
  description = "Map of app names to their URLs"
  value = {
    for name, app in databricks_app.this : name => app.url
  }
}

