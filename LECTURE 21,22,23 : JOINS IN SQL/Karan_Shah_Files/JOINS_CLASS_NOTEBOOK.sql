-- USE ROLE 
USE ROLE ACCOUNTADMIN;

-- USE WAREHOUSE 
USE WAREHOUSE COMPUTE_WH;

-- CREATING A DATABASE 
CREATE DATABASE IF NOT EXISTS JOINS_IN_SQL;

-- USE DATABASE 
USE DATABASE JOINS_IN_SQL;

-- CREATE SCHEMA FOR THE TODAYS CLASS
CREATE SCHEMA IF NOT EXISTS JOINS_SCHEMA;

-- USE SCHEMA 
USE SCHEMA JOINS_SCHEMA;

-- CREATING A TABLE NAMED CUSTOMERS
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(50),
    Country VARCHAR(50)
);

-- CREATING A TABLE NAMED ORDERS
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    OrderDate DATE,
    CustomerID INT,
    Amount DECIMAL(10, 2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- INSERTING VALUES INSIDE TABLE CUSTOMER
INSERT INTO Customers (CustomerID, CustomerName, Country)
VALUES
(1, 'John Doe', 'USA'),
(2, 'Jane Smith', 'UK'),
(3, 'David Brown', 'Canada'),
(4, 'Emily White', 'Australia'),
(5, 'Michael Green', 'USA'),
(6, 'Anna Taylor', 'USA'),
(7, 'Robert King', 'UK'),
(8, 'Laura Wilson', 'Australia'),
(9, 'James Davis', 'Canada'),
(10, 'Sophia Harris', 'USA'),
(11, 'Chris Evans', 'Australia'),
(12, 'Jessica Adams', 'Canada'),
(13, 'Lucas Black', 'USA'),
(14, 'Olivia Walker', 'UK'),
(15, 'Nathan Scott', 'USA'),
(16, 'Emma Stone', 'Australia'),
(17, 'Daniel Lewis', 'UK'),
(18, 'Sophia Clark', 'Canada'),
(19, 'Liam Johnson', 'Australia'),
(20, 'Amelia Brown', 'USA');

-- INSERTING VALUES INTO TABLE ORDERS
INSERT INTO Orders (OrderID, OrderDate, CustomerID, Amount)
VALUES
(101, '2025-01-10', 1, 250.75),
(102, '2025-01-15', 2, 320.00),
(103, '2025-01-20', 3, 450.50),
(104, '2025-02-01', 1, 120.90),
(105, '2025-02-05', 2, 310.50),
(106, '2025-02-10', NULL, 299.99),
(107, '2025-02-15', 4, 400.25),
(108, '2025-02-20', 5, 150.00),
(109, '2025-02-25', 7, 500.75),
(110, '2025-03-01', 6, 225.50),
(111, '2025-03-05', 9, 600.00),
(112, '2025-03-10', NULL, 450.00),
(113, '2025-03-12', 8, 350.00),
(114, '2025-03-15', 11, 520.75),
(115, '2025-03-18', 12, 310.50),
(116, '2025-03-20', 15, 230.99),
(117, '2025-03-22', 13, 150.20),
(118, '2025-03-25', 14, 475.65),
(119, '2025-03-26', 15, 540.90),
(120, '2025-03-28', NULL, 299.00),  -- Another order without a customer
(121, '2025-03-29', 17, 405.50),
(122, '2025-03-29', NULL, 675.00),  -- Another order without a customer
(123, '2025-03-29', 19, 850.00),
(124, '2025-03-29', 20, 399.99);


-- STARTING WITH JOINS

-- INNER JOIN 
-- QUESTION 1
/*
    Find the list of all customers who have placed at least one order.
*/
SELECT
    T1.*,
    T2.*
FROM CUSTOMERS AS T1
JOIN ORDERS AS T2
ON T1.CUSTOMERID = T2.CUSTOMERID;


-- QUESTION 2
/*
    Find the total amount of all orders placed by each customer.
*/
SELECT Customers.CustomerID, Customers.CustomerName, SUM(Orders.Amount) AS TotalAmount
FROM Customers
INNER JOIN Orders
ON Customers.CustomerID = Orders.CustomerID
GROUP BY Customers.CustomerID, Customers.CustomerName;


-- QUESTION 3
/*
    Find the details of orders placed by customers from the USA.
*/
SELECT Customers.CustomerID, Customers.CustomerName, Orders.OrderID, Orders.OrderDate, Orders.Amount
FROM Customers
INNER JOIN Orders
ON Customers.CustomerID = Orders.CustomerID
WHERE Customers.Country = 'USA';



-- Practice Questions 
SELECT *
FROM CUSTOMERS;

SELECT *
FROM ORDERS;

-- Question 1 - Total Spending by Each Customer with More Than One Order
/*
    Get the total amount spent by each customer who has placed more than one order. 
    Show customer name, country, number of orders, and total amount spent. 
    Sort by total amount in descending order.
*/
SELECT
    T1.CUSTOMERID,
    T1.CUSTOMERNAME, 
    T1.COUNTRY,
    COUNT(T2.ORDERID) AS TOTAL_ORDERS,
    SUM(T2.AMOUNT) AS TOTAL_AMOUNT_SPENT
FROM CUSTOMERS AS T1
JOIN ORDERS AS T2
ON T1.CUSTOMERID = T2.CUSTOMERID
GROUP BY T1.CUSTOMERID, T1.CUSTOMERNAME, T1.COUNTRY
HAVING COUNT(T2.ORDERID) > 1
ORDER BY SUM(T2.AMOUNT) DESC;

-- Question 3 - Customers whose name
/*
    Write a query to get the customer name and country where.
    Customers Whose Names Contain 'son'.
    Also the first name in customer name ends with 'ra'.
*/
SELECT CUSTOMERNAME, COUNTRY
FROM CUSTOMERS
WHERE 
    CUSTOMERNAME LIKE '%son%'
    AND 
    SPLIT_PART(CUSTOMERNAME, ' ', 1) LIKE '%ra';

SELECT * FROM CUSTOMERS
WHERE 
    CONTAINS(CUSTOMERNAME, 'son') 
    and 
    endswith(split_part(customername, ' ', 1), 'ra');



-- Question 4 - Customers from UK and USA 
/*
    Display customer name, country, and total amount spent (only if it exceeds 500) 
    for customers from UK and USA.
*/
SELECT
    T1.CUSTOMERNAME AS CUSTOMERNAME,
    T1.COUNTRY AS COUNTRY,
    SUM(T2.AMOUNT) AS TOTAL_AMOUNT_SPENT
FROM CUSTOMERS AS T1
JOIN ORDERS AS T2
ON T1.CUSTOMERID = T2.CUSTOMERID
WHERE T1.COUNTRY IN ('UK', 'USA')
GROUP BY T1.CUSTOMERNAME, T1.COUNTRY
HAVING SUM(T2.AMOUNT) > 500;



-- LEFT JOIN OR LEFT OUTER JOIN 
-- QUESTION 1 
/*
  Write a SQL query to get the customer names you have placed atleast 1 order.   
*/
SELECT 
    DISTINCT
    T1.CUSTOMERNAME AS CUSTOMERNAME
FROM CUSTOMERS AS T1
LEFT JOIN ORDERS AS T2
ON T1.CUSTOMERID = T2.CUSTOMERID
WHERE T2.CUSTOMERID IS NOT NULL;

-- Question 2 
/*
    Write a sql query to print the total number of orders for each customer from usa even if they have not 
    placed any orders. Sort the customers based on the count of their orders
*/
SELECT
    T1.CUSTOMERID AS CUSTOMERID_FROM_CUSTOMERS,
    T1.CUSTOMERNAME AS CUSTOMER_NAME_FROM_CUSTOMERS,
    COUNT(T2.ORDERID) AS ORDER_ID_FROM_ORDERS
FROM CUSTOMERS AS T1
LEFT JOIN ORDERS AS T2
ON T1.CUSTOMERID = T2.CUSTOMERID
WHERE T1.COUNTRY IN ('USA')
GROUP BY T1.CUSTOMERID, T1.CUSTOMERNAME
ORDER BY T1.CUSTOMERID ASC;


/*
    Retrieve a list all customers and the number of their orders, but show only those customers who have 
    placed more than one order or no orders at all. -- 1 order
*/
-- Sol 1
SELECT
    T1.CUSTOMERID,
    COUNT(T2.ORDERID)
FROM customers as T1
LEFT JOIN orders as T2
ON T1.CUSTOMERID = T2.CUSTOMERID
GROUP BY T1.CUSTOMERID
HAVING COUNT(T2.ORDERID) > 1 OR COUNT(T2.ORDERID) = 0;

-- Sol 2
SELECT
    T1.CUSTOMERID,
    COUNT(T2.ORDERID)
FROM customers as T1
LEFT JOIN orders as T2
ON T1.CUSTOMERID = T2.CUSTOMERID
GROUP BY T1.CUSTOMERID
HAVING COUNT(T2.ORDERID) <> 1;

-- sol 3
SELECT 
    C.CUSTOMERID AS ID, 
    C.CUSTOMERNAME AS CUSTOMER_NAME,
    COUNT(O.ORDERID) FROM CUSTOMERS C 
LEFT JOIN ORDERS O ON O.CUSTOMERID = C.CUSTOMERID
GROUP BY C.CUSTOMERID, C.CUSTOMERNAME
HAVING NOT COUNT(O.ORDERID) = 1;



-- Question 4
/*
    Write a sql query to retrive the customer id, customer name, as well as country. 
    Classify the customers as different categorical values such as "Premium customer" if the 
    total number of orders is more than or equal to 4, "Normal Customer" if the total number of order is in range 1-3. 
    Else opportunity if the total number of order is 0
*/ 
SELECT
    T1.CUSTOMERID, 
    T1.CUSTOMERNAME, 
    T1.COUNTRY,
    COUNT(T2.ORDERID) AS TOTAL_ORDERS,
    CASE 
        WHEN COUNT(T2.ORDERID) >= 4 THEN 'Premium Customer'
        WHEN COUNT(T2.ORDERID) BETWEEN 1 AND 3 THEN 'Normal Customer'
        ELSE 'Opportunity'
    END AS Category_of_customers
FROM CUSTOMERS AS T1
LEFT JOIN ORDERS AS T2
ON T1.CUSTOMERID = T2.CUSTOMERID
GROUP BY 
    T1.CUSTOMERID, 
    T1.CUSTOMERNAME, 
    T1.COUNTRY
ORDER BY T1.CUSTOMERID ASC, COUNT(T2.ORDERID) DESC;


SELECT 
    C.CUSTOMERID AS CUSTOMER_ID, 
    C.CUSTOMERNAME AS CUSTOMER_NAME, 
    C.COUNTRY,  
    COUNT(O.ORDERID) AS NO_OF_ORDERS,
CASE 
    WHEN COUNT(O.ORDERID) >= 4 THEN 'Premium Customer'
    WHEN COUNT(O.ORDERID) BETWEEN 1 and 3 THEN 'Normal Customer'
    ELSE 'Opportunity'
END AS CUSTOMER_CATEGORY
FROM CUSTOMERS C
LEFT JOIN ORDERS O 
USING(CUSTOMERID)
GROUP BY C.CUSTOMERID, C.CUSTOMERNAME, C.COUNTRY;

SELECT
    T1.CUSTOMERNAME,
    T1.CUSTOMERID,
    T1.COUNTRY,
    COUNT(T2.ORDERID) AS TOTAL_ORDERS,
    CASE 
        WHEN COUNT(T2.ORDERID) >= 4 THEN 'Premium Customer'
        WHEN COUNT(T2.ORDERID) BETWEEN 1 AND 3 THEN 'Normal Customer'
        ELSE 'Opportunity'
    END AS CUSTOMERTYPE
FROM 
    CUSTOMERS T1
LEFT JOIN 
    ORDERS T2 ON T1.CUSTOMERID = T2.CUSTOMERID
GROUP BY 
    T1.CUSTOMERNAME, T1.CUSTOMERID,T1.COUNTRY
ORDER BY 
    T1.CUSTOMERID ASC;



-- RIGHT JOIN OR RIGHT OUTER JOIN 
-- Question 1 
/*
    Find the list of customers who have placed atleast one order
*/
-- INNER JOIN 
SELECT 
    T1.CUSTOMERNAME, 
    T2.ORDERID
FROM CUSTOMERS AS T1
INNER JOIN ORDERS AS T2
ON T1.CUSTOMERID = T2.CUSTOMERID;

-- HOW CAN WE USE THE OPERATION OF LEFT JOIN USING THE RIGHT JOIN METHOD
-- LEFT JOIN OR LEFT OUTER JOIN 
SELECT
    T1.CUSTOMERNAME, 
    T2.ORDERID
FROM CUSTOMERS AS T1
LEFT JOIN ORDERS AS T2
ON T1.CUSTOMERID = T2.CUSTOMERID
WHERE T2.CUSTOMERID IS NOT NULL;


-- RIGHT JOIN 

-- RIGHT JOIN OR RIGHT OUTER JOIN 
SELECT
    T2.CUSTOMERID AS CUSTOMER_ID_FROM_CUSTOMER, 
    T1.CUSTOMERID AS CUSTOMER_ID_FROM_ORDER
FROM ORDERS AS T1
RIGHT JOIN CUSTOMERS AS T2
ON T1.CUSTOMERID = T2.CUSTOMERID
WHERE T1.CUSTOMERID IS NOT NULL;


-- QUESTION 2 
/*
    Find the total number of orders for each customer from USA, including customers who haven't placed any orders.    
    Sort the customers based on the count of their orders in ASC.
*/
SELECT
    T2.CUSTOMERID, 
    T2.CUSTOMERNAME, 
    T2.COUNTRY,
    COUNT(T1.ORDERID) AS TOTAL_NUMBER_OF_ORDERS
FROM ORDERS AS T1
RIGHT JOIN CUSTOMERS AS T2
ON T1.CUSTOMERID = T2.CUSTOMERID
WHERE T2.COUNTRY IN ('USA')
GROUP BY T2.CUSTOMERID, T2.CUSTOMERNAME, T2.COUNTRY
ORDER BY COUNT(T1.ORDERID);



-- QUESTION 3
/*
    Retrieve a list of all customers and the number of their orders, but show only those who have placed 
    fewer than two orders or no orders at all.
*/
SELECT
    T2.CUSTOMERID, 
    T2.CUSTOMERNAME, 
    T2.COUNTRY,
    COUNT(T1.ORDERID) AS TOTAL_NUMBER_OF_ORDERS
FROM ORDERS AS T1
RIGHT JOIN CUSTOMERS AS T2
ON T1.CUSTOMERID = T2.CUSTOMERID
GROUP BY T2.CUSTOMERID, T2.CUSTOMERNAME, T2.COUNTRY
HAVING COUNT(T1.ORDERID) <= 1;



-- changing the dataset
CREATE TABLE IF NOT EXISTS course
(
    course_id INT PRIMARY KEY,
    course_name VARCHAR(50),
    course_desc VARCHAR(100),
    course_tag VARCHAR(20)
);

-- Inserting values into the course table
INSERT INTO course (course_id, course_name, course_desc, course_tag)
VALUES
(101, 'Mathematics', 'Advanced Mathematics Course', 'Math'),
(102, 'Physics', 'Basics of Physics', 'Physics'),
(103, 'Chemistry', 'Chemistry for Beginners', 'Chemistry'),
(104, 'Biology', 'Introduction to Biology', 'Biology'),
(105, 'Computer Science', 'Learn Programming', 'CS'),
(106, 'English Literature', 'Shakespearean Studies', 'English');


CREATE TABLE IF NOT EXISTS student
(
    student_id INT PRIMARY KEY, 
    student_name VARCHAR(50),
    student_mobile BIGINT, 
    student_course_enroll VARCHAR(50),
    student_course_id INT
);

-- Inserting values into the student table
INSERT INTO student (student_id, student_name, student_mobile, student_course_enroll, student_course_id)
VALUES
(201, 'Alice', 9876543210, 'Mathematics', 101),
(202, 'Bob', 9123456789, 'Physics', 102),
(203, 'Charlie', 9988776655, 'Computer Science', 105),
(204, 'David', 9112233445, 'Mathematics', 101),
(205, 'Eve', 9876654321, 'Biology', 104),
(206, 'Frank', 9543212345, 'Philosophy', NULL), -- Student enrolled in non-existent course
(207, 'Grace', 9898989898, 'Chemistry', 103);


CREATE TABLE IF NOT EXISTS instructor
(
    instructor_id INT PRIMARY KEY,
    instructor_name VARCHAR(50),
    course_id INT -- References course.course_id
);

-- Inserting values into the instructor table
INSERT INTO instructor (instructor_id, instructor_name, course_id)
VALUES
(301, 'Dr. Smith', 101),
(302, 'Dr. Johnson', 102),
(303, 'Dr. Lee', 103),
(304, 'Dr. White', 104),
(305, 'Prof. Davis', 105);


SELECT *
FROM STUDENT;

SELECT *
FROM COURSE;

SELECT *
FROM INSTRUCTOR;


-- FULL OUTER JOIN
-- QUESTION 1
/*
    List all students and the courses they are enrolled in, including students who are not 
    enrolled in any course and courses that have no students.
*/
SELECT 
    T1.student_course_id, 
    T2.course_id
FROM STUDENT AS T1
FULL JOIN COURSE AS T2
ON T1.STUDENT_COURSE_ID = T2.COURSE_ID
order by T1.student_course_id;

SELECT *
FROM COURSE;




-- JOIN SESSION 2 
-- USE ROLE 
USE ROLE ACCOUNTADMIN;

-- USE WAREHOUSE 
USE WAREHOUSE COMPUTE_WH;

-- CREATING A DATABASE 
CREATE DATABASE IF NOT EXISTS JOINS_IN_SQL;

-- USE DATABASE 
USE DATABASE JOINS_IN_SQL;

-- CREATE SCHEMA FOR THE TODAYS CLASS
CREATE SCHEMA IF NOT EXISTS JOINS_SCHEMA;

-- USE SCHEMA 
USE SCHEMA JOINS_SCHEMA;

-- Departments Table
CREATE OR REPLACE TABLE Departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100),
    location VARCHAR(100)
);

