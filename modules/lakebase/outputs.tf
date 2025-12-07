output "database_instances" {
  description = "Created Lakebase database instances"
  value = {
    for k, v in databricks_database_instance.this : k => {
      uid            = v.uid
      name           = v.name
      capacity       = v.capacity
      read_write_dns = v.read_write_dns
      state          = v.state
    }
  }
}

output "database_catalogs" {
  description = "Created Lakebase database catalogs"
  value = {
    for k, v in databricks_database_database_catalog.this : k => {
      uid                    = v.uid
      name                   = v.name
      database_instance_name = v.database_instance_name
      database_name          = v.database_name
    }
  }
}
