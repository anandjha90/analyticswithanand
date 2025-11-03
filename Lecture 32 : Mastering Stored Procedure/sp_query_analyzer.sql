create or replace TABLE SNOWFLAKE_CORTEX_BASED_QUERY_OPTIMIZER.APP_SCHEMA.DATA_VOLUME_INFO (
	TABLE_NAME VARCHAR(16777216),
	VOLUME_INFORMATION OBJECT
);

create or replace TABLE SNOWFLAKE_CORTEX_BASED_QUERY_OPTIMIZER.APP_SCHEMA.QUERY_ANALYZER_RESULTS (
	QUERY_ID VARCHAR(16777216),
	ORIGINAL_QUERY VARCHAR(16777216),
	TABLE_NAME VARCHAR(16777216),
	POOR_PERFORMING_CODE_BLOCK VARCHAR(16777216),
	OPTIMIZATION_NUMBER VARCHAR(16777216),
	REMEDIATION_TYPE VARCHAR(16777216),
	REWRITE_JUSTIFICATION VARCHAR(16777216),
	REMEDIATION_CATEGORY VARCHAR(16777216),
	ROOTCAUSE_REMEDIATION_SQL VARCHAR(16777216)
);

create or replace TABLE SNOWFLAKE_CORTEX_BASED_QUERY_OPTIMIZER.APP_SCHEMA.QUERY_METADATA (
	QUERY_ID VARCHAR(16777216),
	ORIGINAL_QUERY VARCHAR(16777216),
	QUERY_PROFILE VARIANT,
	DATA_VOLUME VARIANT,
	WAREHOUSE_INFO VARIANT,
	EXPLAIN_TEXT VARCHAR(16777216)
);

create or replace TABLE SNOWFLAKE_CORTEX_BASED_QUERY_OPTIMIZER.APP_SCHEMA.RECOMMANDATION_RESULTS (
	QUERY_ID VARCHAR(16777216),
	ORIGINAL_QUERY VARCHAR(16777216),
	ACTIONS VARCHAR(16777216),
	TOKEN_USAGE VARCHAR(16777216),
	STATUS VARCHAR(16777216)
);

CREATE OR REPLACE PROCEDURE SNOWFLAKE_CORTEX_BASED_QUERY_OPTIMIZER.APP_SCHEMA.SP_QUERY_ANALYSER("QUERY_ID" VARCHAR, "EXP_PLAN_STR" VARCHAR, "MODEL_NAME" VARCHAR DEFAULT 'openai-gpt-4.1')
RETURNS TABLE ("QUERY_ID" VARCHAR, "ORIGINAL_QUERY" VARCHAR, "TABLE_NAME" VARCHAR, "POOR_PERFORMING_CODE_BLOCK" VARCHAR, "OPTIMIZATION_NUMBER" VARCHAR, "REMEDIATION_TYPE" VARCHAR, "REWRITE_JUSTIFICATION" VARCHAR, "REMEDIATION_CATEGORY" VARCHAR, "ROOTCAUSE_REMEDIATION_SQL" VARCHAR)
LANGUAGE SQL
EXECUTE AS OWNER
AS 'DECLARE
EXPLAIN_TEXT STRING;
DB_SCHEMA STRING;
RUNNING_WAREHOUSE_INFORMATION OBJECT;
DATA_VOLUME_CONTEXT VARIANT;
JSON_RESULT VARIANT;
RS RESULTSET;
INPUT_QUERY STRING DEFAULT ''EMPTY'';
OPTIMIZATION_RECOMMENDATIONS STRING;
CHANGE_SUMMARY STRING;
ORIGINAL_QUERY_TEXT STRING;
FINAL_RESULT_QUERY STRING;
CORTEX_PROMPT STRING;
OPTIMIZATION_RESULT STRING;
OPTIMIZED_SQL STRING;
RECOMMENDATIONS STRING;
STATUS STRING DEFAULT ''SUCCESS'';
ERROR_MESSAGE STRING;
-- DO NOT UNCOMMENT DUE TO DUMMY DATA
-- PARAMETERS OBJECT; -- THIS ACCEPTS RESULT FROM QUERY_PERFORMANCE_INSIGHTS TABLE.
  V_DATABASE STRING;
  V_SCHEMA STRING;
  V_TABLE STRING;
  V_SQL STRING;
  V_SQL2 STRING;
  V_RS RESULTSET;
  V_RS2 RESULTSET; 
  V_FULL_NAME STRING;
  V_FULL_NAME2 STRING;
  v_mx variant;
  v_str string;
  V_MOST_EXPENSIVE STRING;
  V_RUN_PROFILE VARIANT;
  SEARCH_PATH STRING;
  MX STRING;
