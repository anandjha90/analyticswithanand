-- sql date functions

use database "DEMO_DATABASE";

alter session set timestamp_type_mapping = timestamp_ntz;

create or replace table ts_test(ts timestamp);

desc table ts_test;

create or replace table ts_test(ts timestamp_ltz);

alter session set timezone = 'America/Los_Angeles';

insert into ts_test values('2014-01-01 16:00:00');
insert into ts_test values('2014-01-02 16:00:00 +00:00');

-- Note that the time for January 2nd is 08:00 in Los Angeles (which is 16:00 in UTC)

select * from ts_test;

select ts, hour(ts) from ts_test;

select convert_timezone('Europe/Warsaw', 'UTC', '2019-01-01 00:00:00'::timestamp_ntz) as conv;

SELECT
    months_between('2019-03-15'::date,
                   '2019-02-15'::date) as monthsbetween1,
    months_between('2019-03-31'::date,
                   '2020-02-28'::date) as monthsbetween2;

-- GET CURRENT DATE
SELECT CURRENT_DATE;

-- GET CURRENT TIME
SELECT CURRENT_TIMESTAMP;

-- GET CURRENT DATE
SELECT CURRENT_TIME;


-- CONVERT TIMEZONE
SELECT CONVERT_TIMEZONE('UTC',CURRENT_TIMESTAMP) AS UTC_TIMEZONE;


-- CONVERT DATE TO SUBSEQUENT 4 MONTHS AHEAD
SELECT ADD_MONTHS(CURRENT_DATE,4) as DATE_AFTER_4_MONTHS;

-- 3 MONTHS BACK DATE
SELECT TO_CHAR(ADD_MONTHS(CURRENT_DATE,-3),'DD-MM-YYYY') as DATE_BEFORE_3_MONTHS;
SELECT TO_VARCHAR(ADD_MONTHS(CURRENT_DATE,-3),'MM-DD-YYYY') as DATE_BEFORE_3_MONTHS;

-- GET YR FROM DATE
SELECT DATE_TRUNC('YEAR',CURRENT_DATE) AS YR_FROM_DATE;

-- GET MTH FROM DATE
SELECT DATE_TRUNC('MONTH',CURRENT_DATE) AS MTH_FROM_DATE;

-- GET DAY FROM DATE
SELECT DATE_TRUNC('DAY',CURRENT_DATE) AS DAY_FROM_DATE;

SELECT DATE_TRUNC('WEEK',CURRENT_DATE) AS WEEK_FROM_DATE;

select day(current_timestamp() ) ,
  hour( current_timestamp() ) ,
  second(current_timestamp()) ,
  minute(current_timestamp()) ,
  month(current_timestamp());

SELECT WEEK(CURRENT_DATE) AS WEEK_FROM_START_OF_THE_YEAR;
SELECT MONTH(CURRENT_DATE) AS MNTH_FROM_START_OF_THE_YEAR;
SELECT DAY(CURRENT_DATE) AS MNTH_OF_CURRENT_MONTH;

-- GET LAST DAY OF current MONTH
select last_day(current_date) as last_day_curr_month;

-- GET LAST DAY OF PREVIOUS MONTH
SELECT LAST_DAY(CURRENT_DATE - INTERVAL '1 MONTH') AS LAST_DAY_PREV_MNTH;

SELECT LAST_DAY(CURRENT_DATE - INTERVAL '2 MONTH') + INTERVAL '1 DAY' AS FIRST_DAY;

SELECT QUARTER(CURRENT_DATE) AS QTR;

SELECT EXTRACT(YEAR FROM CURRENT_DATE) AS YR;
SELECT EXTRACT(MONTH FROM CURRENT_DATE) AS MTH;
SELECT EXTRACT(DAY FROM CURRENT_DATE) AS DAY;

select QUARTER(to_date('2022-08-24'));

SELECT to_date('08-23-2022','mm-dd-yyyy');

SELECT TO_DATE('1993-08-17') AS DATE;

SELECT TO_CHAR(TO_DATE('1993-08-17'),'DD-MM-YYYY') AS DATE_DD_MM_YYYY; --THIS WILL BE HIGHLY USED

SELECT TO_CHAR(TO_DATE('1993-08-17'),'MM-YYYY') AS MM_YYYY;

SELECT TO_CHAR(TO_DATE('1993-08-17'),'MON-YYYY') AS MON_YYYY;

SELECT TO_CHAR(TO_DATE('1993-08-17'),'MON-YY') AS DATE_MON_YY;

SELECT TO_CHAR(TO_DATE('1993-08-17'),'DY') AS DATE_DAY;

SELECT TO_CHAR(TO_DATE('1993-08-17'),'DY-DD-MM-YYYY') AS DATE_DAY;

SELECT DAYNAME ('1993-08-23');
SELECT DAYNAME (CURRENT_DATE);

SELECT TO_CHAR(TO_DATE('1993-08-17'),'YYYY-DD') AS DATE;

SELECT TO_CHAR(TO_DATE('1993-08-17'),'DD-MM') AS DATE;

select MONTH(CURRENT_DATE);
SELECT EXTRACT(MONTH FROM CURRENT_DATE) AS MTH;

SELECT ADD_MONTHS(CURRENT_DATE,-3) AS DATE_3_MNTHS_BACK;
SELECT ADD_MONTHS(CURRENT_DATE,5) AS DATE_5_MNTHS_AHEAD;

