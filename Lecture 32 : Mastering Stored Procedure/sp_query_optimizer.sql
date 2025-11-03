create or replace TRANSIENT TABLE QUERY_OPTIMIZER_HELPER_DB.HELPER_SCH.EXP_PLAN_DATA (
	EXP_PLAN_STR VARCHAR(16777216) NOT NULL
);

CREATE OR REPLACE PROCEDURE QUERY_OPTIMIZER_HELPER_DB.HELPER_SCH.GET_EXPLAIN_PLAN_TXT("QUERY_TXT" VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
declare
    rs resultset ;
begin
    create or replace transient table query_optimizer_helper_db.helper_sch.exp_plan_data(
    exp_plan_str string not null
    );

    let sql := ''EXPLAIN USING TEXT '' || query_txt ;
    rs := (execute immediate :sql) ;
    Insert into query_optimizer_helper_db.helper_sch.exp_plan_data SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) ;
    return ''Data Inserted'' ;
end
';
