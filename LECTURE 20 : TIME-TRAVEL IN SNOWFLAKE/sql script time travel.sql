-- PROJECT: Snowflake Time Travel & Data Recovery\
-- Create database and schema\
CREATE OR REPLACE DATABASE SNOWFLAKE_TIMETRAVEL_DEMO;
CREATE OR REPLACE SCHEMA SNOWFLAKE_TIMETRAVEL_DEMO.DATA_LANDING;

USE DATABASE SNOWFLAKE_TIMETRAVEL_DEMO;
USE SCHEMA DATA_LANDING;

-- 

Create the target table
CREATE OR REPLACE TABLE DIM_CUSTOMER (
    CUSTOMER_ID       NUMBER(10,0),
    CUSTOMER_NAME     STRING,
    COUNTRY           STRING,
    LOYALTY_TIER      STRING,
    TOTAL_PURCHASE    FLOAT
);

-- 

Create a file format for the CSV file
CREATE OR REPLACE FILE FORMAT FF_DIM_CUSTOMER_CSV
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  FIELD_DELIMITER = ','
  NULL_IF = ('', 'NULL');

-- 
Create an internal stage for data loading
CREATE OR REPLACE STAGE STG_DIM_CUSTOMER
  FILE_FORMAT = FF_DIM_CUSTOMER_CSV\
  COMMENT = 'Internal stage for customer data (Time Travel Demo)';

-- Load CSV data into the table
COPY INTO DIM_CUSTOMER
FROM @STG_DIM_CUSTOMER
FILE_FORMAT = (FORMAT_NAME = FF_DIM_CUSTOMER_CSV)
ON_ERROR = 'CONTINUE';

--  Verify data load
SELECT COUNT(*) AS ROW_COUNT FROM DIM_CUSTOMER;
SELECT * FROM DIM_CUSTOMER LIMIT 10;

--Step 96 Simulate a Mistake (Accidental Data Corruption)
-- Step 1: Simulate a user error (all purchase amounts set to 0)
UPDATE DIM_CUSTOMER
SET TOTAL_PURCHASE = 0;

-- Step 1.1: Verify the corruption
SELECT * FROM DIM_CUSTOMER LIMIT 10;

--Step View Historical Data Using Time Travel

SELECT *
FROM DIM_CUSTOMER
AT (TIMESTAMP => DATEADD('MINUTE', -5, CURRENT_TIMESTAMP()))
LIMIT 10;

--Step Recover Data by Re-Creating the Table

-- Step 3: Re-create the table using a Time Travel snapshot
CREATE OR REPLACE TABLE DIM_CUSTOMER AS
SELECT
FROM DIM_CUSTOMER
AT (OFFSET => -60*5);

--Step DROP and UNDROP Recovery

-- Step 4.1: Drop the table (simulate accidental deletion)
DROP TABLE DIM_CUSTOMER;

-- Step 4.2: Recover the dropped table using Time Travel
UNDROP TABLE DIM_CUSTOMER;

-- Step 4.3: Verify that data is restored
SELECT COUNT(*) AS ROW_COUNT FROM DIM_CUSTOMER;
SELECT * FROM DIM_CUSTOMER LIMIT 10;
}
