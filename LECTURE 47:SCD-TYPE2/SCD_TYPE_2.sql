--SCD_TYPE_2
-- ============================================================
-- 💠 COMPLETE SNOWFLAKE SETUP SCRIPT (FIXED & READY)
-- AWS → Snowflake → Email Notification (SCD Type 2 Workflow)
-- ============================================================

-- 1️⃣ CREATE WAREHOUSE
CREATE WAREHOUSE IF NOT EXISTS WH_ETL
  WITH WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- 2️⃣ CREATE DATABASE AND SCHEMAS
CREATE OR REPLACE DATABASE DEMO_SCD2;
USE DATABASE DEMO_SCD2;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS STAGING;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS AUDIT;


-- 3️⃣ CREATE STORAGE INTEGRATION (AWS S3)
CREATE OR REPLACE STORAGE INTEGRATION S3_SNOWFLAKE_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::196024211961:role/awa_dev_role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://scd-type2-demo-bucket/data_batches/')
  COMMENT = 'Integration to read S3 batch data files.';

DESC INTEGRATION S3_SNOWFLAKE_INT;

-- 4️⃣ CREATE FILE FORMAT
CREATE OR REPLACE FILE FORMAT RAW.CSV_FORMAT
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1;

-- 5️⃣ CREATE EXTERNAL STAGE
CREATE OR REPLACE STAGE RAW.S3_BATCH_STAGE
  STORAGE_INTEGRATION = S3_SNOWFLAKE_INT
  URL = 's3://scd-type2-demo-bucket/data_batches/'
  FILE_FORMAT = RAW.CSV_FORMAT;

-- ----> Infer schema to create table automatically 
SELECT * from table(
                    INFER_SCHEMA(
                    LOCATION=>'@RAW.S3_BATCH_STAGE/batch1.csv',
                    FILE_FORMAT=>'RAW.CSV_FORMAT',
                    IGNORE_CASE=>TRUE
                                )
                   );
                   
---create table using template 
CREATE OR REPLACE TABLE STAGING.RAW_EMPLOYEE
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(INFER_SCHEMA(
      LOCATION=>'@RAW.S3_BATCH_STAGE/batch1.csv',
      FILE_FORMAT=>'RAW.CSV_FORMAT',
      IGNORE_CASE=>TRUE
    ))
  );

ALTER TABLE DEMO_SCD2.STAGING.RAW_EMPLOYEE
  ADD COLUMN IF NOT EXISTS SOURCE_FILE STRING;

ALTER TABLE DEMO_SCD2.STAGING.RAW_EMPLOYEE
  ADD COLUMN IF NOT EXISTS INGESTED_AT TIMESTAMP_NTZ;

  
-- Customers pipe
CREATE OR REPLACE PIPE DEMO_SCD2.STAGING.EMP_PIPE
AUTO_INGEST = TRUE
AS
COPY INTO DEMO_SCD2.STAGING.RAW_EMPLOYEE
  (C1, C2, C3, C4, C5, C6, C7, SOURCE_FILE, INGESTED_AT)
FROM (
  SELECT t.$1, 
         t.$2, 
         t.$3, 
         t.$4, 
         t.$5, 
         t.$6, 
         t.$7,
         METADATA$FILENAME,
         CURRENT_TIMESTAMP()
  FROM @RAW.S3_BATCH_STAGE (FILE_FORMAT => 'RAW.CSV_FORMAT') t
)
ON_ERROR='CONTINUE';


ALTER PIPE DEMO_SCD2.STAGING.EMP_PIPE REFRESH; -- in s3 first upload batch 1 and then once you call SP upload batch 2 dont upload both altogether

select * from table(information_schema.copy_history(table_name => 'DEMO_SCD2.STAGING.RAW_EMPLOYEE', start_time=>
dateadd(hours, -1, current_timestamp())));

-- 7️⃣ CREATE TARGET TABLE
CREATE OR REPLACE TABLE CURATED.EMPLOYEE_DIM (
  EID STRING,
  EName STRING,
  Email STRING,
  PhoneNo STRING,
  Address STRING,
  CompanyName STRING,
  Exp STRING,
  Start_Date DATE DEFAULT CURRENT_DATE,
  End_Date DATE,
  Is_Current BOOLEAN DEFAULT TRUE
);

