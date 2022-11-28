USE DATABASE DEMO_DATABASE;

create or replace table aj_time_travel_table 
(
        orderkey number(38,0),
        custkey number(38,0),
        orderstatus varchar(1),
        totalprice number(12,2),
        orderdate date,
        orderpriority varchar(15),
        clerk varchar(15),
        shippriority number(38,0),
        comment varchar(79)
 )
    data_retention_time_in_days = 1;
    
show tables like 'aj_time_travel_table';

describe table aj_time_travel_table;

--command to set data_retention_time_in_days to given value
alter table aj_time_travel_table 
set data_retention_time_in_days=55;


CREATE or replace DATABASE TIMETRAVEL;

use database timetravel;

CREATE or replace table AJ_CONSUMER_COMPLAINTS

(    DATE_RECEIVED STRING,
     PRODUCT_NAME VARCHAR2(50),
     SUB_PRODUCT VARCHAR2(100),
     ISSUE VARCHAR2(100),
     SUB_ISSUE VARCHAR2(100),
     CONSUMER_COMPLAINT_NARRATIVE string,
     Company_Public_Response STRING,
     Company VARCHAR(100),
     State_Name CHAR(4),
     Zip_Code string,
     Tags VARCHAR(40),
     Consumer_Consent_Provided CHAR(25),
     Submitted_via STRING,
     Date_Sent_to_Company STRING,
     Company_Response_to_Consumer VARCHAR(40),
     Timely_Response CHAR(4),
     CONSUMER_DISPUTED CHAR(4),
     COMPLAINT_ID NUMBER(12,0) NOT NULL PRIMARY KEY
);

DESCRIBE TABLE AJ_CONSUMER_COMPLAINTS;

select * from AJ_CONSUMER_COMPLAINTS;

-- get the current timestammp
SELECT CURRENT_TIMESTAMP; -- 2022-11-28 18:05:27.882 +0000

-- set timezone to UTC
ALTER SESSION SET TIMEZONE = 'UTC';

SELECT DISTINCT SUB_ISSUE FROM AJ_CONSUMER_COMPLAINTS;

-- update all age as zero
update AJ_CONSUMER_COMPLAINTS set sub_issue = NULL;

SELECT * FROM AJ_CONSUMER_COMPLAINTS;

-- time travel to a time based on the timestamp
select distinct sub_issue from AJ_CONSUMER_COMPLAINTS before(timestamp => '2022-11-28 18:05:27.882 +0000' ::timestamp);
select * from AJ_CONSUMER_COMPLAINTS before(timestamp => '2022-11-28 18:05:27.882 +0000' ::timestamp);

-- time travel to 5 minutes ago 
select * from AJ_CONSUMER_COMPLAINTS AT(offset => -60*5);

-- note down the query id of this query as we will use it in the time travel query as well
update AJ_CONSUMER_COMPLAINTS set TAGS = NULL;
--01a89dc3-3200-9a0b-0002-0dfe00088222

-- time travel to the time before the query id specified
select * from AJ_CONSUMER_COMPLAINTS before(statement => '01a89dc3-3200-9a0b-0002-0dfe00088222');





