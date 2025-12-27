
CREATE OR REPLACE DATABASE iceberg_db;
CREATE OR REPLACE SCHEMA iceberg_db.raw;

CREATE OR REPLACE EXTERNAL VOLUME iceberg_ext_vol
STORAGE_LOCATIONS =
(
  (
    NAME = 'iceberg_bucket'
    STORAGE_PROVIDER = 'S3'
    STORAGE_BASE_URL = 's3://matillion-projects-awa/'
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::127214176877:role/RETAIL_ROLE'
    STORAGE_AWS_EXTERNAL_ID = 'PPB32730_SFCRole=6_fL38xffKCg1WxkOHEXY/M8ySes4='
  )
)
ALLOW_WRITES = TRUE;

describe external volume iceberg_ext_vol;

CREATE OR REPLACE ICEBERG TABLE iceberg_db.raw.sales_iceberg (
    order_id INT,
    customer_id INT,
    order_date DATE,
    amount NUMBER(10,2)
)
CATALOG = 'SNOWFLAKE'
EXTERNAL_VOLUME = 'iceberg_ext_vol'
BASE_LOCATION = 'sales_iceberg/';


CREATE OR REPLACE STORAGE INTEGRATION iceberg_s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::127214176877:role/RETAIL_ROLE'
STORAGE_ALLOWED_LOCATIONS = ('s3://matillion-projects-awa/');

DESC STORAGE INTEGRATION iceberg_s3_int;

CREATE OR REPLACE ICEBERG TABLE iceberg_db.raw.sales_iceberg (
    order_id INT,
    customer_id INT,
    order_date DATE,
    amount NUMBER(10,2)
)
CATALOG = 'SNOWFLAKE'
EXTERNAL_VOLUME = ICEBERG_EXT_VOL
BASE_LOCATION = 'sales_iceberg/';

SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('ICEBERG_EXT_VOL');

INSERT INTO iceberg_db.raw.sales_iceberg VALUES
(1, 101, '2025-01-10', 500),
(2, 102, '2025-01-11', 1200);

SELECT * FROM iceberg_db.raw.sales_iceberg;

create or replace iceberg table customer_detail (
CUST_NUM varchar,
CUST_STAT varchar ,
CUST_BAL number(10,0),
INV_NO varchar ,
INV_AMT number(10,2),
CRID varchar ,
SSN varchar,
phone number(10,0),
Email varchar
)

CATALOG = 'SNOWFLAKE'
external_volume='iceberg_int'
BASE_LOCATION = 'customer_detail';

CREATE OR REPLACE FILE FORMAT csv_ff
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
NULL_IF = ('NULL','null');

CREATE OR REPLACE STAGE matillion_s3_stage
URL = 's3://matillion-projects-awa/customer_detail_1000.csv'
STORAGE_INTEGRATION = iceberg_s3_int
FILE_FORMAT = csv_ff;

LIST @matillion_s3_stage;

COPY INTO customer_detail
FROM @matillion_s3_stage
FILE_FORMAT = csv_ff
ON_ERROR = 'CONTINUE';
