CREATE OR REPLACE DATABASE POS_DEMO;
CREATE OR REPLACE SCHEMA POS_DEMO.RAW;
CREATE OR REPLACE SCHEMA POS_DEMO.CURATED;

USE DATABASE POS_DEMO;
USE SCHEMA RAW;

--DROP DATABASE POS_DEMO;
--DROP SCHEMA RAW;
---------------------------------------------
-- 2️⃣  RAW LAYER: Load JSON Data : table to hold NDJSON
---------------------------------------------
CREATE OR REPLACE TABLE RAW_POS_DATA (
  json_data VARIANT
);

--DROP TABLE RAW_POS_DATA;

-- 1.1 Create file format and stage (NDJSON / ND JSON lines)

CREATE OR REPLACE FILE FORMAT FF_JSON_NDJSON
  TYPE = JSON
  STRIP_OUTER_ARRAY = FALSE;

CREATE OR REPLACE STAGE STG_POS_JSON FILE_FORMAT = FF_JSON_NDJSON;

--JUST TO CHECK THAT THE TABLE CREATED IN RAW HAS NO DATA IN IT RUN IT RESULT WILL BE EMPTY OR ZERO 

SELECT * FROM POS_DEMO.RAW.RAW_POS_DATA;

SELECT COUNT(*) AS rows_loaded FROM POS_DEMO.RAW.RAW_POS_DATA; --0

-- 1.2 Copy from stage into RAW_POS_DATA
-- NOTE: upload the file to the stage first using Web UI.
--OR
-- upload the file to the stage first using SnowSQL (PUT command)
-- Example (SnowSQL):POS_DEMO.RAW.STG_POS_JSON
-- PUT file://retail_pos_12000.json @STG_POS_JSON AUTO_COMPRESS=TRUE;

PUT file://retail_pos_12000.json @STG_POS_JSON AUTO_COMPRESS=TRUE;

COPY INTO RAW_POS_DATA
FROM (
  SELECT $1
  FROM @STG_POS_JSON (PATTERN => '.*retail_pos_12000.*')
)
FILE_FORMAT = (FORMAT_NAME = FF_JSON_NDJSON)
ON_ERROR = 'ABORT_STATEMENT'; ---- Copy executed with FULL file processed.

-- Sanity checks , JUST TO SEE NOW WHETHER FILE IS LOADED TO TABLE FROM STAGE OR NOT  ON SUCCESS IT WILL GIVE COUNT OF 12000

SELECT COUNT(*) AS rows_loaded FROM RAW_POS_DATA; --12000

SELECT * FROM POS_DEMO.RAW.RAW_POS_DATA;

SELECT json_data:event_ts::timestamp_ntz AS ts,
       json_data:product:name::string AS product_name
FROM RAW_POS_DATA
LIMIT 5; 

---------------------------------------------
-- 3️⃣  CURATED LAYER: STAR SCHEMA
---------------------------------------------
USE SCHEMA CURATED;

--DROP SCHEMA CURATED;

-- ✅ FIX: consistent aliasing + dedup logic

-- DIM_PRODUCT: deduplicated latest product attributes per product_id

-- DIM_PRODUCT
CREATE OR REPLACE TABLE DIM_PRODUCT AS
SELECT
  json_data:product:product_id::NUMBER AS PRODUCT_ID,
  json_data:product:name::STRING AS PRODUCT_NAME,
  json_data:product:category::STRING AS CATEGORY,
  json_data:product:brand::STRING AS BRAND,
  COALESCE(json_data:product:attributes:color::STRING, 'Unknown') AS COLOR,
  COALESCE(json_data:product:attributes:size::STRING, 'Unknown') AS SIZE
FROM RAW.RAW_POS_DATA
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY json_data:product:product_id::NUMBER
  ORDER BY json_data:event_ts::TIMESTAMP_NTZ DESC
) = 1;

-- BELOW CODE WILL GIVE DETAILS ABOUT THE SINGLE PRODUCT BASED ON PROVIDED PRODUCT_ID TO CHECK DEDUPLICATION 
SELECT PRODUCT_ID, PRODUCT_NAME, CATEGORY, BRAND, COLOR, SIZE
FROM CURATED.DIM_PRODUCT
WHERE PRODUCT_ID = 1250;

-- DIM_CUSTOMER: deduplicate by customer_id keep latest

-- DIM_CUSTOMER
CREATE OR REPLACE TABLE DIM_CUSTOMER AS
SELECT
  json_data:customer:customer_id::NUMBER AS CUSTOMER_ID,
  json_data:customer:name::STRING AS CUSTOMER_NAME,
  COALESCE(json_data:customer:loyalty_tier::STRING, 'None') AS LOYALTY_TIER
FROM RAW.RAW_POS_DATA
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY json_data:customer:customer_id::NUMBER
  ORDER BY json_data:event_ts::TIMESTAMP_NTZ DESC
) = 1;


