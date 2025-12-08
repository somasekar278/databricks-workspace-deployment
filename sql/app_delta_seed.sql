-- Sample Data for Delta Tables - Fraud Case Management
-- Unified data for both application and dashboards

USE `afc-mvp`.`fraud-investigation`;

-- Insert sample claims
INSERT INTO claims (claim_id, policy_number, claim_amount, claim_date, claim_type, status, created_at) VALUES
('CLM-2024-001', 'POL-123456', 15000.00, TIMESTAMP('2024-01-15 09:00:00'), 'Auto', 'Under Investigation', CURRENT_TIMESTAMP()),
('CLM-2024-002', 'POL-789012', 22000.00, TIMESTAMP('2024-02-01 10:15:00'), 'Property', 'Approved', CURRENT_TIMESTAMP()),
('CLM-2024-003', 'POL-345678', 8500.00, TIMESTAMP('2024-02-10 14:30:00'), 'Auto', 'Under Review', CURRENT_TIMESTAMP());

-- Insert sample SIU cases (without auto-generated case_id)
INSERT INTO siu_cases (claim_id, customer_name, fraud_score, loss_amount, region, status, priority, reported_date, closed_date, investigator_id, fraud_type, investigator_name, resolution, created_at, updated_at) VALUES
('CLM-2024-001', 'Sarah Williams', 95, 15000.00, 'Northeast', 'Closed', 'High', TIMESTAMP('2024-01-15 09:00:00'), TIMESTAMP('2024-01-20 16:30:00'), 127, 'Identity Theft', 'John Doe', 'Confirmed Fraud', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
('CLM-2024-002', 'Michael Chen', 88, 22000.00, 'West', 'In Progress', 'High', TIMESTAMP('2024-02-01 10:15:00'), NULL, NULL, 'Card Fraud', 'Jane Smith', NULL, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
('CLM-2024-003', 'Jessica Martinez', 76, 8500.00, 'Southeast', 'Open', 'Medium', TIMESTAMP('2024-02-10 14:30:00'), NULL, NULL, 'False Claims', NULL, NULL, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

-- Insert sample transactions (referencing case_id)
INSERT INTO transactions (case_id, transaction_date, amount, merchant, transaction_type, risk_score, created_at) VALUES
(1, TIMESTAMP('2024-01-14 18:30:00'), 5000.00, 'Electronics Store A', 'Purchase', 85, CURRENT_TIMESTAMP()),
(1, TIMESTAMP('2024-01-14 19:45:00'), 10000.00, 'Jewelry Store B', 'Purchase', 95, CURRENT_TIMESTAMP()),
(2, TIMESTAMP('2024-01-31 22:00:00'), 15000.00, 'Online Retailer', 'Online', 90, CURRENT_TIMESTAMP()),
(2, TIMESTAMP('2024-02-01 01:30:00'), 7000.00, 'Foreign Merchant', 'International', 88, CURRENT_TIMESTAMP());

-- Insert sample alerts
INSERT INTO alerts (case_id, alert_type, severity, description, status, created_at) VALUES
(1, 'Multiple High-Value Transactions', 'High', 'Two large purchases within short timeframe', 'Resolved', CURRENT_TIMESTAMP()),
(2, 'Unusual Location', 'High', 'Transaction from high-risk country', 'In Review', CURRENT_TIMESTAMP()),
(3, 'Duplicate Claim', 'Medium', 'Similar claim filed 6 months ago', 'New', CURRENT_TIMESTAMP());

-- Insert sample investigation activities
INSERT INTO investigation_activities (case_id, activity_type, activity_date, investigator, notes, created_at) VALUES
(1, 'Initial Review', CURRENT_TIMESTAMP(), 'John Doe', 'Reviewed transaction history - suspicious pattern identified', CURRENT_TIMESTAMP()),
(1, 'Customer Contact', CURRENT_TIMESTAMP(), 'John Doe', 'Customer denied making transactions - identity theft confirmed', CURRENT_TIMESTAMP()),
(2, 'Document Review', CURRENT_TIMESTAMP(), 'Jane Smith', 'Reviewing supporting documentation', CURRENT_TIMESTAMP()),
(2, 'Background Check', CURRENT_TIMESTAMP(), 'Jane Smith', 'Running background check on claimant', CURRENT_TIMESTAMP());

-- Insert sample fraud indicators
INSERT INTO fraud_indicators (case_id, indicator_type, description, severity, created_at) VALUES
(1, 'Rapid Succession', 'Multiple high-value transactions within 2 hours', 'High', CURRENT_TIMESTAMP()),
(1, 'Unusual Pattern', 'Transactions inconsistent with customer history', 'High', CURRENT_TIMESTAMP()),
(2, 'Geographic Anomaly', 'Transaction location 2000 miles from residence', 'Medium', CURRENT_TIMESTAMP()),
(3, 'Documentation Issues', 'Missing or incomplete supporting documents', 'Low', CURRENT_TIMESTAMP());

