#!/bin/bash
# Load Databricks Service Principal credentials for Terraform
# Usage: source ./load-terraform-credentials.sh

echo "🔐 Loading Databricks Service Principal credentials..."

export DATABRICKS_CLIENT_ID=$(aws secretsmanager get-secret-value \
  --secret-id "databricks/terraform-sp-credentials" \
  --region eu-west-1 \
  --profile som \
  --query SecretString \
  --output text | jq -r '.client_id')

export DATABRICKS_CLIENT_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "databricks/terraform-sp-credentials" \
  --region eu-west-1 \
  --profile som \
  --query SecretString \
  --output text | jq -r '.client_secret')

export DATABRICKS_ACCOUNT_ID=$(aws secretsmanager get-secret-value \
  --secret-id "databricks/terraform-sp-credentials" \
  --region eu-west-1 \
  --profile som \
  --query SecretString \
  --output text | jq -r '.account_id')

# Unset workspace host for account-level operations
unset DATABRICKS_HOST

echo "✅ Credentials loaded!"
echo "   Client ID: ${DATABRICKS_CLIENT_ID:0:8}..."
echo "   Account ID: $DATABRICKS_ACCOUNT_ID"
echo ""
echo "Ready for Terraform operations! 🚀"

