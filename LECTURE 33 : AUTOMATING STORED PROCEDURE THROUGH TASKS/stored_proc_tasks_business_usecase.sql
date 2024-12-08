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


CREATE TABLE SHIPMENTS (
    ProductID INT,
    ActualStock INT
);


CREATE OR REPLACE TABLE INVENTORY_DISCREPANCIES (
    ProductID INT,
    StockQuantity INT,
    ActualStock INT,
    ReconciliationDate DATE
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
