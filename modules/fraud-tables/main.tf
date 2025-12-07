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
      
      # Create tables using awk with semicolon as record separator
      # This properly handles multi-line CREATE TABLE statements
      awk 'BEGIN {RS=";"} /CREATE TABLE/ && NF' "${path.root}/sql/fraud_dashboard_schema.sql" | \
        while IFS= read -r sql; do
          # Clean up the SQL statement: remove comments and empty lines, collapse whitespace
          clean_sql=$(echo "$sql" | sed '/^--/d' | sed '/^$/d' | tr '\n' ' ' | sed 's/  */ /g')
          if [ ! -z "$clean_sql" ]; then
            execute_sql "$clean_sql;"
          fi
        done
      
      echo "✅ Tables created successfully"
    EOT
  }

  # FIX Bug 1: Don't wrap var.depends_on_resources in brackets - it's already a list
  depends_on = var.depends_on_resources
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
        echo "Executing data insertion..."
        
        databricks sql execute \
          --profile "${var.databricks_cli_profile}" \
          --host "${var.workspace_url}" \
          --warehouse-id "${var.sql_warehouse_id}" \
          --statement "$sql"
      }
      
      # FIX Bug 2: Use awk with semicolon as record separator to properly handle multi-line INSERT statements
      # This ensures entire INSERT statements (spanning multiple lines) are kept together
      awk 'BEGIN {RS=";"} /INSERT INTO/ && NF' "${path.root}/sql/fraud_dashboard_seed.sql" | \
        while IFS= read -r sql; do
          # Clean up the SQL: remove comments and USE statements, collapse whitespace
          clean_sql=$(echo "$sql" | grep -v '^--' | grep -v '^USE' | sed '/^$/d' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ //;s/ $//')
          
          if [ ! -z "$clean_sql" ] && echo "$clean_sql" | grep -q "INSERT INTO"; then
            # Add semicolon back and execute
            execute_sql "$clean_sql;"
          fi
        done
      
      echo "✅ Data seeded successfully"
    EOT
  }

  depends_on = [null_resource.create_fraud_tables]
}
