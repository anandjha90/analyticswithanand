-- ######################################################################
-- SNOWFLAKE PROJECT: ECommerce Analytics Platform
-- Ecommerce Data Model with Clustering + Materialized Views
-- Target: ECOM_DB.RAW
-- ######################################################################
 
-- 0️  ROLE + WAREHOUSE
-- USE ROLE ACCOUNTADMIN;
-- USE WAREHOUSE WAREHOUSE_SNOWPRO;
 
-- ============================================================
-- 1️  DATABASE & SCHEMA SETUP
-- ============================================================
CREATE OR REPLACE DATABASE ECOM_DB;
USE DATABASE ECOM_DB;
 
CREATE OR REPLACE SCHEMA RAW;
USE SCHEMA RAW;
 
CREATE OR REPLACE WAREHOUSE WAREHOUSE_SNOWPRO
  WITH WAREHOUSE_SIZE = 'MEDIUM'
  WAREHOUSE_TYPE     = 'STANDARD'
  AUTO_SUSPEND       = 60
  AUTO_RESUME        = TRUE
  INITIALLY_SUSPENDED = TRUE;
 
-- ============================================================
-- 2️  FILE FORMAT & INTERNAL STAGE
-- ============================================================
CREATE OR REPLACE FILE FORMAT RAW.CSV_FMT
  TYPE                      = 'CSV'
  FIELD_DELIMITER           = ','
  SKIP_HEADER               = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  TRIM_SPACE                = TRUE
  NULL_IF                   = ('NULL', '');
 
CREATE OR REPLACE STAGE RAW.ECOM_STAGE
  FILE_FORMAT = RAW.CSV_FMT
  DIRECTORY   = (ENABLE = TRUE);
 
-- ============================================================
-- 3️  TABLE CREATION (7 Tables)
-- ============================================================
 
CREATE OR REPLACE TABLE RAW.PRODUCTS (
    PRODUCT_ID      VARCHAR(50),
    PRODUCT_NAME    VARCHAR,
    BRAND           VARCHAR,
    CATEGORY        VARCHAR,
    PRICE           NUMBER(10,2),
    SUBCATEGORY     VARCHAR,
    RATING          NUMBER(3,1),
    STOCK_QTY       NUMBER,
    DISCOUNT_PCT    NUMBER(5,2)
);
 
CREATE OR REPLACE TABLE RAW.CUSTOMERS (
    CUSTOMER_ID       VARCHAR(50),
    FIRST_NAME        VARCHAR,
    LAST_NAME         VARCHAR,
    GENDER            VARCHAR,
    DOB               DATE,
    CITY              VARCHAR,
    STATE             VARCHAR,
    ZIP               VARCHAR,
    EMAIL             VARCHAR,
    PHONE             VARCHAR,
    LOYALTY_TIER      VARCHAR,
    REGISTRATION_DATE DATE
);
 
CREATE OR REPLACE TABLE RAW.STORES (
    STORE_ID        VARCHAR(50),
    STORE_NAME      VARCHAR,
    REGION_ID       VARCHAR,
    CITY            VARCHAR,
    STATE           VARCHAR,
    CHANNEL_ID      VARCHAR,
    STORE_TYPE      VARCHAR,
    OPENING_DATE    DATE,
    FLOOR_AREA_SQFT NUMBER,
    MANAGER         VARCHAR
);
 
CREATE OR REPLACE TABLE RAW.SALES_CHANNELS (
    CHANNEL_ID      VARCHAR(10),
    CHANNEL_NAME    VARCHAR,
    TYPE            VARCHAR,
    DESCRIPTION     VARCHAR,
    COMMISSION_PCT  NUMBER(5,2)
);
 
CREATE OR REPLACE TABLE RAW.FCT_ORDERS (
    ORDER_ID        VARCHAR(50),
    ORDER_DATE      DATE,
    PRODUCT_ID      VARCHAR(50),
    PRODUCT_NAME    VARCHAR,
    BRAND           VARCHAR,
    CATEGORY        VARCHAR,
    QUANTITY        NUMBER,
    UNIT_PRICE      NUMBER(10,2),
    DISCOUNT_PCT    NUMBER(5,2),
    TOTAL_SALES     NUMBER(18,2),
    CUSTOMER_ID     VARCHAR(50),
    STORE_ID        VARCHAR(50),
    CITY            VARCHAR,
    STATE           VARCHAR,
    REGION_ID       VARCHAR,
    CHANNEL_ID      VARCHAR(10),
    ORDER_STATUS    VARCHAR,
    PAYMENT_METHOD  VARCHAR,
    DELIVERY_DAYS   NUMBER,
    RETURN_REASON   VARCHAR
);
 
