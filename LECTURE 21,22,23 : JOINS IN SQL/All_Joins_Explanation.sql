-- WAREHOUSE,DATABASE & SCHEMA CREATION

CREATE OR REPLACE WAREHOUSE DEMO_WAREHOUSE;
CREATE OR REPLACE DATABASE DEMO_DATABASE;
CREATE OR REPLACE SCHEMA  DEMO_SCHEMA;


-- TABLE CREATION
CREATE OR REPLACE TABLE TESTING_A
(
     ID_A VARCHAR(10)
);

CREATE OR REPLACE TABLE TESTING_B
(
    ID_B VARCHAR(10)
);

-- DATA INSERTIONS
INSERT INTO TESTING_A 
VALUES('1'),('1'),('2'),('3'),('4'),('4'),('5'),(''),(NULL);

INSERT INTO TESTING_B
VALUES('1'),('2'),('4'),('6'),('7'),('8'),('8'),('9'),(NULL),(''),('');


-- DATA VALIDATIONS
SELECT * FROM TESTING_A; -- 9 rows in total
SELECT COUNT(*) FROM TESTING_A; -- 9 (as it count total rows)
SELECT DISTINCT ID_A FROM TESTING_A; -- 7 distinct values
SELECT COUNT(DISTINCT ID_A) FROM TESTING_A; -- 6 (null or blank was excluded ?)

SELECT * FROM TESTING_B; -- 11 rows in total
SELECT COUNT(*) FROM TESTING_B; -- 11 (as it count total rows)
SELECT DISTINCT ID_B FROM TESTING_B; -- 9 distinct values
SELECT COUNT(DISTINCT ID_B) FROM TESTING_B; -- 8 (null or blank was excluded ?)

--------------------------------------------------------------------------------- BUSINESS TABLES ----------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    salary DECIMAL(10, 2)
);

CREATE OR REPLACE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50)
);

--------------------------------------------------------------------------------- FILE FORMAT ----------------------------------------------------------------------------------------------
CREATE OR REPLACE file format DEMO_CSV_FILE_FORMAT
    type = 'csv' 
    compression = 'none' 
    field_delimiter = ','
    field_optionally_enclosed_by = 'none'
    skip_header = 1 ;  
    
----------------------------------------------------------------------INNER JOIN --------------------------------------------------------------------------------
/*
1. Inner Join
•	Definition: Returns records with matching values in both tables.
•	Use Case: Often used when you only need data that has relationships in both tables.
•	Cloud Considerations: Inner joins are generally efficient on cloud platforms, especially when tables are partitioned and indexed well. 
    However, large datasets may require optimizations, such as clustering in Snowflake, to improve performance.
*/

SELECT A.*,B.*
FROM TESTING_A AS A
INNER JOIN TESTING_B AS B ON A.ID_A = B.ID_B; -- NULLS are excluded from INNER JOIN while blanks are matched if any

SELECT e.emp_id, e.emp_name, e.salary, d.dept_name
FROM employees AS e 
INNER JOIN departments AS d ON e.dept_id = d.dept_id;

-- Explanation: Only rows with matching dept_id in both employees and departments tables are returned. Diana and Eve are excluded as they don't have matching department entries.

----------------------------------------------------------------------LEFT/LEFT OUTER JOIN --------------------------------------------------------------------------------
/*
2. Left Join (Left Outer Join)
•	Definition: Returns all records from the left table and the matched records from the right table. 
                Unmatched records from the left table are filled with NULL for columns from the right table.
•	Use Case: Useful when you want all records from one table, regardless of whether there’s a matching entry in the other.
•	Cloud Considerations: Left joins can involve large data shuffles in distributed cloud environments. 
    Some platforms optimize these by using distribution keys (like in Redshift) to reduce network transfer, but performance can still be affected if tables are unbalanced.
*/

SELECT A.*,B.*
FROM TESTING_A AS A
LEFT OUTER JOIN TESTING_B AS B ON A.ID_A = B.ID_B
ORDER BY A.ID_A
NULLS LAST;

SELECT e.emp_id, e.emp_name, e.salary, d.dept_name
FROM employees AS e 
LEFT JOIN departments AS d ON e.dept_id = d.dept_id
ORDER BY e.emp_id
NULLS LAST;

-- Explanation: All rows from the employees table are returned. For Diana and Eve, who don't have matching dept_id in departments, dept_name is NULL.

----------------------------------------------------------------------RIGHT/RIGHT OUTER JOIN ------------------------------------------------------------------------------
/*
3. Left Join (Right Outer Join)
•	Definition: Opposite of left join; it returns all records from the right table and matches from the left table, with unmatched left records represented as NULL.
•	Use Case: Useful when you need all records from the right table, irrespective of matching entries in the left table.
•	Cloud Considerations:  In cloud databases, right joins may require specific indexing or partitioning to reduce data transfer costs, especially if one table is 
                           significantly larger than the other.
*/

SELECT A.*,B.*
FROM TESTING_A AS A
RIGHT JOIN TESTING_B AS B ON A.ID_A = B.ID_B
ORDER BY B.ID_B
NULLS FIRST;

SELECT e.emp_id, e.emp_name, e.salary,d.dept_id ,d.dept_name
FROM employees AS e 
RIGHT JOIN departments AS d ON e.dept_id = d.dept_id
ORDER BY d.dept_id
NULLS LAST;

