#!/bin/bash
# 🧹 CLEANUP SCRIPT: Destroy all Databricks resources
# This script removes everything deployed by deploy-everything.sh
#
# Usage: ./cleanup-everything.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRAUD_APP_DIR="${FRAUD_APP_DIR:-../fraud-case-management}"
AWS_PROFILE="${AWS_PROFILE:-som}"
AWS_REGION="${AWS_REGION:-eu-west-1}"

echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║  🧹 CLEANUP: Destroy All Databricks Resources                ║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will destroy:${NC}"
echo "  ❌ Databricks workspace"
echo "  ❌ Unity Catalog metastore"
echo "  ❌ Lakebase database instance"
echo "  ❌ All users and groups"
echo "  ❌ All Unity Catalog objects"
echo "  ❌ Fraud case management application"
echo "  ❌ All AWS resources (S3 buckets, IAM roles, etc.)"
echo ""
echo -e "${RED}THIS CANNOT BE UNDONE!${NC}"
echo ""
read -p "Type 'YES' to confirm destruction: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}Starting cleanup...${NC}"
echo ""

# Track start time
START_TIME=$(date +%s)

# ============================================
# STEP 1: Load Credentials
# ============================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📦 STEP 1/4: Loading Credentials${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "databricks/service-principal" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --query SecretString \
  --output text)

export DATABRICKS_CLIENT_ID=$(echo "$SECRET_JSON" | jq -r '.client_id')
export DATABRICKS_CLIENT_SECRET=$(echo "$SECRET_JSON" | jq -r '.client_secret')

echo "✅ Credentials loaded"
echo ""

# ============================================
# STEP 2: Delete Databricks App
# ============================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🗑️  STEP 2/4: Deleting Databricks Application${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

OAUTH_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "databricks/som-workspace/sp-oauth" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --query SecretString \
  --output text 2>/dev/null || echo '{}')

if [ "$OAUTH_JSON" != "{}" ]; then
    OAUTH_CLIENT_ID=$(echo "$OAUTH_JSON" | jq -r '.client_id')
    OAUTH_CLIENT_SECRET=$(echo "$OAUTH_JSON" | jq -r '.client_secret')
    WORKSPACE_URL=$(echo "$OAUTH_JSON" | jq -r '.workspace_url')
    
    cat > ~/.databrickscfg << EOF
[DEFAULT]
host          = $WORKSPACE_URL
client_id     = $OAUTH_CLIENT_ID
client_secret = $OAUTH_CLIENT_SECRET
EOF
    
    echo "🗑️  Deleting fraud case management app..."
    if databricks apps get som-fraud-case-management > /dev/null 2>&1; then
        databricks apps delete som-fraud-case-management || true
        echo "✅ App deleted"
    else
        echo "ℹ️  App not found (already deleted or never created)"
    fi
else
    echo "ℹ️  OAuth credentials not found, skipping app deletion"
fi

echo ""

# ============================================
# STEP 3: Destroy Terraform Resources
# ============================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}💥 STEP 3/4: Destroying Terraform Infrastructure${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

terraform destroy -auto-approve

echo "✅ Infrastructure destroyed"
echo ""

# ============================================
# STEP 4: Clean up Secrets (Optional)
# ============================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🔐 STEP 4/4: Cleanup AWS Secrets (Optional)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo "Do you want to delete AWS Secrets Manager secrets?"
echo "  - databricks/service-principal"
echo "  - databricks/som-workspace/sp-oauth"
echo ""
read -p "Type 'YES' to delete secrets: " DELETE_SECRETS

if [ "$DELETE_SECRETS" = "YES" ]; then
    echo "🗑️  Deleting secrets..."
    aws secretsmanager delete-secret \
      --secret-id "databricks/service-principal" \
      --region "$AWS_REGION" \
      --profile "$AWS_PROFILE" \
      --force-delete-without-recovery || true
    
    aws secretsmanager delete-secret \
      --secret-id "databricks/som-workspace/sp-oauth" \
      --region "$AWS_REGION" \
      --profile "$AWS_PROFILE" \
      --force-delete-without-recovery || true
    
    echo "✅ Secrets deleted"
else
    echo "ℹ️  Secrets retained (you can reuse them for future deployments)"
fi

echo ""

# ============================================
# CLEANUP COMPLETE
# ============================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           🧹 CLEANUP COMPLETE! 🧹                            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}⏱️  Total cleanup time: ${MINUTES}m ${SECONDS}s${NC}"
echo ""
echo -e "${GREEN}✅ All resources have been destroyed!${NC}"
echo ""
echo -e "${YELLOW}📝 To redeploy everything:${NC}"
echo "   ./deploy-everything.sh"
echo ""

