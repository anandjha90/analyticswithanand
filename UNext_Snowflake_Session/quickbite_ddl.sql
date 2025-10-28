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
