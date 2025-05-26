CREATE OR REPLACE PROCEDURE CEC.DB_PRIVATE_TEST.SP_LOAD_DIM_DATA_QUALITY_RULE()
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
try {
    var snapshotDateSql = `
        SELECT DATEADD(day, 1, MAX(snapshot_date)) AS next_snapshot
        FROM CEC_DB.PRIVATE_TEST.QMM_LOAD_STATUS 
        WHERE status IN ('success', 'skipped')
    `;
    
    var stmt1 = snowflake.createStatement({sqlText: snapshotDateSql});
    var rs1 = stmt1.execute();
    var snapshotDate = null;

    if (rs1.next()) {
        snapshotDate = rs1.getColumnValue('NEXT_SNAPSHOT');
    }

    if (!snapshotDate) {
        return 'No valid snapshot date found. Load aborted.';
    }

    var insertSql = `
        INSERT INTO CEC_DB.PUBLISHED_TEST.QMM_DIM_DATA_QUALITY_RULE_HIST (
            DATASET_KEY,
            DQ_RULE_NAME,
            DQ_RULE_TYPE,
            DQ_RULE_DESCRIPTION,
            DQ_RULE_CATEGORY,
            DQ_RULE_STATUS,
            DQ_DIMENSION,
            DQ_RULE_UPDATION_STATUS,
            DQ_RULE_QUERY,
            SOURCE_SYSTEM_CATEGORY,
            CREATED_DATE,
            LAST_MODIFIED_DATE,
            SNAPSHOT_DATE,
            START_EFFECTIVE_DATE
        )
        SELECT
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
            'INTERNAL',
            DQMS.DQ_RULE_CREATED_DATE,
            DQMS.DQ_RULE_LAST_MODIFIED_DATE,
            DQMS.SNAPSHOT_DATE,
            DQMS.DQ_RULE_LAST_MODIFIED_DATE
        FROM CEC_DB.PRIVATE_TEST.VW_DATA_QUALITY_METRICS_SUMMARY DQMS
        JOIN CEC_DB.PUBLISHED_TEST.DIM_DATASET DD
            ON DQMS.DD_DATASET_NAME = DD.DATASET_NAME
        WHERE DQMS.SNAPSHOT_DATE = ?
          AND DQMS.DQ_RULE_NAME IS NOT NULL
    `;

    var stmt2 = snowflake.createStatement({
        sqlText: insertSql,
        binds: [snapshotDate]
    });

    var rowsInserted = stmt2.execute();
    return 'Insert successful for snapshot_date: ' + snapshotDate;
} catch (err) {
    return 'Error: ' + err.message;
}
$$;
