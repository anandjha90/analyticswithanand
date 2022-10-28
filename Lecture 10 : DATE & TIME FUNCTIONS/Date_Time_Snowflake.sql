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




select datediff('MONTH', '2022-06-01',CURRENT_DATE);
select datediff('YEAR', '2014-06-01',CURRENT_DATE);


