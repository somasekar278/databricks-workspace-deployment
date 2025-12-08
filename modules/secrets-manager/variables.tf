# ============================================================================
# Account-Level Service Principal Variables
# ============================================================================

variable "terraform_sp_secret_name" {
  description = "Name of the AWS secret for Terraform service principal OAuth credentials"
  type        = string
  default     = "databricks/terraform-sp-credentials"
}

variable "terraform_sp_client_id" {
  description = "Service Principal Client ID (UUID) for Terraform account-level operations"
  type        = string
  sensitive   = true
}

variable "terraform_sp_client_secret" {
  description = "Service Principal Client Secret for Terraform account-level operations"
  type        = string
  sensitive   = true
}

variable "databricks_account_id" {
  description = "Databricks Account ID"
  type        = string
}

# ============================================================================
# Workspace-Level Service Principal Variables
# ============================================================================

variable "workspace_sp_secret_name" {
  description = "Name of the AWS secret for workspace-level service principal OAuth credentials"
  type        = string
  default     = "databricks/workspace-sp-oauth"
}

variable "workspace_sp_client_id" {
  description = "Service Principal Client ID (UUID) for workspace-level operations"
  type        = string
  sensitive   = true
}

variable "workspace_sp_client_secret" {
  description = "Service Principal Client Secret for workspace-level operations"
  type        = string
  sensitive   = true
}

variable "workspace_url" {
  description = "Databricks workspace URL (without https://)"
  type        = string
}

# ============================================================================
# Fraud App OAuth Variables (Optional)
# ============================================================================

variable "create_fraud_app_secret" {
  description = "Whether to create a separate secret for the fraud case management app"
  type        = bool
  default     = true
}

variable "fraud_app_secret_name" {
  description = "Name of the AWS secret for fraud app OAuth credentials"
  type        = string
  default     = "databricks/fraud-app/oauth-client"
}

variable "fraud_app_client_id" {
  description = "Service Principal Client ID for fraud app"
  type        = string
  sensitive   = true
  default     = ""
}

variable "fraud_app_client_secret" {
  description = "Service Principal Client Secret for fraud app"
  type        = string
  sensitive   = true
  default     = ""
}

# ============================================================================
# Common Variables
# ============================================================================

variable "tags" {
  description = "Tags to apply to all secrets"
  type        = map(string)
  default     = {}
}

