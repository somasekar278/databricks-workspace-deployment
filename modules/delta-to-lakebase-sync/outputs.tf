output "synced_tables" {
  description = "List of tables being synced from Delta to Lakebase"
  value = [
    "siu_cases",
    "transactions",
    "alerts",
    "claims",
    "investigation_activities",
    "fraud_indicators"
  ]
}

output "sync_schedule" {
  description = "Sync schedule (cron expression)"
  value       = "Daily at 23:00 UTC"
}

output "sync_mode" {
  description = "Sync mode used for all tables"
  value       = "full"
}

