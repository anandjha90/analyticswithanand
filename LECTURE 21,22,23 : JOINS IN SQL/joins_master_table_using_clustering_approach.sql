/*
- To create a master table that combines all the distinct columns from the menus, orders, customers, and employees tables, we’ll join the tables in a way that captures all relevant information.
- Since this will combine details across multiple entities (e.g., customer, menu item, order, and employee), we’ll use Left Joins from the main orders table to include information from all tables, as orders connect with each of the other tables via foreign keys.

Step 1: Identify the Columns
To ensure that each column is unique, let's outline the columns from each table:

- menus:

menu_id (primary key)
item_name
category
price
last_updated

- orders:

order_id (primary key)
order_date
customer_id (foreign key to customers)
menu_id (foreign key to menus)
employee_id (foreign key to employees)
quantity

- customers:

customer_id (primary key)
customer_name
contact_number

- employees:

employee_id (primary key)
employee_name
position
salary

Step 2: Write the Query to Create the Master Table
To create a master table with all the distinct columns, we’ll use Left Joins to ensure that we capture all orders and connect them with available information from menus, customers, and employees.
*/

-- Here’s the SQL code to create the master table:
CREATE OR REPLACE TABLE REST_MASTER_TABLE AS
SELECT 
    o.order_id,
    o.order_date,
    o.menu_id,
    m.item_name,
    m.category,
    m.price,
    o.quantity,
    c.customer_id,
    c.customer_name,
    c.age,
    c.city,
    c.loyalty_level,
    c.join_date,
    o.employee_id,
    e.employee_name,
    e.hire_date,
    e.position
FROM rest_orders o
LEFT JOIN rest_customers c ON o.customer_id = c.customer_id
LEFT JOIN rest_menus m ON o.menu_id = m.menu_id
LEFT JOIN rest_employees e ON o.employee_id = e.employee_id;

SELECT * FROM REST_MASTER_TABLE
ORDER BY CUSTOMER_ID;

/*
Explanation of the Query

Base Table (orders): 
The query starts with the orders table as the base. 
This ensures that all orders will be included, even if some related information (e.g., employee details) is missing.

Joining customers:

We perform a LEFT JOIN on customers using customer_id to bring in customer_name and contact_number.
This ensures that for every order, we get customer details if they exist.

Joining menus:

We perform a LEFT JOIN on menus using menu_id to bring in details about the ordered item (e.g., item_name, category, price, last_updated).
This ensures we have item details for every order.

Joining employees:

We perform a LEFT JOIN on employees using employee_id to include employee information (employee_name, position, salary).
This captures the employee assigned to fulfill the order, if applicable.

Resulting master_table Schema
The resulting master_table will have the following columns:

order_id, order_date,menu_id,quantity, (from orders)
customer_id, customer_name, age,city,loyalty_program,join_date (from customers)
menu_id, item_name, category, price, last_updated (from menus)
employee_id, employee_name, position, salary (from employees)
quantity (from orders)

This master table provides a comprehensive view of each order, linking each order to the customer, menu item, and employee (if available) involved.

Final Note
If you’d like to add constraints, indexes, or further process this master table, please let me know, and I can guide you on the next steps!

*/

/*
In Snowflake, clustering is a powerful way to optimize both data retrieval and insertion, especially for large datasets. 
Clustering organizes data on specific columns, making it easier for Snowflake to retrieve relevant records without scanning the entire table.
This can also reduce the time for data insertions by maintaining efficient access paths.

For our master table and the base tables (menus, orders, customers, employees), we’ll add clustering keys that align with common query patterns and join conditions. 
This will improve performance both for queries and insertions.

Clustering in Snowflake

Master Table: Since this table integrates data from orders, customers, menus, and employees, clustering on commonly filtered or joined columns will help.
Base Tables: For orders, menus, customers, and employees, clustering on frequently used columns will optimize both insertions and retrievals.

Here’s how to define clustering keys for each table in Snowflake:

1. Clustering for master_table
In the master_table, the clustering should focus on fields that are frequently filtered and joined:

order_date: As a timestamp column, it’s often used for filtering by date range.
customer_id, menu_id, employee_id: These columns are commonly used in join conditions.
Composite Clustering Key: If you often query by customer_id within a specific order_date range, clustering on (customer_id, order_date) could be beneficial.

*/
-- Alter master_table to add a clustering key in Snowflake
ALTER TABLE REST_MASTER_TABLE CLUSTER BY (order_date, customer_id, menu_id, employee_id);

-- This clustering key on order_date, customer_id, menu_id, and employee_id will improve query performance on orders by date and customer while also speeding up join operations with the original tables.

/*
2. Clustering for Base Tables
Let’s define clustering keys for the base tables to improve insertion efficiency and retrieval performance.

orders Table
Since orders is likely the largest table, clustering on order_date and customer_id helps optimize for both insertion and retrieval.
*/

ALTER TABLE rest_orders CLUSTER BY (order_date, customer_id);

/*
menus Table
For the menus table, clustering on menu_id and last_updated will support faster updates and retrievals by menu ID and recent updates.
*/


ALTER TABLE rest_menus CLUSTER BY (menu_id); --last_updated

/*
customers Table
For customers, clustering on customer_id ensures efficient access by customer ID. If you often filter by customer_name, you can add that as well, but this depends on your query needs.
*/

ALTER TABLE rest_customers CLUSTER BY (customer_id);

/*
employees Table
In the employees table, clustering on employee_id helps with quick retrieval by employee, particularly for any joins or filtering by employee_id.
*/

ALTER TABLE rest_employees CLUSTER BY (employee_id);

/*

-- Explanation of Clustering Choices

Master Table: The clustering key (order_date, customer_id, menu_id, employee_id) balances retrieval and insertion. 
It focuses on commonly used columns in filters and joins, improving performance for queries that span date ranges or customer data.

- Orders: Clustering on (order_date, customer_id) aligns with likely date-based filtering and customer-based analysis, improving query performance on specific orders and insertion efficiency.

- Menus: Clustering by (menu_id, last_updated) ensures efficient management of data by unique menu items and optimizes retrieval by recent updates.

- Customers and Employees: Clustering by unique identifiers (customer_id and employee_id) improves retrieval efficiency, especially for join operations and customer/employee lookups.

-- Additional Tips for Snowflake Clustering
- Monitor Cluster Depth: Snowflake manages clustering automatically, but it’s beneficial to monitor the “cluster depth” metric for tables to see if reclustering may be necessary for optimal performance.

- Reclustering with Large Inserts/Updates: After substantial data loads or updates, Snowflake may automatically recluster the data if auto-clustering is enabled. 
Manually trigger reclustering if necessary using RECLUSTER.

- Minimize Clustering Key Complexity: Clustering on too many columns can add overhead; prioritize columns based on query patterns.

These clustering keys should help ensure efficient insertions and fast retrievals, especially for the master table and the frequently joined orders table. 
*/