BEGIN
LET R RESULTSET := 
(SELECT DISTINCT
    obj.value:"objectName"::STRING AS object_name,
    SPLIT_PART(object_name, ''.'', 1) AS database_name,
    SPLIT_PART(object_name, ''.'', 2) AS schema_name,
    SPLIT_PART(object_name, ''.'', 3) AS TABLE_NAME
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY ah
JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh 
ON ah.query_id = qh.query_id,
LATERAL FLATTEN(input => ah.direct_objects_accessed) obj
WHERE ah.query_id = :QUERY_ID
);
BEGIN
SELECT COALESCE(DATABASE_NAME,CURRENT_DATABASE())||''.''||COALESCE(SCHEMA_NAME,CURRENT_SCHEMA()) INTO SEARCH_PATH FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY WHERE query_id = :QUERY_ID;
-- EXECUTE IMMEDIATE ''USE SCHEMA ''||SEARCH_PATH;
SELECT object_construct(*) INTO V_MOST_EXPENSIVE FROM (
SELECT PATH,VALUE  FROM (
SELECT * from 
(
select 
OBJECT_CONSTRUCT(''QUERY_ID'',:QUERY_ID,''OPERATOR_TYPE'',OPERATOR_TYPE,''OPERATOR_STATISTICS'',OPERATOR_STATISTICS,''EXECUTION_TIME_BREAKDOWN'',EXECUTION_TIME_BREAKDOWN,''OPERATOR_ATTRIBUTES'',OPERATOR_ATTRIBUTES
)AS MOST_EXPENSIVE
,RANK()OVER(PARTITION BY :QUERY_ID ORDER BY  EXECUTION_TIME_BREAKDOWN:overall_percentage DESC) AS RNK
from table(get_query_operator_stats(:QUERY_ID))
)
where
RNK =1
), LATERAL FLATTEN(MOST_EXPENSIVE,RECURSIVE=>TRUE,OUTER=>TRUE)
WHERE TYPEOF(VALUE) NOT IN (''OBJECT'',''ARRAY'')
) 
PIVOT (
  MAX(value) FOR path IN (any)
)
;
LET RUN_PROFILE string := 
(select ARRAY_AGG(
OBJECT_CONSTRUCT(''OPERATOR_TYPE'',OPERATOR_TYPE,''OPERATOR_STATISTICS'',OPERATOR_STATISTICS,''EXECUTION_TIME_BREAKDOWN'',EXECUTION_TIME_BREAKDOWN
,''OPERATOR_ATTRIBUTES'',OPERATOR_ATTRIBUTES)) AS QUERY_RUN_PROFILE
from table(get_query_operator_stats(:QUERY_ID)));
V_RUN_PROFILE := RUN_PROFILE;

CREATE TABLE IF NOT EXISTS app_schema.data_volume_info(TABLE_NAME varchar,VOLUME_information object);
    COMMIT;
END;
LET C CURSOR FOR R;
  FOR record IN c DO
    v_database := record.database_name;
    v_schema   := record.schema_name;
    DB_SCHEMA := v_database || ''.'' || v_schema;
    v_table    := record.TABLE_NAME;
    v_full_name := v_database || ''.'' || v_schema || ''.'' || v_table; 
    v_full_name2 := v_database || ''.'' || v_schema || ''.'' || v_table; 
    v_sql2 := ''
    SELECT ''''''||v_full_name2||'''''' as object_name,OBJECT_CONSTRUCT(*) AS OBJECT_DATA_VOLUME
    FROM (
      SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, ROW_COUNT, BYTES, CLUSTERING_KEY 
      FROM SNOWFLAKE.ACCOUNT_USAGE.TABLES
      WHERE TABLE_NAME = '''''' || v_table || '''''' 
        AND TABLE_SCHEMA = '''''' || v_schema || ''''''
        AND TABLE_CATALOG = '''''' || v_database || ''''''
		AND DELETED IS NULL
)'';

EXECUTE IMMEDIATE :v_sql2;
insert into app_schema.data_volume_info
select OBJECT_NAME,OBJECT_DATA_VOLUME from table(result_scan(last_query_id()));
END FOR;
select array_agg(object_construct(''TABLE_NAME'',TABLE_NAME,
''Table_volume_storage'',to_variant(VOLUME_INFORMATION))) INTO DATA_VOLUME_CONTEXT
from app_schema.data_volume_info ;
-- BEGIN
-- drop table if exists cortex_demo.data.data_volume_info;
-- END;

