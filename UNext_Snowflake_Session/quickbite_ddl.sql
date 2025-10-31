-- Warehouses / Databases / Schemas

-- Create compute and DB
CREATE WAREHOUSE IF NOT EXISTS WH_ETL WITH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;

CREATE DATABASE IF NOT EXISTS QUICKBITE;
USE DATABASE QUICKBITE;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS STG;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS AUDIT;
CREATE SCHEMA IF NOT EXISTS ETL;

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

  --DROP STORAGE INTEGRATION QUICKBITE_S3_INTEGRATION;

  LIST @RAW.STAGE_CUSTOMERS;


DESC STORAGE INTEGRATION QUICKBITE_S3_INTEGRATION; -- get STORAGE_AWS_IAM_USER_ARN and update trsut relationshi for AWS role

-- Per-table STAGE objects (one per folder)
-- These point to the folder where files will be uploaded.
-- Customers stage
CREATE OR REPLACE STAGE RAW.STAGE_CUSTOMERS
  URL='s3://quickbite-lake/raw/customers.csv'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Restaurants
CREATE OR REPLACE STAGE RAW.STAGE_RESTAURANTS
  URL='s3://quickbite-lake/raw/restaurants.csv'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Drivers
CREATE OR REPLACE STAGE RAW.STAGE_DRIVERS
  URL='s3://quickbite-lake/raw/drivers.csv'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Menu items
CREATE OR REPLACE STAGE RAW.STAGE_MENU_ITEMS
  URL='s3://quickbite-lake/raw/menu_items.csv'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Coupons
CREATE OR REPLACE STAGE RAW.STAGE_COUPONS
  URL='s3://quickbite-lake/raw/coupons.csv'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Orders
CREATE OR REPLACE STAGE RAW.STAGE_ORDERS
  URL='s3://quickbite-lake/raw/orders.csv'
  STORAGE_INTEGRATION = QUICKBITE_S3_INTEGRATION
  FILE_FORMAT = QUICKBITE_CSV_FORMAT;

-- Order items
CREATE OR REPLACE STAGE RAW.STAGE_ORDER_ITEMS
  URL='s3://quickbite-lake/raw/order_items.csv'
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

SELECT SYSTEM$PIPE_STATUS('RAW.PIPE_CUSTOMERS');


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


SELECT CURRENT_DATABASE() AS cur_db, CURRENT_SCHEMA() AS cur_schema, CURRENT_ROLE() AS cur_role, CURRENT_USER() AS cur_user;





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


SHOW STAGES IN SCHEMA QUICKBITE.RAW;
SHOW PIPES IN SCHEMA QUICKBITE.RAW;
DESC PIPE QUICKBITE.RAW.PIPE_CUSTOMERS;





-- This will show the latest file which has been processed
--select SYSTEM$PIPE_STATUS('STG.PIPE_CUSTOMERS');

SELECT SYSTEM$PIPE_STATUS('RAW.PIPE_CUSTOMERS');


SELECT SYSTEM$PIPE_STATUS('RAW.PIPE_CUSTOMERS');
SELECT SYSTEM$PIPE_STATUS('RAW.PIPE_RESTAURANTS');
SELECT SYSTEM$PIPE_STATUS('RAW.PIPE_DRIVERS');
SELECT SYSTEM$PIPE_STATUS('RAW.PIPE_MENU_ITEMS');
SELECT SYSTEM$PIPE_STATUS('RAW.PIPE_COUPONS');
SELECT SYSTEM$PIPE_STATUS('RAW.PIPE_ORDERS');
SELECT SYSTEM$PIPE_STATUS('RAW.PIPE_ORDER_ITEMS');



-- now checking count where data has been arrived or not
--SELECT count(*) FROM DEMO_DATABASE.DEMO_SCHEMA.CUSTOMER_DATA;

SELECT COUNT(*) FROM STG.raw_customers;


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

/*
Stored Procedure — business logic + logger + dedupe + MERGE

Below is an idempotent JS stored procedure that:
    Reads new rows from STG.raw_* tables
    Validates and normalizes data
    Inserts/merges into curated tables using MERGE statements
    Logs summary & detailed row errors into AUDIT tables

Important: JavaScript Stored Procedures in Snowflake run SQL via snowflake.execute and return objects. Adapt role/warehouse usage before running.

*/

