CREATE OR REPLACE DATABASE doc_ai_db;
CREATE OR REPLACE SCHEMA doc_ai_db.doc_ai_schema;

GRANT CREATE MODEL ON SCHEMA DOC_AI_DB.DOC_AI_SCHEMA TO ROLE ACCOUNTADMIN;

----FOR THE IMAGE DATA-----------------------------
--Stage Creation

CREATE OR REPLACE STAGE IMG_DOC
DIRECTORY = (ENABLE = TRUE)
ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

--Extracting Information from the documents

SELECT DOC_AI_DB.DOC_AI_SCHEMA.IMAGE!PREDICT(
  GET_PRESIGNED_URL(@IMG_DOC, RELATIVE_PATH), 1)
FROM DIRECTORY(@IMG_DOC);

--Flatten Data from json to structured format
WITH raw AS (
    SELECT DOC_AI_DB.DOC_AI_SCHEMA.IMAGE!PREDICT(
               GET_PRESIGNED_URL(@IMG_DOC, RELATIVE_PATH), 1
           ) AS prediction_output
    FROM DIRECTORY(@IMG_DOC)
)
SELECT
    prediction_output:"Fabric"[0].value::string         AS Fabric,
    prediction_output:"Manufacturer_Code"[0].value::string AS Manufacturer_Code,
    prediction_output:"Weight"[0].value::string           AS Weight
FROM raw;


--------FOR THE RESUME DATA-------------------------------------------------
--Stage Creation

CREATE OR REPLACE STAGE RESUME_DOC
DIRECTORY = (ENABLE = TRUE)
ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');


--Extracting Information from the documents

SELECT DOC_AI_DB.DOC_AI_SCHEMA.RESUME!PREDICT(
  GET_PRESIGNED_URL(@RESUME_DOC, RELATIVE_PATH), 1)
FROM DIRECTORY(@RESUME_DOC);

--Flatten Data from json to structured format
WITH raw AS (
    SELECT DOC_AI_DB.DOC_AI_SCHEMA.RESUME!PREDICT(
               GET_PRESIGNED_URL(@RESUME_DOC, RELATIVE_PATH), 1
           ) AS prediction_output
    FROM DIRECTORY(@RESUME_DOC)
)
SELECT
    prediction_output:"Candidate_Name"[0].value::string         AS Name,
    prediction_output:"Phone_No"[0].value::string AS Phone_Number,
    prediction_output:"Address"[0].value::string           AS Address,
    prediction_output:"Email_Id"[0].value::string           AS Email
FROM raw;