CREATE OR REPLACE TABLE RAW.FCT_INVENTORY (
    INVENTORY_DATE   DATE,
    STORE_ID         VARCHAR,
    PRODUCT_ID       VARCHAR,
    OPENING_STOCK    NUMBER,
    PURCHASES        NUMBER,
    SALES            NUMBER,
    CLOSING_STOCK    NUMBER,
    REGION_ID        VARCHAR,
    SHRINKAGE        NUMBER(6,2),
    REORDER_TRIGGERED NUMBER
);
 
CREATE OR REPLACE TABLE RAW.FCT_RETURNS (
    RETURN_ID       VARCHAR(50),
    ORDER_ID        VARCHAR(50),
    RETURN_DATE     DATE,
    PRODUCT_ID      VARCHAR,
    CUSTOMER_ID     VARCHAR,
    RETURN_REASON   VARCHAR,
    REFUND_AMOUNT   NUMBER(18,2),
    RETURN_STATUS   VARCHAR,
    CHANNEL_ID      VARCHAR
);
 
-- ============================================================
-- 4️  DATA LOADING  (after uploading CSVs via Snowsight > Data > Stages)
-- ============================================================
 
-- Step A: Upload each CSV via Snowsight UI to @RAW.ECOM_STAGE
-- OR via SnowSQL: PUT file:///local/path/products.csv @RAW.ECOM_STAGE;
 
COPY INTO RAW.PRODUCTS
  FROM @RAW.ECOM_STAGE/products.csv
  FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FMT)
  ON_ERROR = 'CONTINUE' FORCE = TRUE;
 
COPY INTO RAW.CUSTOMERS
  FROM @RAW.ECOM_STAGE/customers.csv
  FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FMT)
  ON_ERROR = 'CONTINUE' FORCE = TRUE;
 
COPY INTO RAW.STORES
  FROM @RAW.ECOM_STAGE/stores.csv
  FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FMT)
  ON_ERROR = 'CONTINUE' FORCE = TRUE;
 
COPY INTO RAW.SALES_CHANNELS
  FROM @RAW.ECOM_STAGE/sales_channels.csv
  FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FMT)
  ON_ERROR = 'CONTINUE' FORCE = TRUE;
 
COPY INTO RAW.FCT_ORDERS
  FROM @RAW.ECOM_STAGE/fct_orders.csv
  FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FMT)
  ON_ERROR = 'CONTINUE' FORCE = TRUE;
 
COPY INTO RAW.FCT_INVENTORY
  FROM @RAW.ECOM_STAGE/fct_inventory.csv
  FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FMT)
  ON_ERROR = 'CONTINUE' FORCE = TRUE;
 
COPY INTO RAW.FCT_RETURNS
  FROM @RAW.ECOM_STAGE/fct_returns.csv
  FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FMT)
  ON_ERROR = 'CONTINUE' FORCE = TRUE;
 
-- ============================================================
-- 5️  DATA VALIDATION
-- ============================================================
SELECT 'PRODUCTS'       AS TABLE_NAME, COUNT(*) AS TOTAL_ROWS FROM RAW.PRODUCTS
UNION ALL 
SELECT 'CUSTOMERS',   COUNT(*) FROM RAW.CUSTOMERS
UNION ALL 
SELECT 'STORES',      COUNT(*) FROM RAW.STORES
UNION ALL 
SELECT 'SALES_CHANNELS', COUNT(*) FROM RAW.SALES_CHANNELS
UNION ALL 
SELECT 'FCT_ORDERS',  COUNT(*) FROM RAW.FCT_ORDERS
UNION ALL 
SELECT 'FCT_INVENTORY', COUNT(*) FROM RAW.FCT_INVENTORY
UNION ALL 
SELECT 'FCT_RETURNS', COUNT(*) FROM RAW.FCT_RETURNS;
 