CREATE OR REPLACE PROCEDURE STG.SP_PROCESS_RAW_ORDERS()
RETURNS VARIANT
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
var result = {};
var job_name = 'SP_PROCESS_RAW_ORDERS_' + new Date().toISOString();

function log_summary(status, rows_processed, rows_inserted, rows_updated, err_msg, details){
  var json_str = JSON.stringify(details || {}).replace(/'/g, "''");
  var sql = `
    INSERT INTO AUDIT.pipeline_job_log
    (job_name, status, rows_processed, rows_inserted, rows_updated, error_message, details)
    SELECT ?, ?, ?, ?, ?, ?, PARSE_JSON('${json_str}')
  `;
  snowflake.execute({
    sqlText: sql,
    binds: [job_name, status, rows_processed, rows_inserted, rows_updated, err_msg]
  });
}

try {
  snowflake.execute({sqlText: "BEGIN"});

  // Row Count
  var cnt_rs = snowflake.execute({sqlText: "SELECT COUNT(*) AS CNT FROM STG.raw_orders"});
  cnt_rs.next();
  var rows_to_process = cnt_rs.getColumnValue('CNT') || 0;
  var rows_inserted = 0;
  var rows_updated = 0;

  // MERGE: Customers
  var merge_customers = `
    MERGE INTO CURATED.customers tgt
    USING (
      SELECT DISTINCT customer_id, name, phone, email, city, TRY_TO_DATE(signup_date) AS signup_date
      FROM STG.raw_customers
    ) src
    ON tgt.customer_id = src.customer_id
    WHEN MATCHED AND (
      tgt.name != src.name OR tgt.phone != src.phone OR tgt.email != src.email OR
      tgt.city != src.city OR tgt.signup_date != src.signup_date
    )
      THEN UPDATE SET name = src.name, phone = src.phone, email = src.email,
                      city = src.city, signup_date = src.signup_date, updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN
      INSERT (customer_id, name, phone, email, city, signup_date)
      VALUES (src.customer_id, src.name, src.phone, src.email, src.city, src.signup_date);
  `;
  snowflake.execute({sqlText: merge_customers});

  // MERGE: Restaurants
  var merge_restaurants = `
    MERGE INTO CURATED.restaurants tgt
    USING (
      SELECT DISTINCT restaurant_id, name, city, rating, avg_cost_for_two
      FROM STG.raw_restaurants
    ) src
    ON tgt.restaurant_id = src.restaurant_id
    WHEN MATCHED THEN
      UPDATE SET name = src.name, city = src.city, rating = src.rating,
                 avg_cost_for_two = src.avg_cost_for_two, updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN
      INSERT (restaurant_id, name, city, rating, avg_cost_for_two)
      VALUES (src.restaurant_id, src.name, src.city, src.rating, src.avg_cost_for_two);
  `;
  snowflake.execute({sqlText: merge_restaurants});

  // MERGE: Drivers
  var merge_drivers = `
    MERGE INTO CURATED.drivers tgt
    USING (
      SELECT DISTINCT driver_id, name, phone, vehicle_type, status
      FROM STG.raw_drivers
    ) src
    ON tgt.driver_id = src.driver_id
    WHEN MATCHED THEN
      UPDATE SET name = src.name, phone = src.phone, vehicle_type = src.vehicle_type,
                 status = src.status, updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN
      INSERT (driver_id, name, phone, vehicle_type, status)
      VALUES (src.driver_id, src.name, src.phone, src.vehicle_type, src.status);
  `;
  snowflake.execute({sqlText: merge_drivers});

  // MERGE: Menu Items
  var merge_menu = `
    MERGE INTO CURATED.menu_items tgt
    USING (
      SELECT DISTINCT item_id, restaurant_id, item_name, price, is_veg
      FROM STG.raw_menu_items
    ) src
    ON tgt.item_id = src.item_id
    WHEN MATCHED THEN
      UPDATE SET item_name = src.item_name, price = src.price, is_veg = src.is_veg,
                 updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN
      INSERT (item_id, restaurant_id, item_name, price, is_veg)
      VALUES (src.item_id, src.restaurant_id, src.item_name, src.price, src.is_veg);
  `;
  snowflake.execute({sqlText: merge_menu});

  // MERGE: Coupons
  var merge_coupons = `
    MERGE INTO CURATED.coupons tgt
    USING (
      SELECT DISTINCT coupon_code, discount_percent, min_order_value,
                      TRY_TO_DATE(valid_from) AS valid_from,
                      TRY_TO_DATE(valid_to) AS valid_to
      FROM STG.raw_coupons
    ) src
    ON tgt.coupon_code = src.coupon_code
    WHEN MATCHED THEN
      UPDATE SET discount_percent = src.discount_percent, min_order_value = src.min_order_value,
                 valid_from = src.valid_from, valid_to = src.valid_to, updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN
      INSERT (coupon_code, discount_percent, min_order_value, valid_from, valid_to)
      VALUES (src.coupon_code, src.discount_percent, src.min_order_value, src.valid_from, src.valid_to);
  `;
  snowflake.execute({sqlText: merge_coupons});

  // MERGE: Orders
  var merge_orders = `
    MERGE INTO CURATED.orders tgt
    USING (
      SELECT
        r.order_id,
        c.customer_key,
        rt.restaurant_key,
        r.order_ts,
        r.status,
        r.total_amount,
        cp.coupon_key,
        d.driver_key,
        r.payment_method
      FROM STG.raw_orders r
      LEFT JOIN CURATED.customers c ON c.customer_id = r.customer_id
      LEFT JOIN CURATED.restaurants rt ON rt.restaurant_id = r.restaurant_id
      LEFT JOIN CURATED.drivers d ON d.driver_id = r.driver_id
      LEFT JOIN CURATED.coupons cp ON cp.coupon_code = r.coupon_code
    ) src
    ON tgt.order_id = src.order_id
    WHEN MATCHED THEN
      UPDATE SET customer_key = src.customer_key, restaurant_key = src.restaurant_key,
                 order_ts = src.order_ts, status = src.status, total_amount = src.total_amount,
                 coupon_key = src.coupon_key, driver_key = src.driver_key,
                 payment_method = src.payment_method, updated_at = CURRENT_TIMESTAMP()
    WHEN NOT MATCHED THEN
      INSERT (order_id, customer_key, restaurant_key, order_ts, status,
              total_amount, coupon_key, driver_key, payment_method)
      VALUES (src.order_id, src.customer_key, src.restaurant_key, src.order_ts,
              src.status, src.total_amount, src.coupon_key, src.driver_key, src.payment_method);
  `;
  snowflake.execute({sqlText: merge_orders});

  // MERGE: Order Items
  var merge_order_items = `
    MERGE INTO CURATED.order_items tgt
    USING (
      SELECT
        oi.order_id,
        oi.item_id,
        oi.item_name,
        oi.quantity,
        oi.unit_price,
        oi.line_total,
        o.order_key,
        mi.item_key
      FROM STG.raw_order_items oi
      LEFT JOIN CURATED.orders o ON o.order_id = oi.order_id
      LEFT JOIN CURATED.menu_items mi ON mi.item_id = oi.item_id
    ) src
    ON tgt.order_key = src.order_key AND tgt.item_key = src.item_key
    WHEN NOT MATCHED THEN
      INSERT (order_key, item_key, item_name, quantity, unit_price, line_total)
      VALUES (src.order_key, src.item_key, src.item_name, src.quantity, src.unit_price, src.line_total);
  `;
  snowflake.execute({sqlText: merge_order_items});

  // Commit & Log
  snowflake.execute({sqlText: "COMMIT"});
  log_summary('SUCCESS', rows_to_process, rows_inserted, rows_updated, null, {note:"Processed raw orders and related tables"});
  result.status = 'SUCCESS';
  result.rows_to_process = rows_to_process;

} catch (err) {
  try { snowflake.execute({sqlText:"ROLLBACK"}); } catch(e) {}
  var msg = err.message || String(err);

  // Log failure
  try {
    log_summary('FAILED', null, null, null, msg, {});
  } catch(e) {}

  // Context info for email
  var ts = null, usr = null, wh = null;
  try {
    var ts_rs = snowflake.execute({sqlText: "SELECT CURRENT_TIMESTAMP() AS ts, CURRENT_USER() AS usr, CURRENT_WAREHOUSE() AS wh"});
    if (ts_rs.next()) {
      ts = ts_rs.getColumnValue('TS');
      usr = ts_rs.getColumnValue('USR');
      wh = ts_rs.getColumnValue('WH');
    }
  } catch(e) {}

  // Email body
  var email_body = '❌ Snowflake Job Failed: SP_PROCESS_RAW_ORDERS\\n\\n'
                 + 'Error: ' + msg + '\\n\\n'
                 + 'Context:\\nTimestamp: ' + ts + '\\nUser: ' + usr + '\\nWarehouse: ' + wh + '\\n\\n'
                 + 'Check AUDIT.pipeline_job_log for details.';

  // Send failure email
  try {
    snowflake.execute({
      sqlText: `
        CALL SYSTEM$SEND_EMAIL(
          'NOTIFICATION_INTG_EMAIL',
          'analyticswithanand@gmail.com',
          '❌ Snowflake Job Failed: SP_PROCESS_RAW_ORDERS',
          ?
        );
      `,
      binds: [email_body]
    });
  } catch(emailErr) {
    try {
      log_summary('FAILED_EMAIL', null, null, null, emailErr.message, {original_error: msg});
    } catch(e) {}
  }

  result.status = 'FAILED';
  result.error = msg;
}

return result;
$$;

ALTER TABLE CURATED.menu_items RENAME TO CURATED.menu_items_backup;
CALL STG.SP_PROCESS_RAW_ORDERS();
-- After test
ALTER TABLE CURATED.menu_items_backup RENAME TO CURATED.menu_items;


/*
Notes & improvements

For large-scale loads, consider using Streams on STG.raw_* tables for change capture and then process only INSERTED rows.
Track MERGE output counts by using staging tables with timestamps or by comparing row counts before/after.
Add schema-qualified try_cast/TRY_TO_TIMESTAMP for robust parsing.
Consider partitioning/historization of raw data in cloud storage.

*/

-- Snowflake Task (scheduler) — with cron
-- Create a Task to run the SP every 5 minutes (or whatever cadence you prefer):

-- Ensure warehouse is set for the task
CREATE OR REPLACE TASK ETL.TASK_PROCESS_ORDERS
  WAREHOUSE = WH_ETL
  SCHEDULE = 'USING CRON */5 * * * * UTC'  -- every 5 minutes; change timezone by converting times or using UTC 
  COMMENT = 'Run stored proc to process raw orders into curated tables every 5 min'
AS
  CALL STG.SP_PROCESS_RAW_ORDERS();

-- Enable the task
ALTER TASK ETL.TASK_PROCESS_ORDERS RESUME;

--SHOW TASKS;
SHOW TASKS IN ACCOUNT;


DESC TASK ETL.TASK_PROCESS_ORDERS;

CALL STG.SP_PROCESS_RAW_ORDERS();

/*
KPIs & analytics columns to compute (examples)

Daily GMV (Gross Merchandise Value) = SUM(total_amount) by date

Total orders per day

Average Order Value (AOV) = GMV / orders

Delivery TAT = AVG(delivery_time — order_ts) across delivered orders (requires delivery timestamp column)

Cancel rate = cancelled_orders / total_orders

Coupon adoption rate = orders_with_coupon / total_orders

Repeat customer rate = customers with >1 order in last 30 days / total active customers

Driver utilization = active_deliveries / total_drivers

Restaurant on-time preparation rate (need prep_time data)

Implement as views/materialized views on CURATED.orders / CURATED.order_items.

*/
CREATE OR REPLACE VIEW CURATED.v_daily_kpis AS
SELECT
  CAST(order_ts AS DATE) AS dt,
  COUNT(*) AS orders,
  SUM(total_amount) AS gmv,
  SUM(total_amount)/NULLIF(COUNT(*),0) AS aov,
  SUM(CASE WHEN status='CANCELLED' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0) AS cancel_rate,
  SUM(CASE WHEN coupon_key IS NOT NULL THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS coupon_rate
FROM CURATED.orders
GROUP BY 1;

/*
Data quality checks to include (in SP or separate Task)

Reject/order to AUDIT.row_errors if required fields are missing (order_id, customer_id, restaurant_id, order_ts)

Check numeric fields parse correctly; log rows that fail parse

Check referential integrity; if missing customer -> create a minimal customer row or flag for enrichment

Monitor ingestion lag: compare file timestamp -> __ingested_at

*/