select datediff('day', '2022-06-01',CURRENT_DATE);
select datediff('day', '2022-07-23','2023-07-19');

select datediff('MONTH', '2021-06-01',CURRENT_DATE);
select datediff('YEAR', '2014-06-01',CURRENT_DATE);

select dateadd('day',-23,'2022-06-01');
select dateadd('month',-2,'2022-06-01');
select dateadd('year',-5,'2022-06-01');

select WEEK(CURRENT_DATE); -- FROM 1ST JAN 2022 HOW MNAY EEKS HAVE SURPASSED
select MONTH(CURRENT_DATE); -- -- FROM 1ST JAN 2022 HOW MNAY MONTHS HAVE SURPASSED

--1. Extracting Components of Date and Time
--Use Case: Extract specific parts (e.g., year, month, day) from a date or timestamp.

-- Extract Year, Month, Day from a Date
SELECT 
    YEAR(CURRENT_DATE) AS year, 
    MONTH(CURRENT_DATE) AS month, 
    DAY(CURRENT_DATE) AS day;
    
--2. Date Arithmetic
---Use Case: Add or subtract intervals from a date or timestamp.
-- Add 10 days to the current date
SELECT CURRENT_DATE + INTERVAL '10 DAY' AS future_date; 
SELECT CURRENT_DATE - INTERVAL '1 MONTH' AS PAST_MONTH;

-- Subtract 2 months from the current date
SELECT DATEADD(MONTH, -2, CURRENT_DATE) AS past_date;

--3. Date Difference
--Use Case: Calculate the difference between two dates or timestamps.

-- Difference in days between two dates
SELECT DATEDIFF(DAY, '2024-01-01', CURRENT_DATE) AS days_diff;

-- Difference in months between two dates
SELECT DATEDIFF(MONTH, '2023-01-01', CURRENT_DATE) AS months_diff;

--4. Formatting Dates
--Use Case: Convert a date into a specific format string.

-- Format date as 'DD/MM/YYYY'
SELECT TO_CHAR(CURRENT_DATE, '') AS formatted_date;
SELECT TO_CHAR(CURRENT_DATE, 'DD-MM-YYYY') AS formatted_date;
SELECT TO_CHAR(CURRENT_DATE, 'DD/MM/YYYY') AS formatted_date;
SELECT TO_CHAR(CURRENT_DATE, 'MM/DD/YYYY') AS formatted_date;
SELECT TO_CHAR(CURRENT_DATE, 'MM-DD-YYYY') AS formatted_date;
SELECT TO_CHAR(CURRENT_DATE, 'YYYY-MM') AS formatted_date;
SELECT TO_CHAR(CURRENT_DATE, 'MM-DD-YY') AS formatted_date;

-- Format timestamp with hour, minute, and second
SELECT TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS') AS formatted_timestamp;

--Truncating Date/Time
--Use Case: Truncate date/time to a specified precision (e.g., hour, day, month).

-- Truncate to start of the month
SELECT DATE_TRUNC('MONTH', CURRENT_DATE) AS month_start;

-- Truncate to start of the hour
SELECT DATE_TRUNC('HOUR', CURRENT_TIMESTAMP) AS hour_start;

--6. Handling Time Zones
--Use Case: Convert timestamps between time zones.
-- Convert current timestamp to 'America/New_York' timezone
SELECT CONVERT_TIMEZONE('UTC', 'America/New_York', CURRENT_TIMESTAMP) AS est_time;

-- Convert from one timezone to another
SELECT CONVERT_TIMEZONE('America/Los_Angeles', 'Europe/London', CURRENT_TIMESTAMP) AS london_time;

--7. Extracting Week Information
--Use Case: Get the week number or weekday from a date.
-- Get the week number of the year
SELECT WEEK(CURRENT_DATE) AS week_number;

-- Get the day of the week (0 = Sunday, 6 = Saturday)
SELECT DAYOFWEEK(CURRENT_DATE) AS day_of_week;

--8. Creating Date/Time Values
--Use Case: Create date or time values from components.
-- Create a date from year, month, and day
SELECT DATE_FROM_PARTS(2024, 9, 8) AS custom_date;

-- Create a timestamp from components
SELECT TIMESTAMP_FROM_PARTS(2024, 9, 8, 12, 30, 45) AS custom_timestamp;

--9. Working with Epoch Time
--Use Case: Convert between epoch time and a human-readable date.
-- Convert epoch time (seconds since 1970-01-01) to timestamp
SELECT TO_TIMESTAMP(1627764000) AS readable_timestamp;

-- Convert a timestamp to epoch seconds
SELECT EXTRACT(EPOCH_SECOND FROM CURRENT_TIMESTAMP) AS epoch_time;

--10. Adjusting Dates for Business Days
--Use Case: Add business days (excluding weekends) to a date.
-- Add 10 business days to the current date

SELECT DATEADD('day', 10, CURRENT_DATE) AS future_business_day;

--11. Comparing Timestamps
--Use Case: Compare two timestamps and find the difference in hours, minutes, etc.

-- Difference in hours between two timestamps




select datediff('MONTH', '2022-06-01',CURRENT_DATE);
select datediff('YEAR', '2014-06-01',CURRENT_DATE);


