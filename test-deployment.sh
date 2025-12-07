#!/bin/bash
# 🧪 Test Deployment - Verify everything is working
#
# Usage: ./test-deployment.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🧪 Testing Databricks Fraud Management Platform            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

PASS=0
FAIL=0

# Helper function
check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}❌ FAIL${NC}"
        FAIL=$((FAIL + 1))
    fi
}

# Test 1: Terraform State
echo -e "${YELLOW}Test 1: Terraform State${NC}"
terraform show > /dev/null 2>&1
check

# Test 2: Workspace Exists
echo -e "${YELLOW}Test 2: Databricks Workspace${NC}"
WORKSPACE_URL=$(terraform output -raw workspace_url 2>/dev/null)
if [ -n "$WORKSPACE_URL" ]; then
    echo "   URL: $WORKSPACE_URL"
    check
else
    false
    check
fi

# Test 3: Unity Catalog Metastore
echo -e "${YELLOW}Test 3: Unity Catalog Metastore${NC}"
UC_METASTORE=$(terraform output -raw uc_metastore_name 2>/dev/null)
if [ -n "$UC_METASTORE" ]; then
    echo "   Metastore: $UC_METASTORE"
    check
else
    false
    check
fi

# Test 4: Lakebase Instance
echo -e "${YELLOW}Test 4: Lakebase Database Instance${NC}"
LAKEBASE_DNS=$(terraform output -json lakebase_database_instances 2>/dev/null | jq -r '."afc-lakebase-instance".read_write_dns' 2>/dev/null)
if [ -n "$LAKEBASE_DNS" ] && [ "$LAKEBASE_DNS" != "null" ]; then
    echo "   Host: $LAKEBASE_DNS"
    check
else
    false
    check
fi

# Test 5: Database Connection
echo -e "${YELLOW}Test 5: Database Connection${NC}"
if [ -n "$LAKEBASE_DNS" ]; then
    PGSSLMODE=require PGPASSWORD="FraudAdmin2024!" psql \
        -h "$LAKEBASE_DNS" \
        -p 5432 \
        -U admin \
        -d fraud_detection_db \
        -c "SELECT 1" > /dev/null 2>&1
    check
else
    echo "   Skipping (no database host)"
    false
    check
fi

# Test 6: Database Tables
echo -e "${YELLOW}Test 6: Database Schema${NC}"
if [ -n "$LAKEBASE_DNS" ]; then
    TABLE_COUNT=$(PGSSLMODE=require PGPASSWORD="FraudAdmin2024!" psql \
        -h "$LAKEBASE_DNS" \
        -p 5432 \
        -U admin \
        -d fraud_detection_db \
        -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='fraud_management'" 2>/dev/null | tr -d ' ')
    if [ "$TABLE_COUNT" -ge 6 ]; then
        echo "   Tables: $TABLE_COUNT/6"
        check
    else
        echo "   Tables: $TABLE_COUNT/6 (expected 6)"
        false
        check
    fi
else
    echo "   Skipping (no database host)"
    false
    check
fi

# Test 7: Sample Data
echo -e "${YELLOW}Test 7: Sample Data Loaded${NC}"
if [ -n "$LAKEBASE_DNS" ]; then
    CASE_COUNT=$(PGSSLMODE=require PGPASSWORD="FraudAdmin2024!" psql \
        -h "$LAKEBASE_DNS" \
        -p 5432 \
        -U admin \
        -d fraud_detection_db \
        -t -c "SELECT COUNT(*) FROM fraud_management.siu_cases" 2>/dev/null | tr -d ' ')
    if [ "$CASE_COUNT" -ge 1 ]; then
        echo "   Cases: $CASE_COUNT"
        check
    else
        echo "   Cases: $CASE_COUNT (expected > 0)"
        false
        check
    fi
else
    echo "   Skipping (no database host)"
    false
    check
fi

# Test 8: Databricks CLI Configured
echo -e "${YELLOW}Test 8: Databricks CLI${NC}"
if [ -f ~/.databrickscfg ]; then
    databricks current-user me > /dev/null 2>&1
    check
else
    echo "   CLI not configured"
    false
    check
fi

# Test 9: Application Deployed
echo -e "${YELLOW}Test 9: Application Status${NC}"
APP_STATUS=$(databricks apps get som-fraud-case-management --output json 2>/dev/null | jq -r '.app_status.state' 2>/dev/null)
if [ "$APP_STATUS" = "RUNNING" ]; then
    echo "   Status: $APP_STATUS"
    check
else
    echo "   Status: $APP_STATUS (expected RUNNING)"
    false
    check
fi

# Test 10: Application URL
echo -e "${YELLOW}Test 10: Application URL${NC}"
APP_URL=$(databricks apps get som-fraud-case-management --output json 2>/dev/null | jq -r '.url' 2>/dev/null)
if [ -n "$APP_URL" ] && [ "$APP_URL" != "null" ]; then
    echo "   URL: $APP_URL"
    check
else
    false
    check
fi

# Test 11: Unity Catalog Objects
echo -e "${YELLOW}Test 11: Unity Catalog Objects${NC}"
UC_CATALOGS=$(terraform output -json uc_catalogs 2>/dev/null | jq 'length' 2>/dev/null)
if [ "$UC_CATALOGS" -ge 1 ]; then
    echo "   Catalogs: $UC_CATALOGS"
    check
else
    false
    check
fi

# Test 12: Users Created
echo -e "${YELLOW}Test 12: Users and Groups${NC}"
USERS=$(terraform output -json users 2>/dev/null | jq 'length' 2>/dev/null)
if [ "$USERS" -ge 1 ]; then
    echo "   Users: $USERS"
    check
else
    false
    check
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Test Results:${NC}"
echo -e "  ✅ Passed: $PASS"
echo -e "  ❌ Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Deployment is healthy! 🎉${NC}"
    echo ""
    echo -e "${BLUE}🌐 Access your application:${NC}"
    echo -e "${YELLOW}   $APP_URL${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Please check the output above.${NC}"
    exit 1
fi

