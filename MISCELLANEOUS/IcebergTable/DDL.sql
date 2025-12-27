CREATE OR REPLACE DATABASE ORDERS_DB;
CREATE OR REPLACE SCHEMA ORDERS_DB.ORDERS_SCHEMA;

create or replace file format csv_format
                    type = csv
                    skip_header = 1
                    null_if = ('NULL', 'null')
                    empty_field_as_null = true;

--upload both files
create or replace stage orders_db.orders_schema.iceberg_load
file_format = orders_db.orders_schema.csv_format;
  
list @orders_db.orders_schema.iceberg_load;

-- tables just for testing
create or replace iceberg table customer_detail (
  CUST_NUM varchar,
  CUST_STAT varchar,
  CUST_BAL number(10,0),
  INV_NO varchar,
  INV_AMT number(10,2),
  CRID varchar,
  SSN varchar,
  phone number(10,0),
  Email varchar
)

create or replace table Accessory_Detail (
  CUST_NUM varchar,
  Accessory varchar,
  status varchar,
  amount number(10,0),
  renewal varchar
);

  

create external volume iceberg_int
  storage_locations =
  (
    (
    name = 'iceberg_bucket'
    storage_provider = 'S3'
    storage_base_url = 's3://icebergconfigbucket/'
    storage_aws_role_arn = 'arn:aws:iam::913267004595:role/icebergconfigrole'
    )
   );

   describe external volume iceberg_int;

{"NAME":"iceberg_bucket",
  "STORAGE_PROVIDER":"S3",
  "STORAGE_BASE_URL":"s3://icebergconfigbucket/",
  "STORAGE_ALLOWED_LOCATIONS"["s3://icebergconfigbucket/*"],
  "STORAGE_AWS_ROLE_ARN":"arn:aws:iam::913267004595:role/icebergconfigrole",
  "STORAGE_AWS_IAM_USER_ARN":"arn:aws:iam::940482405254:user/hzdt0000s",
  "STORAGE_AWS_EXTERNAL_ID":"RU48962_SFCRole=2_iMI2Dcus3iSF+ArSHAB83WJ8twQ=",
  "ENCRYPTION_TYPE":"NONE","ENCRYPTION_KMS_KEY_ID":""
};


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
BASE_LOCATION = 'CUSTOMER_INFO';

show tables;

copy into customer_detail
from @orders_db.orders_schema.iceberg_load/Customer_Invoice.csv
on_error = CONTINUE;

select * from customer_detail;

https://www.tablab.app/parquet/view

create or replace table Accessory_Detail (
CUST_NUM varchar,
Accessory varchar ,
status varchar ,
amount number(10,0),
renewal varchar 
  
);

copy into Accessory_Detail
from @orders_db.orders_schema.iceberg_load/Accessory.csv
on_error = CONTINUE;

select * from Accessory_Detail;
select * from customer_detail;

select * from customer_detail c,accessory_detail a
where c.cust_num = a.cust_num;


CREATE MASKING POLICY mask_ssn_policy AS (val STRING) 
RETURNS STRING ->
CASE
    WHEN CURRENT_ROLE() IN ('OPS', 'SECURITY_ADMIN') THEN val
    ELSE 'XXX-XX-' || RIGHT(val, 4)
END;

ALTER ICEBERG TABLE customer_detail MODIFY COLUMN SSN SET MASKING POLICY mask_ssn_policy;


CREATE OR REPLACE ROW ACCESS POLICY CRID_ACCESS_POLICY
AS (crid_column STRING) RETURNS BOOLEAN ->
    CASE 
        -- Example: Allow users with role 'CRID_ACCESS_ROLE' to see all rows
        WHEN CURRENT_ROLE() = 'CRID_ACCESS_ROLE' THEN TRUE 
        -- Restrict access for others based on CRID
        WHEN crid_column LIKE '2Z3%' THEN TRUE
        ELSE FALSE
    END;

ALTER iceberg TABLE customer_detail ADD ROW ACCESS POLICY CRID_ACCESS_POLICY ON (CRID);


select * from Filtered_Customer_Accessory;


CREATE OR REPLACE ICEBERG TABLE Customer_Accessory_iceberg (
    CUSTOMER_ID varchar,
    status varchar ,
    customer_bal number(10,0),
    Accessory varchar ,
    Accessory_Status varchar,
    amount number(10,0) 
)
    CATALOG = 'SNOWFLAKE'
    EXTERNAL_VOLUME = 'iceberg_int'
    BASE_LOCATION = 'CUST_ACCESSORY';

    select * from Customer_Accessory_iceberg;

select count(*) from DEMO_DATABASE.DEMO_SCHEMA.STG_BARISTA_REVIEWS;
