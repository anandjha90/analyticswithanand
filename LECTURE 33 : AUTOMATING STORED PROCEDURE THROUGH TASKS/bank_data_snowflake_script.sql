CREATE DATABASE BANK;

USE BANK;


CREATE OR REPLACE TABLE DISTRICT(
District_Code INT PRIMARY KEY	,
District_Name VARCHAR(100)	,
Region VARCHAR(100)	,
No_of_inhabitants	INT,
No_of_municipalities_with_inhabitants_less_499 INT,
No_of_municipalities_with_inhabitants_500_btw_1999	INT,
No_of_municipalities_with_inhabitants_2000_btw_9999	INT,
No_of_municipalities_with_inhabitants_less_10000 INT,	
No_of_cities	INT,
Ratio_of_urban_inhabitants	FLOAT,
Average_salary	INT,
No_of_entrepreneurs_per_1000_inhabitants INT,
No_committed_crime_2017	INT,
No_committed_crime_2018 INT
) ;



CREATE OR REPLACE TABLE ACCOUNT(
account_id INT PRIMARY KEY,
district_id	INT,
frequency	VARCHAR(40),
Date DATE ,
FOREIGN KEY (district_id) references DISTRICT(District_Code) 
);

CREATE OR REPLACE TABLE ORDER_LIST (
order_id	INT PRIMARY KEY,
account_id	INT,
bank_to	VARCHAR(45),
account_to	INT,
amount FLOAT,
FOREIGN KEY (account_id) references ACCOUNT(account_id)
);



CREATE OR REPLACE TABLE LOAN(
loan_id	INT ,
account_id	INT,
Date	DATE,
amount	INT,
duration	INT,
payments	INT,
status VARCHAR(35),
FOREIGN KEY (account_id) references ACCOUNT(account_id)
);



CREATE OR REPLACE TABLE TRANSACTIONS(
trans_id INT,	
account_id	INT,
Date	DATE,
Type	VARCHAR(30),
operation	VARCHAR(40),
amount	INT,
balance	FLOAT,
Purpose	VARCHAR(40),
bank	VARCHAR(45),
account_partner_id INT,
FOREIGN KEY (account_id) references ACCOUNT(account_id));


CREATE OR REPLACE TABLE CLIENT(
client_id	INT PRIMARY KEY,
Sex	CHAR(10),
Birth_date	DATE,
district_id INT,
FOREIGN KEY (district_id) references DISTRICT(District_Code) 
);


CREATE OR REPLACE TABLE DISPOSITION(
disp_id	INT PRIMARY KEY,
client_id INT,
account_id	INT,
type CHAR(15),
FOREIGN KEY (account_id) references ACCOUNT(account_id),
FOREIGN KEY (client_id) references CLIENT(client_id)
);


CREATE OR REPLACE TABLE CARD(
card_id	INT PRIMARY KEY,
disp_id	INT,
type CHAR(10)	,
issued DATE,
FOREIGN KEY (disp_id) references DISPOSITION(disp_id)
);

---------------------------------------------------------------------------------------------

CREATE OR REPLACE STORAGE integration s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN ='arn:aws:iam::441615131317:role/bankrole'
STORAGE_ALLOWED_LOCATIONS =('s3://czechbankdata/');
DESC integration s3_int;


CREATE OR REPLACE STAGE BANK
URL ='s3://czechbankdata'
--credentials=(aws_key_id='AKIAXQKR3H3PSG72XFMK'aws_secret_key='eKL6a6FjlQHic4s8Ne712Aelzg2ou4j6tNsVvFq5')
file_format=CSV
storage_integration =s3_int;

LIST @BANK;

SHOW STAGES;

--CREATE SNOWPIPE THAT RECOGNISES CSV THAT ARE INGESTED FROM EXTERNAL STAGE AND COPIES THE DATA INTO PATIENTS TABLE
--The AUTO_INGEST=true parameter specifies to read event notifications sent from an S3 bucket to an SQS queue when new data is ready to load.


