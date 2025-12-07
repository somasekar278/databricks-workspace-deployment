-- SQL scripts to create fraud dashboard tables in Unity Catalog
-- Catalog: afc-mvp
-- Schema: fraud-investigation

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS `afc-mvp`.`fraud-investigation`;

-- Use the schema
USE `afc-mvp`.`fraud-investigation`;

-- SIU Cases table for dashboard analytics
CREATE TABLE IF NOT EXISTS siu_cases (
    case_id STRING,
    case_number STRING,
    customer_name STRING,
    alert_score INT,
    fraud_amount DECIMAL(15, 2),
    region STRING,
    case_status STRING,
    priority STRING,
    opened_date TIMESTAMP,
    closed_date TIMESTAMP,
    investigation_duration_hours INT,
    fraud_type STRING,
    investigator_name STRING,
    resolution STRING
) USING DELTA
COMMENT 'SIU fraud cases for dashboard analytics';

-- Transactions table for fraud pattern analysis
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id STRING,
    case_id STRING,
    transaction_date TIMESTAMP,
    transaction_amount DECIMAL(15, 2),
    merchant_name STRING,
    merchant_category STRING,
    location STRING,
    is_fraudulent BOOLEAN,
    fraud_indicator STRING,
    risk_score INT
) USING DELTA
COMMENT 'Transaction data for fraud pattern analysis';

-- Fraud Indicators table for trend analysis
CREATE TABLE IF NOT EXISTS fraud_indicators (
    indicator_id STRING,
    case_id STRING,
    indicator_type STRING,
    indicator_value STRING,
    severity STRING,
    detected_date TIMESTAMP,
    confidence_score DECIMAL(5, 2)
) USING DELTA
COMMENT 'Fraud indicators and signals for analysis';

-- Investigation Activities table
CREATE TABLE IF NOT EXISTS investigation_activities (
    activity_id STRING,
    case_id STRING,
    activity_type STRING,
    activity_date TIMESTAMP,
    investigator_name STRING,
    duration_minutes INT,
    notes STRING
) USING DELTA
COMMENT 'Investigation activities and timeline tracking';

