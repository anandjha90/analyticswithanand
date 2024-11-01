/*
Cross Joins generate combinations of all records in the two tables involved, which can be useful in scenarios where you want to analyze all possible pairings or compare every entry with every other entry.
However, due to the large output size, Cross Joins are typically used selectively, often with additional filtering criteria to narrow down results. 
Here are some complex business use cases using Cross Joins with the restaurant dataset.

These examples use Cross Joins to explore business scenarios where every possible combination of certain entities is necessary for insight. Because Cross Joins can produce large results, each query is designed to be narrowed down with appropriate filters to answer specific business questions effectively. Let me know if you need further clarification on any of these examples!
*/

/*
1. Generate All Possible Meal Pairings for Cross-Selling
Business Question: What meal pairings (appetizer and main course) could be promoted together?

Solution: A Cross Join between menu items of the appetizer and main course categories generates all possible meal pairings.
*/

SELECT 
    m1.item_name AS appetizer,
    m2.item_name AS main_course,
    m1.price + m2.price AS total_price
FROM rest_menus m1
CROSS JOIN rest_menus m2
WHERE m1.category = 'Appetizer' AND m2.category = 'Main Course';

--This query helps marketing teams identify meal pairings to create combo offers or promotions, encouraging customers to try a variety of appetizers and main courses.

/*
2. Evaluate Customer Preferences Across All Menu Categories
Business Question: Which menu categories might interest customers based on all possible category combinations?

Solution: By Cross Joining customers and unique menu categories, we can assess customer preferences by checking historical order data for matches.
*/

SELECT 
    c.customer_name,
    m.category,
    COUNT(o.order_id) AS order_count
FROM rest_customers c
CROSS JOIN (SELECT DISTINCT category FROM rest_menus) m
LEFT JOIN rest_orders o ON c.customer_id = o.customer_id
LEFT JOIN rest_menus mn ON o.menu_id = mn.menu_id AND mn.category = m.category
GROUP BY c.customer_name, m.category
HAVING order_count > 0
ORDER BY c.customer_name, order_count DESC;

--This query gives insight into categories each customer hasn’t yet tried, which can be used to develop personalized recommendations to encourage sampling across different menu categories.

/*
3. Identify Potential Employee-Menu Specialization Opportunities
Business Question: Are there certain employees who should specialize in promoting or handling specific menu items based on all possible employee-item combinations?

Solution: A Cross Join between employees and menus generates all potential employee-item pairings, which can be filtered based on historical orders to see if an employee has already handled a specific item.
*/

SELECT 
    e.employee_name,
    m.item_name,
    COUNT(o.order_id) AS orders_handled
FROM rest_employees e
CROSS JOIN rest_menus m
LEFT JOIN rest_orders o ON e.employee_id = o.employee_id AND m.menu_id = o.menu_id
GROUP BY e.employee_name, m.item_name
HAVING orders_handled > 0 -- its a blast and you will consume all the snowflake credits - be careful
ORDER BY e.employee_name, orders_handled DESC;

--This analysis allows the management team to evaluate which employees are better suited to specialize in certain menu items based on experience, enabling training or role assignments to improve efficiency and customer service.

/*
4. Compare Customer Preferences for Different Loyalty Levels Across All Cities
Business Question: How does customer ordering behavior for different loyalty levels vary across cities?

Solution: A Cross Join between unique loyalty levels and cities helps analyze the distribution and preferences of loyalty-level customers in all cities.
*/

SELECT 
    l.loyalty_level,
    c.city,
    COUNT(o.order_id) AS total_orders,
    SUM(m.price * o.quantity) AS total_revenue
FROM (SELECT DISTINCT loyalty_level FROM rest_customers) l
CROSS JOIN (SELECT DISTINCT city FROM rest_customers) c
LEFT JOIN rest_customers cust ON cust.loyalty_level = l.loyalty_level AND cust.city = c.city
LEFT JOIN rest_orders o ON cust.customer_id = o.customer_id
LEFT JOIN rest_menus m ON o.menu_id = m.menu_id
GROUP BY l.loyalty_level, c.city
ORDER BY total_revenue DESC;

