# ============================================================================
# Secret ARNs
# ============================================================================

output "terraform_sp_secret_arn" {
  description = "ARN of the Terraform service principal OAuth secret"
  value       = aws_secretsmanager_secret.terraform_sp_oauth.arn
}

output "terraform_sp_secret_name" {
  description = "Name of the Terraform service principal OAuth secret"
  value       = aws_secretsmanager_secret.terraform_sp_oauth.name
}

output "workspace_sp_secret_arn" {
  description = "ARN of the workspace service principal OAuth secret"
  value       = aws_secretsmanager_secret.workspace_sp_oauth.arn
}

output "workspace_sp_secret_name" {
  description = "Name of the workspace service principal OAuth secret"
  value       = aws_secretsmanager_secret.workspace_sp_oauth.name
}

output "fraud_app_secret_arn" {
  description = "ARN of the fraud app OAuth secret (if created)"
  value       = var.create_fraud_app_secret ? aws_secretsmanager_secret.fraud_app_oauth[0].arn : null
}

output "fraud_app_secret_name" {
  description = "Name of the fraud app OAuth secret (if created)"
  value       = var.create_fraud_app_secret ? aws_secretsmanager_secret.fraud_app_oauth[0].name : null
}

# ============================================================================
# Secret Retrieval Commands
# ============================================================================

output "retrieval_commands" {
  description = "AWS CLI commands to retrieve secrets"
  value = {
    terraform_sp = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.terraform_sp_oauth.name} --region ${data.aws_region.current.name} --query SecretString --output text"
    workspace_sp = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.workspace_sp_oauth.name} --region ${data.aws_region.current.name} --query SecretString --output text"
    fraud_app    = var.create_fraud_app_secret ? "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.fraud_app_oauth[0].name} --region ${data.aws_region.current.name} --query SecretString --output text" : null
  }
}

data "aws_region" "current" {}

