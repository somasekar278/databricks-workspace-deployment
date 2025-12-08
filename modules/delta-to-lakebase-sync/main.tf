# Terraform module to sync Unity Catalog Delta tables to Lakebase
# Syncs operational fraud data from Delta to PostgreSQL for app queries
# All tables use a single shared DLT pipeline for efficiency (bin-packed)

# Primary sync: siu_cases (creates the shared pipeline)
resource "databricks_database_synced_database_table" "siu_cases" {
  name = "${var.lakebase_catalog_name}.${var.target_schema}.siu_cases"

  spec = {
    source_table_full_name = "${var.source_catalog}.${var.source_schema}.siu_cases"
    primary_key_columns    = ["case_id"]
    scheduling_policy      = "TRIGGERED"
    
    # Create a new pipeline for all tables to share
    new_pipeline_spec = {
      # Pipeline will be named automatically by Databricks
    }
  }
}

# Sync: transactions (uses shared pipeline)
resource "databricks_database_synced_database_table" "transactions" {
  name = "${var.lakebase_catalog_name}.${var.target_schema}.transactions"

  spec = {
    source_table_full_name = "${var.source_catalog}.${var.source_schema}.transactions"
    primary_key_columns    = ["transaction_id"]
    scheduling_policy      = "TRIGGERED"
    
    # Reuse the pipeline created by siu_cases
    existing_pipeline_id = databricks_database_synced_database_table.siu_cases.data_synchronization_status.pipeline_id
  }

  depends_on = [databricks_database_synced_database_table.siu_cases]
}

# Sync: alerts (uses shared pipeline)
resource "databricks_database_synced_database_table" "alerts" {
  name = "${var.lakebase_catalog_name}.${var.target_schema}.alerts"

  spec = {
    source_table_full_name = "${var.source_catalog}.${var.source_schema}.alerts"
    primary_key_columns    = ["alert_id"]
    scheduling_policy      = "TRIGGERED"
    
    existing_pipeline_id = databricks_database_synced_database_table.siu_cases.data_synchronization_status.pipeline_id
  }

  depends_on = [databricks_database_synced_database_table.siu_cases]
}

# Sync: claims (uses shared pipeline)
resource "databricks_database_synced_database_table" "claims" {
  name = "${var.lakebase_catalog_name}.${var.target_schema}.claims"

  spec = {
    source_table_full_name = "${var.source_catalog}.${var.source_schema}.claims"
    primary_key_columns    = ["claim_id"]
    scheduling_policy      = "TRIGGERED"
    
    existing_pipeline_id = databricks_database_synced_database_table.siu_cases.data_synchronization_status.pipeline_id
  }

  depends_on = [databricks_database_synced_database_table.siu_cases]
}

# Sync: investigation_activities (uses shared pipeline)
resource "databricks_database_synced_database_table" "investigation_activities" {
  name = "${var.lakebase_catalog_name}.${var.target_schema}.investigation_activities"

  spec = {
    source_table_full_name = "${var.source_catalog}.${var.source_schema}.investigation_activities"
    primary_key_columns    = ["activity_id"]
    scheduling_policy      = "TRIGGERED"
    
    existing_pipeline_id = databricks_database_synced_database_table.siu_cases.data_synchronization_status.pipeline_id
  }

  depends_on = [databricks_database_synced_database_table.siu_cases]
}

# Sync: fraud_indicators (uses shared pipeline)
resource "databricks_database_synced_database_table" "fraud_indicators" {
  name = "${var.lakebase_catalog_name}.${var.target_schema}.fraud_indicators"

  spec = {
    source_table_full_name = "${var.source_catalog}.${var.source_schema}.fraud_indicators"
    primary_key_columns    = ["indicator_id"]
    scheduling_policy      = "TRIGGERED"
    
    existing_pipeline_id = databricks_database_synced_database_table.siu_cases.data_synchronization_status.pipeline_id
  }

  depends_on = [databricks_database_synced_database_table.siu_cases]
}
