=-- USE ROLE 
USE ROLE ACCOUNTADMIN;

-- USE WAREHOUSE 
USE WAREHOUSE COMPUTE_WH;

-- CREATING A DATABASE 
CREATE DATABASE IF NOT EXISTS WINDOW_FUNCTIONS_P2;

-- USE DATABASE 
USE DATABASE WINDOW_FUNCTIONS_P2;

-- CREATE SCHEMA FOR THE TODAYS CLASS
CREATE SCHEMA IF NOT EXISTS WINDOW_FUNCTIONS_P2S;

-- USE SCHEMA 
USE SCHEMA WINDOW_FUNCTIONS_P2S;

-- CREATING TABLE
CREATE TABLE employees (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    department VARCHAR(50),
    age INT,
    salary DECIMAL(10, 2)
);


-- INSERTING VALUES 
INSERT INTO employees (id, name, department, age, salary) VALUES
(1, 'John Doe', 'HR', 30, 50000.00),
(2, 'Jane Smith', 'IT', 25, 70000.00),
(3, 'Michael Brown', 'Finance', 40, 85000.00),
(4, 'Emily Davis', 'IT', 35, 75000.00),
(5, 'Chris Johnson', 'HR', 28, 55000.00),
(6, 'Anna Wilson', 'Finance', 50, 90000.00),
(7, 'David Lee', 'IT', 45, 80000.00),
(8, 'Sophia King', 'HR', 26, 53000.00),
(9, 'James White', 'Finance', 38, 88000.00),
(10, 'Olivia Green', 'IT', 32, 72000.00);




-- LEAD()
/*
 We want to compare each employee’s salary with the salary of the next employee in the same department. 
 Can you show the employee's current salary along with the salary of the next employee within the same department?
*/
SELECT 
    id,
    name,
    department,
    salary,
    LEAD(salary, 1) OVER (ORDER BY salary DESC) AS next_employee_salary
FROM employees;


/*
    We want to track the salary progression of employees in the IT department. 
    For each employee, can you show their salary along with the salary of the next two employees in the IT department?
*/
SELECT 
    id,
    name,
    department,
    salary,
    LEAD(salary, 1) OVER (PARTITION BY department ORDER BY salary) AS next_employee_salary,
    LEAD(salary, 2) OVER (PARTITION BY department ORDER BY salary) AS second_next_employee_salary
FROM employees
WHERE department = 'IT';

