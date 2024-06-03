CREATE OR REPLACE DATABASE PARSING_XML;
CREATE OR REPLACE SCHEMA PARSING_XML_SCHEMA;

USE PARSING_XML;
USE SCHEMA PARSING_XML_SCHEMA;

CREATE OR REPLACE FILE FORMAT MY_XML
TYPE=XML;

CREATE OR REPLACE TABLE sample_xml(src VARIANT);

select * from sample_xml;

select src:"$" from sample_xml;

select src:"@" from sample_xml;

select src:"@issue" from sample_xml;

select src:"$"."@id" from sample_xml;

SELECT XMLGET(src,'book') from sample_xml;

SELECT XMLGET(src,'book'):"$" from sample_xml;

SELECT XMLGET(src,'book'):"@" from sample_xml;

SELECT XMLGET(src,'book'):"@id" :: varchar as book_id from sample_xml;

/*
<catalog issue="spring" date="2015-04-15">
    <book id="bk101">
        <title>Some Great Book</title>
        <genre>Great Books</genre>
        <author>Jon Smith</author>
        <publish_date>2001-12-28</publish_date>
        <price>23.39</price>
        <description>This is a great book!</description>
    </book>
    <cd id="cd101">
        <title>Sad Music</title>
        <genre>Sad</genre>
        <artist>Emo Jones</artist>
        <publish_date>2010-11-23</publish_date>
        <price>15.25</price>
        <description>This music is so sad!</description>
    </cd>
    <map id="map101">
        <title>Good CD</title>
        <location>North America</location>
        <author>Joey Bagadonuts</author>
        <publish_date>2013-02-02</publish_date>
        <price>102.95</price>
        <description>Trail map of North America</description>
    </map>
</catalog>
*/

--Returns the "issue" attribute of the root "catalog" element, cast to a string value.
SELECT src:"@issue"::STRING AS issue
FROM sample_xml;

--	Returns the "date" attribute of the "catalog" element, cast to a string value.
-- TO_DATE() takes the string and converts it to a date in the 'YYYY-MM-DD' format.
SELECT TO_DATE( src:"@date"::STRING, 'YYYY-MM-DD' ) AS date, 
FROM sample_xml;

--Returns the child (of THIS) XML with the name "title", cast to a string value.
--SRC:"$" specifies the value in the root element "catalog".
--Then, LATERAL FLATTEN iterates through all of the repeating elements passed in as the input.
CREATE OR REPLACE VIEW XML_DATA_EXTRACTION_VW AS
SELECT XMLGET( VALUE, 'title' ):"$"::STRING AS title,
XMLGET( VALUE, 'author' ):"$"::STRING AS author,
XMLGET( VALUE, 'artist' ):"$"::STRING AS artist,
FROM sample_xml,
LATERAL FLATTEN( INPUT => SRC:"$" );


--Returns the child element "genre" or "location" if it exists, cast to a string value.
SELECT 
COALESCE( XMLGET( VALUE, 'genre' ):"$"::STRING, 
          XMLGET( VALUE, 'location' ):"$"::STRING ) AS genre_or_location
FROM sample_xml,
LATERAL FLATTEN( INPUT => SRC:"$" );

--Returns the child element "author" or "artist" if it exists, cast to a string value.
SELECT 
COALESCE( XMLGET( VALUE, 'author' ):"$"::STRING, 
          XMLGET( VALUE, 'artist' ):"$"::STRING ) AS author_or_artist, 
FROM sample_xml,
LATERAL FLATTEN( INPUT => SRC:"$" );

--Returns the value of the child element "publish_date", cast to a string value.
--TO_DATE() takes the string and converts it to a date.
SELECT TO_DATE( XMLGET( VALUE, 'publish_date' ):"$"::String ) AS publish_date, 
FROM sample_xml,
LATERAL FLATTEN( INPUT => SRC:"$" );

