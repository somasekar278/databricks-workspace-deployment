# Secrets Manager Module

This module manages Databricks OAuth secrets in AWS Secrets Manager.

## Features

- **Account-Level Secret**: Stores Terraform service principal OAuth credentials for account-level operations (workspace creation, UC metastore, etc.)
- **Workspace-Level Secret**: Stores service principal OAuth credentials for workspace-level operations (apps, Lakebase, etc.)
- **App-Level Secret** (Optional): Stores OAuth credentials specifically for the fraud case management app
- **Automatic Secret Rotation Support**: Secrets can be rotated by updating the variables
- **Tagged Resources**: All secrets are tagged for easy identification and cost tracking

## Usage

### Basic Usage

```hcl
module "secrets_manager" {
  source = "./modules/secrets-manager"

  # Account-level SP OAuth (for Terraform)
  terraform_sp_client_id     = "YOUR_TERRAFORM_SP_CLIENT_ID"
  terraform_sp_client_secret = "YOUR_TERRAFORM_SP_CLIENT_SECRET"
  databricks_account_id      = "YOUR_DATABRICKS_ACCOUNT_ID"

  # Workspace-level SP OAuth
  workspace_sp_client_id     = "YOUR_WORKSPACE_SP_CLIENT_ID"
  workspace_sp_client_secret = "YOUR_WORKSPACE_SP_CLIENT_SECRET"
  workspace_url              = "your-workspace.cloud.databricks.com"

  # Optional: Fraud app OAuth (same SP or different)
  create_fraud_app_secret  = true
  fraud_app_client_id      = "YOUR_FRAUD_APP_CLIENT_ID"
  fraud_app_client_secret  = "YOUR_FRAUD_APP_CLIENT_SECRET"

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "Databricks-Deployment"
  }
}
```

### Custom Secret Names

```hcl
module "secrets_manager" {
  source = "./modules/secrets-manager"

  # Custom secret names
  terraform_sp_secret_name = "my-org/databricks/terraform-sp"
  workspace_sp_secret_name = "my-org/databricks/workspace-sp"
  fraud_app_secret_name    = "my-org/databricks/fraud-app"

  # ... other variables
}
```

### Without Fraud App Secret

```hcl
module "secrets_manager" {
  source = "./modules/secrets-manager"

  # Account and workspace SP only
  terraform_sp_client_id     = "..."
  terraform_sp_client_secret = "..."
  databricks_account_id      = "..."
  
  workspace_sp_client_id     = "..."
  workspace_sp_client_secret = "..."
  workspace_url              = "..."

  # Don't create fraud app secret
  create_fraud_app_secret = false
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| terraform_sp_client_id | Service Principal Client ID for Terraform | string | n/a | yes |
| terraform_sp_client_secret | Service Principal Client Secret for Terraform | string | n/a | yes |
| databricks_account_id | Databricks Account ID | string | n/a | yes |
| workspace_sp_client_id | Service Principal Client ID for workspace | string | n/a | yes |
| workspace_sp_client_secret | Service Principal Client Secret for workspace | string | n/a | yes |
| workspace_url | Databricks workspace URL | string | n/a | yes |
| terraform_sp_secret_name | Name for Terraform SP secret | string | `"databricks/terraform-sp-credentials"` | no |
| workspace_sp_secret_name | Name for workspace SP secret | string | `"databricks/workspace-sp-oauth"` | no |
| create_fraud_app_secret | Create fraud app secret | bool | `true` | no |
| fraud_app_secret_name | Name for fraud app secret | string | `"databricks/fraud-app/oauth-client"` | no |
| fraud_app_client_id | Client ID for fraud app | string | `""` | no |
| fraud_app_client_secret | Client secret for fraud app | string | `""` | no |
| tags | Tags to apply to secrets | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| terraform_sp_secret_arn | ARN of Terraform SP secret |
| terraform_sp_secret_name | Name of Terraform SP secret |
| workspace_sp_secret_arn | ARN of workspace SP secret |
| workspace_sp_secret_name | Name of workspace SP secret |
| fraud_app_secret_arn | ARN of fraud app secret (if created) |
| fraud_app_secret_name | Name of fraud app secret (if created) |
| retrieval_commands | AWS CLI commands to retrieve secrets |

## Retrieving Secrets

After creating secrets, retrieve them using:

```bash
# Terraform SP credentials
aws secretsmanager get-secret-value \
  --secret-id databricks/terraform-sp-credentials \
  --region eu-west-1 \
  --query SecretString --output text | jq

# Workspace SP credentials
aws secretsmanager get-secret-value \
  --secret-id databricks/workspace-sp-oauth \
  --region eu-west-1 \
  --query SecretString --output text | jq

# Fraud app credentials
aws secretsmanager get-secret-value \
  --secret-id databricks/fraud-app/oauth-client \
  --region eu-west-1 \
  --query SecretString --output text | jq
```

## Secret Rotation

To rotate secrets:

1. Generate new OAuth secret in Databricks Account Console
2. Update the variable value in your `terraform.tfvars` or variable source
3. Run `terraform apply`

The secret version will be updated automatically without deleting the secret resource.

## Security Best Practices

1. **Never commit secrets to Git**: Use environment variables or secure variable files
2. **Use least privilege**: Grant only necessary permissions to IAM roles/users accessing secrets
3. **Enable secret rotation**: Regularly rotate OAuth secrets
4. **Audit access**: Enable CloudTrail logging for Secrets Manager API calls
5. **Encrypt at rest**: Secrets Manager encrypts secrets by default using AWS KMS

## Example: Using Secrets in Applications

### In Terraform

```hcl
data "aws_secretsmanager_secret_version" "terraform_sp" {
  secret_id = module.secrets_manager.terraform_sp_secret_name
}

locals {
  sp_creds = jsondecode(data.aws_secretsmanager_secret_version.terraform_sp.secret_string)
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = local.sp_creds.account_id
  client_id  = local.sp_creds.client_id
  client_secret = local.sp_creds.client_secret
}
```

### In Shell Scripts

```bash
#!/bin/bash

# Load secret
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id databricks/terraform-sp-credentials \
  --region eu-west-1 \
  --query SecretString --output text)

# Parse JSON
CLIENT_ID=$(echo "$SECRET" | jq -r .client_id)
CLIENT_SECRET=$(echo "$SECRET" | jq -r .client_secret)
ACCOUNT_ID=$(echo "$SECRET" | jq -r .account_id)

# Use credentials
export DATABRICKS_CLIENT_ID="$CLIENT_ID"
export DATABRICKS_CLIENT_SECRET="$CLIENT_SECRET"
export DATABRICKS_ACCOUNT_ID="$ACCOUNT_ID"
```

### In Node.js (Backend)

```javascript
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

async function getOAuthCredentials() {
  const client = new SecretsManagerClient({ region: 'eu-west-1' });
  const response = await client.send(
    new GetSecretValueCommand({
      SecretId: 'databricks/fraud-app/oauth-client'
    })
  );
  return JSON.parse(response.SecretString);
}

// Usage
const { client_id, client_secret } = await getOAuthCredentials();
```

## Cost

AWS Secrets Manager pricing (as of 2024):
- **Storage**: $0.40 per secret per month
- **API calls**: $0.05 per 10,000 API calls

For this module (3 secrets): ~$1.20/month + API call costs

