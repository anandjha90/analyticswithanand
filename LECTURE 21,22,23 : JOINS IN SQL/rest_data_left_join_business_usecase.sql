/*

Here are several complex business questions solved using Left Joins on the restaurant dataset. 
These scenarios leverage Left Joins to retrieve data even when certain records are missing in one of the tables, which is especially useful for identifying gaps or unassigned data.

These examples leverage Left Joins to gain insights from incomplete or missing data in the restaurant datasets, allowing the business to address operational inefficiencies, customer re-engagement, and cross-selling opportunities. Let me know if you need further details on any of these queries!

*/

/*
1. Identify Customers Without Orders
Business Question: Which customers haven’t placed any orders in the past three years?

Solution: This query uses a Left Join between customers and orders to list customers who have no corresponding entries in the orders table.

*/

SELECT 
    c.customer_id, 
    c.customer_name, 
    c.loyalty_level, 
    c.city,
    o.order_id
FROM rest_customers c
LEFT JOIN rest_orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY 1,2,3,4 ;

-- By identifying inactive customers, the restaurant can plan targeted campaigns to re-engage these customers or identify factors contributing to inactivity.

/*
2. Find Menu Items That Haven't Been Ordered
Business Question: Which menu items haven’t been ordered by any customer in the past three years?

Solution: This query uses a Left Join between menus and orders to identify menu items with no associated orders.
*/

SELECT 
    m.menu_id, 
    m.item_name, 
    m.category, 
    m.price,
    o.order_id
FROM rest_menus m
LEFT JOIN rest_orders o ON m.menu_id = o.menu_id
WHERE o.order_id IS NULL
ORDER BY 1,2,3,4;

-- This analysis helps the restaurant identify items that may need re-evaluation, as consistently unpopular items can be removed, modified, or promoted differently.

/*
3. List Employees Without Any Recorded Sales
Business Question: Which employees have not processed any orders?

Solution: This query uses a Left Join between employees and orders to identify employees who have not processed any orders.

*/

SELECT 
    e.employee_id, 
    e.employee_name, 
    e.position,
    o.order_id
FROM rest_employees e
LEFT JOIN rest_orders o ON e.employee_id = o.employee_id
WHERE o.order_id IS NULL
ORDER BY 1,2,3;

-- This helps the management assess employee performance and understand if some employees might need additional training or are underutilized.

/*
4. Calculate Potential Lost Revenue Due to Unordered Menu Items
Business Question: What is the total potential revenue loss from menu items that haven't been ordered at all?

Solution: Using a Left Join between menus and orders, this query calculates the total potential revenue based on the prices of unordered items.

*/

SELECT 
    o.order_id,
    SUM(m.price) AS potential_lost_revenue
FROM rest_menus m
LEFT JOIN rest_orders o ON m.menu_id = o.menu_id
WHERE o.order_id IS NULL
GROUP BY 1
ORDER BY 1;

--By calculating potential lost revenue, the restaurant can quantify the impact of unpopular menu items on the business and decide if changes to the menu might reduce this potential loss.

/*
5. Identify Orders Missing Customer Data
Business Question: Which orders do not have an associated customer (possibly due to data entry errors)?

Solution: This query uses a Left Join between orders and customers to find orders that lack a valid customer reference.

*/

SELECT 
    c.customer_id,
    o.order_id, 
    o.order_date, 
    o.quantity, 
    o.menu_id
FROM rest_orders o
LEFT JOIN rest_customers c ON o.customer_id = c.customer_id
--WHERE c.customer_id IS NULL
order by 1,2,3,4,5;

-- This analysis identifies data integrity issues, allowing the restaurant to investigate and resolve missing customer associations in order records.

/*
6. Analyze Average Order Value Including Customers With No Orders
Business Question: What is the average order value by loyalty level, including customers who haven't placed any orders?

Solution: This query uses a Left Join to include all customers (regardless of order status) to calculate average order values, treating customers with no orders as having zero order value.

*/

SELECT 
    c.loyalty_level,
    ROUND(COALESCE(AVG(m.price * o.quantity), 0),2) AS avg_order_value
FROM rest_customers c
LEFT JOIN rest_orders o ON c.customer_id = o.customer_id
LEFT JOIN rest_menus m ON o.menu_id = m.menu_id
GROUP BY c.loyalty_level
ORDER BY avg_order_value DESC;

--This query gives a more comprehensive picture of average spending per loyalty level, including inactive customers, which helps in evaluating the performance of each loyalty tier.

/*
7. List Employees with Total Orders Processed, Including Those with No Orders
Business Question: How many orders has each employee processed, including those who haven’t processed any orders?

Solution: By Left Joining employees with orders, we count the number of orders per employee, ensuring that even employees with no orders are included.

*/

SELECT 
    e.employee_id, 
    e.employee_name, 
    e.position, 
    COALESCE(COUNT(o.order_id), 0) AS total_orders_processed
FROM rest_employees e
LEFT JOIN rest_orders o ON e.employee_id = o.employee_id
GROUP BY e.employee_id, e.employee_name, e.position
ORDER BY total_orders_processed DESC;

-- This result helps management assess employee productivity and analyze workload distribution, identifying employees who may need more engagement or training.

/*
8. Find Potential Cross-Selling Opportunities by Loyalty Level
Business Question: Are there certain menu categories that loyal customers (Gold and Platinum) haven’t ordered, representing potential cross-sell opportunities?

Solution: This query identifies missing category orders for Gold and Platinum customers, highlighting areas for targeted cross-selling.

*/

SELECT 
    c.loyalty_level, 
    m.category, 
    COUNT(o.order_id) AS orders_count
FROM rest_customers c
LEFT JOIN rest_orders o ON c.customer_id = o.customer_id
LEFT JOIN rest_menus m ON o.menu_id = m.menu_id
WHERE c.loyalty_level IN ('Gold', 'Platinum') AND o.order_id IS NULL
GROUP BY c.loyalty_level, m.category
ORDER BY orders_count DESC;

--This analysis shows which categories have not been purchased by high-loyalty customers, indicating cross-sell opportunities.