INSERT INTO Departments VALUES
(1, 'HR', 'Mumbai'),
(2, 'Engineering', 'Bangalore'),
(3, 'Finance', 'Delhi');

-- Employees Table
CREATE OR REPLACE TABLE Employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT,
    manager_id INT,
    salary INT,
    hire_date DATE,
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id)
);

INSERT INTO Employees VALUES
(101, 'Alice', 1, NULL, 60000, '2018-01-15'),
(102, 'Bob', 2, 101, 80000, '2019-03-20'),
(103, 'Charlie', 2, 102, 70000, '2020-07-10'),
(104, 'David', 3, 101, 75000, '2021-02-18'),
(105, 'Eva', 3, 104, 68000, '2022-05-22');

INSERT INTO Employees VALUES
(109, 'Karan Shah', 3, 104, 68000, '2022-06-21');

-- Projects Table
CREATE OR REPLACE TABLE Projects (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(100),
    emp_id INT,
    budget INT,
    start_date DATE,
    FOREIGN KEY (emp_id) REFERENCES Employees(emp_id)
);

INSERT INTO Projects VALUES
(201, 'Payroll System', 101, 500000, '2023-01-01'),
(202, 'AI Model', 102, 700000, '2023-02-01'),
(203, 'Dashboard', 103, 400000, '2023-03-15'),
(204, 'Audit System', 104, 300000, '2023-04-10'),
(205, 'Investment Portal', 105, 450000, '2023-05-01');