-- ============================================================
-- 6️  CLUSTERING (Fact Tables — Query Optimisation)
-- ============================================================
ALTER TABLE RAW.FCT_ORDERS     CLUSTER BY (ORDER_DATE, CATEGORY, CHANNEL_ID);
ALTER TABLE RAW.FCT_INVENTORY  CLUSTER BY (INVENTORY_DATE, PRODUCT_ID, STORE_ID);
ALTER TABLE RAW.FCT_RETURNS    CLUSTER BY (RETURN_DATE, PRODUCT_ID, CHANNEL_ID);
 
-- ============================================================
-- 7️  MATERIALIZED VIEWS
-- ============================================================
 
-- (1) Daily Sales Summary
CREATE OR REPLACE MATERIALIZED VIEW RAW.MV_DAILY_SALES_SUMMARY
  CLUSTER BY (ORDER_DATE, CATEGORY)
AS
SELECT
  ORDER_DATE::DATE   AS ORDER_DATE,
  CATEGORY,
  BRAND,
  SUM(QUANTITY)      AS TOTAL_QTY,
  SUM(TOTAL_SALES)   AS TOTAL_SALES,
  AVG(DISCOUNT_PCT)  AS AVG_DISCOUNT
FROM RAW.FCT_ORDERS
WHERE ORDER_STATUS = 'Delivered'
GROUP BY ORDER_DATE::DATE, CATEGORY, BRAND;
 
-- (2) Returns by Channel
CREATE OR REPLACE MATERIALIZED VIEW RAW.MV_RETURNS_BY_CHANNEL
  CLUSTER BY (RETURN_DATE, CHANNEL_ID)
AS
SELECT
  RETURN_DATE::DATE  AS RETURN_DATE,
  CHANNEL_ID,
  RETURN_STATUS,
  COUNT(RETURN_ID)   AS TOTAL_RETURNS,
  SUM(REFUND_AMOUNT) AS TOTAL_REFUNDS
FROM RAW.FCT_RETURNS
GROUP BY RETURN_DATE::DATE, CHANNEL_ID, RETURN_STATUS;
 
-- (3) Inventory Health Summary
CREATE OR REPLACE MATERIALIZED VIEW RAW.MV_INVENTORY_HEALTH
  CLUSTER BY (INVENTORY_DATE, PRODUCT_ID)
AS
SELECT
  INVENTORY_DATE::DATE AS INVENTORY_DATE,
  PRODUCT_ID,
  REGION_ID,
  SUM(OPENING_STOCK)   AS TOTAL_OPENING,
  SUM(PURCHASES)       AS TOTAL_PURCHASES,
  SUM(SALES)           AS TOTAL_SOLD,
  SUM(CLOSING_STOCK)   AS TOTAL_CLOSING,
  SUM(REORDER_TRIGGERED) AS REORDER_COUNT
FROM RAW.FCT_INVENTORY
GROUP BY INVENTORY_DATE::DATE, PRODUCT_ID, REGION_ID;
 
-- ============================================================
-- 8️  SEARCH OPTIMIZATION
-- ============================================================
ALTER TABLE RAW.FCT_ORDERS    ADD SEARCH OPTIMIZATION;
ALTER TABLE RAW.FCT_INVENTORY ADD SEARCH OPTIMIZATION;
ALTER TABLE RAW.FCT_RETURNS   ADD SEARCH OPTIMIZATION;
 
-- ============================================================
-- 9️  PERFORMANCE VALIDATION
-- ============================================================
SELECT SYSTEM$CLUSTERING_INFORMATION('RAW.FCT_ORDERS');
SELECT SYSTEM$CLUSTERING_INFORMATION('RAW.FCT_INVENTORY');
SELECT SYSTEM$CLUSTERING_INFORMATION('RAW.FCT_RETURNS');
 
-- Raw vs MV speed comparison
SELECT SUM(TOTAL_SALES) FROM RAW.FCT_ORDERS
  WHERE ORDER_DATE BETWEEN '2024-01-01' AND '2024-01-31';
 
SELECT SUM(TOTAL_SALES) FROM RAW.MV_DAILY_SALES_SUMMARY
  WHERE ORDER_DATE BETWEEN '2024-01-01' AND '2024-01-31';
 
-- ============================================================
-- 10️ MONITORING — Query History
-- ============================================================
SELECT QUERY_TEXT, EXECUTION_TIME, ROWS_PRODUCED
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
ORDER BY START_TIME DESC
LIMIT 20;