CREATE OR REPLACE PIPE BANK_SNOWPIPE AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."DISTRICT"
FROM '@BANK/District/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE2 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."ACCOUNT"
FROM '@BANK/Account/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE3 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."TRANSACTIONS"
FROM '@BANK/Trnx/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE4 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."DISPOSITION"
FROM '@BANK/disp/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE5 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."CARD"
FROM '@BANK/Card/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE6 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."ORDER_LIST"
FROM '@BANK/Order/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE7 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."LOAN"
FROM '@BANK/Loan/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE8 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."CLIENT"
FROM '@BANK/Client/'
FILE_FORMAT = CSV;

SHOW PIPES;

SELECT count(*) FROM DISTRICT;
SELECT count(*) FROM ACCOUNT;
SELECT count(*) FROM TRANSACTIONS;
SELECT count(*) FROM DISPOSITION;
SELECT count(*) FROM CARD;
SELECT count(*) FROM ORDER_LIST;
SELECT count(*) FROM LOAN;
SELECT count(*) FROM CLIENT;

ALTER PIPE BANK_SNOWPIPE refresh;

ALTER PIPE BANK_SNOWPIPE2 refresh;

ALTER PIPE BANK_SNOWPIPE3 refresh;

ALTER PIPE BANK_SNOWPIPE4 refresh;

ALTER PIPE BANK_SNOWPIPE5 refresh;

ALTER PIPE BANK_SNOWPIPE6 refresh;

ALTER PIPE BANK_SNOWPIPE7 refresh;

ALTER PIPE BANK_SNOWPIPE8 refresh;
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM DISTRICT;
SELECT * FROM ACCOUNT;
SELECT * FROM TRANSACTIONS;
SELECT * FROM DISPOSITION;
SELECT * FROM CARD;
SELECT * FROM ORDER_LIST;
SELECT * FROM LOAN;
SELECT * FROM CLIENT;




CREATE DATABASE BANK;

USE BANK;


CREATE OR REPLACE TABLE DISTRICT(
District_Code INT PRIMARY KEY	,
District_Name VARCHAR(100)	,
Region VARCHAR(100)	,
No_of_inhabitants	INT,
No_of_municipalities_with_inhabitants_less_499 INT,
No_of_municipalities_with_inhabitants_500_btw_1999	INT,
No_of_municipalities_with_inhabitants_2000_btw_9999	INT,
No_of_municipalities_with_inhabitants_less_10000 INT,	
No_of_cities	INT,
Ratio_of_urban_inhabitants	FLOAT,
Average_salary	INT,
No_of_entrepreneurs_per_1000_inhabitants INT,
No_committed_crime_2017	INT,
No_committed_crime_2018 INT
) ;



CREATE OR REPLACE TABLE ACCOUNT(
account_id INT PRIMARY KEY,
district_id	INT,
frequency	VARCHAR(40),
Date DATE ,
FOREIGN KEY (district_id) references DISTRICT(District_Code) 
);

CREATE OR REPLACE TABLE ORDER_LIST (
order_id	INT PRIMARY KEY,
account_id	INT,
bank_to	VARCHAR(45),
account_to	INT,
amount FLOAT,
FOREIGN KEY (account_id) references ACCOUNT(account_id)
);



CREATE OR REPLACE TABLE LOAN(
loan_id	INT ,
account_id	INT,
Date	DATE,
amount	INT,
duration	INT,
payments	INT,
status VARCHAR(35),
FOREIGN KEY (account_id) references ACCOUNT(account_id)
);



CREATE OR REPLACE TABLE TRANSACTIONS(
trans_id INT,	
account_id	INT,
Date	DATE,
Type	VARCHAR(30),
operation	VARCHAR(40),
amount	INT,
balance	FLOAT,
Purpose	VARCHAR(40),
bank	VARCHAR(45),
account_partner_id INT,
FOREIGN KEY (account_id) references ACCOUNT(account_id));


