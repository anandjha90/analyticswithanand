create or replace TABLE STREAMLIT_APPS.DQ_APP.DIM_DATE (
	DATE_KEY NUMBER(38,0),
	DATE DATE NOT NULL,
	DAY NUMBER(38,0),
	WEEKDAY NUMBER(38,0),
	WEEK_DAY_NAME VARCHAR(10),
	WEEK_DAY_NAME_SHORT VARCHAR(3),
	DAY_OF_YEAR NUMBER(38,0),
	WEEK_OF_MONTH NUMBER(38,0),
	WEEK_OF_YEAR NUMBER(38,0),
	MONTH NUMBER(38,0),
	MONTH_NAME VARCHAR(10),
	MONTH_NAME_SHORT VARCHAR(3),
	QUARTER NUMBER(38,0),
	QUARTER_NAME VARCHAR(6),
	YEAR NUMBER(38,0),
	MMYYYY VARCHAR(6),
	MONTH_YEAR VARCHAR(7),
	IS_WEEKEND BOOLEAN,
	IS_HOLIDAY BOOLEAN,
	FIRST_DATE_OF_YEAR DATE,
	LAST_DATE_OF_YEAR DATE,
	FIRST_DATE_OF_QUATER DATE,
	LAST_DATE_OF_QUATER DATE,
	FIRST_DATE_OF_MONTH DATE,
	LAST_DATE_OF_MONTH DATE,
	FIRST_DATE_OF_WEEK DATE,
	LAST_DATE_OF_WEEK DATE,
	constraint PK_DIM_DATE primary key (DATE_KEY)
);

CREATE OR REPLACE PROCEDURE STREAMLIT_APPS.DQ_APP.SP_LOAD_DIM_DATE("START_DATE" DATE, "END_DATE" DATE, "TARGET_TABLE" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS OWNER
AS '
DECLARE
    RESULT STRING;
    SQL_COMMAND STRING;
BEGIN
    
    
    -- Construct the INSERT statement using a recursive CTE
    SQL_COMMAND := ''INSERT INTO '' || :TARGET_TABLE || ''
    WITH RECURSIVE date_range AS (
        SELECT '''''' || :START_DATE || ''''''::DATE AS DATE_KEY
        UNION ALL
        SELECT DATEADD(DAY, 1, DATE_KEY)
        FROM date_range
        WHERE DATE_KEY < '''''' || :END_DATE || ''''''::DATE
    )
    SELECT
            YEAR(DATE_KEY) * 10000 + MONTH(DATE_KEY) * 100 + DAY(DATE_KEY) as DATE_KEY,
            DATE_KEY as DATE,
            DAY(DATE_KEY) AS Day,
            EXTRACT(DAYOFWEEK FROM DATE_KEY) AS Weekday,
            TO_CHAR(DATE_KEY, ''''Day'''') AS Week_Day_Name,
            DAYNAME(DATE_KEY)  AS Week_Day_Name_Short,
            DAYOFYEAR(DATE_KEY) AS Day_Of_Year,
            CEIL(DAY(DATE_KEY) / 7) AS Week_Of_Month,
            WEEK(DATE_KEY) AS Week_Of_Year,
            MONTH(DATE_KEY) AS Month,
            TO_CHAR(DATE_KEY, ''''MMMM'''') AS Month_Name,
            UPPER(SUBSTR(TO_CHAR(DATE_KEY, ''''Month''''), 1, 3)) AS Month_Name_Short,
            QUARTER(DATE_KEY) AS Quarter,
            CASE 
                WHEN QUARTER(DATE_KEY) = 1 THEN ''''First''''
                WHEN QUARTER(DATE_KEY) = 2 THEN ''''Second''''
                WHEN QUARTER(DATE_KEY) = 3 THEN ''''Third''''
                WHEN QUARTER(DATE_KEY) = 4 THEN ''''Fourth''''
            END AS Quarter_Name,
            YEAR(DATE_KEY) AS Year,
            LPAD(MONTH(DATE_KEY)::VARCHAR, 2, ''''0'''') || YEAR(DATE_KEY)::VARCHAR AS MMYYYY,
            YEAR(DATE_KEY)::VARCHAR || UPPER(SUBSTR(TO_CHAR(DATE_KEY, ''''Month''''), 1, 3)) AS Month_Year,
            CASE 
                WHEN DAYNAME(DATE_KEY)  IN (''''Sat'''', ''''Sun'''') THEN TRUE
                ELSE FALSE
            END AS Is_Weekend,
            FALSE AS Is_Holiday,
            DATE_TRUNC(''''YEAR'''', DATE_KEY) AS First_Date_of_Year,
            DATE_TRUNC(''''YEAR'''', DATEADD(YEAR, 1, DATE_KEY)) - 1 AS Last_Date_of_Year,
            DATE_TRUNC(''''QUARTER'''', DATE_KEY) AS First_Date_of_Quater,
            DATE_TRUNC(''''QUARTER'''', DATEADD(QUARTER, 1, DATE_KEY)) - 1 AS Last_Date_of_Quater,
            DATE_TRUNC(''''MONTH'''', DATE_KEY) AS First_Date_of_Month,
            LAST_DAY(DATE_KEY) AS Last_Date_of_Month,
            DATE_TRUNC(''''WEEK'''', DATE_KEY) AS First_Date_of_Week,
            DATE_TRUNC(''''WEEK'''', DATEADD(WEEK, 1, DATE_KEY)) - 1 AS Last_Date_of_Week
    FROM date_range
    ORDER BY DATE_KEY'';
    
    -- Execute the INSERT statement
    EXECUTE IMMEDIATE :SQL_COMMAND;
    
   
    RETURN ''Calendar table created'';
END;
';

CALL STREAMLIT_APPS.DQ_APP.SP_LOAD_DIM_DATE('2025-10-01', '2026-03-01','STREAMLIT_APPS.DQ_APP.DIM_DATE');
