ANALYTICSCREATE OR REPLACE TABLE customer_data (
    id INT,
    customer_name STRING,
    credit_card_number STRING,
    email STRING,
    region STRING
);

create or replace file format csv_file_format
    type = 'csv' 
    compression = 'none' 
    field_delimiter = ','
    field_optionally_enclosed_by = 'none'
    skip_header = 1 ; 

CREATE OR REPLACE MASKING POLICY mask_credit_card AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('admin_role') THEN val
        ELSE CONCAT('XXXX-XXXX-XXXX-', RIGHT(val, 4))
    END;

CREATE OR REPLACE MASKING POLICY mask_email AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('admin_role') THEN val
        ELSE CONCAT(LEFT(val, 2), '***@***.***')
    END;

ALTER TABLE customer_data MODIFY COLUMN credit_card_number SET MASKING POLICY mask_credit_card;
ALTER TABLE customer_data MODIFY COLUMN email SET MASKING POLICY mask_email;


-- For Admin User
CREATE OR REPLACE USER admin_user
PASSWORD = 'AdminUser123!'
DEFAULT_ROLE = admin_role
DEFAULT_WAREHOUSE = DEMO_WAREHOUSE
MUST_CHANGE_PASSWORD = TRUE;  -- User will be prompted to change the password on first login

CREATE OR REPLACE USER limited_user
PASSWORD = 'LimitedUser123!'
DEFAULT_ROLE = limited_user_role
DEFAULT_WAREHOUSE = DEMO_WAREHOUSE
MUST_CHANGE_PASSWORD = TRUE;  -- User will be prompted to change the password on first login

CREATE OR REPLACE ROLE admin_role;
CREATE OR REPLACE ROLE limited_user_role;

grant role admin_role to user admin_user;
grant role limited_user_role to user limited_user;

-- Grant full access to admin role : Full Access
GRANT SELECT ON TABLE customer_data TO ROLE admin_role;

-- Grant limited access to limited user role : Masked Access
GRANT SELECT ON TABLE customer_data TO ROLE limited_user_role;


grant usage on warehouse DEMO_WAREHOUSE to role admin_role;
grant usage on warehouse DEMO_WAREHOUSE to role limited_user_role;

grant usage on database DEMO_DATABASE to role admin_role;
grant usage on schema DEMO_SCHEMA to role admin_role;
grant select on all tables in schema DEMO_DATABASE.DEMO_SCHEMA to role admin_role;

grant usage on database DEMO_DATABASE to role limited_user_role;
grant usage on schema DEMO_SCHEMA to role limited_user_role;
grant select on all tables in schema DEMO_DATABASE.DEMO_SCHEMA to role limited_user_role;
    
USE ROLE admin_role;
SELECT id, customer_name, credit_card_number, email, region FROM customer_data;

USE ROLE limited_user_role;
SELECT id, customer_name, credit_card_number, email, region FROM customer_data;

-- check current role
SELECT CURRENT_ROLE();

-- check masking policies
SHOW MASKING POLICIES;

-- check grants on tables
SHOW GRANTS ON TABLE customer_data;