-- joins
-- different types of join 
-- inner or join 
-- left outer join 
-- right outer join 
-- full outer join -- 

SELECT *
FROM DEPARTMENTS;

SELECT *
FROM EMPLOYEES;

SELECT *
FROM PROJECTS;


-- QUESTION 1
/*
        Display the department name and number of employees in each department. 
        Show only those departments where the average salary is above ₹70,000. -- (CONDITION)
        Order the result by employee count descending.
*/
-- EXPLORE THE TABLES 
SELECT *
FROM DEPARTMENTS;

SELECT *
FROM EMPLOYEES;

-- 2ND STEP WOULD BE TO SELECT THE TYPE OF JOIN 
SELECT 
    T1.DEPT_NAME AS DEPT_NAME, 
    COUNT(T2.EMP_ID) AS COUNT_EMP_TAB_ID, 
    ROUND(AVG(T2.SALARY),2) AS AVG_EMP_TAB_SALARY
FROM DEPARTMENTS AS T1
INNER JOIN EMPLOYEES AS T2
ON T1.DEPT_ID = T2.DEPT_ID
GROUP BY T1.DEPT_NAME
HAVING AVG(T2.SALARY) > 70000;



-- QUESTION 2
/*
    Show the names of employees who joined after 1st Jan 2020 and work in departments located in Bangalore. 
    Also, display their salary and hire date.
*/
-- EMPLOYEES TABLE DEPARTMENT TABLE 
-- INNER JOIN 
-- CONDITION (DATE WHERE CONDITION) & (WHERE CONDITION)
-- WHAT NEEDS TO BE DISPLAYED (SALARY, HIREDATE)
SELECT 
    t2.emp_name as employee_name,
    t2.salary as salary, 
    t2.hire_date as hire_date
