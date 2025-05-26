CREATE OR REPLACE PROCEDURE CEC_DB.PRIVATE_TEST.SP_LOAD_QMM_DIM_DATA_QUALITY_RULE_HIST()
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
try {
    // Step 1: Capture start time
    var stmt1 = snowflake.createStatement({sqlText: "SELECT current_timestamp()"});
    var rs1 = stmt1.execute(); rs1.next();
    var start_time = rs1.getColumnValue(1);

    // Step 2: Get max snapshot date from QMM_LOAD_STATUS (incremental snapshot logic)
    var stmt2 = snowflake.createStatement({
        sqlText: `SELECT TO_CHAR(DATEADD(day, 1, MAX(snapshot_date))) FROM CEC_DB_PRIVATE_TEST.QMM_LOAD_STATUS WHERE status IN ('success','skipped')`
    });
    var rs2 = stmt2.execute(); rs2.next();
    var snapshot_date = rs2.getColumnValue(1);

    // Step 3: Get last run date of this task from QMM_TASK_STATUS
    var stmt3 = snowflake.createStatement({
        sqlText: `SELECT TO_CHAR(MAX(snapshot_date)) FROM CEC_DB_PRIVATE_TEST.QMM_TASK_STATUS WHERE task_name = 'task_qmm_dim_data_quality_rule' AND status = 'success'`
    });
    var rs3 = stmt3.execute(); rs3.next();
    var snapshot_date_task = rs3.getColumnValue(1);

    // Step 4: Proceed only if new snapshot_date is available
    if (new Date(snapshot_date) > new Date(snapshot_date_task)) {

        // Step 5: Truncate TEMP table
        snowflake.createStatement({sqlText: `TRUNCATE TABLE CEC_DB.PRIVATE_TEST.TEMP_QMM_DIM_DATA_QUALITY_RULE_HIST`}).execute();

        // Step 6: Load data into TEMP table
        var insertTempSQL = `
        INSERT INTO CEC_DB.PRIVATE_TEST.TEMP_QMM_DIM_DATA_QUALITY_RULE_HIST (
            CHANGE_TYPE, DATASET_KEY, DQ_RULE_NAME, DQ_RULE_TYPE, DQ_RULE_DESCRIPTION, DQ_RULE_CATEGORY,
            DQ_RULE_STATUS, DQ_DIMENSION, DQ_RULE_UPDATION_STATUS, DQ_RULE_QUERY,
            SOURCE_SYSTEM_CATEGORY, CREATED_DATE, LAST_MODIFIED_DATE, SNAPSHOT_DATE, START_EFFECTIVE_DATE
        )
        WITH qmm_cte AS (
            SELECT DISTINCT
                DD.DATASET_KEY,
                DQMS.DQ_RULE_NAME,
                DQMS.DQ_RULE_TYPE,
                DQMS.DQ_RULE_DESCRIPTION,
                DQMS.DQ_RULE_CATEGORY,
                DQMS.DQ_RULE_STATUS,
                DQMS.DQ_DIMENSION,
                CASE
                    WHEN DQMS.DQ_RULE_STATUS = 'Active' AND DQMS.DQ_RULE_CREATED_DATE = DQMS.DQ_RULE_LAST_MODIFIED_DATE THEN 'Created'
                    WHEN DQMS.DQ_RULE_STATUS = 'Active' AND DQMS.DQ_RULE_CREATED_DATE < DQMS.DQ_RULE_LAST_MODIFIED_DATE THEN 'Modified'
                    WHEN DQMS.DQ_RULE_STATUS = 'Inactive' THEN 'Dropped'
                END AS DQ_RULE_UPDATION_STATUS,
                DQMS.DQ_RULE_QUERY,
                'INTERNAL' AS SOURCE_SYSTEM_CATEGORY,
                DQMS.DQ_RULE_CREATED_DATE,
                DQMS.DQ_RULE_LAST_MODIFIED_DATE,
                DQMS.SNAPSHOT_DATE,
                DQMS.DQ_RULE_LAST_MODIFIED_DATE AS START_EFFECTIVE_DATE
            FROM CEC_DB.PRIVATE_TEST.VW_DATA_QUALITY_METRICS_SUMMARY DQMS
            JOIN CEC_DB.PUBLISHED_TEST.DIM_DATASET DD
              ON DQMS.DD_DATASET_NAME = DD.DATASET_NAME
            WHERE DQMS.SNAPSHOT_DATE = ?
              AND DQMS.DQ_RULE_NAME IS NOT NULL
        )
        SELECT 'INSERTED', * FROM qmm_cte
        `;

        var insertStmt = snowflake.createStatement({ sqlText: insertTempSQL, binds: [snapshot_date] });
        insertStmt.execute();

        // Step 7: Insert from TEMP to FINAL target table (pure historical load)
        var insertTargetSQL = `
        INSERT INTO CEC_DB.PUBLISHED_TEST.QMM_DIM_DATA_QUALITY_RULE_HIST (
            DATASET_KEY, DQ_RULE_NAME, DQ_RULE_TYPE, DQ_RULE_DESCRIPTION, DQ_RULE_CATEGORY,
            DQ_RULE_STATUS, DQ_DIMENSION, DQ_RULE_UPDATION_STATUS, DQ_RULE_QUERY,
            SOURCE_SYSTEM_CATEGORY, CREATED_DATE, LAST_MODIFIED_DATE, START_EFFECTIVE_DATE,
            END_EFFECTIVE_DATE, SNAPSHOT_DATE, CURRENT_FLAG
        )
        SELECT 
            DATASET_KEY, DQ_RULE_NAME, DQ_RULE_TYPE, DQ_RULE_DESCRIPTION, DQ_RULE_CATEGORY,
            DQ_RULE_STATUS, DQ_DIMENSION, DQ_RULE_UPDATION_STATUS, DQ_RULE_QUERY,
            SOURCE_SYSTEM_CATEGORY, CREATED_DATE, LAST_MODIFIED_DATE, START_EFFECTIVE_DATE,
            NULL AS END_EFFECTIVE_DATE, SNAPSHOT_DATE, TRUE AS CURRENT_FLAG
        FROM CEC_DB.PRIVATE_TEST.TEMP_QMM_DIM_DATA_QUALITY_RULE_HIST
        `;

        snowflake.createStatement({sqlText: insertTargetSQL}).execute();

        return 'Procedure executed successfully for snapshot_date: ' + snapshot_date;
    } else {
        return 'No execution needed. snapshot_date (' + snapshot_date + ') <= snapshot_date_task (' + snapshot_date_task + ')';
    }
} catch(err) {
    return 'Error occurred: ' + err.message;
}
$$;
