USE DATABASE DEMO_DATABASE;

-- download the sale data from IBM DATASETS 
CREATE OR REPLACE TABLE AJ_SALES 
             (SALES_DATE DATE, 
              SALES_PERSON VARCHAR(15), 
              REGION VARCHAR(15), 
              SALES INTEGER);
              

SHOW COLUMNS IN AJ_SALES;

----LOAD THE DATA 

SELECT * FROM SALES;

SELECT WEEK(SALES_DATE) AS WEEK, 
       DAYOFWEEK(SALES_DATE) AS DAY_WEEK, 
       SALES_PERSON, SALES AS UNITS_SOLD 
FROM SALES 
WHERE WEEK(SALES_DATE) = 13;

--- by week number units sold(sales)
-- Example 1:  Here is a query with a basic GROUP BY clause over 3 columns:
SELECT WEEK(SALES_DATE) AS WEEK,
       DAYOFWEEK(SALES_DATE) AS DAY_WEEK,
       SALES_PERSON, SUM(SALES) AS UNITS_SOLD       
  FROM SALES
  WHERE WEEK(SALES_DATE) = 13
  GROUP BY WEEK(SALES_DATE), DAYOFWEEK(SALES_DATE), SALES_PERSON
  ORDER BY WEEK, DAY_WEEK, SALES_PERSON;
  
-- Produce the result based on two different grouping sets of rows from the SALES table.
-- Example 2:  Produce the result based on two different grouping sets of rows from the SALES table.
SELECT WEEK(SALES_DATE) AS WEEK,
         DAYOFWEEK(SALES_DATE) AS DAY_WEEK,
         SALES_PERSON, SUM(SALES) AS UNITS_SOLD       
FROM SALES 
WHERE WEEK(SALES_DATE) = 13
GROUP BY GROUPING SETS ((WEEK(SALES_DATE), SALES_PERSON),
                         (DAYOFWEEK(SALES_DATE), SALES_PERSON))
ORDER BY WEEK, DAY_WEEK, SALES_PERSON;

-- The rows with WEEK 13 are from the first grouping set and the other rows are from the second grouping set.

-- Example 3:  If you use the 3 distinct columns involved in the grouping sets of Example 2 
-- and perform a ROLLUP, you can see grouping sets for (WEEK,DAY_WEEK,SALES_PERSON), (WEEK, DAY_WEEK), (WEEK) and grand total.

SELECT WEEK(SALES_DATE) AS WEEK,
        DAYOFWEEK(SALES_DATE) AS DAY_WEEK,
        SALES_PERSON, SUM(SALES) AS UNITS_SOLD       
  FROM SALES
  WHERE WEEK(SALES_DATE) = 13
  GROUP BY ROLLUP ( WEEK(SALES_DATE), DAYOFWEEK(SALES_DATE), SALES_PERSON )
  ORDER BY WEEK, DAY_WEEK, SALES_PERSON;
  
--- Example 4:  If you run the same query as Example 3 only replace ROLLUP with CUBE, 
-- you can see additional grouping sets for (WEEK,SALES_PERSON), (DAY_WEEK,SALES_PERSON), (DAY_WEEK), (SALES_PERSON) in the result.  
  SELECT WEEK(SALES_DATE) AS WEEK,
         DAYOFWEEK(SALES_DATE) AS DAY_WEEK,
         SALES_PERSON, SUM(SALES) AS UNITS_SOLD       
  FROM SALES
  WHERE WEEK(SALES_DATE) = 13
  GROUP BY CUBE ( WEEK(SALES_DATE), DAYOFWEEK(SALES_DATE), SALES_PERSON )
  ORDER BY WEEK, DAY_WEEK, SALES_PERSON;


-- Example 5:  Obtain a result set which includes a grand-total of selected rows from the SALES table 
-- together with a group of rows aggregated by SALES_PERSON and MONTH.

  SELECT SALES_PERSON,
         MONTH(SALES_DATE) AS MONTH,
         SUM(SALES) AS UNITS_SOLD
  FROM SALES
  GROUP BY GROUPING SETS ( (SALES_PERSON, MONTH(SALES_DATE)),
                           ()        
                         )
  ORDER BY SALES_PERSON, MONTH;

-- Example 6:  This example shows two simple ROLLUP queries followed by a query which treats the two ROLLUPs 
-- as grouping sets in a single result set and specifies row ordering for each column involved in the grouping sets.
-- Example 6-1:

 SELECT WEEK(SALES_DATE) AS WEEK,
         DAYOFWEEK(SALES_DATE) AS DAY_WEEK,
         SUM(SALES) AS UNITS_SOLD
  FROM SALES
  GROUP BY ROLLUP ( WEEK(SALES_DATE), DAYOFWEEK(SALES_DATE) )
  ORDER BY WEEK, DAY_WEEK;

-- Example 6-2:
 SELECT MONTH(SALES_DATE) AS MONTH,
         REGION,
         SUM(SALES) AS UNITS_SOLD
  FROM SALES
  GROUP BY ROLLUP ( MONTH(SALES_DATE), REGION )
  ORDER BY MONTH, REGION;

-- Example 6-3:

SELECT WEEK(SALES_DATE) AS WEEK,
       DAYOFWEEK(SALES_DATE) AS DAY_WEEK,
       MONTH(SALES_DATE) AS MONTH,
       REGION,
       SUM(SALES) AS UNITS_SOLD
FROM SALES
GROUP BY GROUPING SETS ( ROLLUP(WEEK(SALES_DATE),DAYOFWEEK(SALES_DATE)),
                         ROLLUP( MONTH(SALES_DATE), REGION))
ORDER BY WEEK, DAY_WEEK, MONTH, REGION;}
