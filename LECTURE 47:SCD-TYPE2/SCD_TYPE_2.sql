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

CREATE OR REPLACE PROCEDURE DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM()
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
/*
  Deterministic SCD2 stored procedure for DEMO_SCD2:
  - Ensures SOURCE_FILE and INGESTED_AT exist on staging
  - Dedup staging deterministically by INGESTED_AT (latest)
  - EXPIRE current rows that changed (Is_Current = FALSE, End_Date = CURRENT_DATE())
  - INSERT new current rows (Start_Date = CURRENT_DATE(), Is_Current = TRUE)
  - Write audit logs to AUDIT.PIPELINE_JOB_LOG and ERROR_LOG
  - Best-effort email using EMAIL_INT and AUDIT.EMAIL_RECIPIENTS
*/
var start_time = new Date();
var inserted_rows = 0;
var expired_rows = 0;
var dup_count = 0;
var total_curated = 0;

// Config (change if your DB/schema names differ)
var db = 'DEMO_SCD2';
var staging_schema = 'STAGING';
var staging_table = 'RAW_EMPLOYEE';
var staging_table_fq = db + '.' + staging_schema + '.' + staging_table;
var curated_table_fq = db + '.CURATED.EMPLOYEE_DIM';
var audit_log_fq = db + '.AUDIT.PIPELINE_JOB_LOG';
var error_log_fq = db + '.AUDIT.ERROR_LOG';
var email_recipients_fq = db + '.AUDIT.EMAIL_RECIPIENTS';
var notif_integration = 'EMAIL_INT';
var job_name = 'SP_PROCESS_EMPLOYEE_DIM';
var job_id = job_name + '_' + (new Date()).toISOString().replace(/[:.]/g,'-') + '_' + Math.floor(Math.random()*10000);

// Helper to run SQL (with optional binds)
function runSql(sqlText, binds) {
  if (binds && Array.isArray(binds)) {
    return snowflake.createStatement({ sqlText: sqlText, binds: binds }).execute();
  } else {
    return snowflake.createStatement({ sqlText: sqlText }).execute();
  }
}

// Write pipeline log
function writePipelineLog(status, fileName, details) {
  var details_str = details === undefined || details === null ? '' : String(details);
  var insertSql = `INSERT INTO ` + audit_log_fq + ` (JOB_ID, JOB_NAME, FILE_NAME, STATUS, DETAILS, RUN_AT)
                   VALUES (:1,:2,:3,:4,:5,CURRENT_TIMESTAMP())`;
  runSql(insertSql, [job_id, job_name, fileName, status, details_str]);
}

// Write error log
function writeErrorLog(fileName, errorDetails) {
  var insertSql = `INSERT INTO ` + error_log_fq + ` (FILE_NAME, ERROR_DETAILS, CREATED_AT) VALUES (:1,:2,CURRENT_TIMESTAMP())`;
  runSql(insertSql, [fileName, errorDetails]);
}

