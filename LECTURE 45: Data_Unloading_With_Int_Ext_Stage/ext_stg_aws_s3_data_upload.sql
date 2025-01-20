----------------------------------------------------AWS (S3) INTEGRATION------------------------------------------------------------------------
CREATE OR REPLACE STORAGE integration s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN ='arn:aws:iam::661806635168:role/banking_role' 
STORAGE_ALLOWED_LOCATIONS =('s3://czec-banking/DOWNLOAD_CSV/'); 

DESC integration s3_int;

----------------------- stage---------------------------------------------------------
-- Define an external stage to access the AWS S3 bucket. 
-- Ensure the necessary IAM role and S3 bucket policies are set for Snowflake to read from the bucket.

-- create a file format
create or replace file format csv_file_format
    type = 'csv' 
    compression = 'none' 
    field_delimiter = ','
    field_optionally_enclosed_by = 'none'
    skip_header = 1 ; 
    
CREATE OR REPLACE STAGE s3_stage
URL ='s3://czec-banking/DOWNLOAD_CSV/'
file_format = csv_file_format
storage_integration = s3_int;

-- to show all stages
SHOW STAGES;

-- To show files processsed in stage 
LIST @s3_stage;

-- Example for Table 1
COPY INTO @s3_stage/customer_data.csv
FROM (SELECT * FROM customer_data);

-- Example for Table 2
COPY INTO @s3_stage/sales_region_data.csv
FROM (SELECT * FROM sales_region_data);
