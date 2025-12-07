# Unity Catalog IAM Configuration

## Self-Assuming Role Requirement

Unity Catalog requires that the metastore IAM role can assume itself. This is automatically configured in the Terraform deployment.

## What's Configured

The `aws_iam_role.metastore` resource in `main.tf` includes two trust policy statements:

### 1. Databricks Access (Standard)
Allows Databricks to assume the role using the External ID:
```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::414351767826:root"
  },
  "Action": "sts:AssumeRole",
  "Condition": {
    "StringEquals": {
      "sts:ExternalId": "<your-databricks-account-id>"
    }
  }
}
```

### 2. Self-Assuming (Unity Catalog Requirement)
Allows the role to assume itself:
```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::<your-aws-account-id>:root"
  },
  "Action": "sts:AssumeRole",
  "Condition": {
    "ArnLike": {
      "aws:PrincipalArn": "arn:aws:iam::<your-aws-account-id>:role/<workspace-prefix>-metastore-role"
    }
  }
}
```

## Deployment

When you run:
```bash
./deploy-everything.sh
```

Or:
```bash
terraform apply
```

The IAM role will be created with both statements automatically. No manual AWS Console configuration needed!

## Verification

After deployment, verify the role can assume itself:
```bash
# Get the role name from Terraform
terraform output metastore_role_name

# Check the trust policy in AWS
aws iam get-role --role-name <role-name> --query 'Role.AssumeRolePolicyDocument'
```

You should see both trust policy statements in the output.

## Why This Matters

Without the self-assuming statement, you'll get errors like:
```
INVALID_PARAMETER_VALUE.UC_IAM_ROLE_NON_SELF_ASSUMING
The IAM role for this storage credential was found to be non self-assuming.
```

This prevents Unity Catalog from creating managed tables in custom catalogs (like `afc-mvp`).

## For Existing Deployments

If you deployed before this fix was added, you have two options:

### Option 1: Terraform Update (Recommended)
```bash
cd /Users/som.natarajan/databricks-workspace-deployment
terraform apply -target=aws_iam_role.metastore -auto-approve
```

### Option 2: Manual AWS Console Update
1. Go to AWS IAM Console
2. Find role: `<workspace-prefix>-metastore-role`
3. Click **Trust relationships** → **Edit trust policy**
4. Add the self-assuming statement shown above
5. Save

## References

- [Databricks Unity Catalog Documentation](https://docs.databricks.com/en/data-governance/unity-catalog/index.html)
- [AWS IAM Role Trust Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html)