// Send failure email (best-effort)
function notifyFailure(subject, body) {
  try {
    var r = runSql('SELECT LISTAGG(RECIPIENT_EMAIL, \',\') AS EMAILS FROM ' + email_recipients_fq);
    var recipients = '';
    if (r.next()) recipients = r.getColumnValue(1) || '';
    recipients = String(recipients).trim();
    if (recipients !== '') {
      // Use binds for subject/body
      var callSql = `CALL SYSTEM$SEND_EMAIL('` + notif_integration + `', '` + recipients.replace(/'/g,"") + `', ?, ?)`;
      snowflake.createStatement({ sqlText: callSql, binds: [subject, body] }).execute();
    }
  } catch(e) {
    // swallow - email is best-effort
  }
}

try {
  // 0) START log
  writePipelineLog('STARTED', null, 'Job started: ' + job_id);

  // 1) Discover staging columns: ensure at least 7 columns (EID, EName, Email, PhoneNo, Address, CompanyName, Exp)
  var descSql = 'DESCRIBE TABLE ' + staging_table_fq;
  var descStmt = snowflake.createStatement({ sqlText: descSql });
  var descRs = descStmt.execute();
  var cols = [];
  while (descRs.next()) cols.push(descRs.getColumnValue(1));
  if (cols.length < 7) {
    var msg = 'Staging table has less than 7 columns. Found ' + cols.length;
    writePipelineLog('FAILED', null, msg);
    throw new Error(msg);
  }
  // Use first 7 columns for business attributes
  var srcCols = cols.slice(0,7);

  function quoteCol(colName) {
    return '"' + colName.replace(/"/g,'""') + '"';
  }

  // 2) Ensure provenance columns SOURCE_FILE and INGESTED_AT exist (safe to run repeatedly)
  var alter1 = `ALTER TABLE ` + staging_table_fq + ` ADD COLUMN IF NOT EXISTS SOURCE_FILE STRING`;
  var alter2 = `ALTER TABLE ` + staging_table_fq + ` ADD COLUMN IF NOT EXISTS INGESTED_AT TIMESTAMP_NTZ`;
  runSql(alter1);
  runSql(alter2);

  // 3) Deterministic dedupe: pick latest row per EID by INGESTED_AT (fall back to SOURCE_FILE ordering)
  //   Generates TMP_DEDUP_RAW_EMPLOYEE with one row per EID (latest)
  var dedup_sql = `
    CREATE OR REPLACE TEMP TABLE TMP_DEDUP_RAW_EMPLOYEE AS
    SELECT EID, EName, Email, PhoneNo, Address, CompanyName, Exp, SOURCE_FILE, INGESTED_AT
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
        ROW_NUMBER() OVER (PARTITION BY ` + quoteCol(srcCols[0]) + ` 
                           ORDER BY INGESTED_AT DESC NULLS LAST, SOURCE_FILE DESC NULLS LAST) AS rn
      FROM ` + staging_table_fq + `
      WHERE ` + quoteCol(srcCols[0]) + ` IS NOT NULL
    ) t
    WHERE rn = 1;
  `;
  runSql(dedup_sql);

  // 4) Count duplicates in staging (for logging)
  var dupCountSql = `
    SELECT COUNT(*) AS DUP_COUNT
    FROM (
      SELECT ` + quoteCol(srcCols[0]) + `
      FROM ` + staging_table_fq + `
      GROUP BY ` + quoteCol(srcCols[0]) + `
      HAVING COUNT(*) > 1
    ) x;
  `;
  var dupStmt = runSql(dupCountSql);
  if (dupStmt.next()) dup_count = dupStmt.getColumnValue(1) || 0;

  // 5A) EXPIRE current curated rows where any tracked attribute differs (SCD2 expire)
  var expire_sql = `
    UPDATE ` + curated_table_fq + ` T
    SET Is_Current = FALSE,
        End_Date = CURRENT_DATE()
    FROM TMP_DEDUP_RAW_EMPLOYEE S
    WHERE T.EID = S.EID
      AND T.Is_Current = TRUE
      AND (
         NVL(T.EName,'') <> NVL(S.EName,'')
      OR NVL(T.Email,'') <> NVL(S.Email,'')
      OR NVL(T.PhoneNo,'') <> NVL(S.PhoneNo,'')
      OR NVL(T.Address,'') <> NVL(S.Address,'')
      OR NVL(T.CompanyName,'') <> NVL(S.CompanyName,'')
      OR NVL(T.Exp,'') <> NVL(S.Exp,'')
    );
  `;
  runSql(expire_sql);

  // 5B) INSERT new current rows for new employees or changed employees
  var insert_sql = `
    INSERT INTO ` + curated_table_fq + ` (EID, EName, Email, PhoneNo, Address, CompanyName, Exp, Start_Date, End_Date, Is_Current)
    SELECT S.EID, S.EName, S.Email, S.PhoneNo, S.Address, S.CompanyName, S.Exp, CURRENT_DATE(), NULL, TRUE
    FROM TMP_DEDUP_RAW_EMPLOYEE S
    LEFT JOIN ` + curated_table_fq + ` T
      ON T.EID = S.EID AND T.Is_Current = TRUE
    WHERE T.EID IS NULL
      OR (
         NVL(T.EName,'') <> NVL(S.EName,'')
      OR NVL(T.Email,'') <> NVL(S.Email,'')
      OR NVL(T.PhoneNo,'') <> NVL(S.PhoneNo,'')
      OR NVL(T.Address,'') <> NVL(S.Address,'')
      OR NVL(T.CompanyName,'') <> NVL(S.CompanyName,'')
      OR NVL(T.Exp,'') <> NVL(S.Exp,'')
    );
  `;
  runSql(insert_sql);

  // 6) Metrics: inserted rows are rows in curated that started today and are current joined to TMP_DEDUP
  var insRs = runSql(`
    SELECT COUNT(*) AS INS
    FROM ` + curated_table_fq + ` c
    JOIN TMP_DEDUP_RAW_EMPLOYEE s ON c.EID = s.EID
    WHERE c.Is_Current = TRUE AND DATE(c.Start_Date) = CURRENT_DATE()
  `);
  if (insRs.next()) inserted_rows = insRs.getColumnValue(1) || 0;

  // expired rows: count rows in curated with End_Date = CURRENT_DATE()
  var updRs = runSql(`SELECT COUNT(*) AS UPD FROM ` + curated_table_fq + ` WHERE End_Date = CURRENT_DATE()`);
  if (updRs.next()) expired_rows = updRs.getColumnValue(1) || 0;

  // total curated
  var totRs = runSql(`SELECT COUNT(*) AS C FROM ` + curated_table_fq);
  if (totRs.next()) total_curated = totRs.getColumnValue(1) || 0;

  // 7) Success log
  var end_time = new Date();
  var duration_sec = Math.round((end_time - start_time) / 1000);
  var summary = 'SCD2 run: job_id=' + job_id + ', inserted=' + inserted_rows + ', expired=' + expired_rows + ', dup_collapsed=' + dup_count + ', total_curated=' + total_curated + ', duration_s=' + duration_sec;
  writePipelineLog('SUCCESS', null, summary);

  return 'SUCCESS: ' + summary;

} catch (err) {
  // sanitize
  var safeErr = (err && err.message) ? String(err.message).replace(/'/g,' ') : String(err);
  var end_time = new Date();
  var duration_sec = Math.round((end_time - start_time) / 1000);

  // write pipeline log failed
  try { writePipelineLog('FAILED', null, safeErr + ' | duration_s=' + duration_sec); } catch(e){}

  // write error log
  try { writeErrorLog(null, safeErr + ' | duration_s=' + duration_sec); } catch(e){}

  // notify failure (best effort)
  try {
    var body = 'SCD2 job failed: ' + safeErr + '\nJob ID: ' + job_id + '\nDuration(s): ' + duration_sec;
    notifyFailure('❌ SCD2 job failed: ' + job_name, body);
  } catch(e){}

  return 'FAILED: ' + safeErr + ' | duration_s=' + duration_sec;
}
$$;

CALL DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM();

-- SUCCESS: SCD2 run: inserted=9958, expired=0, dup_collapsed=3928, total_curated=9958, duration_s=3

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
SELECT C1,count(*)  --  3,928
FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE
GROUP BY 1
HAVING count(*) > 1
ORDER BY 2 DESC;

SELECT EID,count(*)  --  605
FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM
GROUP BY 1
HAVING count(*) > 1
ORDER BY 2 DESC;

SELECT count(*) FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM; -- 10,563 total records
SELECT count(*) FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM WHERE IS_CURRENT = FALSE; -- for 605 records address have have been changed
SELECT count(*) FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM WHERE IS_CURRENT = TRUE; -- 9958 are active records

-- for which EID do we have multiple address
SELECT
  C1,
  COUNT(DISTINCT C5) AS distinct_address_count,
  ARRAY_AGG(DISTINCT C5)          AS addresses
FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE
GROUP BY C1
HAVING COUNT(DISTINCT C5) >= 2
ORDER BY distinct_address_count DESC, C1;

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

SELECT * FROM DEMO_SCD2.CURATED.TMP_DEDUP_RAW_EMPLOYEE WHERE EID = 'E954337';

-- checking how the address has been chnaged
SELECT *, ROW_NUMBER() OVER (PARTITION BY C1 ORDER BY C1) AS rn
FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE
WHERE C1 = 'E954337';






