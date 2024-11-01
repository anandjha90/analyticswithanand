/*
Right Joins are helpful in scenarios where we want to ensure that all records from the right table are included, regardless of whether they have corresponding entries in the left table. 
Here are some complex business problems and solutions using Right Joins with the restaurant dataset.

These examples leverage Right Joins to gain insights from incomplete or missing data in the restaurant dataset, helping the business address issues related to inventory, customer engagement, employee performance, and revenue optimization. Let me know if you need further clarification on any of these solutions!

*/

/*
1. Identify Orders for Items No Longer on the Menu
Business Question: Which orders were placed for items that are no longer on the menu?

Solution: This query uses a Right Join between menus and orders to include all records from orders, even if they refer to menu items that might have been removed from the menus table.

*/

WITH ITEMS_NO_LONGER_MENU AS
(SELECT 
    o.order_id, 
    o.order_date, 
    o.customer_id, 
    o.employee_id, 
    o.menu_id, 
    m.item_name
FROM rest_orders o
RIGHT JOIN rest_menus m ON o.menu_id = m.menu_id
--WHERE m.menu_id IS NULL
ORDER BY o.menu_id
)

SELECT * FROM ITEMS_NO_LONGER_MENU
WHERE menu_id IS NULL;
--This query helps the restaurant identify any issues with orders related to discontinued items, which can prevent serving unavailable items and lead to adjustments in data handling or item availability notices.

/*
2. Find Loyalty Levels Not Represented in Recent Orders
Business Question: Are there any loyalty levels (e.g., Regular, Silver, Gold, Platinum) that did not place any orders recently?

Solution: This query uses a Right Join between customers and orders to include all loyalty levels from customers, even if they did not appear in the orders table in the past month.

*/

SELECT 
    c.loyalty_level,
    COUNT(o.order_id) AS orders_count
FROM rest_customers c
RIGHT JOIN rest_orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= DATEADD(month, -1, CURRENT_DATE)
GROUP BY c.loyalty_level
--HAVING COUNT(o.order_id) = 0
ORDER BY orders_count DESC ;

-- This query helps identify any loyalty segments that haven’t been active recently, prompting marketing strategies to re-engage them with offers or targeted communication.

/*
3. Find Employee Assignments to Orders and Missing Employees in Orders
Business Question: Are there any recent orders that lack employee assignment (orders without a valid employee_id), and who are those employees?

Solution: This query uses a Right Join between employees and orders to include all orders, even those with missing employee data.

*/

WITH MISS_EMP_ORDERS AS
(
SELECT 
    o.order_id, 
    o.order_date, 
    e.employee_name, 
    o.employee_id
FROM rest_orders o
RIGHT JOIN rest_employees e ON o.employee_id = e.employee_id
--WHERE e.employee_id IS NULL
ORDER BY e.employee_id
)

SELECT * FROM MISS_EMP_ORDERS
WHERE employee_id IS NULL;

--This query helps in identifying any data integrity issues where orders are placed without employee association, which can impact order tracking and employee accountability.

/*
4. Evaluate Menu Category Performance Including Unordered Categories
Business Question: Which menu categories, including those that haven’t been ordered in the last quarter, are performing well?

Solution: This query uses a Right Join to include all categories in the menus table, even those that did not receive any orders in the last three months.

*/

SELECT 
    m.category,
    COUNT(o.order_id) AS orders_count,
    SUM(o.quantity * m.price) AS total_revenue
FROM rest_menus m
RIGHT JOIN rest_orders o ON m.menu_id = o.menu_id
WHERE o.order_date >= DATEADD(month, -3, CURRENT_DATE)
GROUP BY m.category
ORDER BY total_revenue DESC;

--This query helps identify menu categories that may need more promotion if they have low or zero sales, providing insight into underperforming categories across all options.

/*
5. Calculate Average Spend Per Loyalty Level Including Inactive Levels
Business Question: What is the average spend per order by loyalty level, including loyalty levels that haven’t placed any orders in the last year?

Solution: By using a Right Join between customers and orders, we ensure that all loyalty levels are represented in the result, even those without recent orders.

*/

SELECT 
    c.loyalty_level,
    ROUND(COALESCE(AVG(m.price * o.quantity), 0),2) AS avg_spend
FROM rest_customers c
RIGHT JOIN rest_orders o ON c.customer_id = o.customer_id
LEFT JOIN rest_menus m ON o.menu_id = m.menu_id
WHERE o.order_date >= DATEADD(year, -1, CURRENT_DATE) OR o.order_id IS NULL
GROUP BY c.loyalty_level
ORDER BY avg_spend DESC;

--This provides a complete view of average spending across all loyalty levels, helping the restaurant understand the financial contributions (or lack thereof) from different segments and adapt loyalty strategies.

/*
6. Identify Employees Not Working in High-Revenue Orders
Business Question: Which employees have not been involved in orders generating revenue above a certain threshold in the last six months?

Solution: By using a Right Join with a filter for high-revenue orders, we can identify employees who might be missing out on high-value opportunities.

*/

SELECT 
    e.employee_name,
    e.position,
    o.order_id,
    SUM(m.price * o.quantity) AS order_value
FROM rest_employees e
RIGHT JOIN rest_orders o ON e.employee_id = o.employee_id
LEFT JOIN rest_menus m ON o.menu_id = m.menu_id
WHERE o.order_date >= DATEADD(month, -6, CURRENT_DATE)
GROUP BY e.employee_name, e.position, o.order_id
HAVING order_value < 100 OR order_value IS NULL;

--This query identifies employees who are not actively engaged in high-value orders, which may suggest further training or role reassessment for employees.

/*
7. Identify High-Priced Menu Items Ordered by Each Customer Including Non-Ordering Customers
Business Question: For each customer, which high-priced items (over $40) have they ordered, and which customers have not ordered any high-priced items?

Solution: This query uses a Right Join to list all customers and the high-priced items they’ve ordered, including those who haven’t ordered any.

*/

SELECT 
    c.customer_name,
    m.item_name,
    m.price
FROM rest_customers c
RIGHT JOIN rest_orders o ON c.customer_id = o.customer_id
LEFT JOIN rest_menus m ON o.menu_id = m.menu_id
WHERE m.price > 40 OR m.menu_id IS NULL
ORDER BY c.customer_name;

--This analysis helps the business understand which high-priced items appeal to different customers, allowing targeted promotions for high-value items.

/*
8. Assess Revenue Impact of Low-Frequency Orders by Menu Category
Business Question: How much revenue is generated by categories with less than 10 orders in the past year, and which categories lack orders altogether?

Solution: This query includes all menu categories from the menus table, using Right Join to show categories with or without orders.

*/

SELECT 
    m.category,
    COUNT(o.order_id) AS orders_count,
    SUM(m.price * o.quantity) AS revenue
FROM rest_menus m
RIGHT JOIN rest_orders o ON m.menu_id = o.menu_id
WHERE o.order_date >= DATEADD(year, -1, CURRENT_DATE)
GROUP BY m.category
HAVING orders_count < 10 OR orders_count IS NULL
ORDER BY revenue DESC;

--This helps management understand the revenue impact of low-frequency items and decide if adjustments should be made to enhance sales or remove underperforming items.
