/*
Let’s dive into Semi Joins and Anti Joins specifically using the tables menus, orders, customers, and employees.

Semi Join: A semi join returns rows from one table where matching rows exist in the other table, but it does not return duplicate columns from the second table.
Anti Join: An anti join returns rows from one table where no matching rows exist in the other table.

Here are complex business problems and solutions using Semi Joins and Anti Joins with the specified tables.
*/

--Semi Join Examples

/*
1. Find Customers Who Have Placed Orders in the Last Year
Business Problem: Identify customers who have actively placed at least one order in the past year. The result should list only these active customers without duplicating their order details.

Solution: This semi join will help the restaurant focus on its current customer base and better understand active clientele for marketing efforts.

*/

SELECT 
    c.customer_id,
    c.customer_name,
    c.AGE,
    c.city
    --c.contact_number
FROM rest_customers c
WHERE EXISTS (
    SELECT 1 
    FROM rest_orders o 
    WHERE o.customer_id = c.customer_id  AND o.order_date >= DATEADD(year, -1, CURRENT_DATE)
)
ORDER BY 1,2,3,4;

-- This query uses a semi join to retrieve customers who have made an order in the last year, filtering out those who have not. 
-- It focuses on active customers and their contact details, enabling targeted marketing strategies.

/*
2. List Menu Items That Have Been Ordered at Least Once
Business Problem: Identify menu items that have been ordered at least once. Only list these menu items without including each order’s details.

Solution: This information is useful for the restaurant to assess which items are being ordered, helping in inventory planning and menu curation.
*/

SELECT 
    m.menu_id,
    m.item_name,
    m.category,
    m.price
FROM rest_menus m
WHERE EXISTS (
    SELECT 1 
    FROM rest_orders o 
    WHERE o.menu_id = m.menu_id
)
ORDER BY 1,2,3,4;

-- This query returns only menu items that have been part of an order at least once. 
-- This enables the restaurant to easily see which menu items have been successful with customers, without adding redundant order information.

/*
3. Identify Employees Who Have Handled at Least One Order
Business Problem: Identify all employees who have fulfilled at least one order, without needing details of each order they processed.

Solution: This helps in assessing the engagement level of employees with customer orders.
*/

SELECT 
    e.employee_id,
    e.employee_name,
    e.hire_date,
    e.position,
FROM rest_employees e
WHERE EXISTS (
    SELECT 1 
    FROM rest_orders o 
    WHERE o.employee_id = e.employee_id
)
ORDER BY 1,2,3,4;

-- This query uses a semi join to return only the employees who have handled orders, which is useful for assessing who has been actively engaged in fulfilling orders.

-- Anti Join Examples

/*
4. Find Customers Who Have Never Placed an Order
Business Problem: Identify customers who registered with the restaurant but have not yet placed any order.

Solution: The restaurant can use this information to engage these customers with marketing strategies to encourage their first order.
*/

SELECT 
    c.customer_id,
    c.customer_name,
    c.AGE,
    c.city,
FROM rest_customers c
WHERE NOT EXISTS (
    SELECT 1 
    FROM rest_orders o 
    WHERE o.customer_id = c.customer_id
)
ORDER BY 1,2,3,4;

-- This query returns only those customers who have not placed any orders. 
-- This allows the restaurant to target these individuals with promotions or special offers to encourage them to make their first purchase.

/*
5. List Menu Items That Have Never Been Ordered
Business Problem: Identify all menu items that have never been ordered, which could help the restaurant decide whether to keep, promote, or remove them from the menu.

Solution: This anti join helps isolate menu items that are not contributing to sales and may need attention.
*/

SELECT 
    m.menu_id,
    m.item_name,
    m.category,
    m.price
FROM rest_menus m
WHERE NOT EXISTS (
    SELECT 1 
    FROM rest_orders o 
    WHERE o.menu_id = m.menu_id
)
ORDER BY 1,2,3,4;

-- This query retrieves only those menu items that have never been ordered. 
-- This can help the restaurant decide if these items need a promotion or should be replaced on the menu.

/*
6. Find Employees Who Have Not Handled Any Orders
Business Problem: Identify employees who have never been assigned to fulfill an order, which may indicate areas for improving staffing or scheduling.

Solution: This information can guide management on training or assigning employees to more customer-facing roles.
*/

SELECT 
    e.employee_id,
    e.employee_name,
    e.hire_date,
    e.position
FROM rest_employees e
WHERE NOT EXISTS (
    SELECT 1 
    FROM rest_orders o 
    WHERE o.employee_id = e.employee_id
)
ORDER BY 1,2,3,4;

-- This anti join retrieves only those employees who have not handled any orders, enabling management to analyze whether these employees might need additional assignments or training for more active engagement.

/*
7. Find Menu Items with No Price Updates in the Last Year
Business Problem: Identify menu items that have not had any price update in the last year, suggesting they might need review.

Solution: This helps ensure that pricing is competitive and aligned with market trends.
*/

-- data doesnt exists due to non existent of columns , just focus on the logic part
SELECT 
    m.menu_id,
    m.item_name,
    m.category,
    m.price
FROM rest_menus m
WHERE NOT EXISTS (
    SELECT 1 
    FROM rest_menus m2 
    WHERE m.menu_id = m2.menu_id AND m2.last_updated >= DATEADD(year, -1, CURRENT_DATE)
);

-- This query identifies menu items with no recent price updates, helping the restaurant evaluate if the prices need adjustment.

/*
8. Identify Orders Without Associated Customer Information
Business Problem: Identify orders that lack customer information, possibly due to incomplete or missing data.

Solution: This helps the restaurant verify data integrity and ensure customer records are up-to-date.
*/

SELECT 
    o.order_id,
    o.order_date,
    o.menu_id,
    o.quantity
FROM rest_orders o
WHERE NOT EXISTS (
    SELECT 1 
    FROM rest_customers c 
    WHERE o.customer_id = c.customer_id
)
ORDER BY 1,2,3,4;

-- This anti join isolates orders with missing customer information, which helps the restaurant address potential data issues and maintain accurate records.

/*
9. Identify Orders That Lack Assigned Employees
Business Problem: Identify orders that do not have an employee assigned to them, ensuring that all orders have responsible staff.

Solution: This helps improve operational efficiency by ensuring each order is accounted for by an employee.
*/

SELECT 
    o.order_id,
    o.order_date,
    o.customer_id,
    o.menu_id,
    o.quantity
FROM rest_orders o
WHERE NOT EXISTS (
    SELECT 1 
    FROM rest_employees e 
    WHERE o.employee_id = e.employee_id
)
ORDER BY 1,2,3,4,5;

-- This anti join returns orders without assigned employees, which can highlight staffing gaps and improve customer service management.
