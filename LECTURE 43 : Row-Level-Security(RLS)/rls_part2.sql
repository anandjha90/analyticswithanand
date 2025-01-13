-- drop everything and start fresh
DROP WAREHOUSE DEMO_WAREHOUSE;
DROP DATABASE DEMO_DATABASE;
DROP SCHEMA DEMO_SCHEMA;

-- use the necessary role
USE ROLE SYSADMIN;

CREATE OR REPLACE WAREHOUSE DEMO_WAREHOUSE;
CREATE OR REPLACE DATABASE DEMO_DATABASE;
CREATE OR REPLACE SCHEMA DEMO_SCHEMA;

-- create a file format
create or replace file format csv_file_format
    type = 'csv' 
    compression = 'none' 
    field_delimiter = ','
    field_optionally_enclosed_by = 'none'
    skip_header = 1 ; 

-- Create the Snowflake table where the ingested data will be stored.
CREATE OR REPLACE TABLE ingested_data (
    id INT,
    region STRING,
    department STRING,
    data STRING
);

-- Create a role mapping table
CREATE OR REPLACE TABLE DEMO_DATABASE.DEMO_SCHEMA.ROLE_MAPPING
(
    region varchar(50), 
    department varchar(50),
    role_name varchar(50)
);
INSERT INTO DEMO_DATABASE.DEMO_SCHEMA.ROLE_MAPPING(region, department,role_name) 
VALUES
('East','Finance','admin_user'),
('West','Sales','regional_manager_user'),
('North','IT','department_user'),
('South','HR',NULL);

USE ROLE ACCOUNTADMIN;
----------------------------------------------------AWS (S3) INTEGRATION------------------------------------------------------------------------
CREATE OR REPLACE STORAGE integration s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN ='arn:aws:iam::661806635168:role/banking_role' 
STORAGE_ALLOWED_LOCATIONS =('s3://czec-banking/'); 

DESC integration s3_int;

----------------------- stage---------------------------------------------------------
-- Define an external stage to access the AWS S3 bucket. 
-- Ensure the necessary IAM role and S3 bucket policies are set for Snowflake to read from the bucket.

CREATE OR REPLACE STAGE s3_stage
URL ='s3://czec-banking'
file_format = csv_file_format
storage_integration = s3_int;

LIST @s3_stage;

SHOW STAGES;

-- Set up Snowpipe to automate data ingestion from the S3 bucket.
CREATE OR REPLACE PIPE snopipe_ingested_data  AUTO_INGEST = TRUE AS
COPY INTO DEMO_DATABASE.DEMO_SCHEMA.INGESTED_DATA
FROM '@s3_stage/INGESTION/' 
FILE_FORMAT = csv_file_format;

-- checking pipe status
ALTER PIPE snopipe_ingested_data refresh;

-- to check for data has been ingested or not
select * from table(information_schema.copy_history(table_name=>'ingested_data', start_time=>
dateadd(hours, -1, current_timestamp())));

select distinct region from ingested_data;      -- East,West,North,South 
select distinct department from ingested_data;  -- Finance, Sales, IT, HR

-- Create a Row Access Policy (RLS) to restrict data visibility based on roles.
use role SYSADMIN;

CREATE OR REPLACE ROW ACCESS POLICY region_department_policy
AS (region STRING, department STRING)
RETURNS BOOLEAN ->
    (
        -- Full access for admin role
        CURRENT_ROLE() = 'admin_role'
        -- Access for region managers
        OR (CURRENT_ROLE() = 'region_manager_role' AND region = 'North')
        -- Access for department users
        OR (CURRENT_ROLE() = 'department_user_role' AND department = 'Sales')
    );
 

-- Attach the ROW ACCESS POLICY to the ingested_data table.
ALTER TABLE ingested_data
ADD ROW ACCESS POLICY region_department_policy ON (region, department);


-- First, ensure the roles are created:
use role ACCOUNTADMIN;

CREATE OR REPLACE ROLE admin_role;
CREATE OR REPLACE ROLE region_manager_role;
CREATE OR REPLACE ROLE department_user_role;

-- You can create users using the CREATE USER command. Each user should have a unique name, login credentials, and be assigned a role.

USE ROLE ACCOUNTADMIN;

-- For Admin User
CREATE OR REPLACE USER admin_user
PASSWORD = 'AdminUser123!'
DEFAULT_ROLE = admin_role
DEFAULT_WAREHOUSE = DEMO_WAREHOUSE
MUST_CHANGE_PASSWORD = TRUE;  -- User will be prompted to change the password on first login

-- For Regional Manager User
CREATE OR REPLACE USER regional_manager_user
PASSWORD = 'RegionManager123!'
DEFAULT_ROLE = region_manager_role
DEFAULT_WAREHOUSE = DEMO_WAREHOUSE
MUST_CHANGE_PASSWORD = TRUE;

-- -- For Department User
CREATE OR REPLACE USER department_user
PASSWORD = 'DepartmentUser123!'
DEFAULT_ROLE = department_user_role
DEFAULT_WAREHOUSE = DEMO_WAREHOUSE
MUST_CHANGE_PASSWORD = TRUE;

-- Assign Custom Roles to Users
use role SECURITYADMIN;

grant role admin_role to user admin_user;
grant role region_manager_role to user regional_manager_user;
grant role department_user_role to user department_user;

-- Grant table access
GRANT SELECT ON TABLE ingested_data TO ROLE admin_role;
GRANT SELECT ON TABLE ingested_data TO ROLE region_manager_role;
GRANT SELECT ON TABLE ingested_data TO ROLE department_user_role;

-- The below SQL statements assigns the custom roles to the role SYSADMIN so that the SYSADMIN can inherit all the privileges assigned to custom role.

use role SECURITYADMIN;

grant role admin_role to role SYSADMIN;
grant role region_manager_role to role SYSADMIN;
grant role department_user_role to role SYSADMIN;

-- Grant SELECT privilege on table to custom roles
use role SYSADMIN;

grant usage on database DEMO_DATABASE to role admin_role;
grant usage on schema DEMO_DATABASE.DEMO_SCHEMA to role admin_role;
grant select on all tables in schema DEMO_DATABASE.DEMO_SCHEMA to role admin_role;

grant usage on database DEMO_DATABASE to role region_manager_role;
grant usage on schema DEMO_DATABASE.DEMO_SCHEMA to role region_manager_role;
grant select on all tables in schema DEMO_DATABASE.DEMO_SCHEMA to role region_manager_role;

grant usage on database DEMO_DATABASE to role department_user_role;
grant usage on schema DEMO_DATABASE.DEMO_SCHEMA to role department_user_role;
grant select on all tables in schema DEMO_DATABASE.DEMO_SCHEMA to role department_user_role;

-- Grant USAGE privilege on virtual warehouse to custom roles
use role ACCOUNTADMIN;

grant usage on warehouse DEMO_WAREHOUSE to role admin_role;
grant usage on warehouse DEMO_WAREHOUSE to role region_manager_role;
grant usage on warehouse DEMO_WAREHOUSE to role department_user_role;



-- Query and verify Row-Level Security on table using custom roles
USE ROLE region_manager_role;
SELECT * FROM DEMO_DATABASE.DEMO_SCHEMA.INGESTED_DATA;   -- VISIBLE ONLY US DATA

-- The below SQL statement removes a row access policy on a table.
alter table INGESTED_DATA drop row access policy ROLE_BASED_ACCESS_POLICY;

show row access policies;
