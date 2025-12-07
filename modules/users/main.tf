# Create Databricks groups
resource "databricks_group" "this" {
  for_each     = { for g in var.groups : g.display_name => g }
  display_name = each.value.display_name
}

# Fetch existing built-in groups (like "admins")
data "databricks_group" "existing" {
  for_each = toset(flatten([
    for user in var.users : [
      for group in user.groups :
      group if !contains([for g in var.groups : g.display_name], group)
    ]
  ]))
  display_name = each.value
}

# Create Databricks users
resource "databricks_user" "this" {
  for_each     = { for u in var.users : u.user_name => u }
  user_name    = each.value.user_name
  display_name = each.value.display_name
}

# Assign users to groups (both created and existing)
resource "databricks_group_member" "this" {
  for_each = merge([
    for user in var.users : {
      for group in user.groups :
      "${user.user_name}-${group}" => {
        user_name = user.user_name
        # Use created group if exists, otherwise use existing group
        group_id = contains([for g in var.groups : g.display_name], group) ? databricks_group.this[group].id : data.databricks_group.existing[group].id
      }
    }
  ]...)

  group_id  = each.value.group_id
  member_id = databricks_user.this[each.value.user_name].id
}

