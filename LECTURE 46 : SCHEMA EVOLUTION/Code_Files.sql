-- creating first file format
CREATE OR REPLACE FILE FORMAT CSV_FORMAT 
  TYPE = 'CSV'
  PARSE_HEADER = TRUE
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  FIELD_DELIMITER = ','
  RECORD_DELIMITER = '\n'
  NULL_IF = ('NULL','')
  TRIM_SPACE = TRUE
  ENCODING = 'UTF8';

-- creating storage integration for integrating with aws
CREATE OR REPLACE STORAGE INTEGRATION S3_INT
TYPE = EXTERNAL_STAGE
ENABLED=TRUE
STORAGE_PROVIDER = 'S3'
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::196024211961:role/awa_dev_role' --  replace with your arn
STORAGE_ALLOWED_LOCATIONS =('s3://myawabucketnew/DEV/'); --  replace with your bucket/folder

DESC STORAGE INTEGRATION S3_INT;

---Source Stage for landing files
CREATE OR REPLACE STAGE STG_SCHEMA_FILES
STORAGE_INTEGRATION = S3_INT
URL = 's3://myawabucketnew/DEV/'
FILE_FORMAT = 'CSV_FORMAT';

-- list files
LIST @STG_SCHEMA_FILES;

----> Infer schema to create table automatically 
SELECT * from table(
                    INFER_SCHEMA(
                    LOCATION=>'@STG_SCHEMA_FILES/customer_data_1.csv',
                    FILE_FORMAT=>'CSV_FORMAT',
                    IGNORE_CASE=>TRUE
                                )
                   );

---create table using template 
CREATE OR REPLACE TABLE CUSTOMER_DATA
            USING TEMPLATE (
               SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) FROM TABLE(
                    INFER_SCHEMA(
                    LOCATION=>'@STG_SCHEMA_FILES/customer_data_1.csv',
                    FILE_FORMAT=>'CSV_FORMAT',
                    IGNORE_CASE=>TRUE
                                )
                   )
                   );

SHOW TABLES;

DESC TABLE CUSTOMER_DATA;

----- For Schema evolution
ALTER TABLE CUSTOMER_DATA SET ENABLE_SCHEMA_EVOLUTION=TRUE;
ALTER FILE FORMAT CSV_FORMAT SET ERROR_ON_COLUMN_COUNT_MISMATCH=FALSE;

-- use this for testing as using snowpipe data will get ingested
COPY INTO CUSTOMER_DATA
FROM @STG_SCHEMA_FILES/customer_data_3.csv
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
ON_ERROR = 'CONTINUE';

Select * from CUSTOMER_DATA;

-- using snowpipe for automatic data ingestion
CREATE OR REPLACE PIPE CUSTOMER_DATA_PIPE 
  AUTO_INGEST = TRUE
AS
COPY INTO CUSTOMER_DATA
FROM @STG_SCHEMA_FILES
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
ON_ERROR = 'CONTINUE';

-- Checking pipe
SHOW PIPES;

-- check pipe data flow status
ALTER PIPE CUSTOMER_DATA_PIPE refresh;

-- This will show the latest file which has been processed
select SYSTEM$PIPE_STATUS('CUSTOMER_DATA_PIPE');

-- now checking count where data has been arrived or not
SELECT count(*) FROM DEMO_DATABASE.DEMO_SCHEMA.CUSTOMER_DATA;

-- to check wether the files count in source(AWS S3) & target(Snowflake) are matching or not use below command
-- It will also help to answer question how many rows have been parsed in a particular table on any day or in last few days/hrs.
-- We can get the complete picture

select * from table(information_schema.copy_history(table_name=>'CUSTOMER_DATA', start_time=>
dateadd(hours, -1, current_timestamp())));
