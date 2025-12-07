#!/bin/bash

# Unified deployment script for Databricks workspace and Fraud Case Management app
# This script deploys everything in the correct order:
# 1. Terraform infrastructure (AWS, Databricks workspace, Unity Catalog, Tables)
# 2. Fraud Case Management application
# 3. Dashboard (if needed)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAUD_APP_DIR="${FRAUD_APP_DIR:-$HOME/fraud-case-management}"
DASHBOARD_ID="${DASHBOARD_ID:-01f0d3a2a42714ddb65bf4d5d02ffcde}"

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║  Databricks Fraud Management System - Full Deployment     ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v databricks &> /dev/null; then
        missing_tools+=("databricks CLI")
    fi
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws CLI")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    # Check if fraud app directory exists
    if [ ! -d "$FRAUD_APP_DIR" ]; then
        log_error "Fraud app directory not found: $FRAUD_APP_DIR"
        log_info "Set FRAUD_APP_DIR environment variable or update the script"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Deploy Terraform infrastructure
deploy_infrastructure() {
    log_info "Deploying Terraform infrastructure..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init -upgrade
    
    # Plan
    log_info "Planning Terraform changes..."
    terraform plan -out=tfplan
    
    # Confirm before apply
    echo ""
    log_warning "This will create/update:"
    log_warning "  - AWS resources (VPC, S3, IAM roles)"
    log_warning "  - Databricks workspace"
    log_warning "  - Unity Catalog (metastore, catalogs, schemas)"
    log_warning "  - SQL Warehouse"
    log_warning "  - Fraud dashboard tables (with sample data)"
    echo ""
    read -p "Do you want to proceed? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log_error "Deployment cancelled"
        exit 1
    fi
    
    # Apply
    log_info "Applying Terraform configuration..."
    terraform apply tfplan
    
    log_success "Infrastructure deployed successfully"
}

# Extract workspace information
extract_workspace_info() {
    log_info "Extracting workspace information..."
    
    cd "$TERRAFORM_DIR"
    
    WORKSPACE_URL=$(terraform output -raw workspace_url)
    WORKSPACE_ID=$(terraform output -raw workspace_id)
    SQL_WAREHOUSE_ID=$(terraform output -raw sql_warehouse_id)
    
    export WORKSPACE_URL
    export WORKSPACE_ID
    export SQL_WAREHOUSE_ID
    
    log_info "Workspace URL: https://$WORKSPACE_URL"
    log_info "Workspace ID: $WORKSPACE_ID"
    log_info "SQL Warehouse ID: $SQL_WAREHOUSE_ID"
    
    log_success "Workspace information extracted"
}

# Wait for workspace to be ready
wait_for_workspace() {
    log_info "Waiting for workspace to be fully ready..."
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if databricks workspace list / --host "https://$WORKSPACE_URL" &> /dev/null; then
            log_success "Workspace is ready"
            return 0
        fi
        
        attempt=$((attempt + 1))
        log_info "Attempt $attempt/$max_attempts - waiting 10 seconds..."
        sleep 10
    done
    
    log_error "Workspace did not become ready in time"
    return 1
}

# Deploy fraud case management app
deploy_fraud_app() {
    log_info "Deploying Fraud Case Management application..."
    
    cd "$FRAUD_APP_DIR"
    
    # Check if app.yaml exists
    if [ ! -f "app.yaml" ]; then
        log_error "app.yaml not found in $FRAUD_APP_DIR"
        return 1
    fi
    
    # Update app.yaml with workspace URL if needed
    log_info "Configuring app for workspace: $WORKSPACE_URL"
    
    # Build frontend
    log_info "Building frontend..."
    cd frontend
    if [ ! -d "node_modules" ]; then
        npm install
    fi
    npm run build
    cd ..
    
    # Deploy app
    log_info "Deploying app to Databricks..."
    databricks apps deploy fraud-case-management \
        --host "https://$WORKSPACE_URL" \
        --source-code-path .
    
    log_success "Fraud app deployed successfully"
}

# Get app URL
get_app_url() {
    log_info "Getting app URL..."
    
    local app_url="https://$WORKSPACE_URL/apps/fraud-case-management"
    
    log_success "App URL: $app_url"
    echo ""
    log_info "📱 Access your app at: $app_url"
    echo ""
}

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              🎉 DEPLOYMENT SUCCESSFUL! 🎉                 ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    log_success "Resources Created:"
    echo "  ✅ AWS Infrastructure (VPC, S3, IAM)"
    echo "  ✅ Databricks Workspace: https://$WORKSPACE_URL"
    echo "  ✅ Unity Catalog with 'afc-mvp.fraud-investigation' schema"
    echo "  ✅ Fraud dashboard tables with sample data"
    echo "  ✅ SQL Warehouse: $SQL_WAREHOUSE_ID"
    echo "  ✅ Fraud Case Management App"
    echo ""
    log_info "📊 Dashboard ID: $DASHBOARD_ID"
    log_info "🔗 Dashboard URL: https://$WORKSPACE_URL/sql/dashboardsv3/$DASHBOARD_ID"
    echo ""
    log_info "🚀 Next Steps:"
    echo "  1. Open the app: https://$WORKSPACE_URL/apps/fraud-case-management"
    echo "  2. Login with your Databricks credentials"
    echo "  3. Workspace admins will be automatically granted admin access"
    echo "  4. View the embedded dashboard in Metrics & Reporting"
    echo ""
    log_info "📝 To destroy everything, run:"
    echo "  cd $TERRAFORM_DIR"
    echo "  ./cleanup-everything.sh"
    echo ""
}

# Main execution
main() {
    print_banner
    
    # Check if running from correct directory
    if [ ! -f "$TERRAFORM_DIR/main.tf" ]; then
        log_error "Must run from databricks-workspace-deployment directory"
        exit 1
    fi
    
    # Execute deployment steps
    check_prerequisites
    deploy_infrastructure
    extract_workspace_info
    wait_for_workspace
    deploy_fraud_app
    get_app_url
    print_summary
}

# Run main function
main "$@"

