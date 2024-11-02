/*
A Full Outer Join returns all records from both tables, joining where there is a match and filling in NULL where there is no match. 
In business use, this join can be particularly helpful when trying to compare or reconcile information between two datasets that may have incomplete or mismatched data. 

Here are some complex business questions and solutions using Full Outer Join with the restaurant dataset.

These examples showcase how Full Outer Joins help analyze data with missing or mismatched records, providing insights to optimize promotions, manage inventory, analyze customer behavior, and improve operational efficiency.
*/

/*
1.Identify Menu Items That Have Never Been Ordered
Business Question: Identify all menu items along with their order details, showing which items have been ordered and which have not been ordered in the last three years.

Solution: This query can help the restaurant determine if any menu items are unpopular or haven’t been ordered recently, allowing them to consider revising the menu.
*/

WITH MENU_ITEMS_ORDER_DETAILS AS
(
SELECT 
    m.menu_id,
    m.item_name,
    m.category,
    m.price,
    o.order_id,
    o.order_date,
    o.customer_id,
    o.quantity
FROM rest_menus m
FULL OUTER JOIN rest_orders o ON m.menu_id = o.menu_id
WHERE o.order_date IS NULL OR o.order_date >= DATEADD(year, -1, CURRENT_DATE)
ORDER BY 1,2,3,4,5,6,7,8
)

SELECT MENU_ID,ITEM_NAME,CATEGORY,PRICE FROM MENU_ITEMS_ORDER_DETAILS
WHERE ORDER_ID IS NULL;

--This query lists all menu items with their associated order details or NULL if the item hasn’t been ordered in the specified timeframe, highlighting items that may require promotional efforts or removal from the menu.


/*
2. Track Employee Shift Coverage with Overlapping and Unassigned Shifts
Business Question: For each shift in the past month, identify if there were any employees assigned to it, and for each employee, find if they missed any shifts they were assigned to work.

Solution: This query helps HR understand any gaps in scheduling and identify any shifts that were either unassigned or missed.
*/

-- shift details doesn't exists in our datasets so just understand the code and logic
SELECT 
    s.shift_id,
    s.shift_date,
    e.employee_name,
    e.position,
    e.salary
FROM shifts s
FULL OUTER JOIN rest_employees e ON s.employee_id = e.employee_id
WHERE s.shift_date >= DATEADD(month, -1, CURRENT_DATE);

-- This query lists all shifts and employees, filling in NULL where an employee was either not assigned to a shift or missed their assignment. It helps HR review scheduling gaps and improve shift planning.


/*
3. Generate a Complete Customer Order Report Including Customers with No Orders
Business Question: Retrieve a full list of all customers and all orders, showing orders made by customers and marking as NULL for customers who haven’t placed any orders.

Solution: This report helps the restaurant identify customers who have registered but haven’t yet placed an order, allowing them to create a targeted marketing campaign for these inactive customers.
*/

WITH CUST_ORDERS_DETAILS AS
(
SELECT 
    c.customer_id,
    c.customer_name,
    --c.contact_number,
    o.order_id,
    o.order_date,
    o.menu_id,
    o.quantity
FROM rest_customers c
FULL OUTER JOIN rest_orders o ON c.customer_id = o.customer_id
ORDER BY 1,2,3,4,5,6
)

SELECT CUSTOMER_ID,CUSTOMER_NAME FROM CUST_ORDERS_DETAILS
WHERE ORDER_ID IS NULL
ORDER BY 1,2;

-- This query returns every customer with their order details, filling in NULL for those who haven’t made any orders. 
-- The restaurant can use this information to design marketing strategies for inactive customers.

/*
4. Analyze Menu Price Updates with Missing or Irregular Update Dates
Business Question: Find all menu items and show their last updated price information, even if they haven’t been updated in the last year.

Solution: This query helps the restaurant track if any menu items lack recent price updates or have irregularities in their update schedule.
*/

-- last_updated_price column doesn't exists so kindly ignore and focus on the logic
SELECT 
    m.item_name,
    m.price AS current_price,
    p.price AS past_price,
--  p.last_updated AS past_update_date
FROM rest_menus m
FULL OUTER JOIN rest_menus p ON m.menu_id = p.menu_id AND p.last_updated < DATEADD(year, -1, m.last_updated);

--This query displays all menu items with their current and past price information or NULL where updates are missing, helping the restaurant ensure that menu prices are updated regularly.