-- DIM_STORE: deduplicate by store_id 

-- DIM_STORE
CREATE OR REPLACE TABLE DIM_STORE AS
SELECT
  json_data:store:store_id::NUMBER AS STORE_ID,
  json_data:store:region::STRING AS REGION,
  json_data:store:city::STRING AS CITY
FROM RAW.RAW_POS_DATA
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY json_data:store:store_id::NUMBER
  ORDER BY json_data:event_ts::TIMESTAMP_NTZ DESC
) = 1;

-- FACT TABLE
CREATE OR REPLACE TABLE FCT_SALES AS
SELECT
  json_data:product:product_id::NUMBER AS PRODUCT_ID,
  json_data:customer:customer_id::NUMBER AS CUSTOMER_ID,
  json_data:store:store_id::NUMBER AS STORE_ID,
  TO_TIMESTAMP_NTZ(json_data:event_ts::STRING) AS EVENT_TS,
  json_data:transaction:qty::NUMBER AS QUANTITY,
  json_data:transaction:unit_price::FLOAT AS UNIT_PRICE,
  COALESCE(json_data:transaction:store_discount::FLOAT, 0) AS STORE_DISCOUNT,
  COALESCE(json_data:transaction:loyalty_discount::FLOAT, 0) AS LOYALTY_DISCOUNT,
  COALESCE(json_data:transaction:tax_rate::FLOAT, 0.18) AS TAX_RATE,
  (json_data:transaction:qty::NUMBER * json_data:transaction:unit_price::FLOAT) AS GROSS_AMOUNT,
  json_data:transaction:promo_codes AS PROMO_CODES,
  json_data:transaction:review_comments AS REVIEW_COMMENTS
FROM RAW.RAW_POS_DATA;

SELECT PRODUCT_ID, UNIT_PRICE, QUANTITY, STORE_ID, STORE_DISCOUNT, LOYALTY_DISCOUNT, TAX_RATE
FROM CURATED.FCT_SALES
WHERE PRODUCT_ID = 1250;

--PRODUCT_ID	UNIT_PRICE	QUANTITY	STORE_ID	STORE_DISCOUNT	LOYALTY_DISCOUNT	TAX_RATE
--1250	          820.04	   1	     109	        0.05	           0	          0.18
--1250	          550.61	   3	     131	        0.15	          0.02	          0.18
--1250	          1712.4	   1	     57	            0.05	          0.06	          0.18
--1250	          289.26	   1	     99	            0.1	              0.02	          0.12
--1250	          9863.1	   4	     16	            0.2	               0	          0.12
--1250	          31459.8	   3	     102	        0.25	          0.04	          0.18

---------------------------------------------
-- 4️⃣  BUSINESS LOGIC FUNCTIONS
---------------------------------------------

--: SQL UDFs
------------------------------
-- Primary reusable UDF: CALC_FINAL_PRICE
-- This encapsulates business logic: apply store discount, loyalty discount (bounded),
-- then apply tax (bounded). Created in CURATED schema to be used by downstream views.


-- ✅ FIX: Create inside CURATED schema (important!)
CREATE OR REPLACE FUNCTION CALC_FINAL_PRICE(
    qty FLOAT, unit_price FLOAT, store_disc FLOAT, loyalty_disc FLOAT, tax_rate FLOAT
)
RETURNS FLOAT
AS
$$
    IFF(qty IS NULL OR unit_price IS NULL, NULL,
        (qty * unit_price)
        * (1 - LEAST(GREATEST(COALESCE(store_disc, 0), 0), 0.8))
        * (1 - LEAST(GREATEST(COALESCE(loyalty_disc, 0), 0), 0.8))
        * (1 + LEAST(GREATEST(COALESCE(tax_rate, 0), 0), 0.5))
    )
$$;

-- ✅ Test Function
SELECT
  PRODUCT_ID,
  CUSTOMER_ID,
  EVENT_TS,
  CALC_FINAL_PRICE(QUANTITY, UNIT_PRICE, STORE_DISCOUNT, LOYALTY_DISCOUNT, TAX_RATE) AS FINAL_PRICE
FROM CURATED.FCT_SALES
WHERE PRODUCT_ID = 1250;

--
/*
PRODUCT_ID	CUSTOMER_ID	         EVENT_TS	         FINAL_PRICE
1250	       52286	2025-07-04 09:25:01.000	      919.26484
1250	       57282	2024-03-21 14:42:15.000	      1623.6497802
1250	       58509	2023-05-15 14:52:31.000	      1804.424376
1250	       56541	2024-05-01 07:45:45.000	      285.7425984
1250	       59772	2023-09-11 12:26:09.000	      35349.3504
1250	       61738	2025-07-06 10:02:06.000	      80184.73824
*/


