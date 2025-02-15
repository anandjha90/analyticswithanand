CREATE OR REPLACE TABLE sales_data (
    transaction_id INT PRIMARY KEY,
    transaction_date DATE,
    product_category VARCHAR(50),
    customer_id INT,
    product_id INT,
    region VARCHAR(50),
    sales_amount DECIMAL(10, 2),
    units_sold INT
);

SELECT * FROM sales_data LIMIT 100;

CREATE OR REPLACE TABLE SALES_DATA_OUTPUT AS
SELECT *,
       YEAR(TRANSACTION_DATE) AS TXN_YR,
       MONTH(TRANSACTION_DATE) AS TXN_MNTH,
       MONTHNAME(TRANSACTION_DATE) AS TXN_MNTH_NAME,
       DAY(TRANSACTION_DATE) AS TXN_DAY,
       DAYNAME(TRANSACTION_DATE) AS TXN_DAY_NAME,      
CASE 
    WHEN DAYNAME(TRANSACTION_DATE) NOT IN ('Sat','Sun') THEN 'Weekdays'
    ELSE 'Weekends'  
END AS WEEKEND_WEEKDAYS    
FROM sales_data;

SELECT * FROM SALES_DATA_OUTPUT;

SELECT PRODUCT_CATEGORY,
       COUNT(CASE WHEN TXN_YR = '2023' THEN 1 END) AS TOT_TXNS_2023, -- 396,421,400,418,415
       SUM(CASE WHEN TXN_YR = '2023' THEN SALES_AMOUNT END) AS TOT_SALES_2023,
       SUM(CASE WHEN TXN_YR = '2023' THEN UNITS_SOLD END) AS TOT_UNITS_SOLD_2023,
       
       COUNT(CASE WHEN TXN_YR = '2022' THEN 1 END) AS TOT_TXNS_2022,
       SUM(CASE WHEN TXN_YR = '2022' THEN SALES_AMOUNT END) AS TOT_SALES_2022,
       SUM(CASE WHEN TXN_YR = '2022' THEN UNITS_SOLD END) AS TOT_UNITS_SOLD_2022,

       COUNT(CASE WHEN TXN_YR = '2021' THEN 1 END) AS TOT_TXNS_2021,
       SUM(CASE WHEN TXN_YR = '2021' THEN SALES_AMOUNT END) AS TOT_SALES_2021,
       SUM(CASE WHEN TXN_YR = '2021' THEN UNITS_SOLD END) AS TOT_UNITS_SOLD_2021,

       COUNT(CASE WHEN TXN_YR = '2020' THEN 1 END) AS TOT_TXNS_2020,
       SUM(CASE WHEN TXN_YR = '2020' THEN SALES_AMOUNT END) AS TOT_SALES_2020,
       SUM(CASE WHEN TXN_YR = '2020' THEN UNITS_SOLD END) AS TOT_UNITS_SOLD_2020,

       COUNT(CASE WHEN TXN_YR = '2019' THEN 1 END) AS TOT_TXNS_2019,
       SUM(CASE WHEN TXN_YR = '2019' THEN SALES_AMOUNT END) AS TOT_SALES_2019,
       SUM(CASE WHEN TXN_YR = '2019' THEN UNITS_SOLD END) AS TOT_UNITS_SOLD_2019
       
FROM SALES_DATA_OUTPUT
GROUP BY 1
ORDER BY 1;


CREATE OR REPLACE TABLE SALES_KPI AS
SELECT PRODUCT_CATEGORY,TXN_YR,TXN_MNTH,TXN_DAY_NAME,COUNT(*) AS TOT_RWS
FROM SALES_DATA_OUTPUT
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

CREATE OR REPLACE TABLE SALES_KPI_BUCKET AS
SELECT *,
CASE
    WHEN TOT_RWS < 5 THEN '1X-5X'
    WHEN TOT_RWS >= 5 AND TOT_RWS < 10 THEN '5X-10X'
    WHEN TOT_RWS >= 10 AND TOT_RWS < 15 THEN '10X-15X'
    ELSE '15X+'
END AS TXN_COUNT_BUCKET    
FROM SALES_KPI;

SELECT TXN_COUNT_BUCKET,COUNT(*) FROM SALES_KPI_BUCKET
GROUP BY 1
ORDER BY 1;

CREATE OR REPLACE TABLE Employee 
( 
EmployeeID INT  PRIMARY KEY, 
EmployeeName VARCHAR(100) NOT NULL, 
Gender VARCHAR(1) NOT NULL, 
StateCode VARCHAR(20) NOT NULL, 
Salary NUMBER(10,2) NOT NULL
) ;
describe table Employee;

--INSERTING RECORDS
INSERT INTO EMPLOYEE VALUES (211, 'Manisha', 'F', 'IN', 80000.0000);
INSERT INTO EMPLOYEE VALUES (212, 'Vikas', 'M', 'IN', 5000.0000);

