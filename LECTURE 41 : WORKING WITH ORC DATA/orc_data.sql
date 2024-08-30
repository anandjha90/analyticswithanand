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

//LOOK AT DATA IN THE ORC FILE
SELECT t.$1 from @orc_demo_stage (file_format => orc_ff) t;

//QUERY TO GET DESIRED COLUMN NAMES
SELECT t.$1:"_col2",t.$1:"_col3",t.$1:"_col4",t.$1:"_col5",t.$1:"_col8",t.$1:"_col11"
from @orc_demo_stage (file_format => orc_ff) t;

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
