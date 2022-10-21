CREATE or replace table RJ_CONSUMER_COMPLAINTS

(

DATE_RECEIVED STRING,

PRODUCT_NAME VARCHAR2(50),

SUB_PRODUCT VARCHAR2(100),

ISSUE VARCHAR2(100),

SUB_ISSUE VARCHAR2(100),

CONSUMER_COMPLAINT_NARRATIVE string,

Company_Public_Response STRING,

Company VARCHAR(100),

State_Name CHAR(4),

Zip_Code string,

Tags VARCHAR(30),

Consumer_Consent_Provided CHAR(25),

Submitted_via STRING,

Date_Sent_to_Company STRING,

Company_Response_to_Consumer VARCHAR(40),

Timely_Response CHAR(4),

CONSUMER_DISPUTED CHAR(4),

COMPLAINT_ID NUMBER(12,0) NOT NULL PRIMARY KEY

);