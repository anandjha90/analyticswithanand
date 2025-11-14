
-- ====================================================================================
-- PaintCo — Complete CDC ELT Pipeline (Full, ready-to-run)
-- Includes: DB + Schemas + Stages + File Format,
-- RAW tables, CORE tables, Streams, Merge Procedures,
-- JS Orchestrator, Task, Dynamic Tables, Monitoring, and Reload Blocks
-- Run this file in Snowflake (Snowsight or SnowSQL) with a privileged role.
-- ====================================================================================

-- 0. Safety: use a privileged role for initial deploy
USE ROLE ACCOUNTADMIN;

----------------------------------------
-- 1) Create database + schemas + file format + stages
----------------------------------------
CREATE OR REPLACE DATABASE PAINTCO_DB;
USE DATABASE PAINTCO_DB;

CREATE OR REPLACE SCHEMA STG;
CREATE OR REPLACE SCHEMA RAW;
CREATE OR REPLACE SCHEMA CORE;
CREATE OR REPLACE SCHEMA MONITORING;
CREATE OR REPLACE SCHEMA PUBLIC;

----------------------------------------
-- File format (enhanced for reload tolerance)
----------------------------------------
CREATE OR REPLACE FILE FORMAT PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  TRIM_SPACE = TRUE
  NULL_IF = ('', 'NULL')
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

----------------------------------------
-- Internal stages
----------------------------------------
CREATE OR REPLACE STAGE STG.CUSTOMERS_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.PRODUCTS_STAGE  FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.STORES_STAGE    FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.SUPPLIERS_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.DISTRIBUTORS_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.DEALERS_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.BRANDSTORES_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.LOCALSHOPS_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.INDUSTRIAL_CLIENTS_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.PROJECTS_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.INVENTORY_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.PURCHASE_ORDERS_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.SHIPMENTS_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.PROMOTIONS_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;
CREATE OR REPLACE STAGE STG.SALES_STAGE FILE_FORMAT = PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT;

----------------------------------------
-- 2) Create RAW landing tables
----------------------------------------
USE SCHEMA RAW;

