CREATE OR REPLACE PROCEDURE CEC.DB.PRIVATE_TEST.SP_LOAD_DIM_DATASET()
RETURNS VARCHAR(16777216)
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS '
   //Step 1: start time calculation for the task_qmm_dim_data_quality_rule
    var start_time_query = `SELECT current_timestamp() as start_time;`;
	var stmt1 = snowflake.createStatement({ sqlText: start_time_query });
	var resultset1 = stmt1.execute();
	resultset1.next();
	var start_time = resultset1.getColumnValue(''START_TIME'');
	
	//Step 2: Take the max snapshot_date from QMM_LOAD_STATUS where status = success
	var max_snapshot_date_query = `SELECT to_char(DATEADD(day, -1, MAX(snapshot_date))) AS max_snapshot_date 
                               FROM CEC_DB_PRIVATE_TEST.QMM_LOAD_STATUS 
                               WHERE status in (''success'', ''skipped'')`;
	var stmt2 = snowflake.createStatement({ sqlText: max_snapshot_date_query });
	var resultset2 = stmt2.execute();
	resultset2.next();
	var snapshot_date = resultset2.getColumnValue(''MAX_SNAPSHOT_DATE'');

    // Step 3: Take the max snapshot_date from QMM_TASK_STATUS where status = success
	var max_snapshot_task_query = `SELECT to_char(MAX(snapshot_date)) AS max_snapshot_date_task 
                               FROM CEC_DB_PRIVATE_TEST.QMM_TASK_STATUS 
                               WHERE Task_Name = ''task_qmm_dim_data_quality_rule'' and status = ''success'';`;
	var stmt3 = snowflake.createStatement({ sqlText: max_snapshot_task_query });
	var resultset3 = stmt3.execute();
	resultset3.next();
	var snapshot_date_task = resultset3.getColumnValue(''MAX_SNAPSHOT_DATE_TASK'');
	
	// Step 4: Check the condition and proceed only if snapshot_date > snapshot_date_task
	if (new Date(snapshot_date) > new Date(snapshot_date_task)) {
		try {
			// time_stamp calculation for the audit_log table
			var time_stamp_query = `SELECT current_timestamp() as time_stamp;`;
			var stmt4 = snowflake.createStatement({ sqlText: time_stamp_query });
			var resultset4 = stmt4.execute();
			resultset4.next();
			var TIME_STAMP = resultset4.getColumnValue(''TIME_STAMP1'');
			
			// Log for Step 1 completion
			var log_new_snapshot_calculation = `CALL CEC.DB_PRIVATE_TEST.LOG_TO_QMM_AUDIT_LOG(''task_qmm_dim_data_quality_rule'', ?, ''new snapshot date calculated successfully'', ?)`;        
			var stmt5 = snowflake.createStatement({sqlText: log_new_snapshot_calculation, binds:[snapshot_date, TIME_STAMP1]});
			stmt5.execute();

			// Step 5: truncate temp table
			var truncate_temp_table_query = `TRUNCATE TABLE CEC.DB_PRIVATE_TEST.temp_qmm_dim_data_quality_rule;`;
			var stmt6 = snowflake.createStatement({sqlText: truncate_temp_table_query});
			stmt6.execute();

			// Step 6: inserting records into stage table
			var insert_into_temp_tbl = `INSERT INTO CEC.DB_PRIVATE_TEST.TEMP_QMM_DIM_DATA_QUALITY_RULE
                                    (CHANGE_TYPE,DATASET_KEY,DQ_RULE_NAME,DQ_RULE_TYPE,DQ_RULE_DESCRIPTION,DQ_RULE_CATEGORY,
									DQ_RULE_STATUS,DQ_DIMENSION,DQ_RULE_UPDATION_STATUS,DQ_RULE_QUERY,THRESHOLD,
									SOURCE_SYSTEM_CATEGORY,CREATED_DATE,LAST_MODIFIED_DATE,SNAPSHOT_DATE,START_EFFECTIVE_DATE)
									
			with qmm_dim_data_quality_rule_cte as
			(
			SELECT DISTINCT
					DD.DATASET_KEY
					DQMS. DQ_RULE_NAME,
					DQMS.DQ_RULE_TYPE,
					DQMS.DQ_RULE_DESCRIPTION,
					DQMS.DQ_RULE_CATEGORY,
					DQMS.DQ_RULE_STATUS,
					DQMS.DQ_DIMENSION,
					
			CASE
				WHEN DQMS.DQ_RULE_STATUS = ''Active'' AND DQMS.DQ_RULE_CREATED_DATE = DQMS.DQ_RULE_LAST_MODIFIED_OATE THEN ''Created''
				WHEN DQMS.DO_RULE_STATUS = ''Active'' and DQMS.DQ_RULE_CREATED_DATE < DQMS.DO_RULE_LAST_HODIFIED_DATE THEN ''Modified''
				WHEN DQMS.DO_RULE_STATUS = ''Inactive'' THEN ''Dropped''
			END AS DQ_RULE_UPDATION_STATUS,
			
			DQMS.DO RULE_QUERY,
			DQMS.THRESHOLD,
			''INTERNAL'' AS SOURCE_SYSTEM_CATEGORY, 
			DQMS.DQ_RULE_CREATED_DATE,
			DQMS.DQ_RULE_LAST_MODIFIED_DATE AS LAST_HODIFIED_DATE,
			DQMS.SNAPSHOT_DATE,
			
			MAX(DQMS.DQ_RULE_LAST_MODIFIED_DATE) OVER(PARTITION BY DD.DATASET_KEY. DQMS.DQ_RULE_NAME ORDER DQMS.DQ_RULE_LAST_MODIFIED_DATE DESC) AS START_EFFECTIVE_DATE
			
			FROM
				CEC_DB.PRIVATE_TEST.VW_DATA_QUALITY_METRICS_SUMMARY AS DQMS
				OIN CEC_DB.PUBLISHED_TEST.DIM_DATASET AS DD 
				ON DQMS.DD_DATASET_NAME = DD.DATASET_NAME
				WHERE DQMS. SNAPSHOT _DATE = ?                                                   --Use Snapshot date for which we are running the Process
				QUALIFY ROW_NUMBER OVER(PARTITION BY DD.DATASET_KEY, DQMS.DQ_RULE_NAME ORDER BY DQMS.DO_RULE_NAME) = 1
			)

			(
				SELECT
					'INSERTED" AS change_type
					src.DATASET_KEY,
					src.DQ_RULE_NAME,
					src.DQ_RULE_TYPE
					src.DQ_RULE_DESCRIPTION
					src.DQ_RULE_CATEGORY,
					src.DQ_RULE_STATUS,
					src.DQ_DIMENSION,
					src.DQ_RULE_UPDATION_STATUS,
					src.DQ_RULE_QUERY,
					src.THRESHOLD,
					src.SOURCE_SYSTEM_CATEGORY
					src.CREATED_DATE,
					src.LAST_MODIFIED_DATE,
					src.SNAPSHOT_DATE,
					src.START_EFFECTIVE_DATE
				
				FROM qmm_dim_data_quality_rule_cte src
				WHERE src.DATASET_KEY NOT IN (SELECT DISTINCT DATASET_KEY FROM CEC_DB.PUBLISHED_TEST.QMM_DIM_DATA_QUALITY_RULE where current_flag = TRUE)
				AND src.DQ_RULE_NAME NOT IN (SELECT DISTINCT DQ_RULE_NAME FROM CEC_DB.PUBLISHED_TEST.QMM_DIM_DATA_QUALITY_RULE where current_flag = TRUE)
				
				UNION ALL
				
				// deleted Records : Present in source but not in 
				
				SELECT
					'DELETED" AS change_type
					tgt.DATASET_KEY,
					tgt.DQ_RULE_NAME,
					tgt.DQ_RULE_TYPE
					tgt.DQ_RULE_DESCRIPTION
					tgt.DQ_RULE_CATEGORY,
					tgt.DQ_RULE_STATUS,
					tgt.DQ_DIMENSION,
					tgt.DQ_RULE_UPDATION_STATUS,
					tgt.DQ_RULE_QUERY,
					tgt.THRESHOLD,
					tgt.SOURCE_SYSTEM_CATEGORY
					tgt.CREATED_DATE,
					tgt.LAST_MODIFIED_DATE,
					tgt.SNAPSHOT_DATE,
					tgt.START_EFFECTIVE_DATE
				
				FROM CEC_DB.PUBLISHED_TEST.QMM_DIM_DATA_QUALITY_RULE tgt
				WHERE tgt.current_flag = TRUE AND tgt.DATASET_KEY NOT IN (SELECT DISTINCT DATASET_KEY FROM qmm_dim_data_quality_rule_cte)
				AND tgt.DQ_RULE_NAME NOT IN (SELECT DISTINCT DQ_RULE_NAME FROM qmm_dim_data_quality_rule_cte)
				
				UNION ALL
				
				// Updated Records: Same ID, but different attribute values between source and target
				
				SELECT
					'UPDATED" AS change_type
					src.DATASET_KEY,
					src.DQ_RULE_NAME,
					src.DQ_RULE_TYPE
					src.DQ_RULE_DESCRIPTION
					src.DQ_RULE_CATEGORY,
					src.DQ_RULE_STATUS,
					src.DQ_DIMENSION,
					src.DQ_RULE_UPDATION_STATUS,
					src.DQ_RULE_QUERY,
					src.THRESHOLD,
					src.SOURCE_SYSTEM_CATEGORY
					src.CREATED_DATE,
					src.LAST_MODIFIED_DATE,
					src.SNAPSHOT_DATE,
					src.START_EFFECTIVE_DATE
				
				FROM qmm_dim_data_quality_rule_cte src
				JOIN CEC_DB.PUBLISHED_TEST.QMM_DIM_DATA_QUALITY_RULE tgt ON src.DATASET_KEY = tgt.DATASET_KEY AND src.DQ_RULE_NAME = tgt.DQ_RULE_NAME
				WHERE tgt.current_flag = TRUE
				AND (

						coalesce(src.DQ_RULE_TYPE, ''-1'')!= coalesce(tgt.DQ_RULE_TYPE, ''-1'') or
						coalesce(src.DQ_RULE_DESCRIPTION, ''-1'')!= coalesce(tgt.DQ_RULE_DESCRIPTION, ''-1'') or
src						coalesce(src.DQ_RULE_CATEGORY,''-1'') != coalesce(tgt.DQ_RULE_CATEGORY,''-1'') or
						coalesce(src.DQ_RULE_UPDATION_STATUS,''-1'')!= coalesce(tgt.DQ_RULE_UPDATION_STATUS,''-1'') or 
						coalesce(src.DQ_DIMENSION,''-1'') != coalesce(tgt.DQ_DIMENSION,''-1'') or
						coalesce(src.SOURCE_SYSTEM_CATEGORY,''-1'') != coalesce(tgt.SOURCE_SYSTEM_CATEGORY,''-1'') or
						coalesce(src. THRESHOLD,''-1'')!= coalesce(tgt. THRESHOLD,''-1'') or 
						coalescesc. DQ_RULE_STATUS,''-1'' ) != coalesce(tgt.DOQ_RULE_STATUS,''-1'')))';

				var stmt7 snowflake.createStatement({ sqlText: insert_into_temp_table. binds: [snapshot_date,snapshot_date]});
				stmt7 .execute();
				
				// time_stamp calculation for the audit_ log_table
				
				var time stamp2 = 'SELECT current_timestamp() as time_stamp2;';
				var stmt8= snowflake.createStatement( sqlText: time_stamp2}):
				var resultset8 = stmt8.execute();
				resultset8.next();
				var TIME_STAMP2 = resultset8.getColumnValue(''TIME_STAMP2'');
				
				// Log Step 5 data inserted into temp table
				
				var temp_table_audit_log = 'CALL CEC_DB.PRIVATE_TEST.LOG_TO_MM_AUDIT_LOG(''task_qmm_dim_data_quality_rule'', ?, '' change only records inserted into temp_qmm_dim_ data_quality_rule table'', ?)';
				var stmt9 = snowflake.createStatement({sqlText: temp_table_audit_log. binds: [snapshot_date. TIME_STAMP2]});
				stmt9.execute();
				
				
				// Step 7 : loading data into qmm_dim_data_quality_rule table
				var dim_load_query = 
				MERGE INTO qmm_dim_data_quality_rule AS tgt
				USING (
						SELECT src.DATASET_KEY, src.DQ_RULE_NAME, src.*
						FROM temp_qmm_dim_data_quality_rule AS src

						UNION ALL

						SELECT NULL AS DATASET_KEY, NULL AS DQ_RULE_NAME, src.*
						FROM temp_qmm_dim_data_quality_rule AS src
						JOIN qmm_dim_data_quality_rule AS tgt
						ON src.DATASET_KEY = tgt.DATASET_KEY AND src.DQ_RULE_NAME = tgt.DQ_RULE_NAME
						WHERE src.change_type = ''UPDATED'' AND tgt.current_flag = true
					) AS src
				ON 
					tgt.DATASET_KEY = src.DATASET_KEY AND tgt.DQ_RULE_NAME = src.DQ_RULE_NAME
					AND tgt.current_flag = true


				WHEN MATCHED AND src.change_type = ''DELETED'' THEN
				UPDATE SET	tgt.current_flag = FALSE, tgt.end_effective_date = DATE_ADD(DAY,-1,src.START_EFFECTIVE_DATE)


				WHEN MATCHED AND src.change_type = ''UPDATED'' THEN
				UPDATE SET	tgt.current_flag = FALSE, tgt.end_effective_date = DATE_ADD(DAY,-1,src.START_EFFECTIVE_DATE)


				WHEN NOT MATCHED AND src.change_type = ''INSERTED'' THEN
				INSERT (
						tgt.DATASET_KEY, tgt.DQ_RULE_NAME,tgt.DQ_RULE_TYPE, tgt.DQ_RULE_DESCRIPTION, tgt.DQ_RULE_CATEGORY,
						DQ_RULE_STATUS,tgt.DQ_DIMENSION, tgt.DQ_RULE_UPDATION_STATUS, tgt.DQ_RULE_QUERY, tgt.THRESHOLD,
						tgt.SOURCE_SYSTEM_CATEGORY, tgt.CREATED_DATE, tgt.LAST_MODIFIED_DATE,
						tgt.START_EFFECTIVE_DATE, tgt.END_EFFECTIVE_DATE, tgt.CURRENT_FLAG, tgt.SNAPSHOT_DATE
						)
				VALUES (
						src.DATASET_KEY, src.DQ_RULE_NAME, src.DQ_RULE_TYPE, src.DQ_RULE_DESCRIPTION, src.DQ_RULE_CATEGORY,
						src.DQ_RULE_STATUS, src.DQ_DIMENSION, src.DQ_RULE_UPDATION_STATUS, src.DQ_RULE_QUERY, src.THRESHOLD,
						src.SOURCE_SYSTEM_CATEGORY, src.CREATED_DATE, src.LAST_MODIFIED_DATE,
						src.START_EFFECTIVE_DATE, TO_DATE('9999-01-01'), TRUE, src.SNAPSHOT_DATE
						)


				WHEN NOT MATCHED AND src.DATASET_KEY IS NULL THEN
				INSERT (
						tgt.DATASET_KEY, tgt.DQ_RULE_NAME,tgt.DQ_RULE_TYPE, tgt.DQ_RULE_DESCRIPTION, tgt.DQ_RULE_CATEGORY,
						DQ_RULE_STATUS,tgt.DQ_DIMENSION, tgt.DQ_RULE_UPDATION_STATUS, tgt.DQ_RULE_QUERY, tgt.THRESHOLD,
						tgt.SOURCE_SYSTEM_CATEGORY, tgt.CREATED_DATE, tgt.LAST_MODIFIED_DATE,
						tgt.START_EFFECTIVE_DATE, tgt.END_EFFECTIVE_DATE, tgt.CURRENT_FLAG, tgt.SNAPSHOT_DATE
						)
				VALUES (
						src.DATASET_KEY, src.DQ_RULE_NAME, src.DQ_RULE_TYPE, src.DQ_RULE_DESCRIPTION, src.DQ_RULE_CATEGORY,
						src.DQ_RULE_STATUS, src.DQ_DIMENSION, src.DQ_RULE_UPDATION_STATUS, src.DQ_RULE_QUERY, src.THRESHOLD,
						src.SOURCE_SYSTEM_CATEGORY, src.CREATED_DATE, src.LAST_MODIFIED_DATE,
						src.START_EFFECTIVE_DATE, TO_DATE('9999-01-01'), TRUE, src.SNAPSHOT_DATE
						)';
						
				var stmt10 = snowflake.createStatement({ sqlText: dim_load_query}) 		
				var resultset10 = stmt10.execute();
				resuLtset10.next();
				no_of_records_inserted = resultset10.getColumnValue(1);
				no_of_records_updated = resultset10.getColumnValue(2);
				//no_of records_deleted = resultset10.getCoLumnValue(3); -- Not required
				
				//Default to 0 if the values are null or undefined
				
				no_of_records_inserted = no_of_records_inserted || 0;
				no_of_records_updated = no_of_records_updated || 0;
				//no_of_records_deleted = no_of_records_deleted || 0; -- Not required
				no_of_records_to_be_processed

				var no_of_records_to_be_processed_query = 'select
									COUNT(CASE WHEN change_type = ''UPDATED'' THEN 1 END) AS NO_OF_RECORDS_TO_BE_UPDATED,
									COUNT(CASE WHEN change_type = ''DELETED''THEN 1 END) AS NO_OF_RECORDS_TO_BE_DELETED,
									COUNT(CASE WHEN change_type = ''INSERTED'' THEN 1 END) AS NO_OF_RECORDS_TO_BE_INSERTED)
									FROM CEC_DB.PRIVATE_TEST.temp_qmm_dim_data_quality_rule;'
									
				var stmt11= snowflake.createStatement({ sqlText: no_of_records_to_be_processed_query });
				var resultset11 = stmt11.execute();
				resultset11.next():
				no_of_records_to_be_updated = resultset11.getColumnValue(1);
				no_of_records_to_be_deleted = resultset11.getColumnVaLue (2);
				no_of_records_to_be_inserted =resultset11.getColumnValue(3);
				
				// Detfault to 0 if the values are null or undefined 
				no_of_records_to_be_updated = no_of_records_to_be_updated || 0;
				no_of_records_to_be_deleted = no_of_records_to_be_deleted || 0;
				no_of_records_to_be_inserted = no_of_records_to_be_inserted || 0;
				
				//Rollback and fall if thetask if there is a mismatch in the expected count of loaded records and actual count of records loaded 
				if((no_of_records_inserted != no_of_records_to_be_inserted) ||(no_of_records_updated != no_of_records_to_be_updated))
				{
					snowflake createStatement({ sqlText: "rollback "}).execute();
					throw new Error( ''Mismatch between actual and expected count of records loaded'');
					
				}

					snowflake.createStatement({ sqlText: "commit "}).execute();
				
				// Step 8: end time calculation
				var end_time_query = 'SELECT current_timestamp() as end_time';
				var stmt12 = snowflake.createStatement({ sqlText: end_time_query });
				var resultset12 = stmt12.execute();
				resultset12.next();
				var end_time = resultset12.getColumnValuel(''END_TIME'');
				
				// time_stamp calculation for the audit_log_table
				var time_stamp3 = 'SELECT current_timestamp() as time_stamp3;';
				var stmt13 = snowflake.createStatement({ sqlText: time_stamp3 });
				var resultset13 = stmt12.execute();
				resultset13.next();
				var TIME_STAMP3 = resultset13.getColumnValuel(''TIME_STAMP3'');

				// Log for merge stetemnt completion
				var dim_audit_log = 'CALL CEC_DB.PRIVATE_TEST.LOG_TO_QMM_AUDIT_LOG(''task_qmm_dim_data_data_quality_rule'', ?, ''data loading to qmm_dim_data_data_quality_rule completed successfully'',?)';
				var stmt14 = snowflake.createStatement({sqlText: dim_audit_log. binds: [snapshot_date, TIME_STAMP3]});
				stmt14.execute();
				
				// Step 9: Log task status
				var task_audit_log = 'CALL CEC_DB.PRIVATE_TEST.LOG_TO_QMM_TASK_STATUS(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';
				var stmt15 snowflake.createStatement({sqlText: task_audit_log,
				binds: [''task_qmm_dim_data_quality_rule'', snapshot_date, start_time,
				end_time, no_of_records_to_be_inserted, no_of_records_to_be_updated,
				no_of_records_to_be_deleted, no_of_records_inserted, no_of_records_updated, 0,0,''success'', '' '']});
				stmt15.execute():
			
				return ''Merge statement for qmm_dim_data_quality_rule procedure completed successfully'';
				
			} catch (err) {
					snowflake.createStatement({ sqlText: "rollback ")).execute();
						var error_msg = err.message;
						
					// time_stamp calculation for the audit_log_table
					var time_stamp4 = 'SELECT current_timestamp() as time_stamp4;';
					var stmt16 = snowflake.createStatement({sqlText: time_stamp4});
					var resultset16 stmt16.execute();
					resultset16.next();
					var TIME_STAMP4 = resultset16.getColumnValue(''TIME_STAMP4'');
					
					//Log any error that occurs
					var log_error_query =  'CALL CEC_DB.PRIVATE_TEST.LOG_TO_QMM_AUDIT_LOG(?, ?, ?, ?)';
					var stmt17 = snowflake.createStatement({sqlText: log_error_query, 
					binds:[''task_mm_dim_data_quality_rule'',snapshot_date,error_msg, TIME_STAMP4]});
					stmt17.execute();
					
					// Step 9: Log task status
					var task_audit_Log = 'CALL CEC_DB.PRIVATE_TEST.LOG_TO_QMM_TASK_STATUS(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';
					var stmt18= snowflake.createStatement({sqlText: task_audit_log,
					binds: [''task_qmm_dim_data_quality_rule'', snapshot_date, start_time, TIME_STAMP4,0,0,0,0, 0, 0, ''failed'', error_msg ]});
					stmt18.execute():
					
					/ Step 10: sending failure email alert notification
					var failure_email_alert_query = 'CALL CEC_DB.PRIVATE TEST.SP_SEND_QMM_TASK_FAILURE_ EMAIL_ALERT (?, ?, ?)';
					var stmt19 = snowflake.createStatement ({sqlText: failure_email_alert_query, 
					binds:[''task_qmm_dim_data_quality_rule'', snapshot _date,''failed'']});
					stmt19.execute();
					
			  return ''Error occurred: '' + error_msg:
			}
		} else {
			// Log and exit if snapshot_date ‹= snapshot_date_task
			return ''Procedure skipped as snapshot_date is not greater than snapshot_date_task'';
		}
';
