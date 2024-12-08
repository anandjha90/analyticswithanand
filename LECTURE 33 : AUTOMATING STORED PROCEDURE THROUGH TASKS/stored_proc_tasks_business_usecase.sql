CREATE OR REPLACE DATABASE STORED_PROC_TASKS_DB;
CREATE OR REPLACE SCHEMA STORED_PROC_TASKS_SCHEMA;

--creating file format
create or replace file format csv_file_format
type='csv'
compression='none'
field_delimiter=','
field_optionally_enclosed_by='\042' -- double quotes ASCII value
skip_header=1;

CREATE TABLE SALES (
    Date DATE,
    Region STRING,
    ProductID INT,
    SalesAmount FLOAT,
    CustomerID INT
);

CREATE OR REPLACE TABLE ARCHIVED_SALES (
    Date DATE,
    Region STRING,
    ProductID INT,
    SalesAmount FLOAT,
    CustomerID INT
);


CREATE TABLE CUSTOMERS (
    CustomerID INT,
    CustomerName STRING,
    Email STRING,
    Phone STRING,
    Region STRING,
    AgeGroup STRING,
    JoinDate DATE,
    IsInactive BOOLEAN DEFAULT FALSE
);


CREATE TABLE INVENTORY (
    ProductID INT,
    StockQuantity INT
);


CREATE OR REPLACE TABLE SHIPMENTS (
    ProductID INT,
    ActualStock INT
);


CREATE OR REPLACE TABLE INVENTORY_DISCREPANCIES (
    ProductID INT,
    StockQuantity INT,
    ActualStock INT,
    ReconciliationDate DATE
);
 
create or replace TABLE FRAUD_TRANSACTIONS (
	TRANS_ID NUMBER(38,0),
	ACCOUNT_ID NUMBER(38,0),
	AMOUNT NUMBER(38,0),
    AVG_AMOUNT NUMBER(38,0),
	FLAGGED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
);

create or replace TABLE STOCK_PREDICTIONS
(
   PRODUCTID NUMBER(38,0),
   STOCKQUANTITY NUMBER(38,0),
   AVG_SALES_AMT NUMBER(38,0),
   EstimatedDepletionDays INT,
   CURR_DATE DATE,
   DepletionDate DATE
);


CREATE OR REPLACE TABLE SHIPMENTS_DELAY (
    ShipmentID INT PRIMARY KEY,
    ExpectedDeliveryDate DATE NOT NULL,
    ActualDeliveryDate DATE NOT NULL,
    DelayDays INT NOT NULL,
    FlaggedAt DATETIME NOT NULL
);

CREATE OR REPLACE TABLE DELAYED_SHIPMENTS (
    ShipmentID INT PRIMARY KEY,
    ExpectedDeliveryDate DATE NOT NULL,
    ActualDeliveryDate DATE NOT NULL,
    DelayDays INT NOT NULL,
    FlaggedAt DATETIME NOT NULL
);

-- Business Scenarios
-- 1. Scenario: Automated Data Archiving
-- Use Case: Archive data older than one year from an active SALES table to an ARCHIVED_SALES table.
-- Solution:
-- Procedure: Automate the archival process.
-- Task: Schedule the archival process to run daily.
-- Procedure for Data Archiving

CREATE OR REPLACE PROCEDURE archive_old_sales()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO ARCHIVED_SALES
    SELECT * 
    FROM SALES 
    WHERE DATE < DATEADD(YEAR, -1, CURRENT_DATE);

    DELETE FROM SALES 
    WHERE DATE < DATEADD(YEAR, -1, CURRENT_DATE);

    RETURN 'Data Archiving Completed Successfully!';
END;
$$;

-- Task for Scheduled Execution
CREATE OR REPLACE TASK archive_task
WAREHOUSE = 'DEMO_WAREHOUSE'
SCHEDULE = 'USING CRON 5 * * * * UTC' -- Runs EVERY 5min at UTC
AS
CALL archive_old_sales();

-- Step 4: Start the Task
ALTER TASK archive_task resume;

-- SHOW TASKS
SHOW TASKS;

-- 2. Scenario: Customer Churn Prediction
-- Use Case: Identify customers who haven't made purchases in the last 6 months and flag them for a marketing campaign.
-- Solution:
-- Procedure: Analyze and flag inactive customers.
-- Task: Trigger the procedure weekly.
-- Procedure for Flagging Inactive Customers