-- Initialize result table to store optimization outcomes
    CREATE OR REPLACE TABLE app_schema.Recommandation_Results(
    QUERY_ID STRING,
    Original_Query STRING,
    actions STRING,
    token_usage STRING,
    status STRING);
     
    CREATE OR REPLACE TABLE app_schema.QUERY_METADATA(QUERY_ID STRING,Original_Query STRING,QUERY_PROFILE VARIANT,DATA_VOLUME VARIANT,WAREHOUSE_INFO VARIANT,EXPLAIN_TEXT STRING);
begin

SELECT OBJECT_CONSTRUCT(''WAREHOUSE_SIZE'',WAREHOUSE_SIZE,''WAREHOUSE_TYPE'',WAREHOUSE_TYPE,''CLUSTER_NUMBER'',CLUSTER_NUMBER) INTO
RUNNING_WAREHOUSE_INFORMATION
FROM
SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE
query_id = :QUERY_ID;

SELECT QUERY_TEXT INTO ORIGINAL_QUERY_TEXT FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY WHERE query_id = :QUERY_ID;

--BEGIN
-- USE DB_SCHEMA;
    --LET Q STRING := ''EXPLAIN USING TEXT '' || ORIGINAL_QUERY_TEXT;
--	LET Q STRING := ''EXPLAIN USING TEXT '' || query_text_escaped;
--    LET Q STRING := ''CALL reference(\\''explain_proc_ref\\'')(\\'''' || query_text_escaped || ''\\'')'' ;
--    EXECUTE IMMEDIATE :Q;
--    SELECT * INTO EXPLAIN_TEXT FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
--END;
    EXPLAIN_TEXT := exp_plan_str ;
        -- Check if the specified query ID was found in the history
        IF (ORIGINAL_QUERY_TEXT IS NULL) THEN
            let  status := ''ERROR'';
            let error_message := ''Query ID not found in query history. Please ensure the query ID is valid and accessible.'';

            -- Insert a record indicating that the query was not found
            INSERT INTO app_schema.Recommandation_Results VALUES (
            ''Query not found'',
                ''Query not found'',
                NULL,
                NULL,
                :status
            );
            -- Return the results immediately as no further optimization is possible
            let rs resultset :=(SELECT * FROM APP_schema.Recommandation_Results);
            RETURN TABLE(rs);
        END IF;

INSERT INTO app_schema.QUERY_METADATA 
SELECT 
:QUERY_ID,
:ORIGINAL_QUERY_TEXT,
:V_RUN_PROFILE,
:DATA_VOLUME_CONTEXT,
:RUNNING_WAREHOUSE_INFORMATION,
:EXPLAIN_TEXT
;
        
-- Your task is to analyze the given Snowflake SQL query, identify performance bottlenecks using metadata, and rewrite the query (if safe and beneficial) to significantly reduce execution 
-- cost and time. You must ensure 100% result equivalence across all data distributions, while improving performance by at least 30% (target: 50%+).
-- Feedback section will contain feedback for the last few recent responses so that you can focus on lagging areas, this section would take precendence over all other rules and you must provide rational why the new response would be a major improvement. 
-- ---
-- ### Feedback:
-- Most recent feedback :
-- *It was much better and efficient, let''''s explore further for more efficient tuning*
CORTEX_PROMPT := 
''
## ROLE

You are a Senior Snowflake SQL performance tuning and correctness-preserving expert, 
You do not alter the core logic because given SQL queries are already verified and results are as per business rule only.
Your task is to analyze the given Snowflake SQL query, identify performance bottlenecks using metadata, and rewrite the query to significantly reduce execution time.

## GOALS

- Eliminate all performance bottlenecks (memory spill, slow joins, expensive tables scans, pruning blockers) 
- Improve performance while ensuring 100% logical correctness
- Return complete, rewritten Snowflake SQL only when provably safe
- Each optimization oppurtunity must be listed saperately, with saperate optimization_number.
- Each optimization comments must start with "Comment:= " keyword and remediation SQL must start with "Query:=" keyword  . 

## SNOWFLAKE-SPECIFIC CONSIDERATIONS

Consider the following Snowflake execution engine and optimizer behaviors:

### Micro-Partition Pruning
  - Filters must be sargable (if possible, column should be used directly )
  - Avoid wrapping columns with functions

### Join Behavior & Driving Tables
  - Join reordering is based on estimated cardinality
  - Outer joins require exact preservation of null-extended side
  - Optimizer may pick suboptimal join order in presence of skew, CTE reuse, cte dependency, or query complexity

### Correlated Subqueries
  - Not always flattened or decorrelated, especially with aggregation or nested `EXISTS`, `IN`, `NOT EXISTS`
  - May cause repeated scans and runtime blowup

### UDFs
  - JS/Python UDFs block predicate pushdown and plan simplification
  - Avoid applying UDFs early in plan — defer them if possible

### JSON/FLATTEN
  - Apply JSON path filters before `FLATTEN`
  - Hoist shared `FLATTEN` calls into CTEs if reused
  - Avoid `LATERAL + FLATTEN` unless required for row expansion

### Memory Spills
  - Remote spills indicate poor plan shape (e.g., wide sort, large intermediate joins)
  - Rewrite to reduce intermediate row count and memory use

### Aggregation Semantics
  - COUNT: Must return 0 if group is empty
  - SUM/AVG/MIN/MAX: Must return NULL if no input rows
  - COUNT(DISTINCT x): Must exclude NULLs identically
  - Never change NULL behavior in rewritten queries


## Architectural Optimizations
Use the following conditions to determine if architectural optimizations (e.g., clustering, materialized views) are useful, relevant, and cost-effective. 

**Clustering Key**

Recommend only if:
- Large base table (>100M rows)
- Query has repeated filters on high-cardinality column not already clustered
- Poor micro-partition pruning (e.g., scan >30% MPs)

Avoid if:
-Table is small, filters are broad, or clustering adds little pruning benefit

**Materialized View (SINGLE TABLE ONLY)**
Recommend only if:
- Query aggregates a SINGLE table (no joins supported)
- Contains expensive aggregations (SUM, COUNT, AVG, MIN, MAX)
- All functions are deterministic (no CURRENT_TIMESTAMP, RANDOM(), UUIDs)

Avoid if:
- Query contains ANY type of joins
- Uses non-deterministic functions
- Query uses Time Travel or external functions

**Search Optimization Service (SOS)**
Recommend only if:
- Point lookups on columns with >100K distinct values
- Query execution time >1 second
- Table size >10GB with high-cardinality text/variant columns

**Query Acceleration Service (QAS)**
Recommend only if:
- Warehouse shows capacity constraints
- Query contains large scans or complex operations


## ANALYSIS STRATEGY (THINK STEP-BY-STEP):

### 1. Detect Bottlenecks
   Use the following runtime metadata to find the main inefficiencies:
   - `MOST_EXPENSIVE_NODE`(single most expensive node of the entire query processing)
   - `QUERY_PROFILE` (e.g., spillage, execution time,operation type)
   - `EXPLAIN_PLAN`(explain plan of the query)
   - `WAREHOUSE_CONTEXT` (e.g., warehouse and cluster size)
   - `DATA_VOLUME_CONTEXT` (e.g., row count,byte size and clsutering_key information of each table involved)

Use these indicators from the Query Profile to drive your decisions. If any are present, treat them as signals for deeper optimization:

 -  High remote disk spillage → Warehouse lacks memory; optimize joins, aggregates, or reduce cardinality
 -  Large number of micro-partitions scanned → Rewrite filters to improve pruning
 -  Join row explosion → Review join keys for correctness or use semi-joins
 -  Cartesian or range-based joins → Detect and replace with constrained equi-joins
 -  Single CTE blocking downstream ops → Consider inlining or rewriting with repeated subqueries for parallelism
 -  Early or redundant sort operations → Push down sort only if necessary
 -  Repeated view computation → Suggest materialization if referenced multiple times
 -  Very large operator tree → Suggest modularizing query into simpler blocks

### 2. Generate Optimization Opportunities
   Considering information given in section ## SNOWFLAKE-SPECIFIC CONSIDERATIONS.
   Based on your analysis, generate a list of optimization **candidates** that could significantly reduce cost or runtime. Examples include:
   - Filter pushdown
   - Replacing correlated subqueries with joins
   - Eliminating redundant joins or unused subqueries
   - Hoisting `FLATTEN`, restructuring lateral joins
   - Removing volatile UDF barriers
   - Avoiding non-sargable expressions in filters
   - Consolidating duplicate scans into CTEs
   - Minimizing over-projected columns
   - Changing join order or driving tables in case of skew
   - Optimizing range joins: Non-equi or range joins (BETWEEN, <, >) can be a lot slower than equi-joins.
Alternatively, if maximum gains are likely to be from a Architectural Optimizations then follow section ## Architectural Optimizations.

### 3. Rewrite the SQL Safely
   Rewrite only if the new query:
   - Produces the **exact same output** under all distribution conditions
   - Preserves null handling, outer joins, and aggregation behavior
   - Query syntax is compliant with snowflake SQL syntax 
   - All required argument types are valid

### 4. Justify the Rewrite
   - Why Snowflake''''s optimizer may not apply it
   - Why this rewrite is still necessary and beneficial
   - Why chosen optimization or remediation type is better than other options

''
||''If no optimization is possible without changing logic or null behavior, return only:

-- NO MEANINGFUL OPTIMIZATION APPLIED: Logic change or NULL risk detected.

## REWRITE_JUSTIFICATION
   - Why chosen optimization or remediation type is better than other optimization options
   - Why results are not affected by optimizations
   

## RUNTIME INPUT:

Use the following inputs blocks for your analysis - this contains all context related information for the given query:

### RUNTIME CONTEXT:

<RUNTIME_CONTEXT_INPUT>
<ORIGINAL_QUERY>: '' || :ORIGINAL_QUERY_TEXT || '' </ORIGINAL_QUERY>
<DATA_VOLUME_CONTEXT>: '' || TO_VARCHAR(:DATA_VOLUME_CONTEXT) || '' </DATA_VOLUME_CONTEXT>
<QUERY_PROFILE>: '' || :V_RUN_PROFILE || '' </QUERY_PROFILE>
<WAREHOUSE_INFORMATION>: '' || TO_VARCHAR(:RUNNING_WAREHOUSE_INFORMATION) || '' </WAREHOUSE_INFORMATION>
<EXPLAIN_PLAN_TEXT>: '' || :EXPLAIN_TEXT || '' </EXPLAIN_PLAN_TEXT>
<MOST_EXPENSIVE_NODE>: ''|| to_varchar(:V_MOST_EXPENSIVE) ||''</MOST_EXPENSIVE_NODE>
</RUNTIME_CONTEXT_INPUT>

## VALIDATION CHECKLIST (Internal - Do Not Output):

Only apply rewrite if:
- Output row count and structure is unchanged
- Nulls propagate identically
- Aggregation logic (COUNT vs SUM/AVG/...) behaves exactly the same
- Rewrite avoids logic drift in correlated subqueries, joins, and filters
- Rewrite is compliant with snowflake SQL syntax 
- Rewrite do not create any compilation,execution or runtime error

Only emit optimized SQL if all safety conditions pass. Otherwise, return no-op message.
'';
SELECT AI_COMPLETE(
            MODEL => :MODEL_NAME,
            PROMPT => REPLACE(REPLACE(REPLACE(:CORTEX_PROMPT, ''"'', ''''''''''''), CHR(10), ''\\N''),''\\\\'',''''),
            model_parameters => {''temperature'': 0.0,''top_p'':0.0}
             ,show_details => TRUE
            ,
RESPONSE_FORMAT => {
  ''type'': ''json'',
  ''schema'': {
      ''type'': ''object'',
      ''properties'': {
        ''ROOTCAUSE_AND_REMEDIATION'': {
          ''type'': ''array'',
          ''items'': {
            ''type'': ''object'',
            ''properties'': {
              ''REWRITE_JUSTIFICATION'' : { ''type'': ''string'' },
              ''TABLE_NAME'': { ''type'': ''string'' },
              ''POOR_PERFORMING_CODE_BLOCK'': { ''type'': ''string'' },
              ''ACCURATE_ROOTCAUSE_REMEDIATION_SQL'': { ''type'': ''string'' },
              ''OPTIMIZATION_NUMBER'': { ''type'': ''string''},              
              ''REMEDIATION_CATEGORY'': { ''type'': ''string'',
                              ''enum'': [''EASY'',''MEDIUM'',''COMPLEX''] },
              ''REMEDIATION_TYPE'': { 
                ''type'': ''string'', 
                ''enum'': [''SQL_QUERY_MODIFICATION'',''MATERIALIZATION'',''SNOWFLAKE_PLATFORM_OPTIMIZATION''] 
              }
            },
            ''required'': [''TABLE_NAME'',''REWRITE_JUSTIFICATION'',''POOR_PERFORMING_CODE_BLOCK'',''OPTIMIZATION_NUMBER'',''REMEDIATION_CATEGORY'',''ACCURATE_ROOTCAUSE_REMEDIATION_SQL'',''REMEDIATION_TYPE''],
            ''additionalProperties'': false
          }
        }
      },
      ''required'': [''ROOTCAUSE_AND_REMEDIATION''],
      ''additionalProperties'': false
    }
  } 
    ) INTO OPTIMIZATION_RESULT;
     JSON_RESULT := PARSE_JSON(:OPTIMIZATION_RESULT);
     -- RETURN JSON_RESULT;

