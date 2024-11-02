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

SELECT e.emp_id, e.emp_name, e.salary, d.dept_name
FROM employees AS e
FULL OUTER JOIN departments AS d ON e.dept_id = d.dept_id;


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

SELECT e.emp_id, e.emp_name, d.dept_name
FROM employees AS e
CROSS JOIN departments AS d;

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

/*

Certainly! A self-join is a technique where a table is joined with itself. This is especially useful for hierarchical relationships, like an employee-manager relationship, where each employee has a manager who is also an employee within the same table.

Business Use Case
In an organization, each employee reports to a manager, who is also an employee. By using a self-join, we can create a report that shows each employee along with their manager’s details.

Table Structure
Let’s create an employees table where each employee has:

A unique employee_id
A employee_name
A position
A salary
A manager_id that references another employee_id in the same table (indicating who their manager is)
*/

CREATE OR REPLACE TABLE employees_self_join (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    position VARCHAR(50),
    salary DECIMAL(10, 2),
    manager_id INT,
    FOREIGN KEY (manager_id) REFERENCES employees_self_join(employee_id)
);

-- Insert records into the employees table
INSERT INTO employees_self_join (employee_id, employee_name, position, salary, manager_id) VALUES 
(1, 'Alice', 'CEO', 150000.00, NULL),         -- Alice is the CEO with no manager
(2, 'Bob', 'CTO', 130000.00, 1),              -- Bob reports to Alice
(3, 'Charlie', 'CFO', 130000.00, 1),          -- Charlie reports to Alice
(4, 'David', 'Engineer', 90000.00, 2),        -- David reports to Bob
(5, 'Eve', 'Engineer', 90000.00, 2),          -- Eve reports to Bob
(6, 'Frank', 'Accountant', 80000.00, 3),      -- Frank reports to Charlie
(7, 'Grace', 'HR Manager', 95000.00, 1),      -- Grace reports to Alice
(8, 'Helen', 'HR Specialist', 70000.00, 7);   -- Helen reports to Grace


-- Self-Join Query to Retrieve Employee and Manager Information
-- To get a list of each employee along with their manager’s name and position, we can join the employees table with itself using a self-join.

SELECT 
    e.employee_id AS employee_id,
    e.employee_name AS employee_name,
    e.position AS employee_position,
    e.salary AS employee_salary,
    e.manager_id AS manager_id,
    m.employee_name AS manager_name,
    m.position AS manager_position
FROM employees_self_join e
-- links each employee to their manager’s details by matching manager_id in the employee record with the employee_id in the manager record.
-- We use a LEFT JOIN so that employees without managers (like Alice) are still included in the result with NULL values for the manager fields.
LEFT JOIN employees_self_join m ON e.manager_id = m.employee_id 
ORDER BY e.employee_id ;


-- To see each employee's direct and indirect managers, we can use a recursive CTE (Common Table Expression) along with a self-join. 
-- This approach lets us trace the reporting hierarchy up to the top-level manager.

-- Recursive CTE Setup:
-- The CTE EmployeeHierarchy starts with each employee and their immediate (Level 1) manager.
-- It then recursively joins back to the employees table to find the next level up.

WITH RECURSIVE EmployeeHierarchy AS 
(
    -- Start with each employee and their immediate manager
    SELECT 
        employee_id,
        employee_name,
        manager_id,
        1 AS level -- Level 1: Direct manager
    FROM employees_self_join
    WHERE manager_id IS NOT NULL

    UNION ALL

    -- Recursively join to find higher levels of management
    SELECT 
        e.employee_id,
        e.employee_name,
        eh.manager_id,
        eh.level + 1 AS level
    FROM employees_self_join e
    JOIN EmployeeHierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM EmployeeHierarchy
ORDER BY employee_id, level;

-- In this result:

-- David reports directly to Bob (Level 1) and indirectly to Alice (Level 2).
-- Eve’s chain of command is the same as David’s.
-- Frank reports to Charlie (Level 1) and indirectly to Alice (Level 2).
-- Helen reports directly to Grace (Level 1) and indirectly to Alice (Level 2).

-- To find the number of direct reports for each manager, we can use a simple self-join:

SELECT 
    m.employee_id AS manager_id,                -- m represents each manager , e represents the employees reporting to each manager.
    m.employee_name AS manager_name,             
    COUNT(e.employee_id) AS direct_reports_count -- counts the number of employees reporting directly to each manager.
FROM employees_self_join m
LEFT JOIN employees_self_join e ON m.employee_id = e.manager_id  -- The join condition links each manager to their direct reports.
GROUP BY m.employee_id, m.employee_name
ORDER BY direct_reports_count DESC;

-- In this result:

-- Alice has 3 direct reports: Bob, Charlie, and Grace.
-- Bob has 2 direct reports: David and Eve.
-- Charlie has 1 direct report: Frank.
-- Grace has 1 direct report: Helen.
-- The other employees (David, Eve, Frank, and Helen) don’t have any direct reports.

-- Use Case : Step 1: Calculate Salary Budget for Direct Reports
-- To calculate the total salary each manager is responsible for within their immediate reporting layer, we use a self-join:

SELECT 
    m.employee_id AS manager_id,
    m.employee_name AS manager_name,
    SUM(e.salary) AS direct_reports_salary_budget -- calculates the total salary of all employees directly reporting to each manager.
FROM employees_self_join m
LEFT JOIN employees_self_join e ON m.employee_id = e.manager_id
GROUP BY m.employee_id, m.employee_name
ORDER BY direct_reports_salary_budget DESC
NULLS LAST;

-- In this result:

-- Alice has a direct salary budget of 355,000 for her direct reports (Bob, Charlie, and Grace).
-- Bob is responsible for 180,000, the combined salaries of David and Eve.
-- Charlie oversees Frank with a salary budget of 80,000.
-- Grace oversees Helen with a budget of 70,000.
-- Individual contributors without direct reports have NULL in their budget.

-- Step 2: Calculate Total Hierarchical Salary Budget (Direct + Indirect Reports)
-- To capture the full hierarchy’s salary budget each manager is responsible for, including all levels under them, we use a recursive CTE:

-- The CTE SalaryHierarchy begins with each employee and their salary.
-- It recursively joins to add the salaries of employees’ subordinates through successive levels.

WITH RECURSIVE SalaryHierarchy AS (
    -- Start with each employee and their salary
    SELECT 
        employee_id,
        employee_name,
        manager_id,
        salary AS total_salary
    FROM employees_self_join

    UNION ALL

    -- Recursively add salaries of each employee's subordinates
    SELECT 
        e.employee_id,
        e.employee_name,
        h.manager_id,
        e.salary + h.total_salary AS total_salary
    FROM employees_self_join e
    JOIN SalaryHierarchy h ON e.manager_id = h.employee_id
)
-- Summarize total salary at each manager level
SELECT 
    manager_id,
    SUM(total_salary) AS hierarchical_salary_budget
FROM SalaryHierarchy
GROUP BY manager_id
ORDER BY hierarchical_salary_budget DESC;

*/
-- In this result:

-- Alice(CEO) has a total salary budget of 2,370,000 across her entire reporting structure, including indirect layers.
-- Bob, who reports directly to Alice, oversees a budget of 180,000 for his team (David & Eve)
-- Charlie has a budget of 80,000 under her, as she only directly manages Frank.
-- Grace has a budget of 70,000 under her, as she only directly manages Helen.


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
