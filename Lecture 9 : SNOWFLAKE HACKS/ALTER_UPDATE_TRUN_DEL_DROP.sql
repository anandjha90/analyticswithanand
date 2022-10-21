/* What is Snowflake TRUNCATE Table?
The Snowflake TRUNCATE Table component is a Feature offered by snowflake that 
deletes all existing rows from a table or partition while maintaining the table’s integrity. 
However, you can’t use it on a view, an external, or a temporary table. 
Depending on whether the flow of current is in the midst of a database transaction, 

Snowflake TRUNCATE Table is executed in one of two ways. 
The first is to use the TRUNCATE command. 

The second option is to use a DELETE FROM statement, which itself is recommended 
if the current job is a transaction. 
It eliminates all rows from a table while maintaining the table’s integrity. 

After the command completes, the load metadata for the table is deleted, 
allowing the same files to be uploaded into the table again. 

For the duration of the data retention term, 
Snowflake TRUNCATE Table keeps deleted data for archival purposes (e.g., utilizing Time Travel). 
The load metadata, on the other hand, cannot be restored when a table is truncated.

Snowflake TRUNCATE Table is used to delete all records from a table while keeping the 
table’s schema or structure. 

Despite the fact that Snowflake TRUNCATE Table is regarded as a DDL command, 
rather than a DML statement so it can’t be undone, 
truncate procedures, especially for large tables, drop and recreate the table, 
which is much quicker than deleting rows one by one. 
Truncate operations result in an implicit commit, therefore they can’t be undone


Delete or Truncate: Which is better?
TRUNCATE is quicker than DELETE since it does not check all records before deleting them. 
Snowflake TRUNCATE Table locks the entire table to drop the data from the table. 
As a result, this command needs significantly low transaction space than DELETE. 
TRUNCATE, unlike DELETE, does not revive the no. of rows that have been deleted from the table.

Syntax: TRUNCATE [ TABLE ] [ IF EXISTS ] <name>

Usage Notes:

Snowflake TRUNCATE Table keep deleted data for future reuse for the duration of the data 
retention period; however, the load information cannot be restored when the table is truncated.
If the table name is completely qualified or the database schema is presently in use for the 
session, the table keyword is not required.

The Snowflake TRUNCATE Table command is a DML (Data Manipulation Language) command that is used to add (insert), 
delete (delete), and alter (update) data in a database. */


use database "DEMO_DATABASE";

DROP TABLE aj_retirement;
undrop table aj_retirement ;

describe table aj_retirement;

CREATE or replace TABLE IF NOT EXISTS aj_retirement
(
	 source_name VARCHAR(6)   
	,process_name VARCHAR(3)   
	,val_dt VARCHAR(10)   
	,run_dt VARCHAR(10)   
	,line_indicator VARCHAR(4)    
	,total_record_count VARCHAR(12)   
	,total_record_amount VARCHAR(18)  
	,sel_record_count VARCHAR(12)   
	,sel_record_amount VARCHAR(18)   
	,byp_record_count VARCHAR(12)   
	,byp_record_amount VARCHAR(18)   
	,zero_record_count VARCHAR(12)   
	,zero_record_amount VARCHAR(18)   
	,created_date TIMESTAMP WITHOUT TIME ZONE NOT NULL 
);

SELECT * FROM AJ_RETIREMENT; 
DESCRIBE TABLE AJ_RETIREMENT;

-- Query the 
-- GET_DDL function to retrieve a DDL statement that could be executed to recreate the specified table. 
--- The statement includes the constraints currently set on a table.
select get_ddl('table', 'AJ_RETIREMENT');


SHOW COLUMNS IN AJ_RETIREMENT;

INSERT INTO retirement.aud_copy_updated
SELECT *,ROW_NUMBER() OVER () AS ROW_NUM
FROM retirement.aud_copy ;

SELECT * FROM retirement.aud_copy WHERE total_record_count NOT IN (SELECT DISTINCT total_record_count FROM retirement.aud_copy_view)

SELECT DISTINCT * FROM retirement.aud_copy;

SELECT COUNT(DISTINCT line_indicator) from retirement.aud_copy;
SELECT COUNT(DISTINCT line_indicator) from retirement.aud_copy_view;

SELECT source_name,process_name,val_dt,run_dt,line_indicator,total_record_count,total_record_amount,sel_record_count,sel_record_amount,
byp_record_count,byp_record_amount,zero_record_count,zero_record_amount
FROM retirement.aud_copy
EXCEPT 
SELECT  source_name,process_name,val_dt,run_dt,line_indicator,total_record_count,total_record_amount,sel_record_count,sel_record_amount,
byp_record_count,byp_record_amount,zero_record_count,zero_record_amount
FROM retirement.aud_copy_view

