output "tables_created" {
  description = "Indicates fraud dashboard tables have been created"
  value       = true
  depends_on  = [null_resource.create_fraud_tables]
}

output "tables_seeded" {
  description = "Indicates fraud dashboard tables have been seeded with data"
  value       = true
  depends_on  = [null_resource.seed_fraud_tables]
}