CREATE OR REPLACE TABLE RAW.CUSTOMERS_RAW (
  file_id STRING,
  customer_id STRING,
  customer_name STRING,
  customer_type STRING,
  email STRING,
  phone STRING,
  city STRING,
  state STRING,
  pin_code STRING,
  division STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.PRODUCTS_RAW (
  file_id STRING,
  product_id STRING,
  sku STRING,
  product_name STRING,
  brand STRING,
  category STRING,
  sub_category STRING,
  unit_price NUMBER(10,2),
  uom STRING,
  pack_size STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.STORES_RAW (
  file_id STRING,
  store_id STRING,
  store_name STRING,
  store_type STRING,
  city STRING,
  state STRING,
  region STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.SUPPLIERS_RAW (
  file_id STRING,
  supplier_id STRING,
  supplier_name STRING,
  contact_email STRING,
  city STRING,
  state STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.DISTRIBUTORS_RAW (
  file_id STRING,
  distributor_id STRING,
  distributor_name STRING,
  city STRING,
  state STRING,
  tier STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.DEALERS_RAW (
  file_id STRING,
  dealer_id STRING,
  dealer_name STRING,
  city STRING,
  state STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.BRANDSTORES_RAW (
  file_id STRING,
  brand_store_id STRING,
  name STRING,
  city STRING,
  state STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.LOCALSHOPS_RAW (
  file_id STRING,
  shop_id STRING,
  shop_name STRING,
  owner_name STRING,
  city STRING,
  state STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.INDUSTRIAL_CLIENTS_RAW (
  file_id STRING,
  client_id STRING,
  client_name STRING,
  industry_segment STRING,
  contact_person STRING,
  contact_email STRING,
  city STRING,
  state STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.PROJECTS_RAW (
  file_id STRING,
  project_id STRING,
  project_name STRING,
  client_id STRING,
  start_date TIMESTAMP_LTZ,
  end_date TIMESTAMP_LTZ,
  city STRING,
  state STRING,
  status STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.INVENTORY_RAW (
  file_id STRING,
  product_id STRING,
  location_id STRING,
  location_type STRING,
  quantity NUMBER,
  last_updated TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.SALES_RAW (
  file_id STRING,
  sale_id STRING,
  customer_id STRING,
  customer_type STRING,
  product_id STRING,
  store_id STRING,
  distributor_id STRING,
  dealer_id STRING,
  brand_store_id STRING,
  supplier_id STRING,
  division STRING,
  quantity NUMBER,
  sale_amount NUMBER(12,2),
  discount_amount NUMBER(12,2),
  sale_ts TIMESTAMP_LTZ,
  channel STRING
);

CREATE OR REPLACE TABLE RAW.PURCHASE_ORDERS_RAW (
  file_id STRING,
  po_id STRING,
  supplier_id STRING,
  product_id STRING,
  qty NUMBER,
  price NUMBER(12,2),
  po_ts TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.SHIPMENTS_RAW (
  file_id STRING,
  shipment_id STRING,
  po_id STRING,
  carrier STRING,
  tracking_id STRING,
  shipped_ts TIMESTAMP_LTZ,
  delivered_ts TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE RAW.PROMOTIONS_RAW (
  file_id STRING,
  promo_id STRING,
  promo_name STRING,
  start_ts TIMESTAMP_LTZ,
  end_ts TIMESTAMP_LTZ,
  discount_pct NUMBER
);

----------------------------------------
-- 3) Create CORE curated tables
----------------------------------------
USE SCHEMA CORE;

CREATE OR REPLACE TABLE CORE.CUSTOMERS (
  customer_id STRING PRIMARY KEY,
  customer_name STRING,
  customer_type STRING,
  email STRING,
  phone STRING,
  city STRING,
  state STRING,
  pin_code STRING,
  division STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.PRODUCTS (
  product_id STRING PRIMARY KEY,
  sku STRING,
  product_name STRING,
  brand STRING,
  category STRING,
  sub_category STRING,
  unit_price NUMBER(10,2),
  uom STRING,
  pack_size STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.STORES (
  store_id STRING PRIMARY KEY,
  store_name STRING,
  store_type STRING,
  city STRING,
  state STRING,
  region STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.SUPPLIERS (
  supplier_id STRING PRIMARY KEY,
  supplier_name STRING,
  contact_email STRING,
  city STRING,
  state STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.DISTRIBUTORS (
  distributor_id STRING PRIMARY KEY,
  distributor_name STRING,
  city STRING,
  state STRING,
  tier STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.DEALERS (
  dealer_id STRING PRIMARY KEY,
  dealer_name STRING,
  city STRING,
  state STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.BRAND_STORES (
  brand_store_id STRING PRIMARY KEY,
  name STRING,
  city STRING,
  state STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.LOCAL_SHOPS (
  shop_id STRING PRIMARY KEY,
  shop_name STRING,
  owner_name STRING,
  city STRING,
  state STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.INDUSTRIAL_CLIENTS (
  client_id STRING PRIMARY KEY,
  client_name STRING,
  industry_segment STRING,
  contact_person STRING,
  contact_email STRING,
  city STRING,
  state STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.PROJECTS (
  project_id STRING PRIMARY KEY,
  project_name STRING,
  client_id STRING,
  start_date TIMESTAMP_LTZ,
  end_date TIMESTAMP_LTZ,
  city STRING,
  state STRING,
  status STRING,
  created_at TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.INVENTORY (
  product_id STRING,
  location_id STRING,
  location_type STRING,
  quantity NUMBER,
  last_updated TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.SALES (
  sale_id STRING PRIMARY KEY,
  customer_id STRING,
  customer_type STRING,
  product_id STRING,
  store_id STRING,
  distributor_id STRING,
  dealer_id STRING,
  brand_store_id STRING,
  supplier_id STRING,
  division STRING,
  quantity NUMBER,
  sale_amount NUMBER(12,2),
  discount_amount NUMBER(12,2),
  sale_ts TIMESTAMP_LTZ,
  channel STRING
);

CREATE OR REPLACE TABLE CORE.PURCHASE_ORDERS (
  po_id STRING PRIMARY KEY,
  supplier_id STRING,
  product_id STRING,
  qty NUMBER,
  price NUMBER(12,2),
  po_ts TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.SHIPMENTS (
  shipment_id STRING PRIMARY KEY,
  po_id STRING,
  carrier STRING,
  tracking_id STRING,
  shipped_ts TIMESTAMP_LTZ,
  delivered_ts TIMESTAMP_LTZ
);

CREATE OR REPLACE TABLE CORE.PROMOTIONS (
  promo_id STRING PRIMARY KEY,
  promo_name STRING,
  start_ts TIMESTAMP_LTZ,
  end_ts TIMESTAMP_LTZ,
  discount_pct NUMBER
);

----------------------------------------
-- 4) Monitoring tables (enhanced)
----------------------------------------
USE SCHEMA MONITORING;

CREATE OR REPLACE TABLE MONITORING.COPY_LOAD_ERRORS (
  stage_name STRING,
  file_name STRING,
  error_message STRING,
  raw_json STRING,
  retry_count INT DEFAULT 0,
  recorded_ts TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE TABLE MONITORING.PIPE_LOG (
  log_ts TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP,
  source_stage STRING,
  source_file STRING,
  target_table STRING,
  action STRING,
  rows_loaded INT,
  notes STRING
);

CREATE OR REPLACE TABLE MONITORING.PROCESSED_FILES (
  file_name STRING,
  stage_name STRING,
  file_hash STRING,
  file_size FLOAT,
  loaded_ts TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP,
  notes STRING
);

CREATE OR REPLACE STAGE MONITORING.MONITORING_LOG_STAGE
  FILE_FORMAT = (TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 1)
  COMMENT = 'Holds exported monitoring logs for download';

CREATE OR REPLACE TABLE MONITORING.ALERT_QUEUE (
  alert_ts TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP,
  stage_name STRING,
  file_name STRING,
  error_message STRING,
  processed BOOLEAN DEFAULT FALSE
);

----------------------------------------
-- 5) Streams on RAW tables
----------------------------------------
USE SCHEMA RAW;

CREATE OR REPLACE STREAM RAW.CUSTOMERS_RAW_STREAM ON TABLE RAW.CUSTOMERS_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.PRODUCTS_RAW_STREAM ON TABLE RAW.PRODUCTS_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.STORES_RAW_STREAM ON TABLE RAW.STORES_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.SUPPLIERS_RAW_STREAM ON TABLE RAW.SUPPLIERS_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.DISTRIBUTORS_RAW_STREAM ON TABLE RAW.DISTRIBUTORS_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.DEALERS_RAW_STREAM ON TABLE RAW.DEALERS_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.BRANDSTORES_RAW_STREAM ON TABLE RAW.BRANDSTORES_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.LOCALSHOPS_RAW_STREAM ON TABLE RAW.LOCALSHOPS_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.INDUSTRIAL_CLIENTS_RAW_STREAM ON TABLE RAW.INDUSTRIAL_CLIENTS_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.PROJECTS_RAW_STREAM ON TABLE RAW.PROJECTS_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.INVENTORY_RAW_STREAM ON TABLE RAW.INVENTORY_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.SALES_RAW_STREAM ON TABLE RAW.SALES_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.PURCHASE_ORDERS_RAW_STREAM ON TABLE RAW.PURCHASE_ORDERS_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.SHIPMENTS_RAW_STREAM ON TABLE RAW.SHIPMENTS_RAW APPEND_ONLY = FALSE;
CREATE OR REPLACE STREAM RAW.PROMOTIONS_RAW_STREAM ON TABLE RAW.PROMOTIONS_RAW APPEND_ONLY = FALSE;

----------------------------------------
-- 6) Stream-based MERGE procedures (one per object)
----------------------------------------
USE SCHEMA RAW;

-- Customers
CREATE OR REPLACE PROCEDURE RAW.MERGE_CUSTOMERS_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.CUSTOMERS tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.CUSTOMERS_RAW_STREAM) src
ON tgt.customer_id = src.customer_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  customer_name = src.customer_name,
  customer_type = src.customer_type,
  email = src.email,
  phone = src.phone,
  city = src.city,
  state = src.state,
  pin_code = src.pin_code,
  division = src.division,
  created_at = src.created_at
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (customer_id, customer_name, customer_type, email, phone, city, state, pin_code, division, created_at)
VALUES (src.customer_id, src.customer_name, src.customer_type, src.email, src.phone, src.city, src.state, src.pin_code, src.division, src.created_at);
$$;

-- Products
CREATE OR REPLACE PROCEDURE RAW.MERGE_PRODUCTS_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.PRODUCTS tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.PRODUCTS_RAW_STREAM) src
ON tgt.product_id = src.product_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  sku = src.sku,
  product_name = src.product_name,
  brand = src.brand,
  category = src.category,
  sub_category = src.sub_category,
  unit_price = src.unit_price,
  uom = src.uom,
  pack_size = src.pack_size,
  created_at = src.created_at
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (product_id, sku, product_name, brand, category, sub_category, unit_price, uom, pack_size, created_at)
VALUES (src.product_id, src.sku, src.product_name, src.brand, src.category, src.sub_category, src.unit_price, src.uom, src.pack_size, src.created_at);
$$;

-- Stores
CREATE OR REPLACE PROCEDURE RAW.MERGE_STORES_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.STORES tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.STORES_RAW_STREAM) src
ON tgt.store_id = src.store_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  store_name = src.store_name,
  store_type = src.store_type,
  city = src.city,
  state = src.state,
  region = src.region,
  created_at = src.created_at
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (store_id, store_name, store_type, city, state, region, created_at)
VALUES (src.store_id, src.store_name, src.store_type, src.city, src.state, src.region, src.created_at);
$$;

-- Suppliers
CREATE OR REPLACE PROCEDURE RAW.MERGE_SUPPLIERS_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.SUPPLIERS tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.SUPPLIERS_RAW_STREAM) src
ON tgt.supplier_id = src.supplier_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  supplier_name = src.supplier_name,
  contact_email = src.contact_email,
  city = src.city,
  state = src.state,
  created_at = src.created_at
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (supplier_id, supplier_name, contact_email, city, state, created_at)
VALUES (src.supplier_id, src.supplier_name, src.contact_email, src.city, src.state, src.created_at);
$$;

-- Distributors
CREATE OR REPLACE PROCEDURE RAW.MERGE_DISTRIBUTORS_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.DISTRIBUTORS tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.DISTRIBUTORS_RAW_STREAM) src
ON tgt.distributor_id = src.distributor_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  distributor_name = src.distributor_name,
  city = src.city,
  state = src.state,
  tier = src.tier,
  created_at = src.created_at
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (distributor_id, distributor_name, city, state, tier, created_at)
VALUES (src.distributor_id, src.distributor_name, src.city, src.state, src.tier, src.created_at);
$$;

-- Dealers
CREATE OR REPLACE PROCEDURE RAW.MERGE_DEALERS_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.DEALERS tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.DEALERS_RAW_STREAM) src
ON tgt.dealer_id = src.dealer_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  dealer_name = src.dealer_name,
  city = src.city,
  state = src.state,
  created_at = src.created_at
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (dealer_id, dealer_name, city, state, created_at)
VALUES (src.dealer_id, src.dealer_name, src.city, src.state, src.created_at);
$$;

-- Brand Stores
CREATE OR REPLACE PROCEDURE RAW.MERGE_BRAND_STORES_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.BRAND_STORES tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.BRANDSTORES_RAW_STREAM) src
ON tgt.brand_store_id = src.brand_store_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  name = src.name,
  city = src.city,
  state = src.state,
  created_at = src.created_at
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (brand_store_id, name, city, state, created_at)
VALUES (src.brand_store_id, src.name, src.city, src.state, src.created_at);
$$;

-- Local Shops
CREATE OR REPLACE PROCEDURE RAW.MERGE_LOCAL_SHOPS_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.LOCAL_SHOPS tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.LOCALSHOPS_RAW_STREAM) src
ON tgt.shop_id = src.shop_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  shop_name = src.shop_name,
  owner_name = src.owner_name,
  city = src.city,
  state = src.state,
  created_at = src.created_at
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (shop_id, shop_name, owner_name, city, state, created_at)
VALUES (src.shop_id, src.shop_name, src.owner_name, src.city, src.state, src.created_at);
$$;

-- Industrial Clients
CREATE OR REPLACE PROCEDURE RAW.MERGE_INDUSTRIAL_CLIENTS_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.INDUSTRIAL_CLIENTS tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.INDUSTRIAL_CLIENTS_RAW_STREAM) src
ON tgt.client_id = src.client_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  client_name = src.client_name,
  industry_segment = src.industry_segment,
  contact_person = src.contact_person,
  contact_email = src.contact_email,
  city = src.city,
  state = src.state,
  created_at = src.created_at
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (client_id, client_name, industry_segment, contact_person, contact_email, city, state, created_at)
VALUES (src.client_id, src.client_name, src.industry_segment, src.contact_person, src.contact_email, src.city, src.state, src.created_at);
$$;

-- Projects
CREATE OR REPLACE PROCEDURE RAW.MERGE_PROJECTS_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.PROJECTS tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.PROJECTS_RAW_STREAM) src
ON tgt.project_id = src.project_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  project_name = src.project_name,
  client_id = src.client_id,
  start_date = src.start_date,
  end_date = src.end_date,
  city = src.city,
  state = src.state,
  status = src.status,
  created_at = src.created_at
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (project_id, project_name, client_id, start_date, end_date, city, state, status, created_at)
VALUES (src.project_id, src.project_name, src.client_id, src.start_date, src.end_date, src.city, src.state, src.status, src.created_at);
$$;

-- Inventory
CREATE OR REPLACE PROCEDURE RAW.MERGE_INVENTORY_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.INVENTORY tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.INVENTORY_RAW_STREAM) src
ON tgt.product_id = src.product_id AND tgt.location_id = src.location_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  location_type = src.location_type,
  quantity = src.quantity,
  last_updated = src.last_updated
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (product_id, location_id, location_type, quantity, last_updated)
VALUES (src.product_id, src.location_id, src.location_type, src.quantity, src.last_updated);
$$;

-- Purchase Orders
CREATE OR REPLACE PROCEDURE RAW.MERGE_PURCHASE_ORDERS_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.PURCHASE_ORDERS tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.PURCHASE_ORDERS_RAW_STREAM) src
ON tgt.po_id = src.po_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  supplier_id = src.supplier_id,
  product_id = src.product_id,
  qty = src.qty,
  price = src.price,
  po_ts = src.po_ts
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (po_id, supplier_id, product_id, qty, price, po_ts)
VALUES (src.po_id, src.supplier_id, src.product_id, src.qty, src.price, src.po_ts);
$$;

-- Shipments
CREATE OR REPLACE PROCEDURE RAW.MERGE_SHIPMENTS_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.SHIPMENTS tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.SHIPMENTS_RAW_STREAM) src
ON tgt.shipment_id = src.shipment_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  po_id = src.po_id,
  carrier = src.carrier,
  tracking_id = src.tracking_id,
  shipped_ts = src.shipped_ts,
  delivered_ts = src.delivered_ts
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (shipment_id, po_id, carrier, tracking_id, shipped_ts, delivered_ts)
VALUES (src.shipment_id, src.po_id, src.carrier, src.tracking_id, src.shipped_ts, src.delivered_ts);
$$;

-- Promotions
CREATE OR REPLACE PROCEDURE RAW.MERGE_PROMOTIONS_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.PROMOTIONS tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.PROMOTIONS_RAW_STREAM) src
ON tgt.promo_id = src.promo_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  promo_name = src.promo_name,
  start_ts = src.start_ts,
  end_ts = src.end_ts,
  discount_pct = src.discount_pct
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (promo_id, promo_name, start_ts, end_ts, discount_pct)
VALUES (src.promo_id, src.promo_name, src.start_ts, src.end_ts, src.discount_pct);
$$;

-- Sales (final)
CREATE OR REPLACE PROCEDURE RAW.MERGE_SALES_STREAM()
RETURNS STRING
LANGUAGE SQL
AS
$$
MERGE INTO CORE.SALES tgt
USING (SELECT *, METADATA$ACTION AS __ACTION FROM RAW.SALES_RAW_STREAM) src
ON tgt.sale_id = src.sale_id
WHEN MATCHED AND src.__ACTION = 'DELETE' THEN DELETE
WHEN MATCHED THEN UPDATE SET
  customer_id = src.customer_id,
  customer_type = src.customer_type,
  product_id = src.product_id,
  store_id = src.store_id,
  distributor_id = src.distributor_id,
  dealer_id = src.dealer_id,
  brand_store_id = src.brand_store_id,
  supplier_id = src.supplier_id,
  division = src.division,
  quantity = src.quantity,
  sale_amount = src.sale_amount,
  discount_amount = src.discount_amount,
  sale_ts = src.sale_ts,
  channel = src.channel
WHEN NOT MATCHED AND src.__ACTION != 'DELETE' THEN INSERT (sale_id, customer_id, customer_type, product_id, store_id, distributor_id, dealer_id, brand_store_id, supplier_id, division, quantity, sale_amount, discount_amount, sale_ts, channel)
VALUES (src.sale_id, src.customer_id, src.customer_type, src.product_id, src.store_id, src.distributor_id, src.dealer_id, src.brand_store_id, src.supplier_id, src.division, src.quantity, src.sale_amount, src.discount_amount, src.sale_ts, src.channel);
$$;

----------------------------------------
-- 7) JS orchestrator: LOAD_AND_MERGE_ALL_STREAM()
----------------------------------------
USE SCHEMA RAW;

CREATE OR REPLACE PROCEDURE RAW.LOAD_AND_MERGE_ALL_STREAM()
RETURNS VARIANT
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
/*
  LOAD_AND_MERGE_ALL_STREAM - JS stored procedure
  - Handles nested file names returned by LIST (e.g., 'customers_stage/customers_5k.csv')
  - Uses fully-qualified stage reference strings like '@PAINTCO_DB.STG.CUSTOMERS_STAGE'
  - Uses file format PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT
*/

var DB = 'PAINTCO_DB';
var mappings = [
  {stage_ref: '@' + DB + '.STG.CUSTOMERS_STAGE', fq_stage: DB + '.STG.CUSTOMERS_STAGE', raw_table: 'RAW.CUSTOMERS_RAW', merge_proc: 'RAW.MERGE_CUSTOMERS_STREAM'},
  {stage_ref: '@' + DB + '.STG.PRODUCTS_STAGE',  fq_stage: DB + '.STG.PRODUCTS_STAGE',  raw_table: 'RAW.PRODUCTS_RAW',  merge_proc: 'RAW.MERGE_PRODUCTS_STREAM'},
  {stage_ref: '@' + DB + '.STG.STORES_STAGE',    fq_stage: DB + '.STG.STORES_STAGE',    raw_table: 'RAW.STORES_RAW',    merge_proc: 'RAW.MERGE_STORES_STREAM'},
  {stage_ref: '@' + DB + '.STG.SUPPLIERS_STAGE', fq_stage: DB + '.STG.SUPPLIERS_STAGE', raw_table: 'RAW.SUPPLIERS_RAW', merge_proc: 'RAW.MERGE_SUPPLIERS_STREAM'},
  {stage_ref: '@' + DB + '.STG.DISTRIBUTORS_STAGE', fq_stage: DB + '.STG.DISTRIBUTORS_STAGE', raw_table: 'RAW.DISTRIBUTORS_RAW', merge_proc: 'RAW.MERGE_DISTRIBUTORS_STREAM'},
  {stage_ref: '@' + DB + '.STG.DEALERS_STAGE', fq_stage: DB + '.STG.DEALERS_STAGE', raw_table: 'RAW.DEALERS_RAW', merge_proc: 'RAW.MERGE_DEALERS_STREAM'},
  {stage_ref: '@' + DB + '.STG.BRANDSTORES_STAGE', fq_stage: DB + '.STG.BRANDSTORES_STAGE', raw_table: 'RAW.BRANDSTORES_RAW', merge_proc: 'RAW.MERGE_BRAND_STORES_STREAM'},
  {stage_ref: '@' + DB + '.STG.LOCALSHOPS_STAGE', fq_stage: DB + '.STG.LOCALSHOPS_STAGE', raw_table: 'RAW.LOCALSHOPS_RAW', merge_proc: 'RAW.MERGE_LOCAL_SHOPS_STREAM'},
  {stage_ref: '@' + DB + '.STG.INDUSTRIAL_CLIENTS_STAGE', fq_stage: DB + '.STG.INDUSTRIAL_CLIENTS_STAGE', raw_table: 'RAW.INDUSTRIAL_CLIENTS_RAW', merge_proc: 'RAW.MERGE_INDUSTRIAL_CLIENTS_STREAM'},
  {stage_ref: '@' + DB + '.STG.PROJECTS_STAGE', fq_stage: DB + '.STG.PROJECTS_STAGE', raw_table: 'RAW.PROJECTS_RAW', merge_proc: 'RAW.MERGE_PROJECTS_STREAM'},
  {stage_ref: '@' + DB + '.STG.INVENTORY_STAGE', fq_stage: DB + '.STG.INVENTORY_STAGE', raw_table: 'RAW.INVENTORY_RAW', merge_proc: 'RAW.MERGE_INVENTORY_STREAM'},
  {stage_ref: '@' + DB + '.STG.PURCHASE_ORDERS_STAGE', fq_stage: DB + '.STG.PURCHASE_ORDERS_STAGE', raw_table: 'RAW.PURCHASE_ORDERS_RAW', merge_proc: 'RAW.MERGE_PURCHASE_ORDERS_STREAM'},
  {stage_ref: '@' + DB + '.STG.SHIPMENTS_STAGE', fq_stage: DB + '.STG.SHIPMENTS_STAGE', raw_table: 'RAW.SHIPMENTS_RAW', merge_proc: 'RAW.MERGE_SHIPMENTS_STREAM'},
  {stage_ref: '@' + DB + '.STG.PROMOTIONS_STAGE', fq_stage: DB + '.STG.PROMOTIONS_STAGE', raw_table: 'RAW.PROMOTIONS_RAW', merge_proc: 'RAW.MERGE_PROMOTIONS_STREAM'},
  {stage_ref: '@' + DB + '.STG.SALES_STAGE', fq_stage: DB + '.STG.SALES_STAGE', raw_table: 'RAW.SALES_RAW', merge_proc: 'RAW.MERGE_SALES_STREAM'}
];

// helper: execute a statement (no result expected)
function exec(sql, binds) {
  if (!binds) binds = [];
  var s = snowflake.createStatement({sqlText: sql, binds: binds});
  return s.execute();
}

// helper: safe log to PIPE_LOG
function logPipe(stage, file, table, action, rows, notes) {
  try {
    var sql = "INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes) VALUES(?,?,?,?,?,?)";
    exec(sql, [stage, file, table, action, rows, notes]);
  } catch(e) {}
}

// helper: safe insert into PROCESSED_FILES
function recordProcessed(stage, file, md5, size, notes) {
  try {
    var sql = "INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes) VALUES(?,?,?,?,?)";
    exec(sql, [file, stage, md5, size, notes]);
  } catch(e) {}
}

// helper: safe alert
function raiseAlert(stage, file, message) {
  try {
    var sql = "INSERT INTO MONITORING.ALERT_QUEUE(stage_name, file_name, error_message) VALUES(?,?,?)";
    exec(sql, [stage, file, message]);
  } catch(e) {}
}

// helper: escape single quotes in JS for SQL injection safety
function esc(s) {
  if (s === null || s === undefined) return '';
  return s.replace(/'/g, "''");
}

try {
  for (var m = 0; m < mappings.length; m++) {
    var map = mappings[m];
    var stageRef = map.stage_ref;   // e.g., @PAINTCO_DB.STG.CUSTOMERS_STAGE
    var fqStage  = map.fq_stage;    // e.g., PAINTCO_DB.STG.CUSTOMERS_STAGE
    var rawTable = map.raw_table;
    var mergeProc = map.merge_proc;

    // LIST files in stage (returns rows with columns: name, size, md5, last_modified)
    var listSql = "LIST " + stageRef;
    var listStmt = snowflake.createStatement({sqlText: listSql});
    var rs = listStmt.execute();

    var files = [];
    while (rs.next()) {
      // column positions from LIST: 1 = name, 2 = size, 3 = md5, 4 = last_modified
      var fname = rs.getColumnValue(1);
      var fsize = rs.getColumnValue(2);
      var fmd5  = rs.getColumnValue(3);
      // skip folder markers (end with '/')
      if (!fname) continue;
      files.push({name: fname, size: fsize, md5: fmd5});
    }

    if (files.length === 0) {
      logPipe(fqStage, '(none)', rawTable, 'COPY_EMPTY', 0, 'No files in stage');
      continue;
    }

    // iterate each file row that LIST returned
    for (var i = 0; i < files.length; i++) {
      var f = files[i];
      try {
        if (!f.name || f.name.slice(-1) === '/') {
          // skip directory pseudo entries
          continue;
        }

        // Detect nested prefix and split it
        var prefix = '';
        var fileNameOnly = f.name;
        if (f.name.includes('/')) {
            var parts = f.name.split('/');
            prefix = parts.slice(0, -1).join('/') + '/';
            fileNameOnly = parts[parts.length - 1];
        }

        var copySql = "COPY INTO " + rawTable +
                      " FROM " + stageRef + "/" + prefix +
                      " FILES = ('" + esc(fileNameOnly) + "')" +
                      " FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')" +
                      " ON_ERROR = 'CONTINUE'";

        // execute COPY; returns a ResultSet we can inspect
        var copyStmt = snowflake.createStatement({sqlText: copySql});
        var copyRs = copyStmt.execute();

        // COPY returns 1 row per file, attempt to read rows_loaded column if present
        var rowsLoaded = 0;
        try {
          if (copyRs.next()) {
            try { rowsLoaded = Number(copyRs.getColumnValue(4)) || 0; } catch(e) { rowsLoaded = 0; }
          }
        } catch(e) {
          rowsLoaded = 0;
        }

        // Log COPY result
        logPipe(fqStage, f.name, rawTable, 'COPY_RESULT', rowsLoaded, 'Copied file');

        // If no rows loaded, record and continue (do not remove file so it can be examined)
        if (rowsLoaded === 0) {
          recordProcessed(fqStage, f.name, f.md5, Number(f.size || 0), 'COPY_ZERO_ROWS');
          continue;
        }

        // Call merge procedure which reads the RAW.*_STREAM and applies CDC merge to CORE
        try {
          var callSql = "CALL " + mergeProc + "();";
          exec(callSql);
          logPipe(fqStage, f.name, rawTable, 'MERGE_OK', rowsLoaded, 'Merge applied');
        } catch(mergeErr) {
          logPipe(fqStage, f.name, rawTable, 'MERGE_ERROR', rowsLoaded, mergeErr.message);
          raiseAlert(fqStage, f.name, 'MERGE_ERROR: ' + mergeErr.message);
          // keep file for investigation, do NOT remove
          continue;
        }

        // Insert PROCESSED_FILES record
        recordProcessed(fqStage, f.name, f.md5, Number(f.size || 0), 'loaded');

        // Remove processed file from stage to prevent reprocessing
        try {
          var removeSql = "REMOVE " + stageRef + " '" + esc(f.name) + "'";
          exec(removeSql);
          logPipe(fqStage, f.name, rawTable, 'REMOVE_OK', rowsLoaded, 'Removed file from stage');
        } catch(removeErr) {
          logPipe(fqStage, f.name, rawTable, 'REMOVE_ERROR', rowsLoaded, removeErr.message);
          raiseAlert(fqStage, f.name, 'REMOVE_ERROR: ' + removeErr.message);
        }
      } catch(fileErr) {
        logPipe(fqStage, f.name || '(unknown)', rawTable, 'FILE_PROCESS_ERROR', 0, fileErr.message);
        raiseAlert(fqStage, f.name || '(unknown)', fileErr.message);
      }
    } // end files loop
  } // end mappings loop

  return {status: 'OK', ts: (new Date()).toISOString()};
} catch(e) {
  try {
    var errSql = "INSERT INTO MONITORING.ALERT_QUEUE(stage_name, file_name, error_message) VALUES(?,?,?)";
    snowflake.createStatement({sqlText: errSql, binds: ['LOAD_AND_MERGE_ALL_STREAM','(global)', e.message]}).execute();
  } catch(ee) {}
  throw e;
}
$$;

----------------------------------------
-- 8) Optional helper: Flatten nested folder names into root (noop)
----------------------------------------
USE SCHEMA STG;
CREATE OR REPLACE PROCEDURE STG.NOOP_CLEANUP_STAGE()
RETURNS STRING
LANGUAGE SQL
AS
$$
/* Placeholder - not required. We rely on orchestrator to process nested filenames directly. */
SELECT 'noop';
$$;

----------------------------------------
-- 9) Create a Task to schedule the orchestrator (every 5 minutes)
----------------------------------------
CREATE OR REPLACE TASK RAW.LOAD_AND_MERGE_TASK_STREAM
  WAREHOUSE = 'COMPUTE_WH'
  SCHEDULE = 'USING CRON 0/5 * * * * UTC'
AS
  CALL RAW.LOAD_AND_MERGE_ALL_STREAM();

-- Enable the task when you're ready:
-- ALTER TASK RAW.LOAD_AND_MERGE_TASK_STREAM RESUME;

----------------------------------------
-- 10) Dynamic tables (examples) and monitoring capture
----------------------------------------
USE SCHEMA CORE;

CREATE OR REPLACE DYNAMIC TABLE CORE.SALES_CLEANED
  TARGET_LAG = 'DOWNSTREAM'
  WAREHOUSE = 'COMPUTE_WH'
  REFRESH_MODE = 'INCREMENTAL'
  AS
  SELECT
    s.sale_id,
    s.customer_id,
    c.customer_name,
    s.product_id,
    p.product_name,
    p.brand,
    s.store_id,
    st.store_name,
    s.distributor_id,
    s.dealer_id,
    s.brand_store_id,
    s.supplier_id,
    s.division,
    s.quantity,
    s.sale_amount,
    s.discount_amount,
    s.sale_ts,
    s.channel
  FROM CORE.SALES s
  LEFT JOIN CORE.CUSTOMERS c ON s.customer_id = c.customer_id
  LEFT JOIN CORE.PRODUCTS p ON s.product_id = p.product_id
  LEFT JOIN CORE.STORES st ON s.store_id = st.store_id;

CREATE OR REPLACE DYNAMIC TABLE CORE.DAILY_DIVISION_BRAND_SALES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = 'COMPUTE_WH'
  REFRESH_MODE = 'INCREMENTAL'
  AS
  SELECT
    DATE_TRUNC('day', sale_ts) AS sale_date,
    division,
    brand,
    COUNT(DISTINCT sale_id) AS transactions,
    SUM(quantity) AS units_sold,
    SUM(sale_amount) AS gross_revenue,
    SUM(discount_amount) AS total_discount,
    SUM(sale_amount) - SUM(discount_amount) AS net_revenue
  FROM CORE.SALES_CLEANED
  GROUP BY 1,2,3;

-- Monitoring dynamic table refreshes into PIPE_LOG
USE SCHEMA MONITORING;

CREATE OR REPLACE PROCEDURE MONITORING.CAPTURE_DYNAMIC_REFRESHES()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO MONITORING.PIPE_LOG (source_stage, source_file, target_table, action, notes)
    SELECT 
        NAME, 
        NULL, 
        'DYNAMIC_REFRESH', 
        'DYNAMIC_REFRESH', 
        CONCAT('status=', STATUS, ';rows_changed=', ROWS_CHANGED)
    FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY())
    WHERE DATA_TIMESTAMP >= DATEADD(day, -1, CURRENT_TIMESTAMP());

    RETURN 'CAPTURED_REFRESHES';
END;
$$;

----------------------------------------
-- 11) Enhanced Reload / Error Recovery Blocks (Complete variants for every table)
----------------------------------------

-- ====================================================================
-- (A) FINAL SMART CDC RELOAD  — automatic retry + export logs
-- ====================================================================
USE DATABASE PAINTCO_DB;
USE SCHEMA RAW;

CREATE OR REPLACE TEMP TABLE TMP_STAGE_MAP AS
SELECT * FROM VALUES
('CUSTOMERS_STAGE', 'customers_stage/customers_5k.csv', 'RAW.CUSTOMERS_RAW', 'RAW.MERGE_CUSTOMERS_STREAM'),
('PRODUCTS_STAGE', 'products_stage/products_5k.csv', 'RAW.PRODUCTS_RAW', 'RAW.MERGE_PRODUCTS_STREAM'),
('STORES_STAGE', 'stores_stage/stores_2k.csv', 'RAW.STORES_RAW', 'RAW.MERGE_STORES_STREAM'),
('SUPPLIERS_STAGE', 'suppliers_stage/suppliers_1k.csv', 'RAW.SUPPLIERS_RAW', 'RAW.MERGE_SUPPLIERS_STREAM'),
('DISTRIBUTORS_STAGE', 'distributors_stage/distributors_2k.csv', 'RAW.DISTRIBUTORS_RAW', 'RAW.MERGE_DISTRIBUTORS_STREAM'),
('DEALERS_STAGE', 'dealers_stage/dealers_2k.csv', 'RAW.DEALERS_RAW', 'RAW.MERGE_DEALERS_STREAM'),
('BRANDSTORES_STAGE', 'brandstores_stage/brandstores_1k.csv', 'RAW.BRANDSTORES_RAW', 'RAW.MERGE_BRAND_STORES_STREAM'),
('LOCALSHOPS_STAGE', 'localshops_stage/localshops_5k.csv', 'RAW.LOCALSHOPS_RAW', 'RAW.MERGE_LOCAL_SHOPS_STREAM'),
('INDUSTRIAL_CLIENTS_STAGE', 'industrial_clients_stage/industrial_clients_1k.csv', 'RAW.INDUSTRIAL_CLIENTS_RAW', 'RAW.MERGE_INDUSTRIAL_CLIENTS_STREAM'),
('PROJECTS_STAGE', 'projects_stage/projects_3k.csv', 'RAW.PROJECTS_RAW', 'RAW.MERGE_PROJECTS_STREAM'),
('INVENTORY_STAGE', 'inventory_stage/inventory_10k.csv', 'RAW.INVENTORY_RAW', 'RAW.MERGE_INVENTORY_STREAM'),
('PURCHASE_ORDERS_STAGE', 'purchase_orders_stage/purchase_orders_5k.csv', 'RAW.PURCHASE_ORDERS_RAW', 'RAW.MERGE_PURCHASE_ORDERS_STREAM'),
('SHIPMENTS_STAGE', 'shipments_stage/shipments_4k.csv', 'RAW.SHIPMENTS_RAW', 'RAW.MERGE_SHIPMENTS_STREAM'),
('PROMOTIONS_STAGE', 'promotions_stage/promotions_1k.csv', 'RAW.PROMOTIONS_RAW', 'RAW.MERGE_PROMOTIONS_STREAM'),
('SALES_STAGE', 'sales_stage/sales_25k.csv', 'RAW.SALES_RAW', 'RAW.MERGE_SALES_STREAM')
AS T(STAGE_NAME, FILE_NAME, RAW_TABLE, MERGE_PROC);

BEGIN
  FOR rec IN (SELECT * FROM TMP_STAGE_MAP)
  DO
    LET STAGE_FQ = 'PAINTCO_DB.STG.' || rec.STAGE_NAME;
    LET FILEPATH = rec.FILE_NAME;
    LET RAW_TBL = rec.RAW_TABLE;
    LET MERGE_PROC = rec.MERGE_PROC;

    BEGIN
      COPY INTO IDENTIFIER($RAW_TBL)
      FROM @IDENTIFIER($STAGE_FQ)
      FILES = ($FILEPATH)
      FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
      ON_ERROR = 'CONTINUE';

      INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
      SELECT $STAGE_FQ, $FILEPATH, $RAW_TBL, 'COPY_RESULT',
             COALESCE(TO_NUMBER(rows_loaded), 0), 'Initial load'
      FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    EXCEPTION
      WHEN OTHER THEN
        INSERT INTO MONITORING.COPY_LOAD_ERRORS(stage_name, file_name, error_message, raw_json, retry_count)
        VALUES($STAGE_FQ, $FILEPATH, ERROR_MESSAGE(), TO_JSON(RESULT_SCAN(LAST_QUERY_ID())), 0);
    END;

    BEGIN
      CALL IDENTIFIER($MERGE_PROC)();
      INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
      VALUES($STAGE_FQ, $FILEPATH, $RAW_TBL, 'MERGE_OK', 'Stream merged successfully');
    EXCEPTION
      WHEN OTHER THEN
        INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
        VALUES($STAGE_FQ, $FILEPATH, $RAW_TBL, 'MERGE_ERROR', ERROR_MESSAGE());
    END;

    INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
    SELECT name, $STAGE_FQ, md5, size, 'Initial pass'
    FROM TABLE(LIST(@IDENTIFIER($STAGE_FQ)))
    WHERE name = $FILEPATH;

  END FOR;
END;

-- Auto Retry Failed Copies (single retry)
BEGIN
  FOR err IN (
    SELECT DISTINCT stage_name, file_name
    FROM MONITORING.COPY_LOAD_ERRORS
    WHERE retry_count = 0
  )
  DO
    LET STAGE_FQ = err.stage_name;
    LET FILEPATH = err.file_name;

    BEGIN
      COPY INTO IDENTIFIER(REPLACE(SUBSTR($STAGE_FQ, 1, LENGTH($STAGE_FQ)), 'PAINTCO_DB.STG.', 'RAW.'))
      FROM @IDENTIFIER($STAGE_FQ)
      FILES = ($FILEPATH)
      FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
      ON_ERROR = 'CONTINUE';

      UPDATE MONITORING.COPY_LOAD_ERRORS
      SET retry_count = 1
      WHERE stage_name = $STAGE_FQ AND file_name = $FILEPATH;

      INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
      SELECT $STAGE_FQ, $FILEPATH, REPLACE(SUBSTR($STAGE_FQ, 1, LENGTH($STAGE_FQ)), 'PAINTCO_DB.STG.', 'RAW.'),
             'COPY_RETRY_RESULT', COALESCE(TO_NUMBER(rows_loaded),0), 'Retried after error'
      FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    EXCEPTION
      WHEN OTHER THEN
        INSERT INTO MONITORING.COPY_LOAD_ERRORS(stage_name, file_name, error_message, raw_json, retry_count)
        VALUES($STAGE_FQ, $FILEPATH, 'Retry failed: ' || ERROR_MESSAGE(), TO_JSON(RESULT_SCAN(LAST_QUERY_ID())), 2);
        INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
        VALUES($STAGE_FQ, $FILEPATH, REPLACE(SUBSTR($STAGE_FQ, 1, LENGTH($STAGE_FQ)), 'PAINTCO_DB.STG.', 'RAW.'), 'COPY_RETRY_ERROR', 0, ERROR_MESSAGE());
    END;
  END FOR;
END;

-- Export Monitoring Logs to Stage (for Snowsight Download)
COPY INTO @MONITORING.MONITORING_LOG_STAGE/pipe_log_$(CURRENT_TIMESTAMP())_export.csv
FROM (SELECT * FROM MONITORING.PIPE_LOG ORDER BY log_ts DESC)
FILE_FORMAT = (TYPE='CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' COMPRESSION='NONE')
OVERWRITE = TRUE;

COPY INTO @MONITORING.MONITORING_LOG_STAGE/copy_errors_$(CURRENT_TIMESTAMP())_export.csv
FROM (SELECT * FROM MONITORING.COPY_LOAD_ERRORS ORDER BY recorded_ts DESC)
FILE_FORMAT = (TYPE='CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' COMPRESSION='NONE')
OVERWRITE = TRUE;

-- ====================================================================
-- (B) SAFE RELOAD BLOCK — No file removal, useful for debugging
-- ====================================================================
USE DATABASE PAINTCO_DB;
USE SCHEMA RAW;

-- Safe reload: attempts COPY -> MERGE -> log and does NOT remove files from stage
CREATE OR REPLACE TEMP TABLE TMP_STAGE_MAP_SAFE AS
SELECT * FROM VALUES
('CUSTOMERS_STAGE', 'customers_stage/customers_5k.csv', 'RAW.CUSTOMERS_RAW', 'RAW.MERGE_CUSTOMERS_STREAM'),
('PRODUCTS_STAGE', 'products_stage/products_5k.csv', 'RAW.PRODUCTS_RAW', 'RAW.MERGE_PRODUCTS_STREAM'),
('STORES_STAGE', 'stores_stage/stores_2k.csv', 'RAW.STORES_RAW', 'RAW.MERGE_STORES_STREAM'),
('SUPPLIERS_STAGE', 'suppliers_stage/suppliers_1k.csv', 'RAW.SUPPLIERS_RAW', 'RAW.MERGE_SUPPLIERS_STREAM'),
('DISTRIBUTORS_STAGE', 'distributors_stage/distributors_2k.csv', 'RAW.DISTRIBUTORS_RAW', 'RAW.MERGE_DISTRIBUTORS_STREAM'),
('DEALERS_STAGE', 'dealers_stage/dealers_2k.csv', 'RAW.DEALERS_RAW', 'RAW.MERGE_DEALERS_STREAM'),
('BRANDSTORES_STAGE', 'brandstores_stage/brandstores_1k.csv', 'RAW.BRANDSTORES_RAW', 'RAW.MERGE_BRAND_STORES_STREAM'),
('LOCALSHOPS_STAGE', 'localshops_stage/localshops_5k.csv', 'RAW.LOCALSHOPS_RAW', 'RAW.MERGE_LOCAL_SHOPS_STREAM'),
('INDUSTRIAL_CLIENTS_STAGE', 'industrial_clients_stage/industrial_clients_1k.csv', 'RAW.INDUSTRIAL_CLIENTS_RAW', 'RAW.MERGE_INDUSTRIAL_CLIENTS_STREAM'),
('PROJECTS_STAGE', 'projects_stage/projects_3k.csv', 'RAW.PROJECTS_RAW', 'RAW.MERGE_PROJECTS_STREAM'),
('INVENTORY_STAGE', 'inventory_stage/inventory_10k.csv', 'RAW.INVENTORY_RAW', 'RAW.MERGE_INVENTORY_STREAM'),
('PURCHASE_ORDERS_STAGE', 'purchase_orders_stage/purchase_orders_5k.csv', 'RAW.PURCHASE_ORDERS_RAW', 'RAW.MERGE_PURCHASE_ORDERS_STREAM'),
('SHIPMENTS_STAGE', 'shipments_stage/shipments_4k.csv', 'RAW.SHIPMENTS_RAW', 'RAW.MERGE_SHIPMENTS_STREAM'),
('PROMOTIONS_STAGE', 'promotions_stage/promotions_1k.csv', 'RAW.PROMOTIONS_RAW', 'RAW.MERGE_PROMOTIONS_STREAM'),
('SALES_STAGE', 'sales_stage/sales_25k.csv', 'RAW.SALES_RAW', 'RAW.MERGE_SALES_STREAM')
AS T(STAGE_NAME, FILE_NAME, RAW_TABLE, MERGE_PROC);

BEGIN
  FOR rec IN (SELECT * FROM TMP_STAGE_MAP_SAFE)
  DO
    LET STAGE_FQ = 'PAINTCO_DB.STG.' || rec.STAGE_NAME;
    LET FILEPATH = rec.FILE_NAME;
    LET RAW_TBL = rec.RAW_TABLE;
    LET MERGE_PROC = rec.MERGE_PROC;

    BEGIN
      COPY INTO IDENTIFIER($RAW_TBL)
      FROM @IDENTIFIER($STAGE_FQ)
      FILES = ($FILEPATH)
      FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
      ON_ERROR = 'CONTINUE';

      INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
      SELECT $STAGE_FQ, $FILEPATH, $RAW_TBL, 'COPY_RESULT',
             COALESCE(TO_NUMBER(rows_loaded), 0), 'manual safe reload (no remove)'
      FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    EXCEPTION
      WHEN OTHER THEN
        INSERT INTO MONITORING.COPY_LOAD_ERRORS(stage_name, file_name, error_message, raw_json, retry_count)
        VALUES($STAGE_FQ, $FILEPATH, ERROR_MESSAGE(), TO_JSON(RESULT_SCAN(LAST_QUERY_ID())), 0);
        INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
        VALUES($STAGE_FQ, $FILEPATH, $RAW_TBL, 'COPY_ERROR', 0, ERROR_MESSAGE());
    END;

    BEGIN
      CALL IDENTIFIER($MERGE_PROC)();
      INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
      VALUES($STAGE_FQ, $FILEPATH, $RAW_TBL, 'MERGE_OK', 'Initial stream merge');
    EXCEPTION
      WHEN OTHER THEN
        INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
        VALUES($STAGE_FQ, $FILEPATH, $RAW_TBL, 'MERGE_ERROR', ERROR_MESSAGE());
    END;

    INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
    SELECT name, $STAGE_FQ, md5, size, 'safe-no-remove'
    FROM TABLE(LIST(@IDENTIFIER($STAGE_FQ)))
    WHERE name = $FILEPATH;

  END FOR;
END;

-- ====================================================================
-- (C) BULK RELOAD BLOCK — per-file manual reload, merge, log, and remove
-- ====================================================================
USE DATABASE PAINTCO_DB;
USE SCHEMA RAW;

-- Recreate file format to ensure tolerance (already created but kept here for idempotence)
CREATE OR REPLACE FILE FORMAT PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  TRIM_SPACE = TRUE
  NULL_IF = ('', 'NULL')
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

--------------------------------------------------------------------------------
-- CUSTOMERS
--------------------------------------------------------------------------------
COPY INTO RAW.CUSTOMERS_RAW
FROM @PAINTCO_DB.STG.CUSTOMERS_STAGE/customers_stage
FILES = ('customers_5k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.CUSTOMERS_STAGE', 'customers_stage/customers_5k.csv', 'RAW.CUSTOMERS_RAW', 'COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0), 'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_CUSTOMERS_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.CUSTOMERS_STAGE','customers_stage/customers_5k.csv','RAW.CUSTOMERS_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name, 'PAINTCO_DB.STG.CUSTOMERS_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.CUSTOMERS_STAGE))
WHERE name = 'customers_stage/customers_5k.csv';

-- REMOVE @PAINTCO_DB.STG.CUSTOMERS_STAGE 'customers_stage/customers_5k.csv';

--------------------------------------------------------------------------------
-- PRODUCTS
--------------------------------------------------------------------------------
COPY INTO RAW.PRODUCTS_RAW
FROM @PAINTCO_DB.STG.PRODUCTS_STAGE/products_stage
FILES = ('products_5k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.PRODUCTS_STAGE', 'products_stage/products_5k.csv', 'RAW.PRODUCTS_RAW', 'COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0), 'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_PRODUCTS_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.PRODUCTS_STAGE','products_stage/products_5k.csv','RAW.PRODUCTS_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.PRODUCTS_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.PRODUCTS_STAGE))
WHERE name = 'products_stage/products_5k.csv';

-- REMOVE @PAINTCO_DB.STG.PRODUCTS_STAGE 'products_stage/products_5k.csv';

--------------------------------------------------------------------------------
-- STORES
--------------------------------------------------------------------------------
COPY INTO RAW.STORES_RAW
FROM @PAINTCO_DB.STG.STORES_STAGE/stores_stage
FILES = ('stores_2k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.STORES_STAGE','stores_stage/stores_2k.csv','RAW.STORES_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_STORES_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.STORES_STAGE','stores_stage/stores_2k.csv','RAW.STORES_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.STORES_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.STORES_STAGE))
WHERE name = 'stores_stage/stores_2k.csv';

-- REMOVE @PAINTCO_DB.STG.STORES_STAGE 'stores_stage/stores_2k.csv';

--------------------------------------------------------------------------------
-- SUPPLIERS
--------------------------------------------------------------------------------
COPY INTO RAW.SUPPLIERS_RAW
FROM @PAINTCO_DB.STG.SUPPLIERS_STAGE/suppliers_stage
FILES = ('suppliers_1k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.SUPPLIERS_STAGE','suppliers_stage/suppliers_1k.csv','RAW.SUPPLIERS_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_SUPPLIERS_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.SUPPLIERS_STAGE','suppliers_stage/suppliers_1k.csv','RAW.SUPPLIERS_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.SUPPLIERS_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.SUPPLIERS_STAGE))
WHERE name = 'suppliers_stage/suppliers_1k.csv';

-- REMOVE @PAINTCO_DB.STG.SUPPLIERS_STAGE 'suppliers_stage/suppliers_1k.csv';

--------------------------------------------------------------------------------
-- DISTRIBUTORS
--------------------------------------------------------------------------------
COPY INTO RAW.DISTRIBUTORS_RAW
FROM @PAINTCO_DB.STG.DISTRIBUTORS_STAGE/distributors_stage
FILES = ('distributors_2k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.DISTRIBUTORS_STAGE','distributors_stage/distributors_2k.csv','RAW.DISTRIBUTORS_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_DISTRIBUTORS_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.DISTRIBUTORS_STAGE','distributors_stage/distributors_2k.csv','RAW.DISTRIBUTORS_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.DISTRIBUTORS_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.DISTRIBUTORS_STAGE))
WHERE name = 'distributors_stage/distributors_2k.csv';

-- REMOVE @PAINTCO_DB.STG.DISTRIBUTORS_STAGE 'distributors_stage/distributors_2k.csv';

--------------------------------------------------------------------------------
-- DEALERS
--------------------------------------------------------------------------------
COPY INTO RAW.DEALERS_RAW
FROM @PAINTCO_DB.STG.DEALERS_STAGE/dealers_stage
FILES = ('dealers_2k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.DEALERS_STAGE','dealers_stage/dealers_2k.csv','RAW.DEALERS_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_DEALERS_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.DEALERS_STAGE','dealers_stage/dealers_2k.csv','RAW.DEALERS_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.DEALERS_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.DEALERS_STAGE))
WHERE name = 'dealers_stage/dealers_2k.csv';

-- REMOVE @PAINTCO_DB.STG.DEALERS_STAGE 'dealers_stage/dealers_2k.csv';

--------------------------------------------------------------------------------
-- BRAND STORES
--------------------------------------------------------------------------------
COPY INTO RAW.BRANDSTORES_RAW
FROM @PAINTCO_DB.STG.BRANDSTORES_STAGE/brandstores_stage
FILES = ('brandstores_1k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.BRANDSTORES_STAGE','brandstores_stage/brandstores_1k.csv','RAW.BRANDSTORES_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_BRAND_STORES_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.BRANDSTORES_STAGE','brandstores_stage/brandstores_1k.csv','RAW.BRANDSTORES_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.BRANDSTORES_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.BRANDSTORES_STAGE))
WHERE name = 'brandstores_stage/brandstores_1k.csv';

-- REMOVE @PAINTCO_DB.STG.BRANDSTORES_STAGE 'brandstores_stage/brandstores_1k.csv';

--------------------------------------------------------------------------------
-- LOCAL SHOPS
--------------------------------------------------------------------------------
COPY INTO RAW.LOCALSHOPS_RAW
FROM @PAINTCO_DB.STG.LOCALSHOPS_STAGE/localshops_stage
FILES = ('localshops_5k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.LOCALSHOPS_STAGE','localshops_stage/localshops_5k.csv','RAW.LOCALSHOPS_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_LOCAL_SHOPS_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.LOCALSHOPS_STAGE','localshops_stage/localshops_5k.csv','RAW.LOCALSHOPS_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.LOCALSHOPS_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.LOCALSHOPS_STAGE))
WHERE name = 'localshops_stage/localshops_5k.csv';

-- REMOVE @PAINTCO_DB.STG.LOCALSHOPS_STAGE 'localshops_stage/localshops_5k.csv';

--------------------------------------------------------------------------------
-- INDUSTRIAL CLIENTS
--------------------------------------------------------------------------------
COPY INTO RAW.INDUSTRIAL_CLIENTS_RAW
FROM @PAINTCO_DB.STG.INDUSTRIAL_CLIENTS_STAGE/industrial_clients_stage
FILES = ('industrial_clients_1k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.INDUSTRIAL_CLIENTS_STAGE','industrial_clients_stage/industrial_clients_1k.csv','RAW.INDUSTRIAL_CLIENTS_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_INDUSTRIAL_CLIENTS_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.INDUSTRIAL_CLIENTS_STAGE','industrial_clients_stage/industrial_clients_1k.csv','RAW.INDUSTRIAL_CLIENTS_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.INDUSTRIAL_CLIENTS_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.INDUSTRIAL_CLIENTS_STAGE))
WHERE name = 'industrial_clients_stage/industrial_clients_1k.csv';

-- REMOVE @PAINTCO_DB.STG.INDUSTRIAL_CLIENTS_STAGE 'industrial_clients_stage/industrial_clients_1k.csv';

--------------------------------------------------------------------------------
-- PROJECTS (single file example)
--------------------------------------------------------------------------------
COPY INTO RAW.PROJECTS_RAW
FROM @PAINTCO_DB.STG.PROJECTS_STAGE/projects_stage
FILES = ('projects_3k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.PROJECTS_STAGE','projects_stage/projects_3k.csv','RAW.PROJECTS_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_PROJECTS_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.PROJECTS_STAGE','projects_stage/projects_3k.csv','RAW.PROJECTS_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.PROJECTS_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.PROJECTS_STAGE))
WHERE name = 'projects_stage/projects_3k.csv';

-- REMOVE @PAINTCO_DB.STG.PROJECTS_STAGE 'projects_stage/projects_3k.csv';

--------------------------------------------------------------------------------
-- INVENTORY
--------------------------------------------------------------------------------
COPY INTO RAW.INVENTORY_RAW
FROM @PAINTCO_DB.STG.INVENTORY_STAGE/inventory_stage
FILES = ('inventory_10k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.INVENTORY_STAGE','inventory_stage/inventory_10k.csv','RAW.INVENTORY_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_INVENTORY_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.INVENTORY_STAGE','inventory_stage/inventory_10k.csv','RAW.INVENTORY_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.INVENTORY_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.INVENTORY_STAGE))
WHERE name = 'inventory_stage/inventory_10k.csv';

-- REMOVE @PAINTCO_DB.STG.INVENTORY_STAGE 'inventory_stage/inventory_10k.csv';

--------------------------------------------------------------------------------
-- PURCHASE ORDERS
--------------------------------------------------------------------------------
COPY INTO RAW.PURCHASE_ORDERS_RAW
FROM @PAINTCO_DB.STG.PURCHASE_ORDERS_STAGE/purchase_orders_stage
FILES = ('purchase_orders_5k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.PURCHASE_ORDERS_STAGE','purchase_orders_stage/purchase_orders_5k.csv','RAW.PURCHASE_ORDERS_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_PURCHASE_ORDERS_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.PURCHASE_ORDERS_STAGE','purchase_orders_stage/purchase_orders_5k.csv','RAW.PURCHASE_ORDERS_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.PURCHASE_ORDERS_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.PURCHASE_ORDERS_STAGE))
WHERE name = 'purchase_orders_stage/purchase_orders_5k.csv';

-- REMOVE @PAINTCO_DB.STG.PURCHASE_ORDERS_STAGE 'purchase_orders_stage/purchase_orders_5k.csv';

--------------------------------------------------------------------------------
-- SHIPMENTS
--------------------------------------------------------------------------------
COPY INTO RAW.SHIPMENTS_RAW
FROM @PAINTCO_DB.STG.SHIPMENTS_STAGE/shipments_stage
FILES = ('shipments_4k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.SHIPMENTS_STAGE','shipments_stage/shipments_4k.csv','RAW.SHIPMENTS_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_SHIPMENTS_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.SHIPMENTS_STAGE','shipments_stage/shipments_4k.csv','RAW.SHIPMENTS_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.SHIPMENTS_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.SHIPMENTS_STAGE))
WHERE name = 'shipments_stage/shipments_4k.csv';

-- REMOVE @PAINTCO_DB.STG.SHIPMENTS_STAGE 'shipments_stage/shipments_4k.csv';

--------------------------------------------------------------------------------
-- PROMOTIONS
--------------------------------------------------------------------------------
COPY INTO RAW.PROMOTIONS_RAW
FROM @PAINTCO_DB.STG.PROMOTIONS_STAGE/promotions_stage
FILES = ('promotions_1k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.PROMOTIONS_STAGE','promotions_stage/promotions_1k.csv','RAW.PROMOTIONS_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_PROMOTIONS_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.PROMOTIONS_STAGE','promotions_stage/promotions_1k.csv','RAW.PROMOTIONS_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.PROMOTIONS_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.PROMOTIONS_STAGE))
WHERE name = 'promotions_stage/promotions_1k.csv';

-- REMOVE @PAINTCO_DB.STG.PROMOTIONS_STAGE 'promotions_stage/promotions_1k.csv';

--------------------------------------------------------------------------------
-- SALES
--------------------------------------------------------------------------------
COPY INTO RAW.SALES_RAW
FROM @PAINTCO_DB.STG.SALES_STAGE/sales_stage
FILES = ('sales_25k.csv')
FILE_FORMAT = (FORMAT_NAME = 'PAINTCO_DB.PUBLIC.PAINTCO_CSV_FORMAT')
ON_ERROR = 'CONTINUE';

INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, rows_loaded, notes)
SELECT 'PAINTCO_DB.STG.SALES_STAGE','sales_stage/sales_25k.csv','RAW.SALES_RAW','COPY_RESULT',
       COALESCE(TO_NUMBER(rows_loaded),0),'manual reload'
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

CALL RAW.MERGE_SALES_STREAM();
INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
VALUES('PAINTCO_DB.STG.SALES_STAGE','sales_stage/sales_25k.csv','RAW.SALES_RAW','MERGE_OK','merged');

INSERT INTO MONITORING.PROCESSED_FILES(file_name, stage_name, file_hash, file_size, notes)
SELECT name,'PAINTCO_DB.STG.SALES_STAGE', md5, size, 'reloaded'
FROM TABLE(LIST(@PAINTCO_DB.STG.SALES_STAGE))
WHERE name = 'sales_stage/sales_25k.csv';

-- REMOVE @PAINTCO_DB.STG.SALES_STAGE 'sales_stage/sales_25k.csv';

--------------------------------------------------------------------------------
-- 12) Quick verification queries (run after manual or automated runs)
--------------------------------------------------------------------------------
-- SELECT * FROM MONITORING.PIPE_LOG ORDER BY log_ts DESC LIMIT 50;
-- SELECT * FROM MONITORING.COPY_LOAD_ERRORS ORDER BY recorded_ts DESC LIMIT 50;
-- SELECT * FROM MONITORING.PROCESSED_FILES ORDER BY loaded_ts DESC LIMIT 50;
-- SELECT COUNT(*) AS RAW_CUSTOMERS FROM RAW.CUSTOMERS_RAW;
-- SELECT COUNT(*) AS CORE_CUSTOMERS FROM CORE.CUSTOMERS;

-- End of full deploy script
-- ====================================================================================
"""
# write to file
file_path = "/mnt/data/paintco_full_pipeline.sql"
with open(file_path, "w", encoding="utf-8") as f:
    f.write(sql_content)

# Provide path for user download
file_path


-- ====================================================================================
-- PaintCo CDC ELT Pipeline — Task Enable & Maintenance Schedule
-- ====================================================================================
USE ROLE ACCOUNTADMIN;
USE DATABASE PAINTCO_DB;
USE SCHEMA RAW;

-- 1️⃣ Resume Orchestrator Task
ALTER TASK IF EXISTS RAW.LOAD_AND_MERGE_TASK_STREAM RESUME;

-- 2️⃣ Verify Task State
SHOW TASKS LIKE 'LOAD_AND_MERGE_TASK_STREAM';

-- 3️⃣ (Optional) Run Once Manually to Confirm
CALL RAW.LOAD_AND_MERGE_ALL_STREAM();

-- ====================================================================================
-- 🧭 Maintenance Windows (Daily Pause & Resume)
-- ====================================================================================

-- ⚙️ Create maintenance helper procedures (optional)
USE SCHEMA RAW;

CREATE OR REPLACE PROCEDURE RAW.PAUSE_ELT_TASK()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    ALTER TASK IF EXISTS RAW.LOAD_AND_MERGE_TASK_STREAM SUSPEND;
    INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
    VALUES('SYSTEM', 'N/A', 'TASK_MAINT', 'TASK_PAUSE', 'Task suspended for maintenance');
    RETURN 'TASK_PAUSED';
END;
$$;

CREATE OR REPLACE PROCEDURE RAW.RESUME_ELT_TASK()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    ALTER TASK IF EXISTS RAW.LOAD_AND_MERGE_TASK_STREAM RESUME;
    INSERT INTO MONITORING.PIPE_LOG(source_stage, source_file, target_table, action, notes)
    VALUES('SYSTEM', 'N/A', 'TASK_MAINT', 'TASK_RESUME', 'Task resumed after maintenance');
    RETURN 'TASK_RESUMED';
END;
$$;

-- ====================================================================================
-- 🕒 Scheduled Maintenance Tasks (UTC Time)
-- ====================================================================================

-- Pause Task Every Day at 03:00 UTC
CREATE OR REPLACE TASK RAW.MAINTENANCE_PAUSE_TASK
  WAREHOUSE = 'COMPUTE_WH'
  SCHEDULE = 'USING CRON 0 3 * * * UTC'
AS
  CALL RAW.PAUSE_ELT_TASK();

-- Resume Task Every Day at 04:00 UTC
CREATE OR REPLACE TASK RAW.MAINTENANCE_RESUME_TASK
  WAREHOUSE = 'COMPUTE_WH'
  SCHEDULE = 'USING CRON 0 4 * * * UTC'
AS
  CALL RAW.RESUME_ELT_TASK();

-- ====================================================================================
-- 📊 Optional: Refresh Dynamic Tables Manually
-- ====================================================================================
USE SCHEMA CORE;

ALTER DYNAMIC TABLE CORE.SALES_CLEANED REFRESH;
ALTER DYNAMIC TABLE CORE.DAILY_DIVISION_BRAND_SALES REFRESH;

-- ====================================================================================
-- ✅ Verification Queries
-- ====================================================================================
USE SCHEMA MONITORING;

SELECT 'Task Status' AS label, state, schedule, last_suspended_on, last_resumed_on
FROM TABLE(INFORMATION_SCHEMA.TASKS())
WHERE name IN ('LOAD_AND_MERGE_TASK_STREAM','MAINTENANCE_PAUSE_TASK','MAINTENANCE_RESUME_TASK');

SELECT * FROM MONITORING.PIPE_LOG ORDER BY log_ts DESC LIMIT 20;

-- ====================================================================================
-- End of Task Enable & Maintenance Script
-- ====================================================================================