-- This helps management see how loyalty levels affect purchasing behavior in various cities, which can inform regional promotions and loyalty incentives.

/*
5. Test Menu Item Combinations for Bundling Opportunities
Business Question: Which combinations of items from different categories (e.g., appetizer, main course, dessert) could form a successful bundle based on potential demand and price?

Solution: A Cross Join among menus for different categories generates all possible bundles, giving insight into potential combo deals based on item popularity and price.
*/

SELECT 
    a.item_name AS appetizer,
    m.item_name AS main_course,
    d.item_name AS dessert,
    (a.price + m.price + d.price) AS bundle_price
FROM rest_menus a
CROSS JOIN rest_menus m
CROSS JOIN rest_menus d
WHERE a.category = 'Appetizer' AND m.category = 'Main Course' AND d.category = 'Dessert'
ORDER BY bundle_price ASC;

-- This allows the marketing team to explore bundle pricing, enabling them to promote budget-friendly or premium meal combos based on the item combinations.

/*
6. Evaluate Employee Availability for All Cities
Business Question: Which employees can be scheduled across different cities, ensuring cross-city coverage?

Solution: A Cross Join between employees and unique cities generates all possible location assignments for employees, which can be further refined based on each employee’s availability or recent orders handled.
*/

SELECT 
    e.employee_name,
    e.position,
    c.city,
    COUNT(o.order_id) AS orders_handled_in_city
FROM rest_employees e
CROSS JOIN (SELECT DISTINCT city FROM rest_customers) c
LEFT JOIN rest_orders o ON e.employee_id = o.employee_id
LEFT JOIN rest_customers cust ON o.customer_id = cust.customer_id AND cust.city = c.city
GROUP BY e.employee_name, e.position, c.city
HAVING orders_handled_in_city > 0
ORDER BY orders_handled_in_city DESC;

--This query helps determine employee flexibility and multi-location staffing potential, allowing managers to plan resource allocation effectively.

/*
7. Assess Cross-Loyalty Level Menu Preferences Across All Categories
Business Question: How does each loyalty level's preference vary across all menu categories?

Solution: By Cross Joining loyalty levels with menu categories, the restaurant can assess which categories are preferred or ignored by each loyalty level.
*/

SELECT 
    l.loyalty_level,
    m.category,
    COUNT(o.order_id) AS orders_count,
    SUM(mn.price * o.quantity) AS total_spent
FROM (SELECT DISTINCT loyalty_level FROM rest_customers) l
CROSS JOIN (SELECT DISTINCT category FROM rest_menus) m
LEFT JOIN rest_customers c ON c.loyalty_level = l.loyalty_level
LEFT JOIN rest_orders o ON c.customer_id = o.customer_id
LEFT JOIN rest_menus mn ON o.menu_id = mn.menu_id AND mn.category = m.category
GROUP BY l.loyalty_level, m.category
ORDER BY total_spent DESC;

-- This helps the restaurant understand loyalty-level preferences across categories, informing loyalty-specific promotions or cross-sell opportunities.

/*
8. Evaluate Seasonal Demand by Generating All Date-Order Combinations
Business Question: For each possible month, how do order patterns vary by menu category?

Solution: By creating a Cross Join between all months and categories, the restaurant can assess historical order frequency and revenue by month and menu category.
*/
SELECT 
    o.order_year,
    o.order_month,
    m.category,
    COUNT(ord.order_id) AS orders_count,
    SUM(mn.price * ord.quantity) AS total_revenue
FROM (SELECT DISTINCT YEAR(order_date) AS order_year,MONTH(order_date) AS order_month FROM rest_orders) o
CROSS JOIN (SELECT DISTINCT category FROM rest_menus) m
LEFT JOIN rest_orders ord ON (YEAR(ord.order_date) = o.order_year AND MONTH(ord.order_date) = o.order_month)
LEFT JOIN rest_menus mn ON ord.menu_id = mn.menu_id AND mn.category = m.category
GROUP BY 1,2,3
--ORDER BY 1 DESC,2,3
ORDER BY total_revenue DESC
NULLS LAST;

-- This analysis provides insight into seasonal demand patterns, enabling the restaurant to adjust inventory, marketing, and staffing according to expected demand for each menu category.
