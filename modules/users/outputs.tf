output "users" {
  description = "Created users"
  value = {
    for k, v in databricks_user.this : k => {
      id           = v.id
      user_name    = v.user_name
      display_name = v.display_name
    }
  }
}

output "groups" {
  description = "Created groups"
  value = {
    for k, v in databricks_group.this : k => {
      id           = v.id
      display_name = v.display_name
    }
  }
}

