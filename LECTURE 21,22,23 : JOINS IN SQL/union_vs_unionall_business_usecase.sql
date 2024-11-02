/*
Let’s dive into UNION vs UNION ALL with a realistic business use case, DDLs, sample queries, and CSV datasets.

-- Key Differences
UNION: Combines results from multiple SELECT queries and removes duplicates.
UNION ALL: Combines results from multiple SELECT queries without removing duplicates (faster because no duplicate check is performed).

Business Use Case: Analyzing Customers with Multiple Types of Orders

Consider a restaurant with two tables tracking online and in-store orders from customers. We want to generate a combined list of all customers for marketing purposes:

UNION is used when you need a list of unique customers, excluding duplicates.
UNION ALL is used when you want all order instances, including duplicates, to see each transaction.

Tables and Structure
online_orders: Tracks online orders placed by customers.
instore_orders: Tracks in-store orders placed by customers.

Each table includes the following columns:

customer_id: ID of the customer.
customer_name: Name of the customer.
order_date: Date the order was placed.
amount: Order amount in currency.

*/

CREATE OR REPLACE TABLE online_orders (
    customer_id INT,
    customer_name VARCHAR(255),
    order_date DATE,
    amount DECIMAL(10, 2)
);

CREATE OR REPLACE TABLE instore_orders (
    customer_id INT,
    customer_name VARCHAR(255),
    order_date DATE,
    amount DECIMAL(10, 2)
);

-- Query 1: Getting Unique Customers (UNION)
-- To get a unique list of all customers who placed an order (either online or in-store):

SELECT customer_id, customer_name
FROM online_orders
UNION
SELECT customer_id, customer_name
FROM instore_orders
ORDER BY customer_id;

/*
Business Scenario:
You manage both online and in-store sales channels and need to analyze orders to understand customer behavior, sales trends, and total revenue. The datasets now include some duplicated orders across both online and in-store channels.

Example Use Case for UNION (Removing Duplicates)
In this scenario, you want a report of unique customer orders. 
his could be used to analyze distinct customer behavior, where each customer's order (regardless of channel) is counted only once.

For example, if a customer placed the same order online and in-store, it might have been an error or redundancy. 
Therefore, for customer-centric reports (such as customer acquisition or unique order counts), duplicates should be removed.
*/

SELECT customer_id, customer_name, order_date, amount
FROM online_orders
UNION
SELECT customer_id, customer_name, order_date, amount
FROM instore_orders
ORDER BY customer_id, order_date;

/*
Example Use Case for UNION ALL (Keeping All Records)
In this case, you need a total revenue report across all orders. This report includes every transaction, so if customers made identical purchases in both channels, both transactions should be included to reflect total revenue accurately.

For example, if you want a complete view of all orders (including duplicates), UNION ALL will ensure that every instance of each order is included.

For example, if you want a complete view of all orders (including duplicates), UNION ALL will ensure that every instance of each order is included.
*/

-- Query 2: Getting All Order Instances (UNION ALL)
-- To see all orders from both channels (even if the same customer appears multiple times):

SELECT customer_id, customer_name, order_date, amount
FROM online_orders
UNION ALL
SELECT customer_id, customer_name, order_date, amount
FROM instore_orders
order by customer_id;


-- The UNION result provides a distinct list of customers.
-- The UNION ALL result shows all transactions, allowing detailed analysis of repeated customer orders.