CREATE OR REPLACE TABLE CLIENT(
client_id	INT PRIMARY KEY,
Sex	CHAR(10),
Birth_date	DATE,
district_id INT,
FOREIGN KEY (district_id) references DISTRICT(District_Code) 
);


CREATE OR REPLACE TABLE DISPOSITION(
disp_id	INT PRIMARY KEY,
client_id INT,
account_id	INT,
type CHAR(15),
FOREIGN KEY (account_id) references ACCOUNT(account_id),
FOREIGN KEY (client_id) references CLIENT(client_id)
);


CREATE OR REPLACE TABLE CARD(
card_id	INT PRIMARY KEY,
disp_id	INT,
type CHAR(10)	,
issued DATE,
FOREIGN KEY (disp_id) references DISPOSITION(disp_id)
);

---------------------------------------------------------------------------------------------

CREATE OR REPLACE STORAGE integration s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN ='arn:aws:iam::441615131317:role/bankrole'
STORAGE_ALLOWED_LOCATIONS =('s3://czechbankdata/');
DESC integration s3_int;


CREATE OR REPLACE STAGE BANK
URL ='s3://czechbankdata'
--credentials=(aws_key_id='AKIAXQKR3H3PSG72XFMK'aws_secret_key='eKL6a6FjlQHic4s8Ne712Aelzg2ou4j6tNsVvFq5')
file_format=CSV
storage_integration =s3_int;

LIST @BANK;

SHOW STAGES;

--CREATE SNOWPIPE THAT RECOGNISES CSV THAT ARE INGESTED FROM EXTERNAL STAGE AND COPIES THE DATA INTO PATIENTS TABLE
--The AUTO_INGEST=true parameter specifies to read event notifications sent from an S3 bucket to an SQS queue when new data is ready to load.


CREATE OR REPLACE PIPE BANK_SNOWPIPE AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."DISTRICT"
FROM '@BANK/District/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE2 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."ACCOUNT"
FROM '@BANK/Account/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE3 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."TRANSACTIONS"
FROM '@BANK/Trnx/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE4 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."DISPOSITION"
FROM '@BANK/disp/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE5 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."CARD"
FROM '@BANK/Card/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE6 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."ORDER_LIST"
FROM '@BANK/Order/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE7 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."LOAN"
FROM '@BANK/Loan/'
FILE_FORMAT = CSV;

CREATE OR REPLACE PIPE BANK_SNOWPIPE8 AUTO_INGEST = TRUE AS
COPY INTO "BANK"."PUBLIC"."CLIENT"
FROM '@BANK/Client/'
FILE_FORMAT = CSV;

SHOW PIPES;

SELECT count(*) FROM DISTRICT;
SELECT count(*) FROM ACCOUNT;
SELECT count(*) FROM TRANSACTIONS;
SELECT count(*) FROM DISPOSITION;
SELECT count(*) FROM CARD;
SELECT count(*) FROM ORDER_LIST;
SELECT count(*) FROM LOAN;
SELECT count(*) FROM CLIENT;

ALTER PIPE BANK_SNOWPIPE refresh;

ALTER PIPE BANK_SNOWPIPE2 refresh;

ALTER PIPE BANK_SNOWPIPE3 refresh;

ALTER PIPE BANK_SNOWPIPE4 refresh;

ALTER PIPE BANK_SNOWPIPE5 refresh;

ALTER PIPE BANK_SNOWPIPE6 refresh;

ALTER PIPE BANK_SNOWPIPE7 refresh;

ALTER PIPE BANK_SNOWPIPE8 refresh;
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM DISTRICT;
SELECT * FROM ACCOUNT;
SELECT * FROM TRANSACTIONS;
SELECT * FROM DISPOSITION;
SELECT * FROM CARD;
SELECT * FROM ORDER_LIST;
SELECT * FROM LOAN;
SELECT * FROM CLIENT;




