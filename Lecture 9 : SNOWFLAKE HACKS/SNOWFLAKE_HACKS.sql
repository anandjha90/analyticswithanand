-- What's my current user, role, warehouse, database, etc?
SELECT CURRENT_USER();
SELECT CURRENT_ROLE();
SELECT CURRENT_WAREHOUSE();
SELECT CURRENT_DATABASE();

--How do I use a specific role, warehouse, database, etc?
SHOW ROLES;
USE ROLE {role};

SHOW WAREHOUSES;
USE WAREHOUSE {warehouse};

SELECT * FROM INFORMATION_SCHEMA.DATABASES;
USE DATABASE {database};

--How do I set my default warehouse?
--Determine your current warehouse:
SELECT CURRENT_WAREHOUSE();


--Alter your default warehouse:
ALTER USER {username} SET DEFAULT_WAREHOUSE = {warehouse};

ALTER USER analyticswithanand SET DEFAULT_WAREHOUSE = demo_warehouse;
--How do I create a new warehouse?
--Check if the warehouse already exists:
SHOW WAREHOUSES;
DESCRIBE WAREHOUSE demo_warehouse;

--Create (or replace) the warehouse:
CREATE OR REPLACE WAREHOUSE ANALYTICS
    WITH WAREHOUSE_SIZE = 'X-SMALL'
    MAX_CLUSTER_COUNT = 1
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;
    

--However, with a simple SQL query you can set whatever timeout you need. The timeout value is in seconds.
ALTER WAREHOUSE IF EXISTS {warehouse} SET AUTO_SUSPEND = {seconds};

ALTER WAREHOUSE IF EXISTS ANALYTICS SET AUTO_SUSPEND = 3600;

--How do I create a new database user?
SHOW ROLES;
USE ROLE ACCOUNTADMIN;
-- USE ROLE SECURITYADMIN;
CREATE USER {username} PASSWORD = '{password}' MUST_CHANGE_PASSWORD = TRUE;
-- Grant usage on a database and warehouse to a role
SHOW GRANTS TO ROLE {role};
GRANT USAGE ON WAREHOUSE {warehouse} TO ROLE {role};
GRANT USAGE ON DATABASE {database} TO ROLE {role};

--How to create a role that allows 'create warehouse'
use database analytics;
use warehouse analytics;
create role administrator;
grant create warehouse on account to role ADMINISTRATOR;
grant usage on database ANALYTICS to role ADMINISTRATOR;
show grants on role ADMINISTRATOR;
grant role ADMINISTRATOR to user <username>;
show grants on user <username>;

--Snowflake provides a full set of SQL commands for managing users and security. 
-- These commands can only be executed by users who are granted roles that have the OWNERSHIP privilege on the managed object. 
--This is usually restricted to the ACCOUNTADMIN and SECURITYADMIN roles.

use database "DEMO_DATABASE";

-- Copy only table structure, no data copying:
create or replace table CUSTOMERS_COPY LIKE "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1000"."CUSTOMER";

DESCRIBE TABLE CUSTOMERS_COPY;
describe table CUSTOMERS_COPY_method1;
SELECT * FROM CUSTOMERS_COPY;
SELECT * FROM CUSTOMERS_COPY_method1;

--Copy both the entire table structure and all the data inside:
--method 1
CREATE OR REPLACE TABLE CUSTOMERS_COPY_method1 clone AJ_customer;
CREATE OR REPLACE TABLE CUSTOMERS_COPY_method3 clone "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1000"."LINEITEM";

select * from CUSTOMERS_COPY_method1;
DELETE FROM CUSTOMERS_COPY_method1 WHERE CUST_NAME = 'anand';

--method 2
CREATE OR REPLACE TABLE CUSTOMERS_COPY_method2 AS
SELECT * from "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1000"."ORDERS" limit 1000;

CREATE OR REPLACE TABLE AJ_CUST_TRUNC_TEST AS
SELECT * FROM AJ_customer;

SELECT * FROM AJ_CUST_TRUNC_TEST;

--Copy entire table structure along with particular data set:
create OR REPLACE table AJ_PARTS_COPY as 
select * from "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1000"."PART" 
where P_TYPE = 'ECONOMY ANODIZED COPPER';

--Copy only particular columns into new table along with particular data set:
create OR REPLACE table AJ_PARTS_DETAILS_COPY as 
select P_PARTKEY,P_NAME ,P_MFGR,P_BRAND,P_SIZE,P_RETAILPRICE
from  "SNOWFLAKE_SAMPLE_DATA"."TPCH_SF1000"."PART";
--where category = 2;

SELECT * FROM AJ_PARTS_DETAILS_COPY;

-- Query the 
-- GET_DDL function to retrieve a DDL statement that could be executed to recreate the specified table. 
--- The statement includes the constraints currently set on a table.
select get_ddl('table', 'AJ_PARTS_DETAILS_COPY');



























