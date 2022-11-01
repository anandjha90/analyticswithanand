--How to Remove Spaces in the String in snowflake?

/* Nowadays, data is required everywhere. 
Many organizations automatically capture the data using tools or machines. 
Machines may introduce the unwanted data such as white space when it captures the actual data. 
These junk data is of no use in reporting, thus you need to remove them before loading into the target table.

In a data warehouse, you will receive data from multiple sources. 
You may have to pre-process the data before loading it to target table. 
The pre-process step such as removing white spaces from data is commonly used. 
In this LECTURE we will check how to remove spaces in a string using Snowflake built-in functions. 

Snowflake provides many built-in functions to remove white space or any unwanted data from a string.

You can use any of the following string functions as per your requirements.

Replace String Function
TRIM Function
Translate Function
REGEXP_REPLACE Function */

SELECT REPLACE('AB  C D ', ' ', '') as space_removed_output;

SELECT TRANSLATE('AB  C D ', ' ', '') as output;

/* Remove White Spaces using REGEXP_REPLACE Function

The Regexp_replace remove all occurrences of white space in a string.
For example, consider following regexp_replace example to replace all spaces 
in the string with nothing. */
select REGEXP_COUNT('AB  C D hello how are you hi an a n d ',' ') AS SPACE_COUNT FROM dual;

select REGEXP_REPLACE('AB  C D hello how are you hi an a n d ','( ){10,}','') as output;

select REGEXP_REPLACE('AB  C D hello how are you hi an a n d ','(){3}','') as output;

select REGEXP_REPLACE('AB  C D hello how are you hi an a n d ',' ','') as output;






/* Snowflake Extract Numbers from the string examples
The regular expression functions come handy when you want to 
extract numerical values from the string data. 

Though you can use built-in functions to check if a string is numeric. 
But, getting particular numeric values is done easily using regular expressions.

For example, extract the number from the string 
using Snowflake regexp_replace regular expression Function. */

SELECT  TRIM(REGEXP_REPLACE(string, '[^[:digit:]]', ' ')) AS Numeric_value
FROM (SELECT ' Area code for employee ID 112244 is 12345.' AS string) a;

--For example, consider below query that uses different regex patterns.

SELECT  TRIM(REGEXP_REPLACE(string, '[a-z/-/A-z/./#/*]', '')) AS Numeric_value
FROM (SELECT ' Area code for employee ID 112244 is 12345.' AS string) a;


/* The most common requirement in the data warehouse environment is to extract 
certain digits from the string.
For example, extract the 6 digit number from string data. 

There are many methods that you can use, however, the easiest method is to use the 
Snowflake REGEXP_SUBSTR regular expressions for this requirement. 

You can modify the regular expression pattern to extract any number of 
digits based on your requirements. */

--Snowflake Extract 6 digit’s numbers from string value examples
SELECT REGEXP_SUBSTR(string, '(^|[^[:word:]]|[[:space:]])\\d{10}([^[:word:]]|[[:space:]]|$)') AS ID
FROM (SELECT ' Phone Number for employee ID 112244 is 9008276611.' AS string) a;

-- Another common requirement is to extract alphanumeric values from a string data.
-- Snowflake Extract Alphanumeric from the string examples
-- For example, consider below example to extract ID which is a combination of ‘ID’ 
--and numeric value.

SELECT REGEXP_SUBSTR('abc jjs Updates ID 123 ID_112233','ID_[0-9][0-9][0-9][0-9][0-9][0-9]') as ID;

--01PI10EC014 1pi10eC014

/* Snowflake Regular Expression Functions
The regular expression functions are string functions that match a given regular expression. These functions are commonly called as a ‘regex’ functions.

Below are some of the regular expression function that Snowflake cloud data warehouse supports:

REGEXP_COUNT
REGEXP_INSTR
REGEXP_LIKE
REGEXP_SUBSTR
REGEXP_REPLACE
REGEXP
RLIKE */

/* Snowflake REGEXP_COUNT Function
The REGEXP_COUNT function searches a string and returns an integer that indicates the number of 
times the pattern occurs in the string. If no match is found, then the function returns 0.

syntax : REGEXP_COUNT( <string> , <pattern> [ , <position> , <parameters> ] ) */ 
select regexp_count('qqqabcrtrababcbcd', 'abc');
select regexp_count('qqqabcrtrababcbcd', '[abc]') as abc_character_count;
select REGEXP_COUNT('QQQABCRTRABABCBCD', '[ABC]{3}');


/*
The Snowflake REGEXP_REPLACE function returns the string by replacing specified pattern. 
If no matches found, original string will be returned.

Following is the syntax of the Regexp_replace function.

REGEXP_REPLACE( <string> , <pattern> [ , <replacement> , <position> , <occurrence> , <parameters> ] )

1. Extract date from a text string using Snowflake REGEXP_REPLACE Function
The REGEXP_REPLACE function is one of the easiest functions to get the required value when manipulating strings data.
Consider the below example to replace all characters except the date value. */

--For example, consider following query to return only user name.
select regexp_replace( 'anandjha2309@gmail.com', '@.*\\.(com)');

select regexp_replace('Customers - (NY)','\\(|\\)','') as customers;

SELECT TRIM(REGEXP_REPLACE(string, '[a-z/-/A-Z/.]', ''))
AS date_value 
FROM (SELECT 'My DOB is 04-12-1976.' AS string) a;

/* 2. Extract date using REGEXP_SUBSTR 
Alternatively, REGEXP_SUBSTR function can be used to get date field from the string data. 

For example, consider the below example to get date value from a string containing text and the date. */
SELECT REGEXP_SUBSTR('I am celebrating my birthday on 05/12/2020 this year','[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]') as dob;

-- 3. Validate if date is in a valid format using REGEXP_LIKE function
SELECT * FROM (SELECT '04-12-1976' AS string) a where REGEXP_LIKE(string,'\\d{1,2}\\-\\d{1,2}-\\d{4,4}');

--4. String pattern matching using REGEXP_LIKE
WITH tbl
  AS (select t.column1 mycol 
      from values('A1 something'),('B1 something'),('Should not be matched'),('C1 should be matched') t )

SELECT * FROM tbl WHERE regexp_like (mycol,'[a-zA-z]\\d{1,}[\\s0-9a-zA-Z]*');


/*
-- Snowflake REGEXP Function
The Snowflake REGEXP function is an alias for RLIKE.

Following is the syntax of the REGEXP function.

-- 1st syntax
REGEXP( <string> , <pattern> [ , <parameters> ] )

-- 2nd syntax
<string> REGEXP <pattern> */

--For example, consider following query to matches string with query.
SELECT city REGEXP 'M.*' 
FROM   ( 
              SELECT 'Bangalore' AS city 
              UNION ALL 
              SELECT 'Mangalore' AS city ) AS tmp;

/*
Snowflake RLIKE Function
The Snowflake RLIKE function is an alias for REGEXP and regexp_like.

Following is the syntax of the RLIKE function.

-- 1st syntax
RLIKE( <string> , <pattern> [ , <parameters> ] )

-- 2nd syntax
<string> RLIKE <pattern>
*/

--For example, consider following query to matches string with query.
SELECT city RLIKE 'M.*'
FROM   ( 
              SELECT 'Bangalore' AS city 
              UNION ALL 
              SELECT 'Mangalore' AS city ) AS tmp;














