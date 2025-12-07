# Full Redeployment Guide

This guide shows how to recreate the entire environment from scratch after running `terraform destroy`.

## Prerequisites

1. AWS credentials configured (`~/.aws/credentials`)
2. Databricks account credentials
3. This repository with all files intact

## Step-by-Step Redeployment

### Step 1: Verify Configuration
```bash
cd /Users/som.natarajan/databricks-workspace-deployment
cat config.yaml  # Review your settings
```

### Step 2: Deploy All Infrastructure
```bash
./deploy-everything.sh
```

This single command will:
- ✅ Create AWS resources (VPC, S3, IAM roles)
- ✅ Create Databricks workspace
- ✅ Set up Unity Catalog metastore
- ✅ Create catalogs and schemas
- ✅ Deploy Lakebase database
- ✅ Create tables and populate sample data
- ✅ Set up users and groups
- ✅ Deploy fraud-case-management app

**Expected time**: 15-20 minutes

### Step 3: Upload Application Code to Workspace

The app is already referenced in Terraform, but if you need to update the code:

```bash
cd /Users/som.natarajan/fraud-case-management

# Upload all files to workspace
databricks workspace import-dir . /Workspace/fraud-case-management-app \
  --overwrite --exclude ".git,node_modules,frontend/build"
```

### Step 4: Re-import Dashboard (Optional)

If you want to recreate the dashboard:

```bash
# Dashboard JSON is in your Downloads folder
# Import it via Databricks UI or API
# File: ~/Downloads/"[dbdemos] FSI Fraud analysis Analysis.lvdash.json"
```

Then share the dashboard with service principal `som-one-env-sandbox-sp`.

### Step 5: Update Dashboard ID in App (If New Dashboard)

If you created a new dashboard, update the ID in:
```javascript
// fraud-case-management/frontend/src/components/MetricsReporting.js
iframe.src = 'https://one-env-som-workspace.cloud.databricks.com/embed/dashboardsv3/YOUR_NEW_DASHBOARD_ID?o=700756980496563';
```

Then redeploy:
```bash
databricks apps deploy fraud-case-management \
  --source-code-path /Workspace/fraud-case-management-app
```

## What Gets Recreated Automatically

✅ AWS VPC, subnets, NAT gateway
✅ S3 buckets (root + metastore storage)
✅ IAM roles and policies
✅ Databricks workspace
✅ Unity Catalog metastore
✅ Catalogs: `afc-mvp`, `afc_lakebase_catalog`
✅ Schemas: `fraud-investigation`, etc.
✅ Lakebase PostgreSQL database
✅ Sample tables and data
✅ Service principal: `som-one-env-sandbox-sp`
✅ Users and groups
✅ Fraud-case-management app

## What Needs Manual Steps

⚠️ Dashboard import (if you want the FSI dashboard)
⚠️ Dashboard sharing with service principal
⚠️ AWS Secrets (if you recreated them in Secrets Manager)

## Troubleshooting

### If deployment fails:
```bash
# Check Terraform state
terraform state list

# View detailed logs
terraform apply -auto-approve 2>&1 | tee deployment.log
```

### If app doesn't deploy:
```bash
# Check app status
databricks apps list

# Manually deploy
databricks apps deploy fraud-case-management \
  --source-code-path /Workspace/fraud-case-management-app
```

## Time Estimates

- Terraform infrastructure: 10-15 minutes
- Application code upload: 1 minute
- Dashboard import: 2 minutes
- App deployment: 2-3 minutes

**Total**: ~20 minutes for full environment recreation

## Files That Are Safe to Keep

These files contain your configuration and will be used for redeployment:
- ✅ `config.yaml` - Main configuration
- ✅ `terraform.tfvars` - Generated from config.yaml
- ✅ All `.tf` files - Infrastructure as code
- ✅ All module files
- ✅ Application source code
- ✅ Dashboard JSON in Downloads

## What Gets Lost

After `terraform destroy`, these are gone (but can be recreated):
- ❌ Databricks workspace and all data in it
- ❌ Unity Catalog data (tables, volumes)
- ❌ App deployments
- ❌ Dashboard in workspace (but you have the JSON)
- ❌ AWS resources (VPC, S3, etc.)

But you can recreate ALL of it with `./deploy-everything.sh`! 🚀

