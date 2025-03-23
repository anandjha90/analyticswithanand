CREATE OR REPLACE DATABASE BANKING_DB;
CREATE OR REPLACE SCHEMA BANKING_SCHEMA;


CREATE OR REPLACE TABLE CREDIT_CARD_CUSTOMERS_AUTO_DATA_LOAD_INCR (
    CUST_ID VARCHAR(20) PRIMARY KEY,
    CREDIT_CARD_NUMBER VARCHAR(19),
    BALANCE NUMBER(10,2),
    PURCHASES NUMBER(10,2),
    INSTALLMENTS_PURCHASES NUMBER(10,2),
    CASH_ADVANCE NUMBER(10,2),
    CREDIT_LIMIT NUMBER(10,2),
    PAYMENTS NUMBER(10,2),
    MINIMUM_PAYMENTS NUMBER(10,2),
    TENURE INTEGER,
    DATE_OF_TXN DATE
);

CREATE OR REPLACE FILE FORMAT CSV_FILE_FORMAT
    type = 'csv' 
    compression = 'none' 
    field_delimiter = ','
    field_optionally_enclosed_by = 'none'
    skip_header = 1 ;  

SELECT * FROM CREDIT_CARD_CUSTOMERS_AUTO_DATA_LOAD_INCR;


---------------------------------------------------------------------------------------------

CREATE OR REPLACE STORAGE integration s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN ='arn:aws:iam::418295682990:role/ccc_role'
STORAGE_ALLOWED_LOCATIONS =('s3://banking-awa/');

DESC integration s3_int;


CREATE OR REPLACE STAGE BANK_STG_CRED
URL ='s3://banking-awa/ccc_cust_txns'
credentials=(aws_key_id='*************'aws_secret_key='******************') -- replace with your AWS access key
file_format = CSV_FILE_FORMAT;
-- storage_integration = s3_int;  (Do not execute this if you are creating via access key)

CREATE OR REPLACE STAGE BANK_STG_SINTG
URL ='s3://banking-awa'
-- credentials=(aws_key_id='****************'aws_secret_key='*******************')   -- (Do not execute this if you are creating via storage Integration)
file_format = CSV_FILE_FORMAT
storage_integration = s3_int;  

LIST @BANK_STG_CRED;

SHOW STAGES;

--CREATE SNOWPIPE THAT RECOGNISES CSV THAT ARE INGESTED FROM EXTERNAL STAGE AND COPIES THE DATA INTO EXISTING TABLE

--The AUTO_INGEST=true parameter specifies to read 
--- event notifications sent from an S3 bucket to an SQS queue when new data is ready to load.


CREATE OR REPLACE PIPE CCC_DATA_INJEST_PIPE AUTO_INGEST = TRUE AS
COPY INTO BANKING_DB.BANKING_SCHEMA.CREDIT_CARD_CUSTOMERS_AUTO_DATA_LOAD_INCR --yourdatabase -- your schema ---your table
FROM '@BANK_STG_SINTG/ccc_cust_txns/' --s3 bucket subfolde4r name
FILE_FORMAT = CSV_FILE_FORMAT;

-- Checking pipe
SHOW PIPES;

-- check pipe data flow status
ALTER PIPE CCC_DATA_INJEST_PIPE refresh;

-- now checking count where data has been arrived or not
SELECT count(*) FROM CREDIT_CARD_CUSTOMERS_AUTO_DATA_LOAD_INCR;

-- Following are some snowpipe command which will help you to check snowpipe status

-- This will show the latest file which has been processed
select SYSTEM$PIPE_STATUS('CCC_DATA_INJEST_PIPE');

-- to check wether the files count in source(AWS S3) & target(Snowflake) are matching or not use below command
-- It will also help to answer question how many rows have been parsed in a particular table on any day or in last few days/hrs.
-- We can get the complete picture

select * from table(information_schema.copy_history(table_name=>'CREDIT_CARD_CUSTOMERS_AUTO_DATA_LOAD_INCR', start_time=>
dateadd(hours, -1, current_timestamp())));