-- 8️⃣ CREATE EMAIL RECIPIENTS TABLE
CREATE OR REPLACE TABLE AUDIT.EMAIL_RECIPIENTS (
  RECIPIENT_NAME STRING,
  RECIPIENT_EMAIL STRING
);

INSERT INTO AUDIT.EMAIL_RECIPIENTS VALUES
  ('Admin', 'xyz@gmail.com') -- give your registered email id with which you have registered your snowflake account;

-- 9️⃣ CREATE EMAIL NOTIFICATION INTEGRATION
CREATE OR REPLACE NOTIFICATION INTEGRATION EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('xyz@gmail.com');

DESC INTEGRATION EMAIL_INT;


-- 🔟 ROLE & PRIVILEGE SETUP -- no need of this only if you ahve multiple user and role then its required
USE ROLE ACCOUNTADMIN;

GRANT USAGE ON DATABASE DEMO_SCD2 TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA DEMO_SCD2.RAW, DEMO_SCD2.STAGING, DEMO_SCD2.CURATED, DEMO_SCD2.AUDIT TO ROLE SYSADMIN;

GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE TASK, CREATE STREAM ON ALL SCHEMAS IN DATABASE DEMO_SCD2 TO ROLE SYSADMIN;

GRANT USAGE ON INTEGRATION S3_SNOWFLAKE_INT TO ROLE SYSADMIN;
GRANT USAGE ON INTEGRATION EMAIL_INT TO ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE WH_ETL TO ROLE SYSADMIN;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA DEMO_SCD2.AUDIT TO ROLE SYSADMIN;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA DEMO_SCD2.AUDIT TO ROLE SYSADMIN;

GRANT EXECUTE TASK, EXECUTE MANAGED TASK ON ACCOUNT TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
USE DATABASE DEMO_SCD2;
USE SCHEMA AUDIT;

