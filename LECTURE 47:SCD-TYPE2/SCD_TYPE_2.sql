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
CREATE DATABASE IF NOT EXISTS DEMO_SCD2;
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
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::749661020566:role/scd2-demo-bucket'
  STORAGE_ALLOWED_LOCATIONS = ('s3://scd2-demo-bucket/data_batches/')
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
  URL = 's3://scd2-demo-bucket/data_batches/'
  FILE_FORMAT = RAW.CSV_FORMAT;

-- 6️⃣ INFER SCHEMA FROM SAMPLE FILE
CREATE OR REPLACE TABLE STAGING.RAW_EMPLOYEE
  USING TEMPLATE (
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
    FROM TABLE(INFER_SCHEMA(
      LOCATION=>'@RAW.S3_BATCH_STAGE/batch1.csv',
      FILE_FORMAT=>'RAW.CSV_FORMAT'
    ))
  );

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
  ('Admin', 'analyticswithanand@gmail.com');

-- 9️⃣ CREATE EMAIL NOTIFICATION INTEGRATION
CREATE OR REPLACE NOTIFICATION INTEGRATION EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ( 'analyticswithanand@gmail.com');

DESC INTEGRATION EMAIL_INT;

-- 🔟 ROLE & PRIVILEGE SETUP
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

-- 1️⃣1️⃣ CREATE STORED PROCEDURE (SCD2 + EMAIL ON FAILURE)


CREATE OR REPLACE PROCEDURE DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM()
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
var dup_count = 0;
var inserted_rows = 0;
var updated_rows = 0;
var total_curated = 0;
var start_time = new Date();

