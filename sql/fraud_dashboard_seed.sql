-- Seed data for fraud dashboard tables
-- Inserts sample data for analytics and visualization

USE `afc-mvp`.`fraud-investigation`;

-- Insert sample SIU cases
INSERT INTO siu_cases VALUES
('C001', '2024-001', 'Sarah Williams', 95, 15000.00, 'Northeast', 'Closed', 'High', 
 TIMESTAMP('2024-01-15 09:00:00'), TIMESTAMP('2024-01-20 16:30:00'), 127, 'Identity Theft', 'John Doe', 'Confirmed Fraud'),
('C002', '2024-002', 'Michael Chen', 88, 22000.00, 'West', 'In Progress', 'High', 
 TIMESTAMP('2024-02-01 10:15:00'), NULL, NULL, 'Card Fraud', 'Jane Smith', NULL),
('C003', '2024-003', 'Emily Johnson', 72, 8500.00, 'South', 'Closed', 'Medium', 
 TIMESTAMP('2024-02-10 14:20:00'), TIMESTAMP('2024-02-15 11:45:00'), 117, 'Account Takeover', 'Mike Wilson', 'False Positive'),
('C004', '2024-004', 'David Martinez', 91, 31000.00, 'Midwest', 'In Progress', 'Critical', 
 TIMESTAMP('2024-03-05 08:30:00'), NULL, NULL, 'Wire Fraud', 'John Doe', NULL),
('C005', '2024-005', 'Lisa Anderson', 65, 5200.00, 'Northeast', 'Closed', 'Low', 
 TIMESTAMP('2024-03-12 13:10:00'), TIMESTAMP('2024-03-14 10:20:00'), 45, 'Card Fraud', 'Jane Smith', 'Confirmed Fraud'),
('C006', '2024-006', 'Robert Taylor', 83, 18900.00, 'West', 'New', 'High', 
 TIMESTAMP('2024-03-20 11:40:00'), NULL, NULL, 'Identity Theft', 'Mike Wilson', NULL),
('C007', '2024-007', 'Jennifer Brown', 77, 12300.00, 'South', 'In Progress', 'Medium', 
 TIMESTAMP('2024-03-25 15:55:00'), NULL, NULL, 'Account Takeover', 'John Doe', NULL),
('C008', '2024-008', 'William Davis', 94, 27500.00, 'Midwest', 'Closed', 'Critical', 
 TIMESTAMP('2024-04-01 09:25:00'), TIMESTAMP('2024-04-08 14:15:00'), 172, 'Wire Fraud', 'Jane Smith', 'Confirmed Fraud'),
('C009', '2024-009', 'Amanda Wilson', 68, 9800.00, 'Northeast', 'New', 'Medium', 
 TIMESTAMP('2024-04-10 12:30:00'), NULL, NULL, 'Card Fraud', 'Mike Wilson', NULL),
('C010', '2024-010', 'Christopher Lee', 89, 24700.00, 'West', 'In Progress', 'High', 
 TIMESTAMP('2024-04-15 10:45:00'), NULL, NULL, 'Identity Theft', 'John Doe', NULL);

-- Insert sample transactions
INSERT INTO transactions VALUES
('T001', 'C001', TIMESTAMP('2024-01-14 22:15:00'), 5000.00, 'Electronics Store A', 'Electronics', 'New York, NY', TRUE, 'Unusual Location', 85),
('T002', 'C001', TIMESTAMP('2024-01-14 22:45:00'), 7000.00, 'Jewelry Store B', 'Retail', 'New York, NY', TRUE, 'Large Amount', 90),
('T003', 'C001', TIMESTAMP('2024-01-14 23:10:00'), 3000.00, 'Online Retailer C', 'E-commerce', 'New York, NY', TRUE, 'Multiple Same Day', 88),
('T004', 'C002', TIMESTAMP('2024-01-31 18:30:00'), 15000.00, 'Luxury Store D', 'Luxury Goods', 'Los Angeles, CA', TRUE, 'High Value', 92),
('T005', 'C002', TIMESTAMP('2024-01-31 19:00:00'), 7000.00, 'Electronics Store E', 'Electronics', 'Los Angeles, CA', TRUE, 'Multiple Same Day', 89),
('T006', 'C003', TIMESTAMP('2024-02-09 14:20:00'), 8500.00, 'Department Store F', 'Retail', 'Miami, FL', FALSE, 'Customer Confirmed', 45),
('T007', 'C004', TIMESTAMP('2024-03-04 16:45:00'), 31000.00, 'Wire Transfer', 'Financial', 'Chicago, IL', TRUE, 'Suspicious Wire', 95),
('T008', 'C005', TIMESTAMP('2024-03-11 20:15:00'), 5200.00, 'Gas Station G', 'Fuel', 'Boston, MA', TRUE, 'Card Present Fraud', 78),
('T009', 'C006', TIMESTAMP('2024-03-19 23:30:00'), 18900.00, 'Online Marketplace', 'E-commerce', 'San Francisco, CA', TRUE, 'Account Takeover', 87),
('T010', 'C007', TIMESTAMP('2024-03-24 17:00:00'), 12300.00, 'Electronics Chain', 'Electronics', 'Atlanta, GA', TRUE, 'Unusual Pattern', 82);