--Returns the value of child element "price", cast to a floating point numeric value.
SELECT
XMLGET( VALUE, 'price' ):"$"::FLOAT AS price, 
FROM sample_xml,
LATERAL FLATTEN( INPUT => SRC:"$" );

--Returns the value of the "description" child element, cast to a string value.
SELECT
XMLGET( VALUE, 'description' ):"$"::STRING AS desc
FROM sample_xml,
LATERAL FLATTEN( INPUT => SRC:"$" );

--To display all of the data loaded into the VARIANT column from the XML file:
CREATE OR REPLACE VIEW XML_DATA_EXTRACTION_VW AS
SELECT
src:"@issue"::STRING AS issue, 
TO_DATE( src:"@date"::STRING, 'YYYY-MM-DD' ) AS date, 
XMLGET( VALUE, 'title' ):"$"::STRING AS title, 
COALESCE( XMLGET( VALUE, 'genre' ):"$"::STRING, 
          XMLGET( VALUE, 'location' ):"$"::STRING ) AS genre_or_location, 
COALESCE( XMLGET( VALUE, 'author' ):"$"::STRING, 
          XMLGET( VALUE, 'artist' ):"$"::STRING ) AS author_or_artist, 
TO_DATE( XMLGET( VALUE, 'publish_date' ):"$"::String ) AS publish_date, 
XMLGET( VALUE, 'price' ):"$"::FLOAT AS price, 
XMLGET( VALUE, 'description' ):"$"::STRING AS desc
FROM sample_xml,
LATERAL FLATTEN( INPUT => SRC:"$" );

SELECT * FROM XML_DATA_EXTRACTION_VW;

CREATE OR REPLACE TABLE DEPARTMENT (
     XMLDATA VARIANT  NOT NULL
);

// FILE FORMAT 



CREATE OR REPLACE STORAGE integration s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN ='arn:aws:iam::661806635168:role/XML_ROLE' 
STORAGE_ALLOWED_LOCATIONS =('s3://parsing-xml-file/');

DESC integration s3_int;

CREATE OR REPLACE STAGE XML
URL ='s3://parsing-xml-file'
file_format = MY_XML
storage_integration = s3_int;

LIST @XML;

SHOW STAGES;

CREATE OR REPLACE PIPE DEPARTMENT_XML AUTO_INGEST = TRUE AS
COPY INTO PARSING_XML.PARSING_XML_SCHEMA.DEPARTMENT 
FROM '@XML/Department/' 
FILE_FORMAT= MY_XML; 


SHOW PIPES;

ALTER PIPE DEPARTMENT_XML refresh;

SELECT * FROM DEPARTMENT;

//to get root element name

SELECT xmldata:"@" FROM DEPARTMENT;
SELECT xmldata:"$" FROM DEPARTMENT;

// TO GET ROOT ELEMENT VALUE

SELECT xmldata:"$" FROM DEPARTMENT;

// GET THE CONTENT USING XMLGET FUNCTIONS

SELECT 
XMLGET(XMLDATA,'dept_id'):"$"::INTEGER AS dept_id,
XMLGET(XMLDATA,'dept_name'):"$"::VARCHAR AS dept_name
FROM DEPARTMENT;

// ALWAYS KEEP THE OBJECT NAME IN SINGLE ' '

// LATERAL AND  FLATTEN CONCEPTS

/*Flattens (explodes) compound values into multiple rows.

FLATTEN is a table function that takes a VARIANT, OBJECT, or ARRAY column and produces a lateral view (i.e. an inline view that contains correlation referring to other tables that precede it in the FROM clause).

FLATTEN can be used to convert semi-structured data to a relational representation.

In a FROM clause, the LATERAL keyword allows an inline view to reference columns from a table expression that precedes that inline view.

A lateral join behaves more like a correlated subquery than like most JOINs. 
A lateral join behaves as if the server executed a loop similar to the following:

for each row in left_hand_table LHT:
    execute right_hand_subquery RHS using the values from the current row in the LHT */