FROM DEPARTMENTS AS T1
INNER JOIN EMPLOYEES AS T2
ON T1.DEPT_ID = T2.DEPT_ID
WHERE 
    T2.HIRE_DATE > '2020-01-01'
    AND 
    T1.LOCATION IN ('Bangalore');





-- JOINING MORE THAN TWO TABLES 
-- QUESTION 1 
/*
    Show project name, employee name, their department name, and budget.
*/
-- EMPLOYEES -- JOINED -- PROJECTS
-- DEPARTMENTS 
SELECT *
FROM EMPLOYEES;

SELECT *
FROM DEPARTMENTS;

SELECT 
    P_TAB.PROJ_NAME AS PROJECT_NAME,
    E_TAB.EMP_NAME AS EMPLOYEE_NAME, 
    D_TAB.DEPT_NAME AS DEPARTMENT_NAME,
    P_TAB.BUDGET AS PROJECT_BUDGET
FROM PROJECTS AS P_TAB
INNER JOIN EMPLOYEES AS E_TAB 
ON P_TAB.EMP_ID = E_TAB.EMP_ID
INNER JOIN DEPARTMENTS AS D_TAB 
ON E_TAB.DEPT_ID = D_TAB.DEPT_ID;



-- QUESTION 2 
/*
    List all projects started after March 1, 2023, along with project name, employee name, department, 
    and budget (only for Bangalore-based departments).
*/
SELECT 
    T1.PROJ_NAME AS PROJECT_NAME,
    T2.EMP_NAME AS EMPLOYEE_NAME,
    T3.DEPT_NAME AS DEPARTMENT_NAME,
    T1.START_DATE AS START_DATE, 
    T1.BUDGET AS PROJECT_BUDGET
