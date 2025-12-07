# 🚀 Databricks Fraud Management Platform - One-Click Deployment

Complete infrastructure-as-code for deploying a production-ready fraud case management platform on Databricks.

## 🎯 What This Deploys

This automated deployment creates a complete fraud investigation platform:

- ✅ **Databricks Workspace** with Unity Catalog enabled
- ✅ **Unity Catalog IAM Role** (self-assuming, ready for managed tables)
- ✅ **Lakebase Database Instance** (PostgreSQL-compatible)
- ✅ **Unity Catalog Objects** (catalogs, schemas, volumes)
- ✅ **Fraud Dashboard Tables** (Unity Catalog Delta tables with sample data)
- ✅ **SQL Warehouse** (for analytics and dashboard queries)
- ✅ **Users & Groups** with role-based access control
- ✅ **Fraud Case Management Application** (full-stack React + Node.js app)
- ✅ **Sample Data** (10 fraud cases, 3 investigators, transactions, indicators)

## 📋 Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads) (>= 1.5.0)
- [AWS CLI](https://aws.amazon.com/cli/) (configured with credentials)
- [Databricks CLI](https://docs.databricks.com/dev-tools/cli/index.html)
- [jq](https://stedolan.github.io/jq/) (JSON processor)
- [PostgreSQL Client](https://www.postgresql.org/download/) (`psql`)
- [Node.js](https://nodejs.org/) (>= 18.x)

### Required Credentials

1. **Databricks Service Principal** (Account Admin privileges)
   - Client ID
   - Client Secret

2. **AWS Account** with permissions to create:
   - VPC, Subnets, Security Groups
   - S3 Buckets
   - IAM Roles and Policies
   - Secrets Manager Secrets

3. **Databricks Account ID**

## 🏗️ Project Structure

```
databricks-workspace-deployment/
├── deploy-fraud-app.sh          # 🎯 UNIFIED FRAUD APP DEPLOYMENT
├── deploy-everything.sh         # 🚀 Infrastructure deployment only
├── cleanup-everything.sh        # 🧹 Destroy all resources
├── terraform.tfvars             # Configuration file (edit this!)
├── main.tf                      # Main Terraform configuration
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Output definitions
├── sql/                         # SQL scripts for fraud tables
│   ├── fraud_dashboard_schema.sql
│   └── fraud_dashboard_seed.sql
└── modules/
    ├── users/                   # User & group management
    ├── unity-catalog/           # Catalog, schema, volume management
    ├── fraud-tables/            # Fraud dashboard tables
    ├── lakebase/                # Database instance management
    └── apps/                    # Databricks Apps management

fraud-case-management/
├── app.yaml                     # Databricks App configuration
├── frontend/                    # React frontend
├── backend/                     # Node.js/Express backend
└── backend/db/                  # Database schema & seed data
```

## 🎯 Quick Start (For Someone New)

**Everything is configured in ONE file:** `config.yaml`

```bash
# 1. Copy the example configuration
cp config.yaml.example config.yaml

# 2. Edit config.yaml with your settings
nano config.yaml

# 3. Deploy everything!
./deploy-everything.sh
```

That's it! The deployment script will automatically:
- Generate `terraform.tfvars` from your config
- Update `app.yaml` with correct values
- Create all necessary configuration files

---

## 🎯 Unified Fraud App Deployment (Recommended)

The **simplest way** to deploy everything including the fraud case management app:

```bash
# Deploy everything with one command!
./deploy-fraud-app.sh
```

This script will:
1. ✅ Deploy all infrastructure (AWS + Databricks)
2. ✅ Create Unity Catalog with fraud dashboard tables
3. ✅ Create SQL Warehouse for analytics
4. ✅ Insert sample fraud data (10 cases, transactions, indicators)
5. ✅ Deploy the Fraud Case Management application
6. ✅ Provide you with the app URL

**Environment Variables:**
- `FRAUD_APP_DIR` - Path to fraud-case-management directory (default: `$HOME/fraud-case-management`)
- `DASHBOARD_ID` - Dashboard ID to reference (default: auto-detected)

**Example:**
```bash
FRAUD_APP_DIR=/path/to/fraud-case-management ./deploy-fraud-app.sh
```

**When to use this?**
- ✅ Fresh deployment from scratch
- ✅ You want everything set up automatically
- ✅ You're deploying the fraud management use case

**When NOT to use this?**
- ❌ You only want infrastructure without the app
- ❌ You're deploying a different application
- ❌ You want more control over each step

For infrastructure-only deployment, use `./deploy-everything.sh` instead.

---

## 🚀 DETAILED SETUP

### Step 1: Create Your Configuration File

Copy the example and edit with your settings:

```bash
cp config.yaml.example config.yaml
nano config.yaml
```

**Key settings to update in `config.yaml`:**
- `aws.region` - Your AWS region
- `aws.profile` - Your AWS CLI profile
- `databricks.account_id` - Your Databricks account ID
- `workspace.name` - Your desired workspace name
- `workspace.prefix` - Prefix for all AWS resources
- `unity_catalog.metastore_name` - Your UC metastore name
- `lakebase.instances[0].name` - Your database instance name
- `users.users` - Add your team members

### Step 2: Store Credentials in AWS Secrets Manager

```bash
# Store Databricks Service Principal credentials
aws secretsmanager create-secret \
  --name "databricks/service-principal" \
  --description "Databricks Service Principal for Terraform" \
  --secret-string '{
    "client_id": "YOUR_CLIENT_ID",
    "client_secret": "YOUR_CLIENT_SECRET",
    "account_id": "YOUR_ACCOUNT_ID"
  }' \
  --region eu-west-1 \
  --profile som

# Store OAuth credentials for workspace access
aws secretsmanager create-secret \
  --name "databricks/som-workspace/sp-oauth" \
  --description "Service Principal OAuth credentials" \
  --secret-string '{
    "client_id": "YOUR_CLIENT_ID",
    "client_secret": "YOUR_OAUTH_SECRET",
    "workspace_url": "https://your-workspace.cloud.databricks.com",
    "account_id": "YOUR_ACCOUNT_ID"
  }' \
  --region eu-west-1 \
  --profile som
```

### Step 3: Deploy Everything! 🚀

```bash
./deploy-everything.sh
```

**That's it!** ☕ The script will:
0. Generate all config files from `config.yaml`
1. Load credentials from AWS Secrets Manager
2. Deploy Databricks workspace with Unity Catalog
3. Create Lakebase database instance
4. Add users and groups
5. Create Unity Catalog objects
6. Setup PostgreSQL database schema
7. Deploy fraud case management application

Wait ~10-15 minutes for complete deployment.

---

## 📝 Configuration Reference

All configuration is centralized in `config.yaml`. Here's what each section does:

### AWS Configuration
```yaml
aws:
  region: "eu-west-1"
  profile: "som"
```

### Databricks Configuration
```yaml
databricks:
  account_id: "your-account-id"
  service_principal:
    client_id: "your-sp-client-id"
```

### Workspace Configuration
```yaml
workspace:
  name: "my-workspace"
  prefix: "my-workspace"
  vpc:
    use_existing: true
    vpc_id: "vpc-xxxxx"
```

### Old Method (Still Works)

You can also edit `terraform.tfvars` directly if you prefer:

See `terraform.tfvars.example` for all available options.

### Step 4: Access Your Application

Once deployment completes, you'll see:

```
🎉 DEPLOYMENT COMPLETE! 🎉

🌐 Your Fraud Case Management Application:
   https://som-fraud-case-management-123456.aws.databricksapps.com

📊 Resources Deployed:
   ✅ Databricks Workspace
   ✅ Unity Catalog Metastore
   ✅ Lakebase Instance
   ✅ Database with sample data
   ✅ Application (RUNNING)
```

Click the URL to access your fraud investigation platform!

## 🧹 Cleanup (Destroy Everything)

To remove all resources:

```bash
# Make the script executable
chmod +x cleanup-everything.sh

# Run cleanup
./cleanup-everything.sh
```

This will destroy:
- ❌ Databricks workspace
- ❌ Unity Catalog metastore
- ❌ Lakebase database instance
- ❌ All AWS resources (S3, IAM, etc.)
- ❌ Fraud case management application

## 🔧 Manual Operations

### Update Infrastructure

Edit `terraform.tfvars` and apply changes:

```bash
terraform plan    # Preview changes
terraform apply   # Apply changes
```

### Add More Users

Edit `terraform.tfvars`:

```hcl
users = [
  {
    user_name    = "new.user@databricks.com"
    display_name = "New User"
    groups       = ["Data Engineers"]
  }
]
```

Then run:

```bash
terraform apply
```

### Redeploy Application Only

```bash
cd ../fraud-case-management
./deploy.sh som-fraud-case-management
```

### Connect to Lakebase Database

```bash
# Get database host from Terraform outputs
LAKEBASE_DNS=$(terraform output -json lakebase_database_instances | jq -r '."afc-lakebase-instance".read_write_dns')

# Connect with psql
PGSSLMODE=require PGPASSWORD="FraudAdmin2024!" psql \
  -h "$LAKEBASE_DNS" \
  -p 5432 \
  -U admin \
  -d fraud_detection_db
```

## 📦 Terraform Modules

### Users Module (`modules/users/`)

Manages Databricks users and groups.

**Features:**
- Create users with display names
- Create groups
- Assign users to groups
- Support for built-in groups (e.g., `admins`)

### Unity Catalog Module (`modules/unity-catalog/`)

Manages Unity Catalog objects.

**Features:**
- Create catalogs
- Create schemas within catalogs
- Create volumes for unstructured data

### Lakebase Module (`modules/lakebase/`)

Manages Databricks Lakebase (PostgreSQL) instances.

**Features:**
- Create database instances with configurable capacity
- Enable PostgreSQL native login
- Register databases as Unity Catalog catalogs
- Automatic database creation

## 🎯 Application Features

The deployed fraud case management application includes:

### For Fraud Investigators:
- 📊 **Dashboard** - Real-time fraud metrics and analytics
- 🔍 **Case Management** - Investigate and manage fraud cases
- 📈 **Claims Analysis** - Analyze claims patterns
- 🚨 **Alerts** - Real-time fraud alerts

### For Admins:
- 👥 **User Management** - Add/remove investigators
- 🔧 **Configurations** - Configure thresholds and rules
- 📊 **Reporting** - Generate fraud reports

### Technical Stack:
- **Frontend**: React with modern UI components
- **Backend**: Node.js/Express REST API
- **Database**: PostgreSQL (Lakebase) with optimized schema
- **Auth**: Databricks Service Principal OAuth

## 🔐 Security

### Credentials Management
- ✅ All secrets stored in AWS Secrets Manager
- ✅ Service Principal authentication
- ✅ SSL/TLS encrypted database connections
- ✅ Role-based access control

### Best Practices Implemented
- ✅ Infrastructure as Code (Terraform)
- ✅ Automated deployments
- ✅ Modular architecture
- ✅ Comprehensive logging
- ✅ Resource tagging

## 🐛 Troubleshooting

### Terraform Errors

**Issue**: AWS resource limits
```bash
# Check your VPC limits
aws ec2 describe-account-attributes --region eu-west-1

# Use existing VPC
# Edit terraform.tfvars:
use_existing_vpc = true
existing_vpc_id = "vpc-xxxxx"
```

**Issue**: Databricks validation errors
```bash
# Wait 60 seconds for IAM propagation
sleep 60
terraform apply
```

### Database Connection Errors

**Issue**: Cannot connect to Lakebase
```bash
# Ensure PostgreSQL user exists in Databricks SQL Editor:
CREATE USER admin WITH PASSWORD 'FraudAdmin2024!';
GRANT ALL ON SCHEMA public TO admin;
```

### Application Deployment Errors

**Issue**: Databricks CLI not configured
```bash
# Reload credentials
cd ../fraud-case-management
source ./load-sp-oauth.sh
```

## 📚 Additional Resources

- [Databricks Terraform Provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs)
- [Databricks Apps Documentation](https://docs.databricks.com/dev-tools/databricks-apps/index.html)
- [Lakebase Documentation](https://docs.databricks.com/lakebase/index.html)
- [Unity Catalog Best Practices](https://docs.databricks.com/data-governance/unity-catalog/best-practices.html)

## 📝 License

This project is for internal use only.

## 🤝 Support

For issues or questions, contact: som.natarajan@databricks.com

---

**Built with ❤️ for efficient fraud investigation**