SELECT 
XMLGET(XMLDATA,'dept_id'):"$"::INTEGER AS dept_id,
XMLGET(XMLDATA,'dept_name'):"$"::VARCHAR AS dept_name,
XMLGET(EMP.VALUE,'emp_id'):"$"::INTEGER AS emp_id,
XMLGET( EMP.VALUE, 'emp_fname' ):"$"::STRING || ' ' ||
XMLGET( EMP.VALUE, 'emp_lname' ):"$"::STRING as emp_name,
XMLGET( ADDR.VALUE, 'city' ):"$"::STRING as city
,XMLGET( ADDR.VALUE, 'state' ):"$"::STRING as state
,XMLGET( ADDR.VALUE, 'zipcode' ):"$"::STRING as zipcode
,XMLGET( ADDR.VALUE, 'start_date' ):"$"::VARCHAR  as start_date
,XMLGET( ADDR.VALUE, 'end_date' ):"$"::VARCHAR  as end_date

FROM DEPARTMENT,
LATERAL FLATTEN (XMLDATA:"$") AS EMP,
LATERAL FLATTEN (EMP.VALUE:"$") AS ADDR
WHERE EMP.VALUE LIKE '<employee>%'AND ADDR.VALUE LIKE '<address>%' ;


--DROP TABLE PurchaseOrders;


CREATE OR REPLACE TABLE PurchaseOrders(
Pur_XML VARIANT NOT NULL
);    


CREATE OR REPLACE PIPE PurchaseOrders_PIPE AUTO_INGEST = TRUE AS
COPY INTO PARSING_XML.PARSING_XML_SCHEMA.PURCHASEORDERS
FROM '@XML/PurchaseOrders/' 
FILE_FORMAT= MY_XML ;


SHOW PIPES;

ALTER PIPE  PurchaseOrders_PIPE refresh;


SELECT * FROM PurchaseOrders;
SELECT Pur_XML :"@" FROM PurchaseOrders;

SELECT Pur_XML :"$" FROM PurchaseOrders;

CREATE OR REPLACE VIEW VW_PUR_ORDERS_XML_PARSE AS
SELECT 
XMLGET(ADDR.VALUE,'Name'):"$":: VARCHAR AS name_SHIPPING,
XMLGET(ADDR_BILLING.VALUE,'Name'):"$":: VARCHAR AS name_BILLING,
XMLGET(ADDR.VALUE,'Street'):"$":: VARCHAR ||','||
XMLGET(ADDR.VALUE,'City'):"$":: VARCHAR AS SHIPPING_ADDRESS,
XMLGET(ADDR.VALUE,'State'):"$":: VARCHAR AS SHIPPING_State,
XMLGET(ADDR.VALUE,'Zip'):"$":: VARCHAR AS SHIPPING_zip,
XMLGET(ADDR.VALUE,'Country'):"$":: VARCHAR AS SHIPPING_Country,
XMLGET(ADDR_BILLING.VALUE,'Street'):"$":: VARCHAR ||','||
XMLGET(ADDR_BILLING.VALUE,'City'):"$":: VARCHAR AS BILLING_ADDRESS,
XMLGET(ADDR_BILLING.VALUE,'State'):"$":: VARCHAR AS BILLING_State,
XMLGET(ADDR_BILLING.VALUE,'Zip'):"$":: VARCHAR AS BILLING_zip,
XMLGET(ADDR_BILLING.VALUE,'Country'):"$":: VARCHAR AS BILLING_Country
FROM PurchaseOrders
,LATERAL FLATTEN(Pur_XML:"$")AS PURCHASE
,LATERAL FLATTEN(PURCHASE.VALUE:"$")AS ADDR
,LATERAL FLATTEN(PURCHASE.VALUE:"$")AS ADDR_BILLING
WHERE ADDR.VALUE LIKE '<Address Type="Shipping">%'
AND  ADDR_BILLING.VALUE LIKE '<Address Type="Billing">%'
;

SELECT * FROM VW_PUR_ORDERS_XML_PARSE;











    














  
  







