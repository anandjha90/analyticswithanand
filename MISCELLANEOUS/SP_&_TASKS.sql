-- Warehouses / Databases / Schemas

-- Create compute and DB
CREATE WAREHOUSE IF NOT EXISTS WH_ETL WITH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;

CREATE DATABASE IF NOT EXISTS QUICKBITE;
USE DATABASE QUICKBITE;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS STG;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS AUDIT;

CREATE OR REPLACE FILE FORMAT QUICKBITE_CSV_FORMAT
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  NULL_IF = ('', 'NULL')
  TRIM_SPACE = TRUE;


-- Staging tables (raw data loaded by Snowpipe)
-- Stage target tables (raw CSV content)
CREATE OR REPLACE TABLE STG.raw_orders (
  order_id STRING,
  customer_id STRING,
  restaurant_id STRING,
  order_ts TIMESTAMP_NTZ,
  status STRING,
  total_amount FLOAT,
  coupon_code STRING,
  driver_id STRING,
  payment_method STRING,
  __source_file STRING,
  __ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE STG.raw_order_items (
  order_id STRING,
  item_id STRING,
  restaurant_id STRING,
  item_name STRING,
  quantity INT,
  unit_price FLOAT,
  line_total FLOAT,
  __source_file STRING,
  __ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE STG.raw_customers (
  customer_id STRING,
  name STRING,
  phone STRING,
  email STRING,
  city STRING,
  signup_date DATE,
  __source_file STRING,
  __ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Additional raw tables for restaurants, drivers, menu, coupons
CREATE OR REPLACE TABLE STG.raw_restaurants (
  restaurant_id STRING, 
  name STRING,
  city STRING, 
  rating FLOAT,
  avg_cost_for_two INT,
  __source_file STRING,
  __ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE STG.raw_menu_items (
  item_id STRING, 
  restaurant_id STRING, 
  item_name STRING, 
  price FLOAT, 
  is_veg BOOLEAN, 
  __source_file STRING,
  __ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE STG.raw_drivers (
  driver_id STRING,
  name STRING,
  phone STRING,
  vehicle_type STRING,
  status STRING,
  __source_file STRING,
  __ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE STG.raw_coupons (
  coupon_code STRING,
  discount_percent INT,
  min_order_value FLOAT,
  valid_from DATE,
  valid_to DATE,
  __source_file STRING,
  __ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);


-- Curated (final analytics) tables
CREATE TABLE IF NOT EXISTS CURATED.customers (
  customer_key NUMBER AUTOINCREMENT PRIMARY KEY,
  customer_id STRING, 
  name STRING, 
  phone STRING,
  email STRING, 
  city STRING, 
  signup_date DATE,
  inserted_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS CURATED.restaurants (
  restaurant_key NUMBER AUTOINCREMENT PRIMARY KEY,
  restaurant_id STRING, 
  name STRING, 
  city STRING, 
  rating FLOAT, 
  avg_cost_for_two INT,
  inserted_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS CURATED.menu_items (
  item_key NUMBER AUTOINCREMENT PRIMARY KEY,
  item_id STRING,
  restaurant_id STRING,
  item_name STRING,
  price FLOAT,
  is_veg BOOLEAN,
  inserted_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS CURATED.drivers (
  driver_key NUMBER AUTOINCREMENT PRIMARY KEY,
  driver_id STRING,
  name STRING,
  phone STRING,
  vehicle_type STRING,
  status STRING,
  inserted_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS CURATED.coupons (
  coupon_key NUMBER AUTOINCREMENT PRIMARY KEY,
  coupon_code STRING,
  discount_percent INT,
  min_order_value FLOAT,
  valid_from DATE,
  valid_to DATE,
  inserted_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS CURATED.orders (
  order_key NUMBER AUTOINCREMENT PRIMARY KEY,
  order_id STRING,
  customer_key NUMBER,
  restaurant_key NUMBER,
  order_ts TIMESTAMP_NTZ,
  status STRING,
  total_amount FLOAT,
  coupon_key NUMBER,
  driver_key NUMBER,
  payment_method STRING,
  created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP_NTZ
);

CREATE TABLE IF NOT EXISTS CURATED.order_items (
  order_item_key NUMBER AUTOINCREMENT PRIMARY KEY,
  order_key NUMBER,
  item_key NUMBER,
  item_name STRING,
  quantity INT,
  unit_price FLOAT,
  line_total FLOAT,
  inserted_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Auditing / Logger tables
CREATE TABLE IF NOT EXISTS AUDIT.pipeline_job_log (
  log_id NUMBER AUTOINCREMENT PRIMARY KEY,
  job_name STRING,
  run_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  status STRING,
  rows_processed NUMBER,
  rows_inserted NUMBER,
  rows_updated NUMBER,
  error_message STRING,
  details VARIANT
);

CREATE TABLE IF NOT EXISTS AUDIT.row_errors (
  error_id NUMBER AUTOINCREMENT PRIMARY KEY,
  job_name STRING,
  run_ts TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  raw_row VARIANT,
  error_message STRING
);

-- Snowflake storage integration object
CREATE STORAGE INTEGRATION IF NOT EXISTS QUICKBITE_S3_INTEGRATION
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::196024211961:role/awa_dev_role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://quickbite-lake/raw/');

DESC STORAGE INTEGRATION QUICKBITE_S3_INTEGRATION; -- get STORAGE_AWS_IAM_USER_ARN and update trsut relationshi for AWS role

-- Per-table STAGE objects (one per folder)
-- These point to the folder where files will be uploaded.
-- Customers stage
CREATE OR REPLACE STAGE RAW.STAGE_CUSTOMERS
  URL='s3://quickbite-lake/raw/customers/'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Restaurants
CREATE OR REPLACE STAGE RAW.STAGE_RESTAURANTS
  URL='s3://quickbite-lake/raw/restaurants/'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Drivers
CREATE OR REPLACE STAGE RAW.STAGE_DRIVERS
  URL='s3://quickbite-lake/raw/drivers/'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Menu items
CREATE OR REPLACE STAGE RAW.STAGE_MENU_ITEMS
  URL='s3://quickbite-lake/raw/menu_items/'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Coupons
CREATE OR REPLACE STAGE RAW.STAGE_COUPONS
  URL='s3://quickbite-lake/raw/coupons/'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Orders
CREATE OR REPLACE STAGE RAW.STAGE_ORDERS
  URL='s3://quickbite-lake/raw/orders/'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Order items
CREATE OR REPLACE STAGE RAW.STAGE_ORDER_ITEMS
  URL='s3://quickbite-lake/raw/order_items/'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Per-table PIPE objects (Snowpipe with AUTO_INGEST)
-- Each pipe copies files from its stage folder into the corresponding STG.raw_* table. These are AUTO_INGEST = TRUE so S3 events will trigger Snowpipe.

-- Customers pipe
CREATE OR REPLACE PIPE RAW.PIPE_CUSTOMERS
AUTO_INGEST = TRUE
AS
COPY INTO STG.raw_customers (customer_id, name, phone, email, city, signup_date, __source_file, __ingested_at)
FROM (
  SELECT
    t.$1::STRING,
    t.$2::STRING,
    t.$3::STRING,
    t.$4::STRING,
    t.$5::STRING,
    TRY_TO_DATE(t.$6) as signup_date,
    METADATA$FILENAME,
    CURRENT_TIMESTAMP()
  FROM @RAW.STAGE_CUSTOMERS (FILE_FORMAT => 'QUICKBITE_CSV_FORMAT') t
)
ON_ERROR='CONTINUE';


-- Restaurants pipe
CREATE OR REPLACE PIPE RAW.PIPE_RESTAURANTS
AUTO_INGEST = TRUE
AS
COPY INTO STG.raw_restaurants (restaurant_id, name, city, rating, avg_cost_for_two, __source_file, __ingested_at)
FROM (
  SELECT t.$1::STRING, t.$2::STRING, t.$3::STRING, TRY_TO_DOUBLE(t.$4), TRY_TO_DOUBLE(t.$5), METADATA$FILENAME, CURRENT_TIMESTAMP()
  FROM @RAW.STAGE_RESTAURANTS (FILE_FORMAT => 'QUICKBITE_CSV_FORMAT') t
)
ON_ERROR='CONTINUE';


-- Drivers pipe
CREATE OR REPLACE PIPE RAW.PIPE_DRIVERS
AUTO_INGEST = TRUE
AS
COPY INTO STG.raw_drivers (driver_id, name, phone, vehicle_type, status, __source_file, __ingested_at)
FROM (
  SELECT t.$1::STRING, t.$2::STRING, t.$3::STRING, t.$4::STRING, t.$5::STRING, METADATA$FILENAME, CURRENT_TIMESTAMP()
  FROM @RAW.STAGE_DRIVERS (FILE_FORMAT => 'QUICKBITE_CSV_FORMAT') t
)
ON_ERROR='CONTINUE';

-- Menu items pipe
CREATE OR REPLACE PIPE RAW.PIPE_MENU_ITEMS
AUTO_INGEST = TRUE
AS
COPY INTO STG.raw_menu_items 
(item_id, restaurant_id, item_name, price, is_veg, __source_file, __ingested_at)
FROM (
  SELECT 
    t.$1::STRING AS item_id,
    t.$2::STRING AS restaurant_id,
    t.$3::STRING AS item_name,
    TRY_TO_DOUBLE(t.$4) AS price,
    CASE 
      WHEN t.$5 IN ('TRUE','True','true','1','t','yes','YES') THEN TRUE
      WHEN t.$5 IN ('FALSE','False','false','0','f','no','NO') THEN FALSE
      ELSE NULL 
    END AS is_veg,
    METADATA$FILENAME,
    CURRENT_TIMESTAMP()
  FROM @RAW.STAGE_MENU_ITEMS (FILE_FORMAT => 'QUICKBITE_CSV_FORMAT') t
)
ON_ERROR = 'CONTINUE';


-- Coupons pipe
CREATE OR REPLACE PIPE RAW.PIPE_COUPONS
AUTO_INGEST = TRUE
AS
COPY INTO STG.raw_coupons (coupon_code, discount_percent, min_order_value, valid_from, valid_to, __source_file, __ingested_at)
FROM (
  SELECT t.$1::STRING, TRY_TO_DOUBLE(t.$2), TRY_TO_DOUBLE(t.$3), TRY_TO_DATE(t.$4), TRY_TO_DATE(t.$5), METADATA$FILENAME, CURRENT_TIMESTAMP()
  FROM @RAW.STAGE_COUPONS (FILE_FORMAT => 'QUICKBITE_CSV_FORMAT') t
)
ON_ERROR='CONTINUE';


-- Orders pipe
CREATE OR REPLACE PIPE RAW.PIPE_ORDERS
  AUTO_INGEST = TRUE
AS
COPY INTO STG.raw_orders (order_id, customer_id, restaurant_id, order_ts, status, total_amount, coupon_code, driver_id, payment_method, __source_file, __ingested_at)
FROM (
  SELECT
    t.$1::STRING,
    t.$2::STRING,
    t.$3::STRING,
    TRY_TO_TIMESTAMP(t.$4) as order_ts,
    t.$5::STRING,
    TRY_TO_DOUBLE(t.$6) as total_amount,
    t.$7::STRING,
    t.$8::STRING,
    t.$9::STRING,
    METADATA$FILENAME,
    CURRENT_TIMESTAMP()
  FROM @RAW.STAGE_ORDERS (FILE_FORMAT => 'QUICKBITE_CSV_FORMAT') t
)
ON_ERROR='CONTINUE';


-- Order items pipe
CREATE OR REPLACE PIPE RAW.PIPE_ORDER_ITEMS
  AUTO_INGEST = TRUE
AS
COPY INTO STG.raw_order_items (order_id, item_id, restaurant_id, item_name, quantity, unit_price, line_total, __source_file, __ingested_at)
FROM (
  SELECT
    t.$1::STRING,
    t.$2::STRING,
    t.$3::STRING,
    t.$4::STRING,
    TRY_TO_DOUBLE(t.$5) as quantity,
    TRY_TO_DOUBLE(t.$6) as unit_price,
    TRY_TO_DOUBLE(t.$7) as line_total,
    METADATA$FILENAME,
    CURRENT_TIMESTAMP()
  FROM @RAW.STAGE_ORDER_ITEMS (FILE_FORMAT => 'QUICKBITE_CSV_FORMAT') t
)
ON_ERROR='CONTINUE';

/*
Notes

ON_ERROR = 'CONTINUE' prevents a bad row from stopping entire file ingest — errors will be visible in the COPY history and you can log them from the SP to AUDIT.row_errors.

You can also add PURGE = TRUE in the COPY clause if you want Snowflake to remove files after successful ingest — usually not recommended for initial testing. Better to archive processed files in an archive/ prefix in S3 and have lifecycle rules.
*/


-- Checking pipe
SHOW PIPES;

-- check pipe data flow status
ALTER PIPE RAW.PIPE_CUSTOMERS REFRESH;
ALTER PIPE RAW.PIPE_RESTAURANTS REFRESH;
ALTER PIPE RAW.PIPE_DRIVERS REFRESH;
ALTER PIPE RAW.PIPE_MENU_ITEMS REFRESH;
ALTER PIPE RAW.PIPE_COUPONS REFRESH;
ALTER PIPE RAW.PIPE_ORDERS REFRESH;
ALTER PIPE RAW.PIPE_ORDER_ITEMS REFRESH;


-- This will show the latest file which has been processed
select SYSTEM$PIPE_STATUS('STG.PIPE_CUSTOMERS');

-- now checking count where data has been arrived or not
SELECT count(*) FROM DEMO_DATABASE.DEMO_SCHEMA.CUSTOMER_DATA;

-- to check wether the files count in source(AWS S3) & target(Snowflake) are matching or not use below command
-- It will also help to answer question how many rows have been parsed in a particular table on any day or in last few days/hrs.
-- We can get the complete picture

select * from table(information_schema.copy_history(table_name => 'QUICKBITE.STG.RAW_COUPONS', start_time=>
dateadd(hours, -1, current_timestamp())))
UNION ALL 
select * from table(information_schema.copy_history(table_name => 'QUICKBITE.STG.RAW_DRIVERS', start_time=>
dateadd(hours, -1, current_timestamp())))
UNION ALL
select * from table(information_schema.copy_history(table_name => 'QUICKBITE.STG.RAW_CUSTOMERS', start_time=>
dateadd(hours, -1, current_timestamp())))
UNION ALL
select * from table(information_schema.copy_history(table_name => 'QUICKBITE.STG.RAW_MENU_ITEMS', start_time=>
dateadd(hours, -1, current_timestamp())))
UNION ALL
select * from table(information_schema.copy_history(table_name => 'QUICKBITE.STG.RAW_ORDERS', start_time=>
dateadd(hours, -1, current_timestamp())))
UNION ALL
select * from table(information_schema.copy_history(table_name => 'QUICKBITE.STG.RAW_ORDER_ITEMS', start_time=>
dateadd(hours, -1, current_timestamp())))
UNION ALL
select * from table(information_schema.copy_history(table_name => 'QUICKBITE.STG.RAW_RESTAURANTS', start_time=>
dateadd(hours, -1, current_timestamp())));


--- If you just want a quick health snapshot of all pipes in last hour - simplest for daily ops)
SELECT * 
-- PIPE_NAME, LAST_LOAD_TIME, ROWS_INSERTED, ERROR_COUNT, STATUS
FROM SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY
WHERE PIPE_NAME ILIKE 'PIPE_%'
  AND LAST_LOAD_TIME > DATEADD('hour', -1, CURRENT_TIMESTAMP())
ORDER BY LAST_LOAD_TIME DESC;



-- Sanity checks (run immediately)
-- Row counts per staging table
SELECT 'raw_customers' AS tbl, COUNT(*) FROM STG.raw_customers
UNION ALL
SELECT 'raw_restaurants', COUNT(*) FROM STG.raw_restaurants
UNION ALL
SELECT 'raw_drivers', COUNT(*) FROM STG.raw_drivers
UNION ALL
SELECT 'raw_menu_items', COUNT(*) FROM STG.raw_menu_items
UNION ALL
SELECT 'raw_coupons', COUNT(*) FROM STG.raw_coupons
UNION ALL
SELECT 'raw_orders', COUNT(*) FROM STG.raw_orders
UNION ALL
SELECT 'raw_order_items', COUNT(*) FROM STG.raw_order_items;


-- Peek at problem rows (nulls / parse failures):
-- Show rows where order_ts failed to parse (if any)
SELECT * FROM STG.raw_orders WHERE order_ts IS NULL LIMIT 20;

-- Show rows with missing essential columns
SELECT * FROM STG.raw_orders WHERE order_id IS NULL OR customer_id IS NULL OR restaurant_id IS NULL LIMIT 20;



