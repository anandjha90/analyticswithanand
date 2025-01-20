-- create a file format
create or replace file format csv_file_format
    type = 'csv' 
    compression = 'none' 
    field_delimiter = ','
    field_optionally_enclosed_by = 'none'
    skip_header = 1 ; 
    
-- creating an internal stage
CREATE OR REPLACE STAGE my_internal_stage
file_format = csv_file_format;

-- Example for Table 1
COPY INTO @my_internal_stage/customer_data.csv
FROM (SELECT * FROM customer_data);

-- Example for Table 2
COPY INTO @my_internal_stage/sales_region_data.csv
FROM (SELECT * FROM sales_region_data);

SHOW STAGES;
LIST @my_internal_stage;

GET @my_internal_stage file://D:\Snowflake_Output;
-- run this in SNOWSQL using CLI not in SNOWFLAKE UI as from snowflake ui it will throw unsupported feature 
