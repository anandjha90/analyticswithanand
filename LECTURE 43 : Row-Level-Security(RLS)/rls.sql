DROP WAREHOUSE DEMO_WAREHOUSE;
DROP DATABASE ANALYTICS;

USE ROLE SYSADMIN;

CREATE OR REPLACE WAREHOUSE DEMO_WAREHOUSE;
CREATE OR REPLACE DATABASE ANALYTICS;
CREATE OR REPLACE SCHEMA ANALYTICS.HR;

-- Create a table to apply Row-Level Security
CREATE OR REPLACE TABLE ANALYTICS.HR.EMPLOYEES
(   employee_id number,
    first_name varchar(50),
    last_name varchar(50),
    email varchar(50),
    hire_date date,
    country varchar(50)
);

-- INSERT VALUES
INSERT INTO analytics.hr.employees(employee_id,first_name,last_name,email,hire_date,country) 
VALUES
(100,'Steven','King','SKING@outlook.com','2013-06-17','US'),
(101,'Neena','Kochhar','NKOCHHAR@outlook.com','2015-09-21','US'),
(102,'Lex','De Haan','LDEHAAN@outlook.com','2011-01-13','US'),
(103,'Alexander','Hunold','AHUNOLD@outlook.com','2016-01-03','UK'),
(104,'Bruce','Ernst','BERNST@outlook.com','2017-05-21','UK'),
(105,'David','Austin','DAUSTIN@outlook.com','2015-06-25','UK'),
(106,'Valli','Pataballa','VPATABAL@outlook.com','2016-02-05','CA'),
(107,'Diana','Lorentz','DLORENTZ@outlook.com','2017-02-07','CA'),
(108,'Nancy','Greenberg','NGREENBE@outlook.com','2012-08-17','CA');

select * from analytics.hr.employees;

-- Create a role mapping table
CREATE OR REPLACE TABLE  ANALYTICS.HR.ROLE_MAPPING
(
    country varchar(50),
    role_name varchar(50)
);

INSERT INTO ANALYTICS.HR.ROLE_MAPPING(country, role_name) 
VALUES
('US','DATA_ANALYST_ROLE_US'),
('UK','DATA_ANALYST_ROLE_UK'),
('CA','DATA_ANALYST_ROLE_CA');

select * from role_mapping;

-- Create a Row Access Policy
use role SYSADMIN;

create or replace row access policy analytics.hr.country_role_policy as (country_name varchar) returns boolean ->
  'SYSADMIN' = current_role()
      or exists (
            select 1 from role_mapping
              where role_name = current_role()
                and country = country_name
          )
;

--  Add the Row Access Policy to a table
use role SYSADMIN;

alter table analytics.hr.employees 
add row access policy analytics.hr.country_role_policy on (country);

-- Create Custom Roles and their Role Hierarchy
use role SECURITYADMIN;

drop role DATA_ANALYST_ROLE_US;
drop role DATA_ANALYST_ROLE_UK;
drop role DATA_ANALYST_ROLE_CA;

create or replace role DATA_ANALYST_ROLE_US;
create or replace role DATA_ANALYST_ROLE_UK;
create or replace role DATA_ANALYST_ROLE_CA;

-- For TONY User
CREATE USER user_tony
PASSWORD = 'Tony123!'
DEFAULT_ROLE = DATA_ANALYST_ROLE_US
DEFAULT_WAREHOUSE = DEMO_WAREHOUSE
MUST_CHANGE_PASSWORD = TRUE;  -- User will be prompted to change the password on first login

-- For STEVE User
CREATE USER user_steve
PASSWORD = 'Steve123!'
DEFAULT_ROLE = DATA_ANALYST_ROLE_UK
DEFAULT_WAREHOUSE = DEMO_WAREHOUSE
MUST_CHANGE_PASSWORD = TRUE;

-- -- For BRUCE User
CREATE USER user_bruce
PASSWORD = 'Bruce123!'
DEFAULT_ROLE = DATA_ANALYST_ROLE_CA
DEFAULT_WAREHOUSE = DEMO_WAREHOUSE
MUST_CHANGE_PASSWORD = TRUE;

-- Assign Custom Roles to Users
use role SECURITYADMIN;

grant role DATA_ANALYST_ROLE_US to user user_tony;
grant role DATA_ANALYST_ROLE_UK to user user_steve;
grant role DATA_ANALYST_ROLE_CA to user user_bruce;

-- The below SQL statements assigns the custom roles to the role SYSADMIN so that the SYSADMIN can inherit all the privileges assigned to custom role.

use role SECURITYADMIN;

