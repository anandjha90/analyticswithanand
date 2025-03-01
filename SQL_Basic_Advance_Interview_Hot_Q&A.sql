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

11. Find employees who have worked in the most departments.

SELECT employee_id, COUNT(DISTINCT department_id) AS dept_count 
FROM employee_department_history 
GROUP BY employee_id 
ORDER BY dept_count DESC LIMIT 1;
  
12. Identify customers who made purchases in consecutive months.

SELECT customer_id 
FROM orders 
GROUP BY customer_id 
HAVING COUNT(DISTINCT DATE_FORMAT(order_date, '%Y-%m')) = 
(SELECT COUNT(DISTINCT DATE_FORMAT(order_date, '%Y-%m')) FROM orders);
  
13. Calculate the average session duration from login/logout timestamps.

SELECT user_id, AVG(TIMESTAMPDIFF(MINUTE, login_time, logout_time)) AS avg_session_duration 
FROM session_logs 
GROUP BY user_id;
  
14. Retrieve the least sold product in each category.

SELECT category_id, product_id, SUM(sales) AS total_sales 
FROM products p 
JOIN sales s ON p.product_id = s.product_id 
GROUP BY category_id, product_id 
HAVING total_sales = (SELECT MIN(SUM(sales)) FROM sales s2 WHERE p2.category_id = p.category_id);
  
15. Show the cumulative sales for each product by month.

SELECT product_id, month, 
SUM(sales) OVER (PARTITION BY product_id ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales 
FROM sales;
  
16. Find missing order IDs in a sequential orders table.

SELECT order_id + 1 AS missing_order_id 
FROM orders o1 
WHERE NOT EXISTS (SELECT order_id FROM orders o2 WHERE o2.order_id = o1.order_id + 1);  
  
17. Identify employees who received the same bonus for three years.

SELECT employee_id 
FROM bonus_history 
GROUP BY employee_id, bonus_amount 
HAVING COUNT(*) = 3 AND MAX(year) - MIN(year) = 2;
  
18. Find the product with the lowest sales-to-stock ratio.

SELECT product_id, (SUM(sales) / stock) AS sales_to_stock_ratio 
FROM products p 
JOIN sales s ON p.product_id = s.product_id 
GROUP BY product_id 
ORDER BY sales_to_stock_ratio ASC LIMIT 1;
  
19. Show the top and bottom-performing sales regions.

SELECT region, SUM(sales) AS total_sales 
FROM sales 
GROUP BY region 
ORDER BY total_sales DESC LIMIT 1 

UNION ALL 

SELECT region, SUM(sales) AS total_sales 
FROM sales 
GROUP BY region 
ORDER BY total_sales ASC LIMIT 1;
  
20. Rank employees by revenue contribution within each team.

SELECT team_id, employee_id, 
RANK() OVER (PARTITION BY team_id ORDER BY SUM(sales) DESC) AS rank 
FROM employees e 
JOIN sales s ON e.employee_id = s.employee_id 
GROUP BY team_id, employee_id;
  
