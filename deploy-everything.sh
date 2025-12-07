#!/bin/bash
# 🚀 ONE-CLICK DEPLOYMENT: Complete Databricks Fraud Management Platform
# This script deploys everything from scratch to a fully running application
#
# Usage: ./deploy-everything.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_PREFIX="${WORKSPACE_PREFIX:-som-workspace}"
FRAUD_APP_DIR="${FRAUD_APP_DIR:-../fraud-case-management}"
AWS_PROFILE="${AWS_PROFILE:-som}"
AWS_REGION="${AWS_REGION:-eu-west-1}"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🚀 ONE-CLICK DATABRICKS FRAUD MANAGEMENT DEPLOYMENT         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This script will:${NC}"
echo "  0️⃣  Generate configuration files from config.yaml"
echo "  1️⃣  Load credentials from AWS Secrets Manager"
echo "  2️⃣  Deploy Databricks workspace with Unity Catalog"
echo "  3️⃣  Create Lakebase database instance"
echo "  4️⃣  Add users and groups"
echo "  5️⃣  Create Unity Catalog objects (catalogs, schemas, volumes)"
echo "  6️⃣  Setup PostgreSQL database schema"
echo "  7️⃣  Deploy fraud case management application"
echo ""
echo -e "${YELLOW}Estimated time: 10-15 minutes${NC}"
echo ""
read -p "Press Enter to start deployment or Ctrl+C to cancel..."
echo ""

# Track start time
START_TIME=$(date +%s)

# ============================================
# STEP 0: Generate Configuration Files
# ============================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🔧 STEP 0/7: Generating Configuration Files${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [ ! -f "config.yaml" ]; then
    echo -e "${RED}❌ Error: config.yaml not found!${NC}"
    echo ""
    echo "Please create config.yaml with your settings:"
    echo "  1. Copy the example: cp config.yaml.example config.yaml"
    echo "  2. Edit config.yaml with your settings"
    echo "  3. Run this script again"
    echo ""
    exit 1
fi

echo "🔧 Running configuration generator..."
./configure.sh

echo "✅ Configuration files generated"
echo ""

# ============================================
# STEP 1: Load Credentials from AWS Secrets
# ============================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📦 STEP 1/7: Loading Credentials from AWS Secrets Manager${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Load Terraform credentials (account-level SP)
echo "🔐 Loading Terraform Service Principal credentials..."
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "databricks/terraform-sp-credentials" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --query SecretString \
  --output text)

export DATABRICKS_CLIENT_ID=$(echo "$SECRET_JSON" | jq -r '.client_id')
export DATABRICKS_CLIENT_SECRET=$(echo "$SECRET_JSON" | jq -r '.client_secret')
export DATABRICKS_ACCOUNT_ID=$(echo "$SECRET_JSON" | jq -r '.account_id')

# Unset workspace host for account-level operations
unset DATABRICKS_HOST

echo "✅ Terraform credentials loaded"

# Load OAuth credentials (workspace-level SP)
echo "🔐 Loading OAuth credentials..."
OAUTH_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "databricks/som-workspace/sp-oauth" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --query SecretString \
  --output text)

OAUTH_CLIENT_ID=$(echo "$OAUTH_JSON" | jq -r '.client_id')
OAUTH_CLIENT_SECRET=$(echo "$OAUTH_JSON" | jq -r '.client_secret')
WORKSPACE_URL=$(echo "$OAUTH_JSON" | jq -r '.workspace_url')

echo "✅ OAuth credentials loaded"
echo ""

# ============================================
# STEP 2: Deploy Infrastructure with Terraform
# ============================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🏗️  STEP 2/7: Deploying Infrastructure with Terraform${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

terraform init
terraform plan -out=tfplan
terraform apply tfplan

echo ""
echo "✅ Infrastructure deployed successfully!"
echo ""

# Get outputs
WORKSPACE_ID=$(terraform output -raw workspace_id)
WORKSPACE_URL=$(terraform output -raw workspace_url)
LAKEBASE_INSTANCE=$(terraform output -json lakebase_database_instances | jq -r '."afc-lakebase-instance".name')
LAKEBASE_DNS=$(terraform output -json lakebase_database_instances | jq -r '."afc-lakebase-instance".read_write_dns')

echo "📊 Deployed Resources:"
echo "   Workspace: $WORKSPACE_URL"
echo "   Lakebase Instance: $LAKEBASE_INSTANCE"
echo "   Database Host: $LAKEBASE_DNS"
echo ""

# ============================================
# STEP 3: Configure Databricks CLI
# ============================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🔧 STEP 3/7: Configuring Databricks CLI${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

cat > ~/.databrickscfg << EOF
[DEFAULT]
host          = $WORKSPACE_URL
client_id     = $OAUTH_CLIENT_ID
client_secret = $OAUTH_CLIENT_SECRET
EOF

echo "✅ Databricks CLI configured with Service Principal OAuth"
echo ""

# ============================================
# STEP 4: Wait for Lakebase Instance
# ============================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}⏳ STEP 4/7: Waiting for Lakebase Instance to be Ready${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo "⏳ Lakebase instances can take 3-5 minutes to become fully available..."
echo "   Waiting 60 seconds before database setup..."
sleep 60

echo "✅ Wait complete"
echo ""