grant role DATA_ANALYST_ROLE_US to role SYSADMIN;
grant role DATA_ANALYST_ROLE_UK to role SYSADMIN;
grant role DATA_ANALYST_ROLE_CA to role SYSADMIN;

-- Grant SELECT privilege on table to custom roles
use role SYSADMIN;

-- Grant SELECT privilege on table to custom roles
use role SYSADMIN;

GRANT ALL PRIVILEGES ON SCHEMA DEMO_SCHEMA TO ROLE sysadmin;

-- Grant USAGE privilege on virtual warehouse to custom roles
use role ACCOUNTADMIN;

SHOW GRANTS ON DATABASE DEMO_DATABASE;
SHOW GRANTS ON SCHEMA DEMO_SCHEMA;

SHOW GRANTS TO USER user_tony;
SHOW GRANTS TO USER user_steve;
SHOW GRANTS TO USER user_bruce;

SHOW GRANTS TO ROLE DATA_ANALYST_ROLE_US;
SHOW GRANTS TO ROLE DATA_ANALYST_ROLE_UK;
SHOW GRANTS TO ROLE DATA_ANALYST_ROLE_CA;

GRANT ALL PRIVILEGES ON SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_US;
GRANT ALL PRIVILEGES ON SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_UK;
GRANT ALL PRIVILEGES ON SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_CA;

GRANT USAGE ON WAREHOUSE DEMO_WAREHOUSE  TO ROLE DATA_ANALYST_ROLE_US;
GRANT USAGE ON DATABASE DEMO_DATABASE TO ROLE DATA_ANALYST_ROLE_US;
GRANT USAGE ON SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_US;
GRANT SELECT ON ALL TABLES IN SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_US;
GRANT CREATE TABLE ON SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_US;
GRANT SELECT ON FUTURE TABLES IN SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_US;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_US;
GRANT INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_US;

GRANT USAGE ON WAREHOUSE DEMO_WAREHOUSE  TO ROLE DATA_ANALYST_ROLE_UK;
GRANT USAGE ON DATABASE DEMO_DATABASE TO ROLE DATA_ANALYST_ROLE_UK;
GRANT USAGE ON SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_UK;
GRANT CREATE TABLE ON SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_UK;
GRANT SELECT ON ALL TABLES IN SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_UK;
GRANT SELECT ON FUTURE TABLES IN SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_UK;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_UK;
GRANT INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_UK;

GRANT USAGE ON WAREHOUSE DEMO_WAREHOUSE  TO ROLE DATA_ANALYST_ROLE_UK;
GRANT USAGE ON DATABASE DEMO_DATABASE TO ROLE DATA_ANALYST_ROLE_CA;
GRANT USAGE ON SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_CA;
GRANT CREATE TABLE ON SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_CA;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_CA;
GRANT SELECT ON FUTURE TABLES IN SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_CA;
GRANT INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA DEMO_SCHEMA TO ROLE DATA_ANALYST_ROLE_UK;

-- Query and verify Row-Level Security on table using custom roles
USE ROLE DATA_ANALYST_ROLE_US;
SELECT * FROM ANALYTICS.HR.EMPLOYEES;   -- VISIBLE ONLY US DATA

USE ROLE DATA_ANALYST_ROLE_UK;
SELECT * FROM ANALYTICS.HR.EMPLOYEES; --  VISIBLE ONLY UK DATA

USE ROLE DATA_ANALYST_ROLE_CA;
SELECT * FROM ANALYTICS.HR.EMPLOYEES; -- VISIBLE ONLY CA DATA

USE ROLE SYSADMIN;
SELECT * FROM ANALYTICS.HR.EMPLOYEES; -- ALL DATA VISIBLE

-- Revoke privileges on role mapping table to custom roles
use role SYSADMIN;

revoke all privileges on table analytics.hr.role_mapping from role DATA_ANALYST_ROLE_US;
revoke all privileges on table analytics.hr.role_mapping from role DATA_ANALYST_ROLE_UK;
revoke all privileges on table analytics.hr.role_mapping from role DATA_ANALYST_ROLE_CA;

-- The below SQL statement removes a row access policy on a table.
alter table EMPLOYEES drop row access policy country_role_policy;

-- The below SQL statement removes all row access policy associations from a table.
alter table EMPLOYEES drop all row access policies;

-- The below SQL statement extracts the row access policies present in the database and schema of the current session.
show row access policies;

-- The below SQL statement extracts information of the row access policy country_role_policy.
describe row access policy country_role_policy;

-- The below SQL statement lists all the objects on which row access policy named country_role_policy is attached.
select * from table(information_schema.policy_references(policy_name=>'country_role_policy'));

-- The below SQL statement drops row access policy named country_role_policy.
drop row access policy country_role_policy;


