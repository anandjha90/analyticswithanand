/*
Self Joins are used to join a table to itself, allowing you to compare records within the same table. 
This can be particularly helpful for finding relationships or comparisons within similar data entries. 

Here are complex business questions and solutions using Self Joins with the restaurant dataset.
These examples use Self Joins to analyze trends and patterns within the same dataset, providing insights that can support strategic decisions across various areas like customer loyalty, pricing, employee management, 
and menu optimization. Let me know if you have specific areas you'd like to explore further!
*/

/*
1. Identify Returning Customers Based on Past and Recent Orders
Business Question: Which customers placed an order in the last month and also had orders in previous months, indicating a pattern of return visits?

Solution: By performing a Self Join on the orders table, we can find customers with orders in different months.
*/

SELECT 
    o1.customer_id,
    o1.order_id AS recent_order,
    o1.order_date AS recent_order_date,
    o2.order_id AS past_order,
    o2.order_date AS past_order_date
FROM rest_orders o1
JOIN rest_orders o2 ON o1.customer_id = o2.customer_id
WHERE o1.order_date >= DATEADD(month, -1, CURRENT_DATE) AND o2.order_date < DATEADD(month, -1, CURRENT_DATE)
ORDER BY 1,2,3,4,5;

--This query identifies customers with recent and past orders, helping the restaurant understand which customers are returning. This can be used to encourage loyalty with special offers or targeted promotions.

/*
2. Determine Customer Order Frequency and Potential for High-Loyalty Segmentation
Business Question: Which customers have placed orders within the same week on multiple occasions, suggesting a high frequency of visits?

Solution: Using a Self Join on the orders table, we can check if a customer has multiple orders in the same week.
*/

SELECT 
    o1.customer_id,
    o1.order_id AS order_1,
    o1.order_date AS order_date_1,
    o2.order_id AS order_2,
    o2.order_date AS order_date_2
FROM rest_orders o1
JOIN rest_orders o2 ON o1.customer_id = o2.customer_id
WHERE DATEDIFF(day, o1.order_date, o2.order_date) BETWEEN 1 AND 7 AND o1.order_id != o2.order_id
ORDER BY 1,2,3,4,5;

-- This query reveals customers who frequently visit within the same week, allowing the restaurant to identify highly loyal customers who may benefit from loyalty programs or frequent-visitor incentives.

/*
3. Compare Menu Prices Across Different Periods
Business Question: Has the price of any menu item changed in the past year, and if so, by how much?

Solution: Using a Self Join on the menus table, we compare menu items to detect changes in pricing over time.
*/

SELECT 
    m1.item_name,
    m1.price AS current_price,
    m2.price AS past_price,
    (m1.price - m2.price) AS price_difference
FROM rest_menus m1
JOIN rest_menus m2 ON m1.menu_id = m2.menu_id
--WHERE m1.last_updated > DATEADD(year, -1, m2.last_updated)
ORDER BY 1,2,3,4;

-- This query identifies changes in menu item prices, helping the restaurant track inflation or pricing adjustments and evaluate their impact on sales.

/*
4. Identify Employees with Similar Job Titles and Pay Ranges
Business Question: Which employees have similar roles and fall within the same salary range?

Solution: Using a Self Join on the employees table, we can find employees with similar roles and comparable pay.
*/

SELECT 
    e1.employee_name AS employee_1,
    e2.employee_name AS employee_2,
    e1.position,
    --e1.salary AS salary_1,
    --e2.salary AS salary_2
FROM rest_employees e1
JOIN rest_employees e2 ON e1.position = e2.position
WHERE e1.employee_id != e2.employee_id;
-- AND ABS(e1.salary - e2.salary) <= 5000

-- This query helps management see which employees are in similar roles with similar pay, supporting fair pay assessments or restructuring if discrepancies are detected.

/*
5. Analyze Customer Order Patterns Based on Time Between Orders
Business Question: What is the average time between orders for each customer?

Solution: Using a Self Join on the orders table, we calculate the time difference between consecutive orders for each customer.
*/

SELECT 
    o1.customer_id,
    MIN(o1.order_date) AS LATEST_ORDER_DATE,
    MAX(o2.order_date) AS EARLIEST_ORDER_DATE,
    ROUND(AVG(DATEDIFF(day, o2.order_date, o1.order_date)),0) AS avg_days_between_orders
FROM rest_orders o1
JOIN rest_orders o2 ON o1.customer_id = o2.customer_id
WHERE o1.order_date > o2.order_date
GROUP BY 1
ORDER BY 1;