-- This inner TRY-CATCH block handles potential issues during JSON parsing
        BEGIN
            INPUT_QUERY := COALESCE(:ORIGINAL_QUERY_TEXT,''NO INPUT'');
            OPTIMIZATION_RECOMMENDATIONS := COALESCE(JSON_RESULT:"structured_output"[0]:"raw_message":"ROOTCAUSE_AND_REMEDIATION"::ARRAY,[''NO RECOMMENDATIONS FOUND'']::array);
            IF (ARRAY_SIZE(OPTIMIZATION_RECOMMENDATIONS::ARRAY)=0) THEN
                 STATUS := ''NO_OPTIMIZATION_POSSIBLE'';
                 OPTIMIZED_SQL := NULL; -- EXPLICITLY SET TO NULL IF NO OPTIMIZATION IS PROVIDED
                 CHANGE_SUMMARY := ''CORTEX DETERMINED THE QUERY CANNOT BE FURTHER OPTIMIZED BASED ON CURRENT ANALYSIS OR IT IS ALREADY WELL-OPTIMIZED.'';
            END IF;
        EXCEPTION
            WHEN OTHER THEN
                -- HANDLE ERRORS SPECIFICALLY DURING CORTEX RESPONSE PARSING
                STATUS := ''PARSING_ERROR'';
                 ERROR_MESSAGE := ''FAILED TO PARSE CORTEX RESPONSE JSON: '' || SQLERRM;
                 OPTIMIZATION_RECOMMENDATIONS := ''PLEASE REVIEW THE ORIGINAL CORTEX RESPONSE MANUALLY FOR DETAILS.'';
        END;
        LET DETAILS ARRAY := JSON_RESULT:"structured_output"[0]:"raw_message":"ROOTCAUSE_AND_REMEDIATION";

        -- Step 7: Perform additional Snowflake-specific validation on the optimized query
        -- If the status is success and an optimized SQL was provided, attempt to explain it
        -- to catch basic syntax errors before reporting success.

    -- Step 8: Insert the final optimization results into the temporary table
    INSERT INTO app_schema.RECOMMANDATION_RESULTS
    select
    :QUERY_ID,
    :INPUT_QUERY,
    :DETAILS::STRING,
     :JSON_RESULT:"usage"::STRING,
     :STATUS
    ;