INSERT INTO EMPLOYEE VALUES (201, 'Jerome', 'M', 'FL', 83000.0000);
INSERT INTO EMPLOYEE VALUES (202, 'Ray', 'M', 'AL', 88000.0000);
INSERT INTO EMPLOYEE VALUES (203, 'Stella', 'F', 'AL', 76000.0000);
INSERT INTO EMPLOYEE VALUES (204, 'Gilbert', 'M', 'Ar', 42000.0000);
INSERT INTO EMPLOYEE VALUES (205, 'Edward', 'M', 'FL', 93000.0000);
INSERT INTO EMPLOYEE VALUES (206, 'Ernest', 'F', 'Al', 64000.0000);
INSERT INTO EMPLOYEE VALUES  (207, 'Jorge', 'F', 'IN', 75000.0000);
INSERT INTO EMPLOYEE VALUES  (208, 'Nicholas', 'F', 'Ge', 71000.0000);
INSERT INTO EMPLOYEE VALUES (209, 'Lawrence', 'M', 'IN', 95000.0000);
INSERT INTO EMPLOYEE VALUES (210, 'Salvador', 'M', 'Co', 75000.0000);

SELECT * FROM EMPLOYEE;

--The SQL CASE statement allows you to perform IF-THEN-ELSE functionality within an SQL statement. 
-- The CASE statement allows you to perform an IF-THEN-ELSE check within an SQL statement.

/* It’s good for displaying a value in the SELECT query based on logic that you have defined. 
   As the data for columns can vary from row to row, using a CASE SQL expression can help make your data more readable and useful to the user or to the application. "*/

-- It’s quite common if you’re writing complicated queries or doing any kind of ETL work.

-- SYNTAX
/* The syntax of the SQL CASE expression is:

CASE [expression]
WHEN condition_1 THEN result_1
WHEN condition_2 THEN result_2 ...
WHEN condition_n THEN result_n
ELSE result
END case_name 
*/

/*
The CASE statement and comparison operator
In this format of a CASE statement in SQL, we can evaluate a condition using comparison operators. Once this condition is satisfied, we get an expression from corresponding THEN in the output.
Suppose we have a salary band for each designation. 
If employee salary is in between a particular range, 
we want to get designation using a Case statement.

In the following query, we are using a comparison operator and evaluate an expression.
*/

SELECT *,
 CASE
      WHEN Salary >=10000 AND Salary < 30000 THEN 'Data Analyst Trainee'
      WHEN Salary >=30000 AND Salary < 50000 THEN 'Data Analyst'
      WHEN Salary >=50000 AND Salary < 80000 THEN 'Consultant'
      WHEN Salary >=80000 AND Salary < 100000 THEN 'Senior Consultant'
      WHEN Salary >= 100000 THEN 'Senior Folks'
ELSE 'Contractor'
END AS Designation
FROM Employee;


/* Case Statement with Order by clause
We can use Case statement with order by clause as well. 
In SQL, we use Order By clause to sort results in ascending or descending order.

Suppose in a further example; we want to sort result in the following method.

For Female employee, employee salaries should come in descending order
For Male employee, we should get employee salaries in ascending order
We can define this condition with a combination of Order by and Case statement. 
In the following query, you can see we specified Order By and Case together. 
We defined sort conditions in case expression. */


SELECT EmployeeName,Gender,Salary
FROM Employee
ORDER BY  
     CASE Gender WHEN 'F' THEN Salary END DESC ,
     CASE WHEN Gender = 'M' THEN Salary END;

/*
Case Statement in SQL with Group by clause
We can use a Case statement with Group By clause as well. 

Suppose we want to group employees based on their salary. 
We further want to calculate the minimum and maximum salary for a particular range of employees.

In the following query, you can see that we have Group By clause and it contains i with the condition to get the required output.
*/

DESCRIBE TABLE EMPLOYEE;

SELECT 
 CASE
      WHEN Salary >=10000 AND Salary < 30000 THEN 'Data Analyst Trainee'
      WHEN Salary >=30000 AND Salary < 50000 THEN 'Data Analyst'
      WHEN Salary >=50000 AND Salary < 80000 THEN 'Consultant'
      WHEN Salary >=80000 AND Salary < 100000 THEN 'Senior Consultant'
      WHEN Salary >= 100000 THEN 'Senior Folks'
ELSE 'Contractor'
END AS Designation,
Min(salary) as Min_Salary,
Max(Salary) as Max_Salary
FROM Employee
Group By Designation;

/* Case Statement limitations
We cannot control the execution flow of stored procedures, functions using a Case statement in SQL
We can have multiple conditions in a Case statement; 
however, it works in a sequential model. If one condition is satisfied, it stops checking further conditions
We cannot use a Case statement for checking NULL values in a table
*/