-- OPTIONAL simple version for only store discount
CREATE OR REPLACE FUNCTION CALC_FINAL_PRICE_STORE_ONLY(
    qty FLOAT, unit_price FLOAT, store_disc FLOAT
)
RETURNS FLOAT
AS
$$
  IFF(qty IS NULL OR unit_price IS NULL, NULL,
      qty * unit_price * (1 - COALESCE(store_disc, 0))
  )
$$;

-- ✅ Test Function
SELECT
  PRODUCT_ID,
  CUSTOMER_ID,
  QUANTITY,
  EVENT_TS,
  CALC_FINAL_PRICE_STORE_ONLY(QUANTITY, UNIT_PRICE, STORE_DISCOUNT)AS STORE_PRICE ---1*
FROM CURATED.FCT_SALES
WHERE PRODUCT_ID = 1250;

/*          
PRODUCT_ID	CUSTOMER_ID	QUANTITY	      EVENT_TS	           STORE_PRICE
1250	       52286	  1	      2025-07-04 09:25:01.000	    779.038
1250	       57282	  3	      2024-03-21 14:42:15.000	    1404.0555
1250	       58509	  1	      2023-05-15 14:52:31.000	    1626.78
1250	       56541	  1	      2024-05-01 07:45:45.000	    260.334
1250	       59772	  4	      2023-09-11 12:26:09.000	    31561.92
1250	       61738	  3	      2025-07-06 10:02:06.000	    70784.55
*/

---------------------------------------------
-- 5️⃣  UDTF: Reviews per Product (returns table of review comments)
---------------------------------------------
CREATE OR REPLACE FUNCTION GET_REVIEWS_BY_PRODUCT(PRODUCT_ID NUMBER)
RETURNS TABLE (
    REVIEW_COMMENT STRING,
    EVENT_TS TIMESTAMP_NTZ,
    CUSTOMER_ID NUMBER
)
AS
$$
  SELECT
    TRIM(f.value::STRING) AS REVIEW_COMMENT,
    TO_TIMESTAMP_NTZ(r.json_data:event_ts::STRING) AS EVENT_TS,
    r.json_data:customer:customer_id::NUMBER AS CUSTOMER_ID
  FROM RAW.RAW_POS_DATA r,
       LATERAL FLATTEN(input => r.json_data:transaction:review_comments) f
  WHERE r.json_data:product:product_id::NUMBER = PRODUCT_ID
    AND f.value IS NOT NULL
$$;

-- ✅ Test UDTF

SELECT * FROM TABLE(GET_REVIEWS_BY_PRODUCT(1010)) ORDER BY EVENT_TS DESC;
SELECT * FROM TABLE(CURATED.GET_REVIEWS_BY_PRODUCT(1389))
ORDER BY EVENT_TS DESC;



---------------------------------------------
-- 6️⃣  TABLEAU-READY STAR VIEW
---------------------------------------------
CREATE OR REPLACE VIEW VW_SALES_STAR AS
SELECT
  f.EVENT_TS::DATE AS ORDER_DATE,
  p.PRODUCT_ID, p.PRODUCT_NAME, p.CATEGORY, p.BRAND, p.COLOR, p.SIZE,
  c.CUSTOMER_ID, c.CUSTOMER_NAME, c.LOYALTY_TIER,
  s.STORE_ID, s.REGION, s.CITY,
  f.QUANTITY, f.UNIT_PRICE,
  f.STORE_DISCOUNT, f.LOYALTY_DISCOUNT, f.TAX_RATE,
  f.GROSS_AMOUNT,
  POS_DEMO.CURATED.CALC_FINAL_PRICE(
      f.QUANTITY, f.UNIT_PRICE, f.STORE_DISCOUNT, f.LOYALTY_DISCOUNT, f.TAX_RATE
  ) AS FINAL_PRICE,
  ARRAY_SIZE(SPLIT(f.PROMO_CODES, ',')) AS NUM_PROMOS_USED
FROM CURATED.FCT_SALES f
LEFT JOIN CURATED.DIM_PRODUCT  p ON f.PRODUCT_ID = p.PRODUCT_ID
LEFT JOIN CURATED.DIM_CUSTOMER c ON f.CUSTOMER_ID = c.CUSTOMER_ID
LEFT JOIN CURATED.DIM_STORE    s ON f.STORE_ID = s.STORE_ID;

---------------------------------------------
-- ✅ Validate final view
---------------------------------------------
SELECT * FROM VW_SALES_STAR;
--LIMIT 10;

SELECT * FROM VW_SALES_STAR
WHERE PRODUCT_ID = 1250;

SELECT ORDER_DATE, PRODUCT_ID, CUSTOMER_ID, QUANTITY, UNIT_PRICE, FINAL_PRICE
FROM CURATED.VW_SALES_STAR
WHERE PRODUCT_ID = 1250
ORDER BY ORDER_DATE DESC
--LIMIT 1;