FROM PROJECTS AS T1
INNER JOIN EMPLOYEES AS T2
ON T1.EMP_ID = T2.EMP_ID
INNER JOIN DEPARTMENTS AS T3
ON T2.DEPT_ID = T3.DEPT_ID
WHERE 
    T1.START_DATE > '2023-03-01'
    AND 
    T3.LOCATION IN ('Bangalore');


-- QUESTION 3 
/*
   Write a SQL query to get the employee name, project they are assigned onto
   department the employee is from. 
   And the total project budget given for their all the projects. 
   Even display the employees that are not allocated in any projects yet

   I can have 10 employees in my org, but not necessary all the employees are allocated to a project 
*/
-- type of join 
SELECT
    T1.EMP_NAME AS EMPLOYEE_NAME, 
    T3.DEPT_NAME AS DEPARTMENT_NAME,
    T2.PROJ_NAME AS PROJECT_NAME, 
    T2.BUDGET AS PROJECT_BUDGET
FROM EMPLOYEES AS T1 -- LEFT TABLE 
LEFT JOIN PROJECTS AS T2 -- RIGHT TABLE 
ON T1.EMP_ID = T2.EMP_ID
INNER JOIN DEPARTMENTS AS T3
ON T1.DEPT_ID = T3.DEPT_ID;