-- This query provides insight into the frequency of customer visits, allowing the restaurant to identify patterns for targeted promotions or loyalty programs.

/*
6. Track Shifts for Employees with Similar Work Patterns
Business Question: Which employees have worked shifts on the same days, suggesting they might cover similar responsibilities?

Solution: Using a Self Join on an employee_shifts table (hypothetical for this scenario), we identify employees with overlapping shifts.
*/

SELECT 
    e1.employee_name AS employee_1,
    e2.employee_name AS employee_2,
    e1.hire_date
FROM rest_employees e1
JOIN rest_employees e2 ON e1.hire_date = e2.hire_date
WHERE e1.employee_id != e2.employee_id
ORDER BY 1,2,3;

-- This query can help management plan shift rotations or optimize staffing based on workload patterns, ensuring balanced schedules across employees.

/*
7. Detect Repeat Orders of the Same Item by Customers
Business Question: Are there any items that customers frequently reorder, suggesting they are popular among repeat customers?

Solution: Using a Self Join on orders, we can identify customers who repeatedly order the same item.
*/

SELECT 
    o1.customer_id,
    o1.menu_id,
    m.item_name,
    COUNT(*) AS order_count
FROM rest_orders o1
JOIN rest_orders o2 ON o1.customer_id = o2.customer_id AND o1.menu_id = o2.menu_id
JOIN rest_menus m ON o1.menu_id = m.menu_id
WHERE o1.order_id != o2.order_id
GROUP BY o1.customer_id, o1.menu_id, m.item_name
HAVING COUNT(*) >= 1;

-- This query reveals menu items with high reorder rates, which helps the restaurant identify items that should be consistently available or promoted further.

/*
8. Compare Customer Spend Over Time
Business Question: Has a customer's average spend per order increased or decreased compared to their initial orders?

Solution: Using a Self Join on the orders table, we compare the amount spent by each customer in their early orders versus recent orders.
*/

SELECT 
    o1.customer_id,
    ROUND(AVG(o1.quantity * m.price),0) AS recent_avg_spend,
    ROUND(AVG(o2.quantity * m.price),0) AS initial_avg_spend,
    ROUND((AVG(o1.quantity * m.price) - AVG(o2.quantity * m.price)),0) AS spend_difference
FROM rest_orders o1
JOIN rest_orders o2 ON o1.customer_id = o2.customer_id
JOIN rest_menus m ON o1.menu_id = m.menu_id AND o2.menu_id = m.menu_id
WHERE o1.order_date >= DATEADD(month, -12, CURRENT_DATE)  AND o2.order_date < DATEADD(year, -1, CURRENT_DATE)
GROUP BY o1.customer_id;

-- This query helps the restaurant track changes in customer spending behavior, allowing management to adjust marketing strategies based on whether customer spending is increasing or declining.

/*
9. Find Employees Who Worked Together Frequently
Business Question: Are there employee pairs who frequently work on the same shift, potentially allowing for team assignments?

Solution: Using a Self Join on an employee_shifts table (hypothetical), we identify employees who repeatedly work together.
*/

-- shift details doesnt't exist so just understand the logic behind
SELECT 
    e1.employee_id AS employee_1,
    e2.employee_id AS employee_2,
    COUNT(*) AS shifts_worked_together
FROM rest_employee_shifts e1
JOIN employee_shifts e2 ON e1.shift_date = e2.shift_date
WHERE e1.employee_id != e2.employee_id
GROUP BY e1.employee_id, e2.employee_id
HAVING shifts_worked_together > 5;

-- This query helps management see which employees have a working rapport, potentially aiding in team formation for special events or peak times.

/*
10. Evaluate Price Changes Across Menu Items Over Time
Business Question: For each menu item, how has the price changed in comparison to the price one year ago?

Solution: Using a Self Join on the menus table with different update dates, we can track historical price changes.
*/

-- last_updated column doesn't exists so just understand code part
SELECT 
    m1.item_name,
    m1.price AS current_price,
    m2.price AS past_price,
    (m1.price - m2.price) AS price_difference
FROM rest_menus m1
JOIN rest_menus m2 ON m1.menu_id = m2.menu_id
WHERE m1.last_updated > DATEADD(year, -1, m2.last_updated);

-- This query allows the restaurant to monitor price fluctuations over time, making it easier to understand the financial impact of pricing strategies on sales.
