terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# Account-Level Service Principal OAuth Secret
# ============================================================================

resource "aws_secretsmanager_secret" "terraform_sp_oauth" {
  name        = var.terraform_sp_secret_name
  description = "Databricks Service Principal OAuth credentials for Terraform (account-level operations)"
  
  tags = merge(
    var.tags,
    {
      Name        = var.terraform_sp_secret_name
      Purpose     = "Terraform Account-Level Authentication"
      SecretType  = "ServicePrincipal-OAuth"
    }
  )
}

resource "aws_secretsmanager_secret_version" "terraform_sp_oauth" {
  secret_id = aws_secretsmanager_secret.terraform_sp_oauth.id
  secret_string = jsonencode({
    client_id     = var.terraform_sp_client_id
    client_secret = var.terraform_sp_client_secret
    account_id    = var.databricks_account_id
  })
}

# ============================================================================
# Workspace-Level Service Principal OAuth Secret
# ============================================================================

resource "aws_secretsmanager_secret" "workspace_sp_oauth" {
  name        = var.workspace_sp_secret_name
  description = "Databricks Service Principal OAuth credentials for Workspace-level operations (Apps, Lakebase)"
  
  tags = merge(
    var.tags,
    {
      Name        = var.workspace_sp_secret_name
      Purpose     = "Workspace-Level Authentication"
      SecretType  = "ServicePrincipal-OAuth"
    }
  )
}

resource "aws_secretsmanager_secret_version" "workspace_sp_oauth" {
  secret_id = aws_secretsmanager_secret.workspace_sp_oauth.id
  secret_string = jsonencode({
    client_id     = var.workspace_sp_client_id
    client_secret = var.workspace_sp_client_secret
    workspace_url = var.workspace_url
  })
}

# ============================================================================
# Optional: Databricks App OAuth Secret (for fraud case management app)
# ============================================================================

resource "aws_secretsmanager_secret" "fraud_app_oauth" {
  count       = var.create_fraud_app_secret ? 1 : 0
  name        = var.fraud_app_secret_name
  description = "OAuth credentials for Fraud Case Management App"
  
  tags = merge(
    var.tags,
    {
      Name        = var.fraud_app_secret_name
      Purpose     = "Fraud App Authentication"
      SecretType  = "App-OAuth"
    }
  )
}

resource "aws_secretsmanager_secret_version" "fraud_app_oauth" {
  count     = var.create_fraud_app_secret ? 1 : 0
  secret_id = aws_secretsmanager_secret.fraud_app_oauth[0].id
  secret_string = jsonencode({
    client_id     = var.fraud_app_client_id
    client_secret = var.fraud_app_client_secret
  })
}