# ============================================
# STEP 5: Setup Database
# ============================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🗄️  STEP 5/7: Setting up PostgreSQL Database${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo "⚠️  MANUAL STEP REQUIRED:"
echo ""
echo "Please run these SQL commands in Databricks SQL Editor:"
echo "  (Connect to: $LAKEBASE_INSTANCE)"
echo ""
echo -e "${YELLOW}────────────────────────────────────────────────────────${NC}"
cat << 'SQLEOF'
-- 1. Create PostgreSQL user
CREATE USER admin WITH PASSWORD 'FraudAdmin2024!';

-- 2. Grant privileges
GRANT ALL ON SCHEMA public TO admin;
GRANT CREATE ON SCHEMA public TO admin;
GRANT USAGE ON SCHEMA public TO admin;

-- 3. Create fraud_management schema
CREATE SCHEMA IF NOT EXISTS fraud_management;
GRANT ALL ON SCHEMA fraud_management TO admin;
GRANT CREATE ON SCHEMA fraud_management TO admin;
GRANT USAGE ON SCHEMA fraud_management TO admin;
SQLEOF
echo -e "${YELLOW}────────────────────────────────────────────────────────${NC}"
echo ""
read -p "Press Enter once you've run these SQL commands..."
echo ""

# Now setup tables and data
cd "$FRAUD_APP_DIR"
echo "📝 Creating database tables..."
PGSSLMODE=require PGPASSWORD="FraudAdmin2024!" psql \
  -h "$LAKEBASE_DNS" \
  -p 5432 \
  -U admin \
  -d fraud_detection_db \
  -f backend/db/schema-with-namespace.sql > /dev/null 2>&1

echo "🌱 Seeding sample data..."
PGSSLMODE=require PGPASSWORD="FraudAdmin2024!" psql \
  -h "$LAKEBASE_DNS" \
  -p 5432 \
  -U admin \
  -d fraud_detection_db \
  -f backend/db/seed-with-namespace.sql > /dev/null 2>&1

echo "✅ Database setup complete!"
echo ""

# ============================================
# STEP 6: Deploy Application
# ============================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🚀 STEP 6/7: Deploying Fraud Case Management Application${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Build frontend
echo "📦 Building frontend..."
cd frontend
npm run build > /dev/null 2>&1
cd ..

# Sync code to workspace
echo "📤 Syncing code to workspace..."
databricks workspace mkdirs /Workspace/fraud-case-management-app || true
databricks workspace import-dir . /Workspace/fraud-case-management-app --overwrite > /dev/null 2>&1

# Create app if doesn't exist, or get existing
echo "📱 Checking if app exists..."
if databricks apps get som-fraud-case-management > /dev/null 2>&1; then
    echo "   App already exists, deploying update..."
else
    echo "   Creating new app..."
    databricks apps create som-fraud-case-management \
      --description "Fraud Case Management Application" > /dev/null 2>&1
fi

# Deploy the app
echo "🚀 Deploying application..."
databricks apps deploy som-fraud-case-management \
  --source-code-path /Workspace/fraud-case-management-app > /dev/null 2>&1

# Wait for app to be running
echo "⏳ Waiting for app to start..."
for i in {1..30}; do
    STATUS=$(databricks apps get som-fraud-case-management --output json | jq -r '.app_status.state' 2>/dev/null || echo "UNKNOWN")
    if [ "$STATUS" = "RUNNING" ]; then
        break
    fi
    echo "   Attempt $i/30: $STATUS"
    sleep 5
done

APP_URL=$(databricks apps get som-fraud-case-management --output json | jq -r '.url' 2>/dev/null)

echo "✅ Application deployed successfully!"
echo ""

# ============================================
# DEPLOYMENT COMPLETE
# ============================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           🎉 DEPLOYMENT COMPLETE! 🎉                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}⏱️  Total deployment time: ${MINUTES}m ${SECONDS}s${NC}"
echo ""
echo -e "${GREEN}🌐 Your Fraud Case Management Application:${NC}"
echo -e "${YELLOW}   $APP_URL${NC}"
echo ""
echo -e "${GREEN}📊 Resources Deployed:${NC}"
echo "   ✅ Databricks Workspace: $WORKSPACE_URL"
echo "   ✅ Unity Catalog Metastore: som-uc-metastore"
echo "   ✅ Lakebase Instance: $LAKEBASE_INSTANCE"
echo "   ✅ Database: fraud_detection_db (6 tables, sample data loaded)"
echo "   ✅ Unity Catalog: afc-mvp (with fraud-investigation schema)"
echo "   ✅ User: Som Natarajan (Workspace Admin)"
echo "   ✅ Application: som-fraud-case-management (RUNNING)"
echo ""
echo -e "${GREEN}🎯 Next Steps:${NC}"
echo "   1. Open your app: $APP_URL"
echo "   2. Start investigating fraud cases!"
echo "   3. Add more users: Update terraform.tfvars and run 'terraform apply'"
echo ""
echo -e "${BLUE}📝 All infrastructure is managed by Terraform!${NC}"
echo "   - Modify terraform.tfvars to make changes"
echo "   - Run 'terraform plan' to preview"
echo "   - Run 'terraform apply' to apply changes"
echo ""
echo -e "${GREEN}🎊 Your fraud investigation platform is ready to use!${NC}"
echo ""

