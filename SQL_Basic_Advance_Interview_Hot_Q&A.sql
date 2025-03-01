Here are some challenging SQL interview questions:

1. How can you find the second-lowest salary in a table without using MIN?
  
SELECT salary FROM employees 
WHERE salary > (SELECT DISTINCT salary FROM employees ORDER BY salary ASC LIMIT 1) 
ORDER BY salary ASC LIMIT 1;

2. Write a query to find employees who report to the same manager and have the exact same salary.
  
SELECT e1.* FROM employees e1 
JOIN employees e2 ON e1.manager_id = e2.manager_id 
WHERE e1.salary = e2.salary AND e1.employee_id <> e2.employee_id;
  
3. Identify rows where a specific column has missing or null values and replace them with the column’s average.
  
UPDATE table_name 
SET column_name = (SELECT AVG(column_name) FROM table_name WHERE column_name IS NOT NULL) 
WHERE column_name IS NULL;

4. Write a query to find the employees whose salaries rank in the top 5% without using percentile functions.
  
SELECT * FROM employees 
WHERE salary >= (SELECT salary FROM employees ORDER BY salary DESC LIMIT (SELECT COUNT(*) FROM employees) * 5 / 100);
  
5. Calculate a running total of sales in a table.

  SELECT id, sales, SUM(sales) OVER (ORDER BY id) AS running_total 
FROM sales_table;

6. Find employees who have worked in more than one department.

SELECT employee_id FROM employee_department 
GROUP BY employee_id 
HAVING COUNT(DISTINCT department_id) > 1;

  
7. Write a query to compare each employee’s salary with the average salary of their department.

SELECT employee_id, salary, 
AVG(salary) OVER (PARTITION BY department_id) AS avg_dept_salary 
FROM employees;
  
  
8. Identify departments that currently have no employees.
SELECT department_id FROM departments 
WHERE department_id NOT IN (SELECT DISTINCT department_id FROM employees);

9. Write a query to display the total sales for each month in a pivot-like format.
  
SELECT 
 SUM(CASE WHEN month = 'January' THEN sales END) AS January, 
 SUM(CASE WHEN month = 'February' THEN sales END) AS February, 
 SUM(CASE WHEN month = 'March' THEN sales END) AS March 
FROM sales_table;
  
10. Determine employees whose salaries increased by more than 20% compared to their last salary.
  
SELECT e.employee_id FROM employees e 
JOIN salary_history s ON e.employee_id = s.employee_id 
WHERE e.salary > 1.2 * s.previous_salary;
