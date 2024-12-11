CREATE OR REPLACE WAREHOUSE DEMO_WAREHOUSE;
CREATE OR REPLACE DATABASE DEMO_DATABASE;
CREATE OR REPLACE SCHEMA DEMO_SCHEMA;

--creating tsv ff
create or replace file format clustering_csv
type='csv'
compression='none'
field_delimiter=','
field_optionally_enclosed_by='\042' -- double quotes ASCII value
skip_header=1;

-- CREATING SALES TABLE
CREATE OR REPLACE TABLE SALES (
    Date DATE,
    Region STRING,
    ProductID INT,
    SalesAmount FLOAT,
    CustomerID INT
);

-- CREATING INVENTORY TABLE
CREATE OR REPLACE TABLE INVENTORY (
    Date DATE,
    ProductID INT,
    StockQuantity INT
);

-- -- CREATING PRODUCTS TABLE
CREATE OR REPLACE TABLE PRODUCTS (
    ProductID INT,
    ProductName STRING,
    Category STRING,
    Price FLOAT
);

-- CREATING SHIPMENTS TABLE
CREATE OR REPLACE TABLE SHIPMENTS (
    ShipmentID STRING,
    OrderID INT,
    ShipDate DATE,
    OriginRegion STRING,
    DestinationRegion STRING,
    Carrier STRING,
    ShipmentWeight FLOAT,
    Status STRING
);

--CREATING CUSTOMERS TABLE
CREATE OR REPLACE TABLE CUSTOMERS (
    CustomerID INT PRIMARY KEY,
    Name VARCHAR(255),
    Region VARCHAR(50),
    AgeGroup VARCHAR(20)
);


-- CREATING TRANSACTIONS TABLE
CREATE OR REPLACE TABLE TRANSACTIONS (
    TransactionID STRING,
    CustomerID STRING,
    TransactionDate DATE,
    TransactionAmount FLOAT,
    PaymentMethod STRING,
    TransactionStatus STRING
);