-- ✅ CREATE LOG TABLES BEFORE PROCEDURE
CREATE OR REPLACE TABLE AUDIT.PIPELINE_JOB_LOG (
    JOB_ID STRING,
    JOB_NAME STRING,
    FILE_NAME STRING,
    STATUS STRING,
    DETAILS STRING,
    RUN_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE AUDIT.ERROR_LOG (
    FILE_NAME STRING,
    ERROR_DETAILS STRING,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Switch to CURATED for main logic
USE SCHEMA CURATED;

-- Result Behavior:
-- Any change in Email, Address, Company, Phone, Name, or Experience will generate:
        -- One expired row (Is_Current = FALSE, End_Date = CURRENT_DATE())
        -- One new current row (Is_Current = TRUE, Start_Date = CURRENT_DATE())

CREATE OR REPLACE PROCEDURE DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM()
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
/* =============================================================================
   STORED PROCEDURE: SP_PROCESS_EMPLOYEE_DIM
   =============================================================================
   📘 Purpose:
   Implements a robust, deterministic **Slowly Changing Dimension Type 2 (SCD2)**
   process for EMPLOYEE_DIM table. Detects and tracks changes in any employee 
   attributes (Name, Email, Phone, Address, Company, Experience).

   -----------------------------------------------------------------------------
   🧩 Key Features:
   -----------------------------------------------------------------------------
   ✅ Adds missing columns (SOURCE_FILE, INGESTED_AT) to STAGING for provenance.  
   ✅ Adds missing columns (SRC_HASH, BATCH_ID) to CURATED for change tracking.  
   ✅ Deduplicates staging data (latest per EID using INGESTED_AT).  
   ✅ Computes MD5 hash across tracked columns to detect *any* attribute change.  
   ✅ SCD2 logic → Expire old record (Is_Current=FALSE) + Insert new record.  
   ✅ Logs success/failure to AUDIT tables.  
   ✅ Sends email alerts via Snowflake Notification Integration (EMAIL_INT).  
   ✅ Handles nulls, trims spaces, ignores case differences for change detection.  
   ✅ Reusable across environments and resilient to schema evolution.

   -----------------------------------------------------------------------------
   📁 Dependencies:
   -----------------------------------------------------------------------------
   - STAGING.RAW_EMPLOYEE (source data)
   - CURATED.EMPLOYEE_DIM (dimension table)
   - AUDIT.PIPELINE_JOB_LOG, AUDIT.ERROR_LOG, AUDIT.EMAIL_RECIPIENTS
   - EMAIL_INT Notification Integration
   -----------------------------------------------------------------------------
*/

//////////////////////////////////////////////////////////
// 🕓 Step 1: Initialize runtime variables and metadata //
//////////////////////////////////////////////////////////

var start_time = new Date(); // Capture job start time for duration tracking

// Define database and schema paths (modify if needed)
var db = 'DEMO_SCD2';
var staging_schema = 'STAGING';
var staging_table = 'RAW_EMPLOYEE';
var staging_table_fq = db + '.' + staging_schema + '.' + staging_table;  // Fully-qualified name
var curated_table_fq = db + '.CURATED.EMPLOYEE_DIM';                     // Target dimension table
var audit_log_fq = db + '.AUDIT.PIPELINE_JOB_LOG';                       // Job log table
var error_log_fq = db + '.AUDIT.ERROR_LOG';                              // Error log table
var email_recipients_fq = db + '.AUDIT.EMAIL_RECIPIENTS';                // Email recipients table
var notif_integration = 'EMAIL_INT';                                     // Email integration name
var job_name = 'SP_PROCESS_EMPLOYEE_DIM';                                // Stored proc name
var job_id = job_name + '_' + (new Date()).toISOString().replace(/[:.]/g,'-') + '_' + Math.floor(Math.random()*10000);  // Unique job ID per run

// Initialize metric counters
var inserted_rows = 0;
var expired_rows = 0;
var dup_count = 0;
var total_curated = 0;


////////////////////////////////////////////////////////////
// 🧰 Step 2: Utility Functions for SQL, Logging, and Email //
////////////////////////////////////////////////////////////

// Helper: Execute SQL safely with optional bind parameters
function runSql(sqlText, binds) {
  if (binds && Array.isArray(binds)) {
    return snowflake.createStatement({ sqlText: sqlText, binds: binds }).execute();
  } else {
    return snowflake.createStatement({ sqlText: sqlText }).execute();
  }
}

// Helper: Write an entry to PIPELINE_JOB_LOG for audit trail
function writePipelineLog(jobId, status, fileName, details) {
  var details_str = details === undefined || details === null ? '' : String(details);
  var insertSql = `INSERT INTO ` + audit_log_fq + 
    ` (JOB_ID, JOB_NAME, FILE_NAME, STATUS, DETAILS, RUN_AT)
       VALUES (:1,:2,:3,:4,:5,CURRENT_TIMESTAMP())`;
  runSql(insertSql, [jobId, job_name, fileName, status, details_str]);
}

// Helper: Write a detailed error message to ERROR_LOG
function writeErrorLog(fileName, errorDetails) {
  var insertSql = `INSERT INTO ` + error_log_fq + 
    ` (FILE_NAME, ERROR_DETAILS, CREATED_AT) VALUES (:1,:2,CURRENT_TIMESTAMP())`;
  runSql(insertSql, [fileName, errorDetails]);
}

// Helper: Send email notifications on job failure (best-effort)
function notifyFailure(subject, body) {
  try {
    // Aggregate all recipients from EMAIL_RECIPIENTS table
    var r = runSql('SELECT LISTAGG(RECIPIENT_EMAIL, \',\') AS EMAILS FROM ' + email_recipients_fq);
    var recipients = '';
    if (r.next()) recipients = r.getColumnValue(1) || '';
    recipients = String(recipients).trim();

    // Only send email if recipient list is not empty
    if (recipients !== '') {
      var callSql = `CALL SYSTEM$SEND_EMAIL('` + notif_integration + 
                    `', '` + recipients.replace(/'/g,"") + `', ?, ?)`;
      snowflake.createStatement({ sqlText: callSql, binds: [subject, body] }).execute();
    }
  } catch(e) {
    // Ignore errors during notification
  }
}


/////////////////////////////////////////////
// 🧩 Step 3: Main SCD2 Processing Section //
/////////////////////////////////////////////

try {

  // Log job start in audit table
  writePipelineLog(job_id, 'STARTED', null, 'Job started: ' + job_id);

  //---------------------------------------------
  // 3.1  Describe STAGING table and validate it
  //---------------------------------------------
  var descSql = 'DESCRIBE TABLE ' + staging_table_fq;
  var descRs = runSql(descSql);
  var cols = [];
  while (descRs.next()) cols.push(descRs.getColumnValue(1));  // Capture column names

  // Expect at least 7 columns: EID, EName, Email, PhoneNo, Address, CompanyName, Exp
  if (cols.length < 7) {
    var msg = 'Invalid staging schema: found only ' + cols.length + ' columns.';
    writePipelineLog(job_id, 'FAILED', null, msg);
    throw new Error(msg);
  }

  // Select first 7 columns as core business fields
  var srcCols = cols.slice(0,7);

  // Helper: quote column names safely (in case of special characters)
  function quoteCol(c) { return '"' + c.replace(/"/g,'""') + '"'; }


  //---------------------------------------------------
  // 3.2  Ensure required columns exist (adds if missing)
  //---------------------------------------------------
  // Staging: provenance columns
  runSql(`ALTER TABLE ` + staging_table_fq + ` ADD COLUMN IF NOT EXISTS SOURCE_FILE STRING`);
  runSql(`ALTER TABLE ` + staging_table_fq + ` ADD COLUMN IF NOT EXISTS INGESTED_AT TIMESTAMP_NTZ`);
  // Curated: hash + batch lineage columns
  runSql(`ALTER TABLE ` + curated_table_fq + ` ADD COLUMN IF NOT EXISTS SRC_HASH STRING`);
  runSql(`ALTER TABLE ` + curated_table_fq + ` ADD COLUMN IF NOT EXISTS BATCH_ID STRING`);


  //---------------------------------------------------
  // 3.3  Deduplicate staging (deterministic by INGESTED_AT)
  //      + Compute normalized MD5 hash across tracked columns
  //---------------------------------------------------
  var dedup_sql = `
    CREATE OR REPLACE TEMP TABLE TMP_DEDUP_RAW_EMPLOYEE AS
    SELECT
      EID, EName, Email, PhoneNo, Address, CompanyName, Exp,
      SOURCE_FILE, INGESTED_AT,
      MD5(  -- Compute unique hash across lowercased & trimmed columns
        COALESCE(LOWER(TRIM(EName)),'') || '||' ||
        COALESCE(LOWER(TRIM(Email)),'') || '||' ||
        COALESCE(LOWER(TRIM(PhoneNo)),'') || '||' ||
        COALESCE(LOWER(TRIM(Address)),'') || '||' ||
        COALESCE(LOWER(TRIM(CompanyName)),'') || '||' ||
        COALESCE(LOWER(TRIM(Exp)),'')
      ) AS SRC_HASH
    FROM (
      SELECT
        ` + quoteCol(srcCols[0]) + ` AS EID,
        ` + quoteCol(srcCols[1]) + ` AS EName,
        ` + quoteCol(srcCols[2]) + ` AS Email,
        ` + quoteCol(srcCols[3]) + ` AS PhoneNo,
        ` + quoteCol(srcCols[4]) + ` AS Address,
        ` + quoteCol(srcCols[5]) + ` AS CompanyName,
        ` + quoteCol(srcCols[6]) + ` AS Exp,
        SOURCE_FILE,
        INGESTED_AT,
        ROW_NUMBER() OVER (
          PARTITION BY ` + quoteCol(srcCols[0]) + `
          ORDER BY INGESTED_AT DESC NULLS LAST, SOURCE_FILE DESC NULLS LAST
        ) AS rn
      FROM ` + staging_table_fq + `
      WHERE ` + quoteCol(srcCols[0]) + ` IS NOT NULL
    ) t
    WHERE rn = 1;`;
  runSql(dedup_sql);


  //---------------------------------------------------
  // 3.4  Count duplicates in STAGING (for audit info)
  //---------------------------------------------------
  var dupCountSql = `
    SELECT COUNT(*) AS DUP_COUNT
    FROM (
      SELECT ` + quoteCol(srcCols[0]) + `
      FROM ` + staging_table_fq + `
      GROUP BY ` + quoteCol(srcCols[0]) + `
      HAVING COUNT(*) > 1
    ) x;`;
  var dupRs = runSql(dupCountSql);
  if (dupRs.next()) dup_count = dupRs.getColumnValue(1) || 0;


  //---------------------------------------------------
  // 3.5  SCD2: Expire old rows where SRC_HASH differs
  //---------------------------------------------------
  var expire_sql = `
    UPDATE ` + curated_table_fq + ` T
    SET Is_Current = FALSE,
        End_Date = CURRENT_DATE()
    FROM TMP_DEDUP_RAW_EMPLOYEE S
    WHERE T.EID = S.EID
      AND T.Is_Current = TRUE
      AND NVL(T.SRC_HASH,'') <> NVL(S.SRC_HASH,'');`;
  runSql(expire_sql);


  //---------------------------------------------------
  // 3.6  SCD2: Insert new current rows for new/changed EIDs
  //---------------------------------------------------
  var insert_sql = `
    INSERT INTO ` + curated_table_fq + `
      (EID, EName, Email, PhoneNo, Address, CompanyName, Exp, 
       Start_Date, End_Date, Is_Current, SRC_HASH, BATCH_ID)
    SELECT
      S.EID, S.EName, S.Email, S.PhoneNo, S.Address, S.CompanyName, S.Exp,
      CURRENT_DATE(), NULL, TRUE,
      S.SRC_HASH,
      (S.SOURCE_FILE || '|' || '` + job_id + `') AS BATCH_ID
    FROM TMP_DEDUP_RAW_EMPLOYEE S
    LEFT JOIN ` + curated_table_fq + ` T
      ON T.EID = S.EID AND T.Is_Current = TRUE
    WHERE T.EID IS NULL
       OR NVL(T.SRC_HASH,'') <> NVL(S.SRC_HASH,'');`;
  runSql(insert_sql);


  //---------------------------------------------------
  // 3.7  Capture metrics for inserted, expired, total
  //---------------------------------------------------
  var insRs = runSql(`
    SELECT COUNT(*) AS INS
    FROM ` + curated_table_fq + ` c
    JOIN TMP_DEDUP_RAW_EMPLOYEE s ON c.EID = s.EID
    WHERE c.Is_Current = TRUE AND DATE(c.Start_Date) = CURRENT_DATE();`);
  if (insRs.next()) inserted_rows = insRs.getColumnValue(1) || 0;

  var updRs = runSql(`SELECT COUNT(*) AS UPD FROM ` + curated_table_fq + ` WHERE End_Date = CURRENT_DATE();`);
  if (updRs.next()) expired_rows = updRs.getColumnValue(1) || 0;

  var totRs = runSql(`SELECT COUNT(*) AS C FROM ` + curated_table_fq);
  if (totRs.next()) total_curated = totRs.getColumnValue(1) || 0;


  //---------------------------------------------------
  // 3.8  Write success audit log and return summary
  //---------------------------------------------------
  var end_time = new Date();
  var duration_sec = Math.round((end_time - start_time) / 1000);
  var summary = 'SCD2 run: job_id=' + job_id +
                ', inserted=' + inserted_rows +
                ', expired=' + expired_rows +
                ', dup_collapsed=' + dup_count +
                ', total_curated=' + total_curated +
                ', duration_s=' + duration_sec;

  writePipelineLog(job_id, 'SUCCESS', null, summary);

  // Return summary message to user
  return '✅ SUCCESS: ' + summary;


//////////////////////////////////////////
// 🧯 Step 4: Error handling and cleanup //
//////////////////////////////////////////
} catch (err) {

  // Sanitize error message
  var safeErr = (err && err.message) ? String(err.message).replace(/'/g,' ') : String(err);
  var end_time = new Date();
  var duration_sec = Math.round((end_time - start_time) / 1000);

  // Log to pipeline log
  try { writePipelineLog(job_id, 'FAILED', null, safeErr + ' | duration_s=' + duration_sec); } catch(e){}

  // Log to error table
  try { writeErrorLog(null, safeErr + ' | duration_s=' + duration_sec); } catch(e){}

  // Send notification (optional)
  try {
    var body = 'SCD2 job failed: ' + safeErr + '\nJob ID: ' + job_id + '\nDuration(s): ' + duration_sec;
    notifyFailure('❌ SCD2 job failed: ' + job_name, body);
  } catch(e){}

  // Return failed status
  return '❌ FAILED: ' + safeErr + ' | duration_s=' + duration_sec;
}

$$;

CALL DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM();

-- ✅ SUCCESS: SCD2 run: job_id=SP_PROCESS_EMPLOYEE_DIM_2025-11-01T02-29-42-030Z_9234, inserted=9958, expired=10563, dup_collapsed=6346, total_curated=20521, duration_s=4

-- 1️⃣2️⃣ CREATE AUTOMATED TASK
DROP TASK IF EXISTS DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM;

CREATE OR REPLACE TASK DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM
  WAREHOUSE = WH_ETL
  SCHEDULE = 'USING CRON */2 * * * * UTC'
  COMMENT = 'Runs SCD2 procedure every 2 minutes for testing.'
AS
  CALL DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM();

ALTER TASK DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM RESUME;  --  for starting task

ALTER TASK DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM SUSPEND; -- for suspending task

-- check log details for running SP
SELECT *
FROM DEMO_SCD2.AUDIT.PIPELINE_JOB_LOG
WHERE JOB_NAME = 'SP_PROCESS_EMPLOYEE_DIM'
ORDER BY RUN_AT DESC
LIMIT 10;

-- data quality checks and validation
SELECT C1,count(*)  --  6,346
FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE
GROUP BY 1
HAVING count(*) > 1
ORDER BY 2 DESC;

SELECT EID,count(*)  --  9,958
FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM
GROUP BY 1
HAVING count(*) > 1
ORDER BY 2 DESC;

SELECT count(*) FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM; -- 20,521 total records
SELECT count(*) FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM WHERE IS_CURRENT = FALSE; -- for 10,563 records address/email/office have have been changed
SELECT count(*) FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM WHERE IS_CURRENT = TRUE; -- 9958 are active records

-- multiple address -- E224062
SELECT
  C1,
  COUNT(DISTINCT C5) AS distinct_address_count,
  ARRAY_AGG(DISTINCT C5) AS addresses
FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE
GROUP BY C1
HAVING COUNT(DISTINCT C5) >= 2
ORDER BY distinct_address_count DESC, C1;

-- multiple email address -- E134800
SELECT
  C1,
  COUNT(DISTINCT C3) AS distinct_email_count,
  ARRAY_AGG(DISTINCT C3) AS multiple_email
FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE
GROUP BY C1
HAVING COUNT(DISTINCT C3) >= 2
ORDER BY distinct_email_count DESC, C1;

-- multiple companies -- E853602
SELECT
  C1,
  COUNT(DISTINCT C6) AS distinct_company_count,
  ARRAY_AGG(DISTINCT C6) AS multiple_companies
FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE
GROUP BY C1
HAVING COUNT(DISTINCT C6) >= 2
ORDER BY distinct_company_count DESC, C1;


-- Once you have an EID from the result above (for example E954337), inspect the exact staged rows:
-- This helps you verify which address is the latest (rn = 1) and which addresses are older (rn > 1).
SELECT *, ROW_NUMBER() OVER (PARTITION BY C1 ORDER BY INGESTED_AT DESC NULLS LAST) rn
FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE
WHERE C1 = 'E224062'
ORDER BY INGESTED_AT DESC, SOURCE_FILE DESC;


SELECT * FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE WHERE C1 = 'E414977'; -- 6 DUPLICATES no address chnage
SELECT * FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM WHERE EID = 'E414977'; -- duplicates removed

SELECT distinct * FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE WHERE C1 = 'E954337'; -- address chnaged multiple times
SELECT * FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM WHERE EID = 'E954337';

SELECT distinct * FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE WHERE C1 = 'E853602'; -- companies chnaged multiple times
SELECT * FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM WHERE EID = 'E853602';

SELECT * FROM DEMO_SCD2.CURATED.TMP_DEDUP_RAW_EMPLOYEE WHERE EID = 'E954337';

-- checking how the address has been chnaged
SELECT *, ROW_NUMBER() OVER (PARTITION BY C1 ORDER BY C1) AS rn
FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE
WHERE C1 = 'E954337';

