create or replace TABLE DATA_GOVERNANCE.SNOWFLAKE.TABLE_DESCRIPTIONS (
	DATABASE_NAME VARCHAR(16777216),
	SCHEMA_NAME VARCHAR(16777216),
	TABLE_NAME VARCHAR(16777216) NOT NULL,
	DESCRIPTION VARCHAR(16777216),
	GENERATED_ON TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP(),
	primary key (TABLE_NAME)
);


CREATE OR REPLACE PROCEDURE DATA_GOVERNANCE.SNOWFLAKE.GENERATE_NEW_TABLE_DESCRIPTIONS()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
BEGIN
    -- Insert AI-generated descriptions into the table_descriptions table
    INSERT INTO table_descriptions (database_name, schema_name, table_name, description)
    SELECT 
        table_catalog AS database_name,
        table_schema AS schema_name,
        table_name,
        SNOWFLAKE.CORTEX.COMPLETE(
            ''llama2-70b-chat'',
            CONCAT(
                ''You are an expert in database management and metadata documentation. Your task is to generate a concise and meaningful description of a database table based on its name. 
                
                Table Name: '', table_name, ''

                Provide a one-sentence description of what this table likely contains. Focus on its purpose in a business or analytical context. 
                
                Respond only with the description, without additional text.''
            )
        )::STRING  -- Ensure it''s cast to STRING
    FROM SNOWFLAKE.ACCOUNT_USAGE.TABLES
    WHERE (table_catalog, table_schema, table_name) NOT IN 
          (SELECT database_name, schema_name, table_name FROM table_descriptions);
    -- Return success message
    RETURN ''Table descriptions updated successfully!'';
END;
';

CALL DATA_GOVERNANCE.SNOWFLAKE.GENERATE_NEW_TABLE_DESCRIPTIONS();