-- INTERVIEW 
-- CREATE 
CREATE OR REPLACE TABLE Weather (
    id INT PRIMARY KEY,
    record_date DATE,
    temperature INT
);

INSERT INTO Weather (id, record_date, temperature) VALUES
(1, '2023-03-01', 20),
(2, '2023-03-02', 25),
(3, '2023-03-03', 22),
(4, '2023-03-04', 26),
(5, '2023-03-05', 24);


-- CROSS JOIN -- ALL THE RECORDS FROM BOTH THE TABLES WILL BE JOINED WITH EACH OTHER 
-- X x Y = result
select *
from weather;


-- QUESTION 1 
/*
    Write a SQL query to find the dates on which the temperature was higher than the previous day.
    Return the result as a table with the column name record_date.
*/
-- SELF JOIN - cross join 
SELECT 
    TODAY.RECORD_DATE AS T_RECORD_DATE, 
    TODAY.TEMPERATURE AS T_TEMP,
    YESTERDAY.TEMPERATURE AS Y_TEMP
FROM WEATHER AS YESTERDAY
CROSS JOIN WEATHER AS TODAY
WHERE 
    DATEDIFF(DAY, YESTERDAY.RECORD_DATE, TODAY.RECORD_DATE) = 1
    AND 
    TODAY.TEMPERATURE > YESTERDAY.TEMPERATURE
ORDER BY YESTERDAY.ID ASC, TODAY.ID ASC; 



