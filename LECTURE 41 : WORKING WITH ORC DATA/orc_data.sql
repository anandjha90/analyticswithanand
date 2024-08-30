// For setup, you must create a database, table, and file format. See below for SQL Statements:


//CREATE TABLE

CREATE OR REPLACE TABLE SAMPLE_ORC(src VARIANT);

CREATE OR REPLACE TABLE ORC_TEST_TABLE
(FIRSTNAME STRING, 
LASTNAME STRING, 
EMAIL STRING, 
GENDER STRING,
COUNTRY STRING,
DESIGNATION VARCHAR(50));

//CREATE A FILE FORMAT
CREATE OR REPLACE FILE FORMAT orc_ff TYPE = 'ORC';

// Querying the Stage
// With Snowflake you have the ability to Query the data before you load it in. 
// For this sample, we are going to look at the data and also show how we can specify certain columns to ingest 
// into our Snowflake environment. 

// I will start by querying my stage to check the files 
------------------------------------------------------------------------------------------
--WORKING WITH THE STAGE
------------------------------------------------------------------------------------------
CREATE OR REPLACE STORAGE INTEGRATION S3_BANK
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN ='arn:aws:iam::661806635168:role/banking_role'
STORAGE_ALLOWED_LOCATIONS =('s3://czec-banking/');

DESC integration S3_BANK;

CREATE OR REPLACE STAGE orc_demo_stage
URL ='s3://czec-banking'
--credentials=(aws_key_id='AKIAXQKR3H3PSG72XFMK'aws_secret_key='eKL6a6FjlQHic4s8Ne712Aelzg2ou4j6tNsVvFq5')
file_format = orc_ff
storage_integration = S3_BANK;

LIST @orc_demo_stage;

SHOW STAGES;

CREATE OR REPLACE PIPE orc_demo_pipe AUTO_INGEST = TRUE AS
COPY INTO DEMO_DATABASE.DEMO_SCHEMA.SAMPLE_ORC
FROM '@orc_demo_stage/ORC_PARSER/' 
FILE_FORMAT= orc_ff; 

SHOW PIPES;

ALTER PIPE orc_demo_pipe refresh;


//QUERY ALL FILES IN STAGE
list @orc_demo_stage;

// We can look at each record in the ORC file by using the below statement. Notice how we utilize the file format we created in the setup step. 
// We can also query and utilize dot notation to specify which columns we need out of the ORC file. 
// In this case, we will utilize _col2 (FIRSTNAME), _col3(LASTNAME), _col4(EMAIL), _col5(GENDER), and _col8(COUNTRY) as our desired columns. 

//LOOK AT DATA IN THE ORC FILE
SELECT t.$1 from @orc_demo_stage (file_format => orc_ff) t;

//If you click on the first record you will see the below. This shows you what the record will look like and tells us what values we need to grab. 

//QUERY TO GET DESIRED COLUMN NAMES
SELECT t.$1:"_col2",t.$1:"_col3",t.$1:"_col4",t.$1:"_col5",t.$1:"_col8",t.$1:"_col11"
from @orc_demo_stage (file_format => orc_ff) t;

//After looking at the data we can choose which files or columns we’d like to load utilizing the same SELECT as we utilized above. 
//In order to load data into the table, we need to run a COPY INTO statement to get the data in. 

------------------------------------------------------------------------------------------
--LOADING THE DATA
------------------------------------------------------------------------------------------

//USE SELECT STATEMENT FROM ABOVE TO LOAD INTO TABLE
copy into ORC_TEST_TABLE
from
(
SELECT t.$1:"_col2",t.$1:"_col3",t.$1:"_col4",t.$1:"_col5",t.$1:"_col8",t.$1:"_col11"
from @orc_demo_stage (file_format => orc_ff) t
);

//CHECK LOADED VALUES
SELECT * FROM ORC_TEST_TABLE;


// We have successfully loaded in all the data. This is a sample of how easy it is to work with ORC data in the Snowflake environment.