-- Insert sample fraud indicators
INSERT INTO fraud_indicators VALUES
('FI001', 'C001', 'Location Mismatch', 'Purchase from different state than usual', 'High', TIMESTAMP('2024-01-14 22:15:00'), 0.85),
('FI002', 'C001', 'Velocity Check', 'Multiple high-value transactions within 1 hour', 'Critical', TIMESTAMP('2024-01-14 23:10:00'), 0.92),
('FI003', 'C002', 'Amount Threshold', 'Single transaction exceeds $10,000', 'High', TIMESTAMP('2024-01-31 18:30:00'), 0.88),
('FI004', 'C003', 'Device Change', 'Login from new device', 'Medium', TIMESTAMP('2024-02-09 14:00:00'), 0.65),
('FI005', 'C004', 'Wire Transfer', 'International wire to high-risk country', 'Critical', TIMESTAMP('2024-03-04 16:45:00'), 0.95),
('FI006', 'C005', 'Time Pattern', 'Transaction outside normal hours', 'Medium', TIMESTAMP('2024-03-11 20:15:00'), 0.72),
('FI007', 'C006', 'Behavioral Change', 'Sudden change in spending pattern', 'High', TIMESTAMP('2024-03-19 23:30:00'), 0.83),
('FI008', 'C007', 'Merchant Category', 'Multiple purchases from unusual merchant type', 'Medium', TIMESTAMP('2024-03-24 17:00:00'), 0.75),
('FI009', 'C008', 'Cross-Border', 'Transaction from foreign country', 'High', TIMESTAMP('2024-04-01 09:00:00'), 0.89),
('FI010', 'C009', 'Velocity Check', 'Multiple declined transactions followed by success', 'Medium', TIMESTAMP('2024-04-10 12:00:00'), 0.68);

-- Insert sample investigation activities
INSERT INTO investigation_activities VALUES
('ACT001', 'C001', 'Initial Review', TIMESTAMP('2024-01-15 09:30:00'), 'John Doe', 45, 'Reviewed transaction history and alerts'),
('ACT002', 'C001', 'Customer Contact', TIMESTAMP('2024-01-16 10:00:00'), 'John Doe', 30, 'Contacted customer - confirmed unauthorized transactions'),
('ACT003', 'C001', 'Merchant Verification', TIMESTAMP('2024-01-17 14:00:00'), 'John Doe', 60, 'Verified with merchants - purchases made with stolen card info'),
('ACT004', 'C001', 'Case Closure', TIMESTAMP('2024-01-20 16:30:00'), 'John Doe', 30, 'Confirmed fraud, customer reimbursed, case closed'),
('ACT005', 'C002', 'Initial Review', TIMESTAMP('2024-02-01 11:00:00'), 'Jane Smith', 50, 'Flagged high-value transactions for investigation'),
('ACT006', 'C003', 'Initial Review', TIMESTAMP('2024-02-10 15:00:00'), 'Mike Wilson', 40, 'Reviewed device change and location'),
('ACT007', 'C003', 'Customer Contact', TIMESTAMP('2024-02-12 09:00:00'), 'Mike Wilson', 25, 'Customer confirmed legitimate purchase - false positive'),
('ACT008', 'C003', 'Case Closure', TIMESTAMP('2024-02-15 11:45:00'), 'Mike Wilson', 20, 'Closed as false positive'),
('ACT009', 'C008', 'Initial Review', TIMESTAMP('2024-04-01 10:00:00'), 'Jane Smith', 55, 'Wire transfer flagged as suspicious'),
('ACT010', 'C008', 'Investigation Complete', TIMESTAMP('2024-04-08 14:15:00'), 'Jane Smith', 90, 'Confirmed fraudulent wire transfer, funds recovered');