CREATE OR REPLACE PROCEDURE flag_inactive_customers()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    UPDATE CUSTOMERS
    SET IsInactive = TRUE
    WHERE CustomerID NOT IN (
        SELECT DISTINCT CustomerID 
        FROM SALES
        WHERE DATE >= DATEADD(MONTH, -6, CURRENT_DATE)
    );

    RETURN 'Inactive Customers Flagged Successfully!';
END;
$$;

--Task for Scheduled Execution
CREATE OR REPLACE TASK flag_inactive_task
WAREHOUSE = 'COMPUTE_WH'
SCHEDULE = 'USING CRON 0 12 * * 1 UTC' -- Runs every Monday at 12 PM
AS
CALL flag_inactive_customers();

ALTER TASK flag_inactive_task resume;

-- 3. Scenario: Inventory Reconciliation
-- Use Case: Compare the INVENTORY table with actual shipments to identify discrepancies in stock levels.
-- Solution:
-- Procedure: Generate a reconciliation report.
-- Task: Run the reconciliation process at the end of each month.
-- Procedure for Inventory Reconciliation

CREATE OR REPLACE PROCEDURE reconcile_inventory()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO INVENTORY_DISCREPANCIES
    SELECT i.ProductID, i.StockQuantity, s.ActualStock, CURRENT_DATE AS ReconciliationDate
    FROM INVENTORY i
    LEFT JOIN SHIPMENTS s ON i.ProductID = s.ProductID
    WHERE i.StockQuantity != s.ActualStock;

    RETURN 'Inventory Reconciliation Completed Successfully!';
END;
$$;

--Task for Scheduled Execution
CREATE OR REPLACE TASK inventory_reconciliation_task
WAREHOUSE = 'DEMO_WAREHOUSE'
SCHEDULE = 'USING CRON 0 22 * * 1-5 UTC' -- “At 22:00 on every day-of-week from Monday through Friday.”
AS
CALL reconcile_inventory();

ALTER TASK inventory_reconciliation_task resume;

-- 4. Dynamic Partitioned Data Loading
-- Use Case: Load sales data from an external S3 bucket into Snowflake, dynamically partitioning the data based on the Region column.
-- Solution:
-- Procedure: Dynamically create tables for each region and load the respective data.
-- Task: Schedule the process to run daily to handle new data.
-- Stored Procedure

select distinct region from STORED_PROC_TASKS_DB.STORED_PROC_TASKS_SCHEMA.SALES;

CREATE OR REPLACE PROCEDURE load_partitioned_data()
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
var regions = ['North', 'South', 'East', 'West'];
var region;
for (var i = 0; i < regions.length; i++) {
    region = regions[i];
    var query = `CREATE OR REPLACE TABLE SALES_${region} AS
                 SELECT * FROM STORED_PROC_TASKS_DB.STORED_PROC_TASKS_SCHEMA.SALES
                 WHERE Region = '${region}'`;
    snowflake.execute({ sqlText: query });
}

return 'Data partitioned successfully!';
$$;

-- tasks
CREATE OR REPLACE TASK partition_sales_task
WAREHOUSE = 'DEMO_WAREHOUSE'
SCHEDULE = 'USING CRON 0 1 * * * UTC' -- Runs daily at 1 AM
AS
CALL load_partitioned_data();

ALTER TASK partition_sales_task resume;

-- 5. Fraud Detection for Transactions
-- Use Case: Identify potentially fraudulent transactions where the TransactionAmount exceeds a certain threshold compared to the average for the customer.
-- Solution:
-- Procedure: Analyze transactions and flag suspicious records.
-- Task: Schedule the fraud detection to run hourly.
-- Stored Procedure

CREATE OR REPLACE PROCEDURE detect_fraudulent_transactions()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO FRAUD_TRANSACTIONS
    SELECT 
        t.TRANS_ID,
        t.ACCOUNT_ID,
        t.AMOUNT,
        AVG(t.AMOUNT) OVER (PARTITION BY t.ACCOUNT_ID) AS AvgAmount,
        CURRENT_TIMESTAMP AS FlaggedAt
    FROM BANK_DB.BANK_SCHEMA.TRANSACTIONS t
    WHERE t.AMOUNT > 2 * (
        SELECT AVG(AMOUNT)
        FROM BANK_DB.BANK_SCHEMA.TRANSACTIONS
        WHERE ACCOUNT_ID = t.ACCOUNT_ID
    );

    RETURN 'Fraudulent transactions flagged successfully!';