-- Explanation: All rows from departments are included. For Marketing, which has no matching employee, the emp_id, emp_name, and salary columns are NULL.

----------------------------------------------------------------------FULL OUTER JOIN ------------------------------------------------------------------------------
/*
4. Full Outer Join
•	Definition: Returns all records from both tables, filling NULL in places where no match exists on either side.
•	Use Case: Often used when you need a complete view of data from both tables, including unmatched records.
•	Cloud Considerations: Full outer joins can be resource-intensive on distributed platforms, as they require both tables to be fully scanned. In systems like Snowflake 
                          or BigQuery, clustered tables or partitions can help mitigate performance issues.
*/

SELECT A.*,B.*
FROM TESTING_A AS A
FULL OUTER JOIN TESTING_B AS B ON A.ID_A = B.ID_B
ORDER BY A.ID_A,B.ID_B
NULLS LAST;

-- Explanation: Returns all records from both tables, filling in NULL where there’s no match. Both unmatched employees and departments are included.

----------------------------------------------------------------------CROSS/CARTESIAN JOIN ------------------------------------------------------------------------------
/*
5. Cross Join (Cartesian Join)
•	Definition:Returns a Cartesian product of both tables, resulting in every combination of records.
•	Use Case: Rarely used due to the large volume of data it can produce, but can be useful for generating test data or combining all pairs of records.
•	Cloud Considerations: Cross joins can be extremely taxing on cloud resources, especially with large tables. 
                          Cloud-based systems usually discourage cross joins unless necessary.
*/

SELECT A.*,B.*
FROM TESTING_A AS A
CROSS JOIN TESTING_B AS B
ORDER BY A.ID_A,B.ID_B
NULLS LAST;

-- Explanation: Every row from employees is combined with every row from departments, resulting in a large number of combinations. This join type is seldom used in production.

----------------------------------------------------------------------SELF JOIN ------------------------------------------------------------------------------
/*
6.Self Join
•	Definition:A join of a table with itself. This is useful for comparing rows within the same table.
•	Use Case: Often used in hierarchical or recursive data structures, like organizational charts.
•	Cloud Considerations: Performance can be impacted in cloud systems if the table is large. Partitioning and indexing may help but could still lead to significant processing time.
*/

SELECT A1.ID_A AS ORIG_ID_A,A2.ID_A AS DUPL_ID_A
FROM TESTING_A AS A1
INNER JOIN TESTING_A A2 ON A1.ID_A = A2.ID_A
ORDER BY A1.ID_A
NULLS LAST;

SELECT B1.ID_B AS ORIG_ID_B,B2.ID_B AS DUPL_ID_B
FROM TESTING_B AS B1
INNER JOIN TESTING_B B2 ON B1.ID_B = B2.ID_B
ORDER BY B1.ID_B;

SELECT e1.emp_name AS Employee, e2.emp_name AS Colleague
FROM employees e1
INNER JOIN employees e2 ON e1.emp_id <> e2.emp_id
ORDER BY e1.emp_name;

-- Explanation: Self join here shows each employee paired with every other employee (excluding self-pairs). It’s often used in hierarchical data.

----------------------------------------------------------------------SEMI JOIN------------------------------------------------------------------------------
/*
7.Semi Join
•	Definition: Returns rows from the left table where there’s a match in the right table but does not return columns from the right table.
•	Use Case:   Useful when checking for existence rather than retrieving data from both tables.
•	Cloud Considerations: Many cloud platforms optimize semi joins through query rewriting, reducing unnecessary data scans and improving performance.
*/

SELECT A.*
FROM TESTING_A AS A
WHERE EXISTS (
    SELECT 1
    FROM TESTING_B AS B
    WHERE A.ID_A = B.ID_B
)
order by A.ID_A;

SELECT B.*
FROM TESTING_B AS B
WHERE EXISTS (
    SELECT 1
    FROM TESTING_A AS A
    WHERE B.ID_B = A.ID_A
)
order by B.ID_B;

SELECT emp_id, emp_name
FROM employees
WHERE EXISTS (
    SELECT 1
    FROM departments
    WHERE employees.dept_id = departments.dept_id
) 
order by emp_id;

-- Explanation: Returns employees with a matching department, but without including department details. This is achieved by checking the existence of a match in departments.

----------------------------------------------------------------------ANTI JOIN------------------------------------------------------------------------------
/*
8.Anti Join
•	Definition: Returns rows from the left table where no match is found in the right table.
•	Use Case: Useful for finding data present in one table but missing in another.
•	Cloud Considerations: Anti joins can often be optimized by cloud platforms using filter-based optimizations, improving performance on large datasets.
*/

SELECT A.*
FROM TESTING_A AS A
WHERE NOT EXISTS (
    SELECT 1
    FROM TESTING_B AS B
    WHERE A.ID_A = B.ID_B
)
order by A.ID_A;

SELECT B.*
FROM TESTING_B AS B
WHERE NOT EXISTS (
    SELECT 1
    FROM TESTING_A AS A
    WHERE B.ID_B = A.ID_A
)
order by B.ID_B;

SELECT emp_id, emp_name
FROM employees
WHERE NOT EXISTS (
    SELECT 1
    FROM departments
    WHERE employees.dept_id = departments.dept_id
)
order by emp_id;