SELECT source_name,process_name,val_dt,run_dt FROM retirement.aud_copy WHERE run_dt NOT IN
 (SELECT distinct run_dt FROM retirement.aud_copy_view)

DROP VIEW retirement.aud_copy_view;

create or replace view retirement.aud_copy_view AS
SELECT source_name,process_name,val_dt,run_dt,line_indicator,total_record_count,total_record_amount,sel_record_count,sel_record_amount,
byp_record_count,byp_record_amount,zero_record_count,zero_record_amount,
MAX(created_date) AS LATEST_CREATED_DATE
FROM retirement.aud_copy
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13
ORDER BY  1,2,3,4,5,6,7,8,9,10,11,12,13;

SELECT * FROM  retirement.aud_copy_view;

--23874,30,000
DROP VIEW retirement.aud_copy_view

DROP TABLE aud_copy_update

ALTER TABLE retirement.aud_copy
DROP COLUMN row_num

update table 
set age = null where name = 'anand'

commit
CREATE VIEW retirement.aud_view AS
SELECT DISTINCT a.source_name,a.process_name,a.val_dt,a.run_dt,line_indicator,total_record_count,total_record_amount,sel_record_count,sel_record_amount,
byp_record_count,byp_record_amount,zero_record_count,zero_record_amount,b.LATEST_CREATED_DATE
FROM retirement.aud_copy a
INNER JOIN
(
SELECT source_name,process_name,val_dt,run_dt,
MAX(CREATED_DATE) AS LATEST_CREATED_DATE
FROM retirement.aud_copy  
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4) b
ON a.source_name = b.source_name 
AND a.process_name = b.process_name 
AND a.val_dt = b.val_dt 
AND a.run_dt = b.run_dt
AND a.created_date = b.latest_created_date
ORDER BY 4,5



SELECT * FROM retirement.aud_copy  
DELETE FROM retirement.aud_copy WHERE row_num = 88
COMMIT
-- 24,874 , 32,0000,382,22492



WHERE 






SELECT DISTINCT source_name,process_name,val_dt,run_dt
FROM retirement.aud_copy_view;

SELECT DISTINCT source_name,process_name,val_dt,run_dt,total_record_count,total_record_amount,LATEST_CREATED_DATE
FROM retirement.aud_copy_view;

SELECT DISTINCT run_dt FROM retirement.aud_copy

SELECT *, ROW_NUMBER() OVER() FROM retirement.aud_copy_view;

INSERT INTO retirement.aud_copy
VLAUES

INSERT INTO retirement.aud_copy 
VALUES('210DE1','PN ','04-30-2022','04-19-2022','1   ','     24,874','  32,0000                ','         382','                  ','      22,492','                  ','           0','                  ','2022-05-15 00:00:00.000');

UPDATE retirement.aud_copy 
SET created_date = ''

DROP TABLE  retirement.aud_copy 

INSERT INTO retirement.aud_copy 
SELECT * FROM retirement.aud_copy_update 

SELECT * INTO retirement.aud_copy FROM retirement.aud_copy_update

SELECT * FROM retirement.aud_copy

select * from retirement.aud_copy where created_date = '2022-05-04'
-- DITINCT : source_name,process_name,val_dt,run_dt

INSERT INTO retirement.aud_copy 
--VALUES('210DE1','PN ','04-30-2022','04-19-2022','1   ','     22,874','                  ','         382','                  ','      22,492','                  ','           0','                  ','2022-05-04 00:00:00.000')
VALUES('210DE1','PN ','04-30-2022','04-19-2022','1   ','     22,874','                  ','         382','                  ','      22,492','                  ','           0','                  ','2022-05-10 00:00:00.000');

SELECT * FROM retirement.aud_copy_update where created_date = '2022-05-05';

update retirement.aud_copy_update
set created_date = '2022-05-05' where row_num >=175 and row_num <= 178


DROP TABLE retirement.aud_copy_update

CREATE TABLE retirement.aud_copy_update AS
SELECT *,ROW_NUMBER() OVER() AS ROW_NUM
FROM retirement.aud_copy ;

SELECT * FROM retirement.aud_copy_update

UPDATE retirement.aud_copy_update
SET created_date = '05-02-2022' WHERE row_num >=59 and row_num <= 87

UPDATE retirement.aud_copy_update
SET created_date = '05-03-2022' WHERE row_num >=88 and row_num <= 116

