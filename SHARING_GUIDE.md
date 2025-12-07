# 🤝 Sharing This Project - Quick Guide

## For the Person Sharing (You)

### 1. Prepare the Project

```bash
# Ensure you have the example config
ls config.yaml.example  # Should exist

# Ensure you DON'T commit secrets
echo "config.yaml" >> .gitignore
echo ".env" >> .gitignore
echo "terraform.tfvars" >> .gitignore
echo "terraform.tfstate*" >> .gitignore
```

### 2. Commit to Git

```bash
git init
git add .
git commit -m "Initial commit: Databricks deployment automation"
git remote add origin <your-repo-url>
git push -u origin main
```

### 3. Share Instructions

Send your colleague this:

> Hey! I've set up an automated Databricks deployment. Here's how to use it:
> 
> 1. Clone the repo: `git clone <repo-url>`
> 2. Create your config: `cp config.yaml.example config.yaml`
> 3. Edit `config.yaml` with your settings (workspace name, DB names, etc.)
> 4. Setup AWS secrets (see instructions in config.yaml)
> 5. Run: `./deploy-everything.sh`
> 
> That's it! You'll have a complete Databricks workspace with fraud management app in ~15 minutes.

---

## For the Person Receiving (Them)

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd databricks-workspace-deployment
```

### Step 2: Create Your Configuration

```bash
# Copy the example config
cp config.yaml.example config.yaml

# Edit with your settings
nano config.yaml
```

**What to change in `config.yaml`:**

```yaml
aws:
  region: "your-aws-region"          # e.g., us-east-1
  profile: "your-aws-profile"        # e.g., default

databricks:
  account_id: "your-account-id"      # From Databricks Admin Console

workspace:
  name: "your-workspace-name"        # e.g., john-workspace
  prefix: "your-prefix"              # e.g., john-dbx (used for AWS resources)

unity_catalog:
  metastore_name: "your-metastore"   # e.g., john-uc-metastore

lakebase:
  instances:
    - name: "your-db-instance"       # e.g., john-lakebase
  catalogs:
    - database_name: "your_database" # e.g., john_fraud_db

users:
  users:
    - user_name: "your.email@company.com"
      display_name: "Your Name"
      groups: ["Data Engineers", "admins"]
```

### Step 3: Store Credentials in AWS Secrets Manager

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
  --region your-region \
  --profile your-profile

# Store OAuth credentials for workspace
aws secretsmanager create-secret \
  --name "databricks/YOUR_WORKSPACE_NAME/sp-oauth" \
  --description "OAuth credentials for workspace" \
  --secret-string '{
    "client_id": "YOUR_CLIENT_ID",
    "client_secret": "YOUR_OAUTH_SECRET",
    "workspace_url": "https://...",
    "account_id": "YOUR_ACCOUNT_ID"
  }' \
  --region your-region \
  --profile your-profile
```

### Step 4: Deploy Everything!

```bash
./deploy-everything.sh
```

**Wait ~15 minutes** and you'll have:
- ✅ Databricks Workspace
- ✅ Unity Catalog Metastore
- ✅ Lakebase Database
- ✅ Fraud Management Application
- ✅ Sample Data Loaded

### Step 5: Access Your Application

Once deployment completes, you'll see:

```
🎉 DEPLOYMENT COMPLETE!

🌐 Your Application:
   https://your-app-name-123456.aws.databricksapps.com

📊 Your Workspace:
   https://one-env-your-workspace.cloud.databricks.com
```

---

## Configuration Reference

### Minimal Configuration

The minimum you need to change in `config.yaml`:

```yaml
aws:
  region: "us-east-1"
  profile: "default"

databricks:
  account_id: "your-databricks-account-id"
  service_principal:
    client_id: "your-sp-client-id"
  oauth:
    client_id: "your-sp-client-id"

workspace:
  name: "my-workspace"
  prefix: "my-workspace"

users:
  users:
    - user_name: "your.email@company.com"
      display_name: "Your Name"
      groups: ["admins"]
```

Everything else has sensible defaults!

### Advanced Configuration

For advanced users, you can customize:
- VPC settings (use existing or create new)
- Multiple catalogs and schemas
- Multiple Lakebase instances
- Custom tags for resources
- Multiple users and groups
- Database names and schemas

See `config.yaml.example` for all options.

---

## Common Questions

### Q: Do I need to know Terraform?
**A:** No! Just edit `config.yaml` and run the deployment script.

### Q: Can I use an existing VPC?
**A:** Yes! Set `workspace.vpc.use_existing: true` in `config.yaml` and provide your VPC/subnet IDs.

### Q: How do I add more users later?
**A:** Edit `config.yaml`, add users to the `users.users` list, and run `terraform apply`.

### Q: Can I customize the database name?
**A:** Yes! Change `lakebase.catalogs[0].database_name` in `config.yaml`.

### Q: What if I want multiple workspaces?
**A:** Copy the project to a new directory, create a new `config.yaml` with different names, and deploy.

### Q: Is this production-ready?
**A:** Yes! All best practices are built-in:
- Service Principal authentication
- AWS Secrets Manager for credentials
- SSL/TLS encryption
- IAM least privilege
- Infrastructure as Code

### Q: How do I destroy everything?
**A:** Run `./cleanup-everything.sh`

---

## Troubleshooting

### Deployment Failed?

```bash
# Check what went wrong
terraform show

# Fix the issue in config.yaml
nano config.yaml

# Try again
./deploy-everything.sh
```

### Wrong Configuration?

```bash
# Edit config.yaml
nano config.yaml

# Regenerate all configs
./configure.sh

# Apply changes
terraform apply
```

### Need Help?

1. Check `README.md` for detailed documentation
2. Run `./test-deployment.sh` to verify your setup
3. Check Terraform state: `terraform show`
4. View app logs: `databricks apps logs <app-name>`

---

## Best Practices for Sharing

### Do ✅
- Share `config.yaml.example` (not `config.yaml`)
- Document what needs to be changed
- Include instructions for AWS Secrets Manager
- Add `.gitignore` entries for secrets
- Version control the code, not the secrets

### Don't ❌
- Don't commit `config.yaml` with real values
- Don't commit `terraform.tfvars`
- Don't commit `.env`
- Don't commit `terraform.tfstate`
- Don't hardcode secrets in code

---

## File Checklist for Sharing

**Include in Git:**
- ✅ `config.yaml.example`
- ✅ `configure.sh`
- ✅ `deploy-everything.sh`
- ✅ `cleanup-everything.sh`
- ✅ `test-deployment.sh`
- ✅ `README.md`
- ✅ `SHARING_GUIDE.md`
- ✅ `main.tf` and all Terraform files
- ✅ `modules/` directory
- ✅ `fraud-case-management/` app code

**Exclude from Git:**
- ❌ `config.yaml` (your actual config)
- ❌ `terraform.tfvars`
- ❌ `terraform.tfstate*`
- ❌ `.env`
- ❌ `.terraform/`
- ❌ `node_modules/`

---

## Example `.gitignore`

```gitignore
# Terraform
terraform.tfstate*
.terraform/
*.tfvars
!terraform.tfvars.example

# Configuration
config.yaml
.env

# Dependencies
node_modules/
venv/
__pycache__/

# Build
build/
dist/

# Logs
*.log
```

---

**Happy Sharing! 🚀**

Your colleague will be up and running in 15 minutes with a complete Databricks platform!

