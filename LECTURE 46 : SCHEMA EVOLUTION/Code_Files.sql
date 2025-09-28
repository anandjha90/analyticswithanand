create or replace TABLE CUSTOMER_DATA_TEST (
	CUST_ID VARCHAR(16777216),
	CREDIT_CARD_NUMBER VARCHAR(16777216),
	BALANCE NUMBER(7,2),
	PURCHASES NUMBER(6,2),
	INSTALLMENTS_PURCHASES NUMBER(6,2),
	CASH_ADVANCE NUMBER(6,2),
	CREDIT_LIMIT NUMBER(7,2),
	PAYMENTS NUMBER(7,2),
	MINIMUM_PAYMENTS NUMBER(7,2)
);

SHOW FILE FORMATS;

CREATE OR REPLACE FILE FORMAT CSV_FORMAT 
  TYPE = 'CSV'
  PARSE_HEADER = TRUE
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  FIELD_DELIMITER = ','
  RECORD_DELIMITER = '\n'
  NULL_IF = ('NULL','')
  TRIM_SPACE = TRUE
  ENCODING = 'UTF8';

CREATE OR REPLACE STORAGE INTEGRATION S3_INT
TYPE = EXTERNAL_STAGE
ENABLED=TRUE
STORAGE_PROVIDER = 'S3'
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::196024211961:role/awa_dev_role'
STORAGE_ALLOWED_LOCATIONS =('s3://myawabucketnew/DEV/');

DESC STORAGE INTEGRATION S3_INT;

---Source Stage
CREATE OR REPLACE STAGE STG_SCHEMA_FILES
STORAGE_INTEGRATION = S3_INT
URL = 's3://myawabucketnew/DEV/'
FILE_FORMAT = 'CSV_FORMAT';


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
            
Select * from CUSTOMER_DATA;

DESC TABLE CUSTOMER_DATA;

----- For Schema evolution
ALTER TABLE CUSTOMER_DATA SET ENABLE_SCHEMA_EVOLUTION=TRUE;
ALTER FILE FORMAT CSV_FORMAT SET ERROR_ON_COLUMN_COUNT_MISMATCH=FALSE;

SHOW TABLES;

COPY INTO CUSTOMER_DATA
FROM @STG_SCHEMA_FILES/customer_data_3.csv
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
ON_ERROR = 'CONTINUE';

Select * from CUSTOMER_DATA;

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

-- now checking count where data has been arrived or not
SELECT count(*) FROM DEMO_DATABASE.DEMO_SCHEMA.CUSTOMER_DATA;

-- Following are some snowpipe command which will help you to check snowpipe status

-- This will show the latest file which has been processed
select SYSTEM$PIPE_STATUS('CUSTOMER_DATA_PIPE');

-- to check wether the files count in source(AWS S3) & target(Snowflake) are matching or not use below command
-- It will also help to answer question how many rows have been parsed in a particular table on any day or in last few days/hrs.
-- We can get the complete picture

select * from table(information_schema.copy_history(table_name=>'CUSTOMER_DATA', start_time=>
dateadd(hours, -1, current_timestamp())));


