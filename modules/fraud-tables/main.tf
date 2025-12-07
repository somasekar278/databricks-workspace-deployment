# Terraform module to create fraud dashboard tables in Unity Catalog
# Uses Databricks SQL to execute table creation and seeding

# Execute schema creation SQL
resource "null_resource" "create_fraud_tables" {
  # Trigger on SQL file changes
  triggers = {
    schema_file = filemd5("${path.root}/sql/fraud_dashboard_schema.sql")
    seed_file   = filemd5("${path.root}/sql/fraud_dashboard_seed.sql")
  }

  # Read and split SQL file into individual statements
  provisioner "local-exec" {
    command = <<-EOT
      echo "🔨 Creating fraud dashboard tables..."
      
      # Function to execute SQL via Databricks CLI
      execute_sql() {
        local sql="$1"
        echo "Executing: $(echo "$sql" | head -c 100)..."
        
        databricks sql execute \
          --profile "${var.databricks_cli_profile}" \
          --host "${var.workspace_url}" \
          --warehouse-id "${var.sql_warehouse_id}" \
          --statement "$sql"
      }
      
      # Create schema
      execute_sql "CREATE SCHEMA IF NOT EXISTS \`afc-mvp\`.\`fraud-investigation\`"
      
      # Create tables (execute each CREATE TABLE separately)
      cat "${path.root}/sql/fraud_dashboard_schema.sql" | \
        grep -v "^--" | \
        awk '/CREATE TABLE/,/;/' | \
        sed 's/CREATE SCHEMA.*;//' | \
        sed 's/USE.*;//' | \
        awk -v RS=';' 'NF {print $0 ";"}' | \
        while IFS= read -r sql; do
          if [ ! -z "$sql" ] && echo "$sql" | grep -q "CREATE TABLE"; then
            execute_sql "$sql"
          fi
        done
      
      echo "✅ Tables created successfully"
    EOT
  }

  depends_on = [var.depends_on_resources]
}

# Execute seed data SQL
resource "null_resource" "seed_fraud_tables" {
  # Only seed if tables were created
  triggers = {
    seed_file = filemd5("${path.root}/sql/fraud_dashboard_seed.sql")
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "🌱 Seeding fraud dashboard tables..."
      
      # Function to execute SQL via Databricks CLI
      execute_sql() {
        local sql="$1"
        
        databricks sql execute \
          --profile "${var.databricks_cli_profile}" \
          --host "${var.workspace_url}" \
          --warehouse-id "${var.sql_warehouse_id}" \
          --statement "$sql"
      }
      
      # Execute INSERT statements
      cat "${path.root}/sql/fraud_dashboard_seed.sql" | \
        grep -v "^--" | \
        sed 's/USE.*;//' | \
        awk -v RS=';' 'NF {print $0 ";"}' | \
        while IFS= read -r sql; do
          if [ ! -z "$sql" ] && echo "$sql" | grep -q "INSERT INTO"; then
            echo "Inserting data..."
            execute_sql "$sql"
          fi
        done
      
      echo "✅ Data seeded successfully"
    EOT
  }

  depends_on = [null_resource.create_fraud_tables]
}