try {
    var db = 'DEMO_SCD2';
    var staging_schema = 'STAGING';
    var staging_table = 'RAW_EMPLOYEE';
    var curated_table_fq = db + '.CURATED.EMPLOYEE_DIM';
    var staging_table_fq = db + '.' + staging_schema + '.' + staging_table;
    var email_table_fq = db + '.AUDIT.EMAIL_RECIPIENTS';
    var log_table_fq = db + '.AUDIT.PIPELINE_JOB_LOG';
    var notif_integration = 'EMAIL_INT';
    var job_name = 'SP_PROCESS_EMPLOYEE_DIM';

    // 1️⃣ Discover staging columns
    var descSql = `DESCRIBE TABLE ` + staging_table_fq;
    var descStmt = snowflake.createStatement({ sqlText: descSql });
    var descRs = descStmt.execute();
    var cols = [];
    while (descRs.next()) cols.push(descRs.getColumnValue(1));
    if (cols.length < 7) throw new Error('Staging table has less than 7 columns. Found ' + cols.length);
    var srcCols = cols.slice(0,7);

    function quoteCol(colName) {
        var clean = colName.replace(/"/g, '""');
        return '"' + clean + '"';
    }

    // 2️⃣ Deduplication
    var dedup_sql = `
      CREATE OR REPLACE TEMP TABLE TMP_DEDUP_RAW_EMPLOYEE AS
      SELECT
        ` + quoteCol(srcCols[0]) + ` AS EID,
        ANY_VALUE(` + quoteCol(srcCols[1]) + `) AS EName,
        ANY_VALUE(` + quoteCol(srcCols[2]) + `) AS Email,
        ANY_VALUE(` + quoteCol(srcCols[3]) + `) AS PhoneNo,
        ANY_VALUE(` + quoteCol(srcCols[4]) + `) AS Address,
        ANY_VALUE(` + quoteCol(srcCols[5]) + `) AS CompanyName,
        ANY_VALUE(` + quoteCol(srcCols[6]) + `) AS Exp
      FROM ` + staging_table_fq + `
      WHERE ` + quoteCol(srcCols[0]) + ` IS NOT NULL
      GROUP BY ` + quoteCol(srcCols[0]) + `;
    `;
    snowflake.createStatement({ sqlText: dedup_sql }).execute();

    // 3️⃣ Count duplicates
    var dupCountSql = `
      SELECT COUNT(*) AS DUP_COUNT
      FROM (
        SELECT ` + quoteCol(srcCols[0]) + `
        FROM ` + staging_table_fq + `
        GROUP BY ` + quoteCol(srcCols[0]) + `
        HAVING COUNT(*) > 1
      ) t;
    `;
    var dupStmt = snowflake.createStatement({ sqlText: dupCountSql });
    var dupRs = dupStmt.execute();
    if (dupRs.next()) dup_count = dupRs.getColumnValue('DUP_COUNT') || 0;

    // 4️⃣ MERGE
    var merge_sql = `
      MERGE INTO ` + curated_table_fq + ` AS T
      USING TMP_DEDUP_RAW_EMPLOYEE AS S
      ON T.EID = S.EID AND T.Is_Current = TRUE
      WHEN MATCHED AND (
        NVL(T.EName,'') <> NVL(S.EName,'') OR
        NVL(T.Email,'') <> NVL(S.Email,'') OR
        NVL(T.PhoneNo,'') <> NVL(S.PhoneNo,'') OR
        NVL(T.Address,'') <> NVL(S.Address,'') OR
        NVL(T.CompanyName,'') <> NVL(S.CompanyName,'') OR
        NVL(T.Exp,'') <> NVL(S.Exp,'')
      )
        THEN UPDATE SET
          T.Is_Current = FALSE,
          T.End_Date = CURRENT_DATE()
      WHEN NOT MATCHED THEN
        INSERT (EID, EName, Email, PhoneNo, Address, CompanyName, Exp, Start_Date, End_Date, Is_Current)
        VALUES (S.EID, S.EName, S.Email, S.PhoneNo, S.Address, S.CompanyName, S.Exp, CURRENT_DATE(), NULL, TRUE);
    `;
    var mergeStmt = snowflake.createStatement({ sqlText: merge_sql });
    mergeStmt.execute();

    // 5️⃣ Capture merge metrics safely
    try {
        var qidRs = snowflake.createStatement({ sqlText: "SELECT LAST_QUERY_ID() AS QID" }).execute();
        if (qidRs.next()) {
            var qid = qidRs.getColumnValue('QID');
            var resultSql = `
                SELECT *
                FROM TABLE(RESULT_SCAN('` + qid + `'))
                LIMIT 1;
            `;
            var testRs = snowflake.createStatement({ sqlText: resultSql }).execute();
            if (testRs.next()) {
                // we know RESULT_SCAN returned something — check if METRIC_NAME exists
                var colsMeta = testRs.getColumnValueNames ? testRs.getColumnValueNames() : [];
                if (colsMeta && colsMeta.indexOf('METRIC_NAME') !== -1) {
                    var metricSql = `
                        SELECT
                          SUM(CASE WHEN METRIC_NAME = 'Rows Updated' THEN METRIC_VALUE ELSE 0 END) AS UPDATED_ROWS,
                          SUM(CASE WHEN METRIC_NAME = 'Rows Inserted' THEN METRIC_VALUE ELSE 0 END) AS INSERTED_ROWS
                        FROM TABLE(RESULT_SCAN('` + qid + `'))
                        WHERE METRIC_NAME IN ('Rows Inserted','Rows Updated');
                    `;
                    var resStmt = snowflake.createStatement({ sqlText: metricSql });
                    var resRs = resStmt.execute();
                    if (resRs.next()) {
                        inserted_rows = resRs.getColumnValue('INSERTED_ROWS') || 0;
                        updated_rows = resRs.getColumnValue('UPDATED_ROWS') || 0;
                    }
                }
            }
        }
    } catch (mErr) {
        inserted_rows = inserted_rows || 0;
        updated_rows = updated_rows || 0;
    }

    // 6️⃣ Get total curated record count
    try {
        var cnt_rs = snowflake.createStatement({ sqlText: `SELECT COUNT(*) AS TOTAL_CURATED FROM ` + curated_table_fq }).execute();
        if (cnt_rs.next()) total_curated = cnt_rs.getColumnValue('TOTAL_CURATED') || 0;
    } catch(e) {}

    // 7️⃣ Log success
    var end_time = new Date();
    var duration_sec = Math.round((end_time - start_time) / 1000);
    var log_msg = 'SCD2 Merge completed successfully. Inserted: ' + inserted_rows +
                  ', Updated: ' + updated_rows +
                  ', Duplicates collapsed: ' + dup_count +
                  ', Total curated rows: ' + total_curated +
                  ', Duration: ' + duration_sec + ' sec';
    snowflake.createStatement({
        sqlText: `INSERT INTO ` + log_table_fq + ` (JOB_NAME, STATUS, DETAILS, RUN_AT) VALUES (:1,:2,:3,CURRENT_TIMESTAMP())`,
        binds: [job_name, 'SUCCESS', log_msg]
    }).execute();

    return '✅ ' + log_msg;

} catch (err) {
    var safeErr = (err && err.message) ? err.message.replace(/'/g," ") : '';
    var end_time = new Date();
    var duration_sec = Math.round((end_time - start_time) / 1000);

    // Log failure
    try {
        snowflake.createStatement({
            sqlText: `INSERT INTO DEMO_SCD2.AUDIT.PIPELINE_JOB_LOG (JOB_NAME, STATUS, DETAILS, RUN_AT)
                      VALUES (:1,:2,:3,CURRENT_TIMESTAMP())`,
            binds: ['SP_PROCESS_EMPLOYEE_DIM','FAILED', safeErr + ' | Duration: ' + duration_sec + ' sec']
        }).execute();
    } catch (logErr) {}

    // Email on failure
    try {
        var emaAgg = snowflake.createStatement({
            sqlText: `SELECT LISTAGG(RECIPIENT_EMAIL, ',') AS EMAIL_LIST FROM DEMO_SCD2.AUDIT.EMAIL_RECIPIENTS`
        }).execute();
        var recipients = '';
        if (emaAgg.next()) recipients = emaAgg.getColumnValue(1) || '';
        if (recipients && recipients.trim() !== '') {
            var email_body = '❌ SCD2 Job Failed: SP_PROCESS_EMPLOYEE_DIM\\n\\n'
                           + 'Error: ' + safeErr + '\\n\\n'
                           + 'Duration: ' + duration_sec + ' sec\\n'
                           + 'Inserted: ' + inserted_rows + '\\n'
                           + 'Updated: ' + updated_rows + '\\n'
                           + 'Total curated: ' + total_curated + '\\n\\n'
                           + 'Please check AUDIT.PIPELINE_JOB_LOG for details.';
            var failMailSql = `
                CALL SYSTEM$SEND_EMAIL(
                    '` + notif_integration + `',
                    '` + recipients.replace(/'/g,"") + `',
                    '❌ SCD2 job failed',
                    ?
                );
            `;
            snowflake.createStatement({ sqlText: failMailSql, binds: [email_body] }).execute();
        }
    } catch(mailErr) {}

    return '❌ SCD2 job failed: ' + safeErr + ' | Duration: ' + duration_sec + ' sec';
}
$$;




-- 1️⃣2️⃣ CREATE AUTOMATED TASK
DROP TASK IF EXISTS DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM;

CREATE OR REPLACE TASK DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM
  WAREHOUSE = WH_ETL
  SCHEDULE = 'USING CRON */2 * * * * UTC'
  COMMENT = 'Runs SCD2 procedure every 2 minutes for testing.'
AS
  CALL DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM();

ALTER TASK DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM RESUME;

ALTER TASK DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM SUSPEND;


-- Test run
CALL DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM();

-- ✅ END OF COMPLETE WORKFLOW SETUP
-- ============================================================






--------------------------------------------------------------------------------------------------------------------------

-- **********************************************************************
-- 🏁 SCD TYPE-2 END-TO-END TESTING AND MONITORING SCRIPT (UPDATED)
-- **********************************************************************

USE ROLE SYSADMIN;
USE DATABASE DEMO_SCD2;
USE SCHEMA CURATED;

-- =========================================================================
-- STEP 1️⃣ — VERIFY ENVIRONMENT SETUP
-- =========================================================================
SHOW INTEGRATIONS LIKE 'S3_SNOWFLAKE_INT';
SHOW INTEGRATIONS LIKE 'EMAIL_INT';
SHOW STAGES IN SCHEMA DEMO_SCD2.RAW;
SHOW TASKS IN SCHEMA DEMO_SCD2.CURATED;
SHOW PROCEDURES IN SCHEMA DEMO_SCD2.CURATED;
SHOW TABLES IN SCHEMA DEMO_SCD2.CURATED;
SHOW TABLES IN SCHEMA DEMO_SCD2.STAGING;
SHOW TABLES IN SCHEMA DEMO_SCD2.AUDIT;

-- =========================================================================
-- STEP 2️⃣ — LOAD BATCHES FROM S3 (or local upload)
-- =========================================================================
-- Assumes S3 bucket path: s3://scd2-demo-bucket/data_batches/
-- and that batch1.csv, batch2.csv, batch3.csv, batch4.csv are uploaded there

-- Check file availability on the canonical stage
LIST @DEMO_SCD2.RAW.S3_BATCH_STAGE;

-- Preview one file (first 5 rows)
SELECT $1, $2, $3, $4, $5, $6, $7
FROM @DEMO_SCD2.RAW.S3_BATCH_STAGE (FILE_FORMAT => DEMO_SCD2.RAW.CSV_FORMAT, PATTERN => '.*batch1.*')
LIMIT 5;

-- =========================================================================
-- STEP 3️⃣ — INITIAL LOAD (Batch 1)
-- =========================================================================
COPY INTO DEMO_SCD2.STAGING.RAW_EMPLOYEE
FROM @DEMO_SCD2.RAW.S3_BATCH_STAGE
FILES = ('batch1.csv')
FILE_FORMAT = (FORMAT_NAME = DEMO_SCD2.RAW.CSV_FORMAT)
ON_ERROR = 'CONTINUE';

CALL DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM();

-- Verify after batch 1
SELECT COUNT(*) AS TOTAL_AFTER_BATCH1 FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM;
SELECT * FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM SAMPLE (10);

-- =========================================================================
-- STEP 4️⃣ — SECOND LOAD (Batch 2: new + updates)
-- =========================================================================
COPY INTO DEMO_SCD2.STAGING.RAW_EMPLOYEE
FROM @DEMO_SCD2.RAW.S3_BATCH_STAGE
FILES = ('batch2.csv')
FILE_FORMAT = (FORMAT_NAME = DEMO_SCD2.RAW.CSV_FORMAT)
ON_ERROR = 'CONTINUE';

CALL DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM();

-- Check SCD2 behavior (old records closed, new active)
SELECT 
  EID, EName, Email, Address, CompanyName, Exp, 
  Start_Date, End_Date, Is_Current
FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM
WHERE EID IN (SELECT /* top 10 from staging for quick check */ 
                  (SELECT "c1" FROM DEMO_SCD2.STAGING.RAW_EMPLOYEE LIMIT 1))
ORDER BY EID, Start_Date
LIMIT 50;

-- =========================================================================
-- STEP 5️⃣ — THIRD LOAD (Batch 3)
-- =========================================================================
COPY INTO DEMO_SCD2.STAGING.RAW_EMPLOYEE
FROM @DEMO_SCD2.RAW.S3_BATCH_STAGE
FILES = ('batch3.csv')
FILE_FORMAT = (FORMAT_NAME = DEMO_SCD2.RAW.CSV_FORMAT)
ON_ERROR = 'CONTINUE';

CALL DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM();

-- Verify active/inactive counts
SELECT 
  COUNT_IF(Is_Current) AS ACTIVE_RECORDS,
  COUNT_IF(NOT Is_Current) AS INACTIVE_RECORDS,
  COUNT(*) AS TOTAL_RECORDS
FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM;

-- =========================================================================
-- STEP 6️⃣ — FOURTH LOAD (Batch 4)
-- =========================================================================
COPY INTO DEMO_SCD2.STAGING.RAW_EMPLOYEE
FROM @DEMO_SCD2.RAW.S3_BATCH_STAGE
FILES = ('batch4.csv')
FILE_FORMAT = (FORMAT_NAME = DEMO_SCD2.RAW.CSV_FORMAT)
ON_ERROR = 'CONTINUE';

CALL DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM();

-- =========================================================================
-- STEP 7️⃣ — VALIDATE DATA VERSIONING
-- =========================================================================
-- Each changed employee should have multiple records
SELECT EID, COUNT(*) AS VERSION_COUNT
FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM
GROUP BY EID
HAVING COUNT(*) > 1
ORDER BY VERSION_COUNT DESC
LIMIT 10;

-- Show a specific employee’s version history (sample)
-- Check one random employee's version history
WITH one_eid AS (
  SELECT EID FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM
  QUALIFY ROW_NUMBER() OVER (ORDER BY RANDOM()) = 1
)
SELECT *
FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM
WHERE EID = (SELECT EID FROM one_eid)
ORDER BY Start_Date;


-- =========================================================================
-- STEP 8️⃣ — CHECK AUDIT LOGS AND JOB STATUS
-- =========================================================================
SELECT * 
FROM DEMO_SCD2.AUDIT.PIPELINE_JOB_LOG
ORDER BY RUN_AT DESC
LIMIT 20;

-- Health summary (per job)
SELECT 
  JOB_NAME,
  COUNT_IF(STATUS='SUCCESS') AS SUCCESS_COUNT,
  COUNT_IF(STATUS='FAILED') AS FAILURE_COUNT,
  MAX(RUN_AT) AS LAST_RUN
FROM DEMO_SCD2.AUDIT.PIPELINE_JOB_LOG
GROUP BY JOB_NAME
ORDER BY LAST_RUN DESC;

-- =========================================================================
-- STEP 9️⃣ — VALIDATE AUTOMATED TASK EXECUTION
-- =========================================================================
SHOW TASKS IN SCHEMA DEMO_SCD2.CURATED LIKE 'TASK_SCD2_TEST';
SELECT * 
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
  SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP()),
  RESULT_LIMIT => 20
));

-- To manually trigger task run (fully-qualified)
EXECUTE TASK DEMO_SCD2.CURATED.TASK_SCD2_TEST;

-- =========================================================================
-- 🔟 — TEST FAILURE SCENARIO (for Email Notification)
-- =========================================================================
-- Option A: Force bad data — insert one bad row into staging (7 columns expected)
INSERT INTO DEMO_SCD2.STAGING.RAW_EMPLOYEE VALUES
('TEST_NULL_EID', 'TestError', 'bademail', '0000000000', 'Nowhere', 'BrokenCorp', '5');

CALL DEMO_SCD2.CURATED.SP_PROCESS_EMPLOYEE_DIM();

-- Option B: Trigger SQL failure manually (example)
BEGIN
  INSERT INTO DEMO_SCD2.NON_EXISTING_TABLE VALUES (1);  -- Force error
EXCEPTION
  WHEN OTHER THEN
    INSERT INTO DEMO_SCD2.AUDIT.PIPELINE_JOB_LOG (JOB_NAME, STATUS, DETAILS, RUN_AT)
    VALUES ('SP_PROCESS_EMPLOYEE_DIM', 'FAILED', 'Manual Failure Triggered', CURRENT_TIMESTAMP());
END;

-- Check for failure entry
SELECT * 
FROM DEMO_SCD2.AUDIT.PIPELINE_JOB_LOG 
WHERE STATUS = 'FAILED'
ORDER BY RUN_AT DESC
LIMIT 5;

-- =========================================================================
-- STEP 1️⃣1️⃣ — VERIFY EMAIL NOTIFICATION DELIVERY
-- =========================================================================
-- (Manually check the inbox of recipients defined in DEMO_SCD2.AUDIT.EMAIL_RECIPIENTS)
SELECT * FROM DEMO_SCD2.AUDIT.EMAIL_RECIPIENTS;

-- =========================================================================
-- STEP 1️⃣2️⃣ — CONTINUOUS MONITORING DASHBOARD
-- =========================================================================
-- Monitor last 24h task runs
SELECT 
  NAME,
  STATE,
  SCHEDULED_TIME,
  COMPLETED_TIME,
  RETURN_VALUE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
  SCHEDULED_TIME_RANGE_START => DATEADD('day', -1, CURRENT_TIMESTAMP()),
  RESULT_LIMIT => 50
))
ORDER BY SCHEDULED_TIME DESC;

-- Stream activity check (if using STREAM on CURATED table)
SHOW STREAMS IN SCHEMA DEMO_SCD2.CURATED;
-- If you created a stream named STR_EMP you can check:
-- SELECT SYSTEM$STREAM_HAS_DATA('DEMO_SCD2.CURATED.STR_EMP');

-- =========================================================================
-- STEP 1️⃣3️⃣ — CLEANUP (optional after testing)
-- =========================================================================
-- TRUNCATE TABLE DEMO_SCD2.STAGING.RAW_EMPLOYEE;
-- DELETE FROM DEMO_SCD2.CURATED.EMPLOYEE_DIM WHERE EName LIKE 'Test%';
-- DELETE FROM DEMO_SCD2.AUDIT.PIPELINE_JOB_LOG WHERE JOB_NAME='SP_PROCESS_EMPLOYEE_DIM' AND STATUS='FAILED';
-- ALTER TASK DEMO_SCD2.CURATED.TASK_SCD2_TEST SUSPEND;