END;
$$;

CREATE OR REPLACE TASK detect_fraud_task
WAREHOUSE = 'DEMO_WAREHOUSE'
SCHEDULE = 'USING CRON 0 * * * * UTC' -- Runs hourly
AS
CALL detect_fraudulent_transactions();

ALTER TASK detect_fraud_task resume;

-- 6. Customer Loyalty Program Management
-- Use Case: Calculate loyalty points for customers based on their monthly spending and update the Customers table.
-- Solution:
-- Procedure: Assign loyalty points.
-- Task: Run the loyalty points calculation at the end of each month.
-- Stored Procedure

ALTER TABLE CUSTOMERS
ADD COLUMN LoyaltyPoints INT DEFAULT 0;

CREATE OR REPLACE PROCEDURE calculate_loyalty_points()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    UPDATE CUSTOMERS c
    SET LoyaltyPoints = LoyaltyPoints + (
        SELECT SUM(SALESAMOUNT) / 100
        FROM SALES s
        WHERE s.CustomerID = c.CustomerID AND s.Date >= DATE_TRUNC('MONTH', CURRENT_DATE)
    );

    RETURN 'Loyalty points updated successfully!';
END;
$$;

-- Task

CREATE OR REPLACE TASK loyalty_points_task
WAREHOUSE = 'DEMO_WAREHOUSE'
SCHEDULE = 'USING CRON 0 0 * * 1 UTC' -- “At 00:00 on Monday.”
AS
CALL calculate_loyalty_points();

ALTER TASK loyalty_points_task resume;


-- 7. Predictive Analytics for Inventory Stock
-- Use Case: Predict stock depletion dates based on current inventory levels and average sales rates for each product.
-- Solution:
-- Procedure: Calculate and store the estimated depletion date.
-- Task: Update stock predictions weekly.
-- Stored Procedure



CREATE OR REPLACE PROCEDURE predict_stock_depletion()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO STOCK_PREDICTIONS
SELECT 
        i.ProductID,
        i.StockQuantity,
        ROUND(AVG(s.SalesAmount),0) AS AVG_SALES_AMT,
        ROUND(i.StockQuantity / AVG(s.SalesAmount), 0) AS EstimatedDepletionDays,
        CURRENT_DATE AS CURR_DATE,
        DATEADD(DAY, ROUND(i.StockQuantity / AVG(s.SalesAmount), 0), CURRENT_DATE) AS DepletionDate
    FROM INVENTORY i
    JOIN SALES s ON i.ProductID = s.ProductID
    WHERE s.Date >= DATEADD(MONTH, -12, CURRENT_DATE)
    GROUP BY i.ProductID, i.StockQuantity;

    RETURN 'Stock depletion predictions updated successfully!';
END;
$$;

--Task

CREATE OR REPLACE TASK stock_prediction_task
WAREHOUSE = 'COMPUTE_WH'
SCHEDULE = 'USING CRON 0 3 * * 0 UTC' -- Runs weekly on Sunday at 3 AM
AS
CALL predict_stock_depletion();

-- 8. Real-Time Shipment Delay Monitoring
-- Use Case: Monitor shipments for delays and notify the operations team if a delay exceeds a threshold.
-- Solution:
-- Procedure: Flag delayed shipments.
-- Task: Run every 15 minutes for near real-time monitoring.
-- Stored Procedure

CREATE OR REPLACE PROCEDURE monitor_shipment_delays()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO DELAYED_SHIPMENTS
    SELECT 
        s.ShipmentID,
        s.ExpectedDeliveryDate,
        s.ActualDeliveryDate,
        DATEDIFF(DAY, s.ExpectedDeliveryDate, s.ActualDeliveryDate) AS DelayDays,
        CURRENT_TIMESTAMP AS FlaggedAt
    FROM SHIPMENTS_DELAY s
    WHERE DATEDIFF(DAY, s.ExpectedDeliveryDate, s.ActualDeliveryDate) > 2;

    RETURN 'Delayed shipments flagged successfully!';
END;
$$;


--Task
CREATE OR REPLACE TASK shipment_delay_task
WAREHOUSE = 'COMPUTE_WH'
SCHEDULE = 'USING CRON */15 * * * * UTC' -- Runs every 15 minutes
AS
CALL monitor_shipment_delays();

ALTER TASK shipment_delay_task resume;

SHOW TASKS;