-- CREATING CLUSTERING_METRICS_LOG TABLE
CREATE TABLE CLUSTERING_METRICS_LOG (
    TableName STRING,
    ClusteringKeys STRING,
    AvgDepth FLOAT,
    TotalPartitions INT,
    Overlaps INT,
    LogTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- CREATING ALERTS_LOG TABLE
CREATE TABLE ALERTS_LOG (
    AlertID INT AUTOINCREMENT,
    AlertType STRING,
    AlertDetails STRING,
    AlertTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Processed BOOLEAN DEFAULT FALSE
);

-- 1. Multi-Fact Table Scenario
-- Scenario: Reporting involves filtering Sales and Inventory tables by Date, Region, and ProductID.
-- Clustering Definition:

ALTER TABLE SALES CLUSTER BY (Date, Region, ProductID);
ALTER TABLE INVENTORY CLUSTER BY (Date,ProductID);

-- SQL Query
SELECT 
    s.Region,
    p.ProductName,
    SUM(s.SalesAmount) AS TotalSales,
    SUM(i.StockQuantity) AS AvailableStock
FROM 
    Sales s
JOIN 
    Inventory i ON s.ProductID = i.ProductID AND s.Date = i.Date
JOIN 
    Products p ON s.ProductID = p.ProductID
WHERE 
    s.Date BETWEEN '2024-01-01' AND '2024-01-31'
    AND s.Region = 'North'
GROUP BY 
    s.Region, p.ProductName
ORDER BY 
    TotalSales DESC;

-- 2. Historical Data with Temporal Queries
-- Scenario: Analysts frequently filter Transactions by TransactionDate and CustomerID.
-- Clustering Definition:
ALTER TABLE TRANSACTIONS CLUSTER BY (TransactionDate, CustomerID);

-- SQL QUERY
SELECT 
    CustomerID,
    COUNT(*) AS TotalTransactions,
    SUM(TransactionAmount) AS TotalAmount
FROM 
    Transactions
WHERE 
    TransactionDate BETWEEN '2024-01-01' AND '2024-03-31'
    AND CustomerID IN ('CUST123', 'CUST456')
GROUP BY 
    CustomerID
ORDER BY 
    TotalAmount DESC;

-- 3. Geo-Spatial Analysis
-- Scenario: Shipments are analyzed by DestinationRegion and ShipDate.
-- Clustering Definition:
ALTER TABLE SHIPMENTS CLUSTER BY (DestinationRegion, ShipDate);

-- SQL Query
SELECT 
    DestinationRegion,
    COUNT(*) AS TotalShipments,
    MIN(ShipDate) AS FirstShipmentDate,
    MAX(ShipDate) AS LastShipmentDate
FROM 
    Shipments
WHERE 
    DestinationRegion = 'East Coast'
    AND ShipDate BETWEEN '2024-06-01' AND '2024-06-30'
GROUP BY 
    DestinationRegion
ORDER BY 
    TotalShipments DESC;

-- 4. Large-Scale Dimension Table
-- Scenario: The Customers table is frequently joined with fact tables, and filters are applied to Region and AgeGroup.
-- Clustering Definition:
ALTER TABLE CUSTOMERS CLUSTER BY (Region, AgeGroup);

-- SQL QUERY
SELECT 
    c.Region,
    c.AgeGroup,
    SUM(s.SalesAmount) AS TotalSales
FROM 
    Customers c
JOIN 
    Sales s ON c.CustomerID = s.CustomerID
WHERE 
    c.Region = 'West'
    AND c.AgeGroup = '25-34'
    AND s.Date BETWEEN '2024-07-01' AND '2024-07-31'
GROUP BY 
    c.Region, c.AgeGroup
ORDER BY 
    TotalSales DESC;

-- 5. Clustering Analysis and Optimization
-- Analyze Clustering Information:
-- To check the clustering depth and quality:

SELECT SYSTEM$CLUSTERING_INFORMATION('DEMO_DATABASE.DEMO_SCHEMA.SALES', '(Date, Region, ProductID)');

-- Reclustering a Table:
-- If clustering depth is high, trigger reclustering manually:
ALTER TABLE SALES RECLUSTER;

-- To analyze query performance using the Query Profile in Snowflake, follow these steps:
--Step 1: Run a Query
-- Execute a sample query on a table with clustering keys to observe the performance impact.

SELECT 
    Region,
    ProductID,
    SUM(SalesAmount) AS TotalSales
FROM 
    Sales
WHERE 
    Date BETWEEN '2024-01-01' AND '2024-01-31'
    AND Region = 'North'
GROUP BY 
    Region, ProductID
ORDER BY 
    TotalSales DESC;

-- Step 2: Access the Query Profile
-- Open the Snowflake Web UI.
-- Navigate to History (left-hand menu).
-- Locate the query you executed. Use filters if necessary to find it quickly.
-- Click on the query’s ID to open the Query Details page.

-- Step 4: Analyze Clustering Quality
-- To dive deeper, check the clustering information using:
SELECT SYSTEM$CLUSTERING_INFORMATION('DEMO_DATABASE.DEMO_SCHEMA.SALES', '(Date, Region, ProductID)');


-- 1. Monitoring Clustering Metrics
-- Scheduled Clustering Depth Monitoring
-- You can create a task in Snowflake to regularly check clustering metrics and log results for analysis.

-- Step 1: Create a Table to Store Clustering Metrics
CREATE OR REPLACE TABLE CLUSTERING_METRICS_LOG (
    LogTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    TableName STRING,
    ClusteringKeys STRING,
    ClusterMethod STRING,
    AverageDepth FLOAT,
    AverageOverlaps INT,
    TotalPartitions INT
);

-- Step 2: Create a Stored Procedure to Log Clustering Metrics
CREATE OR REPLACE PROCEDURE LOG_CLUSTERING_METRICS()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO CLUSTERING_METRICS_LOG
    SELECT  
        CURRENT_TIMESTAMP AS LogTimestamp,
        'DEMO_DATABASE.DEMO_SCHEMA.SALES' AS TableName,
        'Date, Region, ProductID' AS ClusteringKeys,
         ClusterMethod,
         AverageDepth,
         AverageOverlaps,
         TotalPartitionCount
    FROM
    (
    WITH ClusteringMetrics AS (
    SELECT 
        PARSE_JSON(SELECT SYSTEM$CLUSTERING_INFORMATION('DEMO_DATABASE.DEMO_SCHEMA.SALES', '(Date, Region, ProductID)')) AS Metrics
                              )
    SELECT 
        Metrics:cluster_by_keys::STRING AS ClusterMethod,
        Metrics:average_depth::FLOAT AS AverageDepth,
        Metrics:average_overlaps::FLOAT AS AverageOverlaps,
        Metrics:total_partition_count::INT AS TotalPartitionCount
    FROM ClusteringMetrics);
    RETURN 'Clustering Metrics Logged Successfully';
END;
$$;

-- Step 3: Schedule a Task
CREATE OR REPLACE TASK MONITOR_CLUSTERING
WAREHOUSE = COMPUTE_WH
SCHEDULE = 'USING CRON 5 * * * * UTC'  -- Every 5 minutes. UTC time zone.
AS
CALL LOG_CLUSTERING_METRICS();

-- Step 4: Start the Task
ALTER TASK MONITOR_CLUSTERING resume;

-- SHOW TASKS
SHOW TASKS;


SELECT SYSTEM$CLUSTERING_INFORMATION('DEMO_DATABASE.DEMO_SCHEMA.SALES', '(Date, Region, ProductID)');
SELECT SYSTEM$CLUSTERING_DEPTH('DEMO_DATABASE.DEMO_SCHEMA.SALES');

-- code checking
SELECT  
        CURRENT_TIMESTAMP AS LogTimestamp,
        'DEMO_DATABASE.DEMO_SCHEMA.SALES' AS TableName,
        'Date, Region, ProductID' AS ClusteringKeys,
        ClusterMethod,
        AverageDepth,
        AverageOverlaps,
        TotalPartitionCount
    FROM
    (
WITH ClusteringMetrics AS (
    SELECT 
        PARSE_JSON(SELECT SYSTEM$CLUSTERING_INFORMATION('DEMO_DATABASE.DEMO_SCHEMA.SALES', '(Date, Region, ProductID)')) AS Metrics
)
SELECT 
    Metrics:cluster_by_keys::STRING AS ClusterMethod,
    Metrics:average_depth::FLOAT AS AverageDepth,
    Metrics:average_overlaps::FLOAT AS AverageOverlaps,
    Metrics:total_partition_count::INT AS TotalPartitionCount
FROM ClusteringMetrics
);

/*
To analyze query performance in Snowflake, you can use Account Usage and Information Schema views. 
Snowflake provides detailed metadata about query history, resource usage, and storage, 
enabling you to identify and optimize slow queries, understand clustering efficiency, and monitor resource consumption.
*/

--1. Query Execution Metrics
-- Create a view to retrieve detailed information about query execution time, scanned rows, and returned rows.

/*
Key Columns : 

total_elapsed_time: Total execution time in milliseconds.
rows_produced: Number of rows produced during query execution.
bytes_scanned: Amount of data scanned, in bytes.

*/

CREATE OR REPLACE VIEW query_performance_metrics AS
SELECT 
    query_id,
    user_name,
    database_name,
    schema_name,
    query_text,
    execution_status,
    start_time,
    end_time,
    total_elapsed_time / 1000 AS elapsed_time_seconds,
    rows_produced,
    ROWS_INSERTED,
    ROWS_UPDATED,
    ROWS_DELETED,
    PARTITIONS_SCANNED,
    PARTITIONS_TOTAL,
    ROUND(BYTES_SCANNED / 1024 / 1024,5) AS bytes_scanned_mb,
    ROUND(BYTES_WRITTEN / 1024 / 1024.5) AS bytes_written_mb
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD(DAY, -7, CURRENT_DATE) -- Last 7 days
AND execution_status = 'SUCCESS'
AND SCHEMA_NAME = 'DEMO_SCHEMA'
ORDER BY total_elapsed_time DESC;

select * from query_performance_metrics;

-- 2. Long-Running Queries
-- Identify queries with the highest execution times.

CREATE OR REPLACE VIEW long_running_queries AS
SELECT 
    query_id,
    user_name,
    warehouse_name,
    ROUND(total_elapsed_time / 1000,0) AS elapsed_time_seconds,
    query_text
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD(DAY, -30, CURRENT_DATE)
AND total_elapsed_time > 60000 -- Queries running longer than 60 seconds
ORDER BY total_elapsed_time DESC;

SELECT * FROM long_running_queries;

-- 3. Resource Usage by Query
-- Analyze the compute cost of queries to identify resource-intensive ones.

/*
AUTOMATIC_CLUSTERING_HISTORY(
      [ DATE_RANGE_START => <constant_expr> ]
      [ , DATE_RANGE_END => <constant_expr> ]
      [ , TABLE_NAME => '<string>' ] )
*/      

-- Reference Link : https://docs.snowflake.com/en/sql-reference/functions/automatic_clustering_history

CREATE OR REPLACE VIEW resource_usage AS
SELECT 
    START_TIME,
    END_TIME,
    DATEDIFF('second', START_TIME, END_TIME) AS total_seconds,
    FLOOR(DATEDIFF('second', START_TIME, END_TIME) / 3600) AS hours,
    FLOOR((DATEDIFF('second', START_TIME, END_TIME) % 3600) / 60) AS minutes,
    DATEDIFF('second', START_TIME, END_TIME) % 60 AS seconds,
    credits_used,
    credits_used * 3.3  AS Tot_Amt_USD,
    ROUND(NUM_BYTES_RECLUSTERED / 1024 / 1024,2) AS bytes_reclustered_mb,
    NUM_ROWS_RECLUSTERED,
    TABLE_NAME
FROM TABLE(information_schema.automatic_clustering_history(date_range_start=>dateadd(D, -7, current_date),date_range_end=>current_date)) -- Last 1 week
ORDER BY credits_used DESC;


SELECT 
    START_TIME,
    END_TIME,
    DATEDIFF('second', START_TIME, END_TIME) AS total_seconds,
    FLOOR(DATEDIFF('second', START_TIME, END_TIME) / 3600) AS hours,
    FLOOR((DATEDIFF('second', START_TIME, END_TIME) % 3600) / 60) AS minutes,
    DATEDIFF('second', START_TIME, END_TIME) % 60 AS seconds
FROM (
    SELECT 
        TO_TIMESTAMP('2024-12-10 06:00:00.000 -0800') AS START_TIME,
        TO_TIMESTAMP('2024-12-11 07:00:00.000 -0800') AS END_TIME
) data;

    
-- Actions to Improve Clustering

--1. Adjust Clustering Keys
-- Re-evaluate and update clustering keys if they don’t align with frequent query filters.
ALTER TABLE YOUR_TABLE_NAME CLUSTER BY (new_column1, new_column2);

-- 2. Recluster the Table
-- Manually recluster the table if the depth value is high.
ALTER TABLE YOUR_TABLE_NAME RECLUSTER;

-- 3. Enable Auto Clustering
-- If the table experiences frequent changes, enable Snowflake’s auto-clustering.
ALTER TABLE YOUR_TABLE_NAME SET CLUSTERING KEY (clustering_key_column1, clustering_key_column2);
