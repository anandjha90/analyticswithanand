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

-- Alternative Approach

-- if staging details are not availble such as no roles and policies have been created abnd client have given aws access key then execute below steps
CREATE OR REPLACE STAGE my_external_stage
URL = 's3://czec-banking/DOWNLOAD_CSV/' -- path to S3 bucket folder
--STORAGE_INTEGRATION = my_s3_integration
CREDENTIALS = (
    AWS_KEY_ID = '*******************'                         -- aws access key 
    AWS_SECRET_KEY = '*******************'                     -- aws secret access key
)
FILE_FORMAT = csv_file_format;

COPY INTO @my_external_stage/customer_data.csv -- copying data into external stage give proper file name with extension else it will create with data.csv(filename)
FROM (SELECT * FROM customer_data)
OVERWRITE=TRUE ; 

-- if file already exists with teh same name it will overwrite it else if you have not use this property and trying to write to the same file you get an error

COPY INTO @my_external_stage/sales_region_data.csv -- copying data into external stage give proper file name with extension else it will create with data.csv(filename)
FROM (SELECT * FROM sales_region_data)
OVERWRITE=TRUE ; 