/*
5. Cross-Reference Employees and Orders to Ensure Full Staff Coverage
Business Question: Retrieve all orders from the last three years along with the employees responsible for fulfilling them, or mark as NULL where no employee was associated with an order.

Solution: This report helps the restaurant evaluate staffing coverage and identify any orders that lack an employee assignment, ensuring service quality and accountability.
*/

SELECT 
    e.employee_id,
    e.employee_name,
    e.position,
    --e.salary,
    o.order_id,
    o.order_date,
    o.customer_id,
    o.menu_id,
    o.quantity
FROM rest_employees e
FULL OUTER JOIN rest_orders o ON e.employee_id = o.employee_id
WHERE o.order_date >= DATEADD(year, -3, CURRENT_DATE)
ORDER BY 1,2,3,4,5,6,7,8;

-- This query lists all employees and the orders they fulfilled, filling in NULL where orders lack employee details. 
-- It supports staffing analysis and helps ensure orders are appropriately managed.

/*
6. Evaluate Customer Interaction with Menu Items Over Time
Business Question: Generate a report of all customers and the menu items they have ordered, marking NULL for customers who haven’t ordered certain items.

Solution: This report helps the restaurant analyze customer preferences by seeing which items are ordered by which customers and identifying gaps in interaction.
*/

WITH CUST_INTERACTION_MENU_ITEMS AS
(
SELECT 
    c.customer_id,
    c.customer_name,
    o.menu_id,
    m.item_name,
    m.category,
    m.price,
    o.order_date,
    o.quantity
FROM rest_customers c
FULL OUTER JOIN rest_orders o ON c.customer_id = o.customer_id
FULL OUTER JOIN rest_menus m ON o.menu_id = m.menu_id
ORDER BY 1,2,3,4,5,6,7,8
)

SELECT CUSTOMER_ID,CUSTOMER_NAME FROM CUST_INTERACTION_MENU_ITEMS
WHERE MENU_ID IS NULL AND CUSTOMER_ID IS NOT NULL;

-- This query lists each customer’s interaction with menu items, displaying NULL where a customer hasn’t ordered specific items. 
-- It enables the restaurant to see customer preferences and consider targeted promotions for less popular items.

/*
7. Analyze Employee-Customer Interactions on Orders Over the Last Year
Business Question: Generate a list of all orders from the last year, showing the customer and employee involved, or NULL if a customer didn’t place an order or no employee was assigned.

Solution: This report provides insight into the interactions between customers and employees, helping the restaurant monitor customer service and identify orders with missing details.

*/

SELECT 
    o.order_id,
    o.order_date,
    o.customer_id,
    c.customer_name,
    o.menu_id,
    o.quantity,
    o.employee_id,
    e.employee_name,
    e.position
FROM rest_orders o
FULL OUTER JOIN rest_customers c ON o.customer_id = c.customer_id
FULL OUTER JOIN rest_employees e ON o.employee_id = e.employee_id
WHERE o.order_date >= DATEADD(year, -1, CURRENT_DATE)
ORDER BY 1,2,3,4,5,6,7,8,9;

-- This query returns orders along with customer and employee details or NULL where orders lack customer or employee assignments. 
-- It helps the restaurant track interactions and improve customer service.

/*
8. Compare Employees’ Service Across All Orders
Business Question: Generate a report of all employees and the orders they handled, even if they had no orders assigned to them. This shows employee workload and involvement in service.

Solution: This report helps assess employee participation in service, highlighting those with fewer or no assigned orders.
*/

-- This query lists all employees and their associated orders, showing NULL for employees with no orders assigned. 
-- This supports management in monitoring employee involvement and workload distribution.

WITH EMP_SERV_HISTORY_ACROSS_ORDERS AS
(
SELECT 
    e.employee_id,
    e.employee_name,
    e.position,
    o.order_id,
    o.order_date,
    o.customer_id,
    o.menu_id,
    o.quantity
FROM rest_employees e
FULL OUTER JOIN rest_orders o ON e.employee_id = o.employee_id
ORDER BY 1,2,3,4,5,6,7,8
),

EMP_NO_SERV_HISTORY_ACROSS_ORDERS AS
(
SELECT EMPLOYEE_ID,EMPLOYEE_NAME,POSITION 
FROM EMP_SERV_HISTORY_ACROSS_ORDERS
WHERE ORDER_ID IS NULL
)

SELECT POSITION,COUNT(*)
FROM EMP_NO_SERV_HISTORY_ACROSS_ORDERS
GROUP BY 1
ORDER BY 2 DESC;
