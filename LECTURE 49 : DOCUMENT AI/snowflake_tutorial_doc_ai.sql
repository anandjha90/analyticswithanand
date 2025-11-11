-- Create a database and schema in which to create a Document AI model build:
CREATE DATABASE doc_ai_db;
CREATE SCHEMA doc_ai_db.doc_ai_schema;

--Create custom role doc_ai_role to prepare the Document AI model build and to create processing pipelines: 
USE ROLE ACCOUNTADMIN;
CREATE ROLE doc_ai_role;

-- Grant the SNOWFLAKE.DOCUMENT_INTELLIGENCE_CREATOR database role to the doc_ai_role role:
GRANT DATABASE ROLE SNOWFLAKE.DOCUMENT_INTELLIGENCE_CREATOR TO ROLE doc_ai_role;

-- Grant warehouse usage and operating privileges to the doc_ai_role role:
GRANT USAGE, OPERATE ON WAREHOUSE DEMO_WAREHOUSE TO ROLE doc_ai_role;

-- Grant the privileges to use the database and schema you created to the doc_ai_role:
GRANT USAGE ON DATABASE doc_ai_db TO ROLE doc_ai_role;
GRANT USAGE ON SCHEMA doc_ai_db.doc_ai_schema TO ROLE doc_ai_role;

-- Grant the create stage privilege on the schema to the doc_ai_role role to store the documents for extraction:
GRANT CREATE STAGE ON SCHEMA doc_ai_db.doc_ai_schema TO ROLE doc_ai_role;

-- Grant the privileges to create model builds (instances of the DOCUMENT_INTELLIGENCE class) to the doc_ai_role role:
GRANT CREATE SNOWFLAKE.ML.DOCUMENT_INTELLIGENCE ON SCHEMA doc_ai_db.doc_ai_schema TO ROLE doc_ai_role;
GRANT CREATE MODEL ON SCHEMA doc_ai_db.doc_ai_schema TO ROLE doc_ai_role;

-- Grant the privileges required to create a processing pipeline using streams and tasks to the doc_ai_role role:
GRANT CREATE STREAM, CREATE TABLE, CREATE TASK, CREATE VIEW ON SCHEMA doc_ai_db.doc_ai_schema TO ROLE doc_ai_role;
GRANT EXECUTE TASK ON ACCOUNT TO ROLE doc_ai_role;

-- Grant the doc_ai_role to tutorial user for use in the next steps of the tutorial:
GRANT ROLE doc_ai_role TO USER ANALYTICSWITHANAND;


-- Create an internal my_pdf_stage stage to store the documents:
CREATE OR REPLACE STAGE my_pdf_stage
  DIRECTORY = (ENABLE = TRUE)
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Create a my_pdf_stream stream on a my_pdf_stage stage:
CREATE STREAM my_pdf_stream ON STAGE my_pdf_stage;

-- Refresh the metadata of the directory table that will store the staged document files:
ALTER STAGE my_pdf_stage REFRESH;

-- Specify the database and schema:
USE DATABASE doc_ai_db;
USE SCHEMA doc_ai_schema;

-- Create a pdf_reviews table to store the information about the documents (such as file_name) and the data to be extracted from the PDF documents:

CREATE OR REPLACE TABLE pdf_reviews (
  file_name VARCHAR,
  file_size VARIANT,
  last_modified VARCHAR,
  snowflake_file_url VARCHAR,
  json_content VARCHAR
);

-- The json_content column will include the extracted information in JSON format.

-- Create a load_new_file_data task to process new documents in the stage:

SHOW MODELS IN SCHEMA DOC_AI_DB.DOC_AI_SCHEMA;

CREATE OR REPLACE TASK load_new_file_data
  WAREHOUSE = DEMO_WAREHOUSE
  SCHEDULE = '1 minutes'
  COMMENT = 'Process new files in the stage and insert data into the pdf_reviews table.'
WHEN SYSTEM$STREAM_HAS_DATA('my_pdf_stream')
AS
INSERT INTO pdf_reviews (
  SELECT
    RELATIVE_PATH AS file_name,
    size AS file_size,
    last_modified,
    file_url AS snowflake_file_url,
    inspection_reviews!PREDICT(GET_PRESIGNED_URL('@my_pdf_stage', RELATIVE_PATH), 1) AS json_content
  FROM my_pdf_stream
  WHERE METADATA$ACTION = 'INSERT'
);

-- Note that newly created tasks are automatically suspended.

-- Start the newly created task:
ALTER TASK load_new_file_data RESUME;

--Lsit the task
SHOW TASKS;

-- After uploading the documents to the stage, view the information extracted from new documents:
SELECT * FROM pdf_reviews;

-- Create a pdf_reviews_2 table to analyze the extracted information in separate columns:
CREATE OR REPLACE TABLE doc_ai_db.doc_ai_schema.pdf_reviews_2 AS (
 WITH temp AS (
   SELECT
     RELATIVE_PATH AS file_name,
     size AS file_size,
     last_modified,
     file_url AS snowflake_file_url,
     inspection_reviews!PREDICT(get_presigned_url('@my_pdf_stage', RELATIVE_PATH), 1) AS json_content
   FROM directory(@my_pdf_stage)
 )

 SELECT
   file_name,
   file_size,
   last_modified,
   snowflake_file_url,
   json_content:__documentMetadata.ocrScore::FLOAT AS ocrScore,
   f.value:score::FLOAT AS inspection_date_score,
   f.value:value::STRING AS inspection_date_value,
   g.value:score::FLOAT AS inspection_grade_score,
   g.value:value::STRING AS inspection_grade_value,
   i.value:score::FLOAT AS inspector_score,
   i.value:value::STRING AS inspector_value,
   ARRAY_TO_STRING(ARRAY_AGG(j.value:value::STRING), ', ') AS list_of_units
 FROM temp,
   LATERAL FLATTEN(INPUT => json_content:inspection_date) f,
   LATERAL FLATTEN(INPUT => json_content:inspection_grade) g,
   LATERAL FLATTEN(INPUT => json_content:inspector) i,
   LATERAL FLATTEN(INPUT => json_content:list_of_units) j
 GROUP BY ALL
);


SELECT * FROM pdf_reviews_2;
