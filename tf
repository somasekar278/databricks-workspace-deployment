#!/bin/bash
# Terraform wrapper that automatically loads credentials
# Usage: ./tf [terraform commands]
# Example: ./tf apply -target=module.apps

# Load credentials
export DATABRICKS_CLIENT_ID=$(aws secretsmanager get-secret-value \
  --secret-id "databricks/terraform-sp-credentials" \
  --region eu-west-1 \
  --profile som \
  --query SecretString \
  --output text 2>/dev/null | jq -r '.client_id')

export DATABRICKS_CLIENT_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "databricks/terraform-sp-credentials" \
  --region eu-west-1 \
  --profile som \
  --query SecretString \
  --output text 2>/dev/null | jq -r '.client_secret')

export DATABRICKS_ACCOUNT_ID=$(aws secretsmanager get-secret-value \
  --secret-id "databricks/terraform-sp-credentials" \
  --region eu-west-1 \
  --profile som \
  --query SecretString \
  --output text 2>/dev/null | jq -r '.account_id')

# Unset workspace host for account-level operations
unset DATABRICKS_HOST

# Check if credentials loaded
if [ -z "$DATABRICKS_CLIENT_ID" ]; then
    echo "❌ Error: Could not load credentials from AWS Secrets Manager"
    echo "   Make sure AWS credentials are valid and secret exists"
    exit 1
fi

# Run terraform with all arguments passed through
terraform "$@"

