-- USE ROLE 
USE ROLE ACCOUNTADMIN;

-- USE WAREHOUSE 
USE WAREHOUSE COMPUTE_WH;

-- CREATING A DATABASE FOR TODAY LET US NAME DATABASE AS 'SUPERSTORE_2016'
CREATE DATABASE IF NOT EXISTS people_and_returns;

-- USE DATABASE 
USE DATABASE people_and_returns

-- CREATE SCHEMA FOR THE TODAYS CLASS
CREATE SCHEMA IF NOT EXISTS people_and_returns_schema;

-- USE SCHEMA 
USE SCHEMA people_and_returns_schema;

-- CREATING THE TABLE FOR PEOPLE
CREATE TABLE IF NOT EXISTS PEOPLE (
    PERSON VARCHAR(50), 
    REGION VARCHAR(50)
);

-- CREATING THE TABLE FOR RETURNS
CREATE TABLE IF NOT EXISTS RETURNS (
    RETURNED VARCHAR(10),
    ORDER_ID VARCHAR(50),
    REGION VARCHAR(40)
);

-- INSERTING VALUES INTO TABLE PEOPLE
INSERT INTO PEOPLE (PERSON, REGION) VALUES 
('Marilène Rousseau', 'Caribbean'),
('Andile Ihejirika', 'Central Africa'),
('Nicodemo Bautista', 'Central America'),
('Cansu Peynirci', 'Central Asia'),
('Lon Bonher', 'Central US'),
('Wasswa Ahmed', 'Eastern Africa'),
('Hadia Bousaid', 'Eastern Asia'),
('Lynne Marchand', 'Eastern Canada'),
('Oxana Lagunov', 'Eastern Europe'),
('Dolores Davis', 'Eastern US'),
('Lindiwe Afolayan', 'North Africa'),
('Miina Nylund', 'Northern Europe'),
('Kauri Anaru', 'Oceania'),
('Vasco Magalhães', 'South America'),
('Preecha Metharom', 'Southeastern Asia'),
('Nora Cuijper', 'Southern Africa'),
('Chandrakant Chaudhri', 'Southern Asia'),
('Gavino Bove', 'Southern Europe'),
('Flannery Newton', 'Southern US'),
('Katlego Akosua', 'Western Africa'),
('Kaoru Xun', 'Western Asia'),
('Angela Jephson', 'Western Canada'),
('Gilbert Wolff', 'Western Europe'),
('Derrick Snyders', 'Western US');


-- INSERTING THE VALUES INTO THE RETURNS TABLE 
INSERT INTO RETURNS (RETURNED, ORDER_ID, REGION) VALUES 
('Yes', 'CA-2012-SA20830140-41210', 'Central US'),
('Yes', 'IN-2012-PB19210127-41259', 'Eastern Asia'),
('Yes', 'CA-2012-SC20095140-41174', 'Central US'),
('Yes', 'IN-2015-JH158207-42140', 'Oceania'),
('Yes', 'IN-2014-LC168857-41747', 'Oceania'),
('Yes', 'ID-2013-AB1001527-41439', 'Eastern Asia'),
('Yes', 'ES-2015-RA1994545-42218', 'Western Europe'),
('Yes', 'CA-2014-TB21280140-41724', 'Central US'),
('Yes', 'ES-2014-JF15295120-41924', 'Southern Europe'),
('Yes', 'IN-2014-NM1844527-41800', 'Eastern Asia'),
('Yes', 'IN-2015-GB145307-42260', 'Oceania'),
('Yes', 'ES-2012-SC208458-41070', 'Western Europe'),
('Yes', 'TU-2013-SF10200134-41417', 'Western Asia'),
('Yes', 'ID-2015-RD1993092-42140', 'Oceania'),
('Yes', 'CA-2014-TC21295140-41800', 'Southern US'),
('Yes', 'SF-2015-MV8190117-42362', 'Southern Africa'),
('Yes', 'IN-2014-EM1382566-41850', 'Eastern Asia'),
('Yes', 'ES-2015-CC1210045-42182', 'Western Europe'),
('Yes', 'ES-2015-MM1792045-42199', 'Western Europe'),
('Yes', 'IN-2015-DB1306027-42353', 'Eastern Asia'),
('Yes', 'IN-2013-JC157757-41310', 'Oceania'),
('Yes', 'CA-2015-RB19705140-42262', 'Eastern US'),
('Yes', 'ES-2015-BB1154548-42336', 'Western Europe'),
('Yes', 'AL-2012-SC102302-40970', 'Southern Europe'),
('Yes', 'UP-2014-MC7275137-41997', 'Eastern Europe'),
('Yes', 'IN-2013-EJ13720113-41608', 'Southeastern Asia'),
('Yes', 'CA-2012-AJ10780140-41212', 'Eastern US'),
('Yes', 'CA-2014-EM14140140-41822', 'Western US'),
('Yes', 'ES-2015-RD19585120-42007', 'Southern Europe'),
('Yes', 'US-2014-SC20230140-41873', 'Western US'),
('Yes', 'IN-2013-JR1570058-41441', 'Southern Asia'),
('Yes', 'IN-2013-DL129257-41418', 'Oceania'),
('Yes', 'ES-2014-EG1390045-41644', 'Western Europe'),
('Yes', 'ES-2013-DB1297045-41458', 'Western Europe'),
('Yes', 'CA-2014-CL12565140-41768', 'Eastern US'),
('Yes', 'ES-2014-EB13930139-41962', 'Northern Europe'),
('Yes', 'IN-2015-ML1739559-42369', 'Southeastern Asia'),
('Yes', 'SA-2015-MC7575110-42326', 'Western Asia'),
('Yes', 'CA-2014-SS1041023-41995', 'Eastern Canada'),
('Yes', 'ID-2015-ST205307-42336', 'Oceania'),
('Yes', 'MX-2012-AH1003082-41251', 'Central America'),
('Yes', 'ID-2015-MM1726078-42181', 'Southeastern Asia'),
('Yes', 'IT-2015-DM1301564-42167', 'Southern Europe'),
('Yes', 'IN-2015-JW1595527-42190', 'Eastern Asia'),
('Yes', 'CA-2013-SG20080140-41578', 'Western US'),
('Yes', 'IN-2014-PF1912027-41916', 'Eastern Asia'),
('Yes', 'US-2015-AG1052582-42355', 'Central America'),
('Yes', 'IN-2015-PB191057-42281', 'Oceania'),
('Yes', 'MX-2015-BS1136518-42199', 'South America');

-- VIEWING THE PEOPLE TABLE
SELECT * FROM PEOPLE;

-- VIEWING THE RETURNS TABLE 
SELECT * FROM RETURNS;