BEGIN
    CREATE OR REPLACE TABLE app_schema.QUERY_ANALYZER_RESULTS
    AS
    SELECT 
    QUERY_ID,
    ORIGINAL_QUERY,
    -- :CORTEX_PROMPT AS COMPLETE_PROMPT,
    -- TOKEN_USAGE,
    VALUE:TABLE_NAME::STRING AS TABLE_NAME,
    VALUE:POOR_PERFORMING_CODE_BLOCK::string AS POOR_PERFORMING_CODE_BLOCK,
    regexp_replace(VALUE:OPTIMIZATION_NUMBER,''[^0-9]'') AS OPTIMIZATION_NUMBER,
    VALUE:REMEDIATION_TYPE::string AS REMEDIATION_TYPE,
    VALUE:REWRITE_JUSTIFICATION::string AS REWRITE_JUSTIFICATION,
    VALUE:REMEDIATION_CATEGORY::STRING AS REMEDIATION_CATEGORY,
    VALUE:ACCURATE_ROOTCAUSE_REMEDIATION_SQL::STRING AS ROOTCAUSE_REMEDIATION_SQL  
    FROM 
    app_schema.RECOMMANDATION_RESULTS, LATERAL FLATTEN(PARSE_JSON(ACTIONS));
    COMMIT;
    END;
FINAL_RESULT_QUERY := ''SELECT * FROM app_schema.QUERY_ANALYZER_RESULTS'';
    -- Return the temporary table containing the optimization results
RS := (EXECUTE IMMEDIATE  :FINAL_RESULT_QUERY);
RETURN TABLE(RS);
END;
END';