UPDATE retirement.aud_copy_update
SET created_date = '05-04-2022' WHERE row_num >=117 and row_num <= 145

UPDATE retirement.aud_copy_update
SET created_date = '05-05-2022' WHERE row_num >=146 and row_num <= 174

UPDATE retirement.aud_copy_update
SET created_date = '05-06-2022' WHERE row_num =175 

use database "DEMO_DATABASE";

CREATE or REPLACE TABLE AJ_customer
(
cust_id INT NOT NULL unique,
cust_name varchar(100) NOT NULL,
cust_address text NOT NULL,
cust_aadhaar_number varchar(50) DEFAULT NULL,
cust_pan_number varchar(50) NOT NULL
) ;

--ALTER <object>
--Modifies the metadata of an account-level or database object, or the parameters for a session
ALTER TABLE AJ_customer
ADD PRIMARY KEY (cust_id);

describe table AJ_customer;

ALTER TABLE AJ_customer
ADD UNIQUE(cust_id);

ALTER TABLE AJ_customer
ADD COLUMN AGE INT;

--UPDATE
--Updates specified rows in the target table with new values.
/*UPDATE <target_table>
       SET <col_name> = <value> [ , <col_name> = <value> , ... ]
        [ FROM <additional_tables> ]
        [ WHERE <condition> ] */

/*

Required Parameters
target_table
Specifies the table to update.

col_name
Specifies the name of a column in target_table. Do not include the table name. For example, UPDATE t1 SET t1.col = 1 is invalid.

value
Specifies the new value to set in col_name.
*/

UPDATE AJ_customer
SET AGE = 31 WHERE cust_id = 123;

UPDATE AJ_customer
SET AGE = 27 WHERE CUST_NAME = 'SHANMUKH';

UPDATE AJ_customer
SET AGE = 22 WHERE CUST_NAME = 'MANISHA';

DESCRIBE TABLE AJ_customer;

INSERT INTO AJ_customer VALUES (123,'anand','Ambika homes ashraya layout mahadevapura banaglore','988042369887','ALZTR645R',31);
INSERT INTO AJ_customer VALUES (143,'MANISHA','pATNA bIHAR','988045672345','ALPJ8769R');    

SELECT * FROM AJ_customer;
drop table AJ_customer;


truncate table AJ_customer;
describe table AJ_customer;

select * from AJ_customer;

undrop table AJ_customer ;


INSERT INTO AJ_customer VALUES (123,'SHANMUKH','Whitefiled Bangalore','988042364567','ALZPJ567R',27);



/*
Referential Integrity Constraints
Referential integrity constraints in Snowflake are informational and, with the exception of NOT NULL, 
not enforced. Constraints other than NOT NULL are created as disabled.

However, constraints provide valuable metadata. 
The primary keys and foreign keys enable members of your project team to orient themselves to the schema design 
and familiarize themselves with how the tables relate with one another.

Additionally, most business intelligence (BI) and visualization tools import the foreign key definitions with the tables and 
build the proper join conditions. 
This approach saves you time and is potentially less prone to error than someone 
later having to guess how to join the tables and then manually configuring the tool. 

Basing joins on the primary and foreign keys also helps ensure integrity to the design, 
since the joins are not left to different developers to interpret. 

Some BI and visualization tools also take advantage of constraint information to rewrite queries 
into more efficient forms, e.g. join elimination.

Specify a constraint when creating or modifying a table using the CREATE | ALTER TABLE … CONSTRAINT commands.

In the following example, the CREATE TABLE statement for the second table (salesorders) 
defines an out-of-line foreign key constraint that references a column in the first table (salespeople):
*/

create or replace table aj_salespeople 
(
  sp_id int not null unique,
  name varchar default null,
  region varchar,
  constraint pk_sp_id primary key (sp_id)
);


create or replace table aj_salesorders 
(
  order_id int not null unique,
  quantity int default null,
  description varchar,
  sp_id int not null unique,
  constraint pk_order_id primary key (order_id),
  constraint fk_sp_id foreign key (sp_id) references aj_salespeople(sp_id)
);

describe table aj_salespeople;
describe table aj_salesorders;

-- Query the 
-- GET_DDL function to retrieve a DDL statement that could be executed to recreate the specified table. 
--- The statement includes the constraints currently set on a table.


select get_ddl('table', '"DEMO_DATABASE"."PUBLIC"."AJ_SALESORDERS"');
select get_ddl('table', '"DEMO_DATABASE"."PUBLIC"."AJ_SALESPEOPLE"');

truncate 
