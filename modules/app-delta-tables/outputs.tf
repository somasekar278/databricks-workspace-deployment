output "schema_name" {
  description = "Name of the schema where Delta tables were created"
  value       = "afc-mvp.fraud-investigation"
}

output "tables_created" {
  description = "List of Delta tables created (used by both app and dashboards)"
  value = [
    "siu_cases",
    "transactions",
    "alerts",
    "claims",
    "investigation_activities",
    "fraud_indicators"
  ]
}

