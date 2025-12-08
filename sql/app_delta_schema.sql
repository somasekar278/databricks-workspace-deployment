-- Unity Catalog Delta Tables for Fraud Case Management
-- Unified tables used by BOTH the application (CRUD) and dashboards (analytics)

USE CATALOG `afc-mvp`;
USE SCHEMA `fraud-investigation`;

-- SIU Cases Table (Delta)
CREATE TABLE IF NOT EXISTS siu_cases (
    case_id BIGINT GENERATED ALWAYS AS IDENTITY,
    claim_id STRING NOT NULL,
    customer_name STRING,
    fraud_score INT,
    loss_amount DECIMAL(15, 2),
    region STRING,
    status STRING DEFAULT 'Open',
    priority STRING,
    reported_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    closed_date TIMESTAMP,
    investigator_id INT,
    fraud_type STRING,
    investigator_name STRING,
    resolution STRING,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) USING DELTA
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported')
COMMENT 'SIU case management - operational table for fraud investigations';

-- Transactions Table (Delta)
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id BIGINT GENERATED ALWAYS AS IDENTITY,
    case_id BIGINT,
    transaction_date TIMESTAMP,
    amount DECIMAL(15, 2),
    merchant STRING,
    transaction_type STRING,
    risk_score INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) USING DELTA
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported')
COMMENT 'Transaction records associated with fraud cases';

-- Alerts Table (Delta)
CREATE TABLE IF NOT EXISTS alerts (
    alert_id BIGINT GENERATED ALWAYS AS IDENTITY,
    case_id BIGINT,
    alert_type STRING,
    severity STRING,
    description STRING,
    status STRING DEFAULT 'New',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    acknowledged_at TIMESTAMP,
    acknowledged_by STRING
) USING DELTA
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported')
COMMENT 'Fraud alerts and notifications';

-- Claims Table (Delta)
CREATE TABLE IF NOT EXISTS claims (
    claim_id STRING,
    policy_number STRING,
    claim_amount DECIMAL(15, 2),
    claim_date TIMESTAMP,
    claim_type STRING,
    status STRING,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) USING DELTA
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported')
COMMENT 'Insurance claims records';

-- Investigation Activities Table (Delta)
CREATE TABLE IF NOT EXISTS investigation_activities (
    activity_id BIGINT GENERATED ALWAYS AS IDENTITY,
    case_id BIGINT,
    activity_type STRING,
    activity_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    investigator STRING,
    notes STRING,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) USING DELTA
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported')
COMMENT 'Investigation activity log and audit trail';

-- Fraud Indicators Table (Delta)
CREATE TABLE IF NOT EXISTS fraud_indicators (
    indicator_id BIGINT GENERATED ALWAYS AS IDENTITY,
    case_id BIGINT,
    indicator_type STRING,
    description STRING,
    severity STRING,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) USING DELTA
TBLPROPERTIES('delta.feature.allowColumnDefaults' = 'supported')
COMMENT 'Fraud risk indicators and patterns';

