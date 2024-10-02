CREATE OR REPLACE TABLE sales_data (
    transaction_id INT PRIMARY KEY,
    transaction_date DATE,
    product_category VARCHAR(50),
    customer_id INT,
    product_id INT,
    region VARCHAR(50),
    sales_amount DECIMAL(10, 2),
    units_sold INT
);

SELECT * FROM sales_data LIMIT 100;
-- Use Case 1: Sales Performance Analysis by Product Category
-- Scenario: You have a dataset of sales transactions over the last 4 years, with columns like transaction_id, product_category, transaction_date, sales_amount, and region.

-- Objective: You want to analyze total sales per product category over the last 4 years, focusing on categories with at least $500,000 in sales.
SELECT 
    product_category,
    SUM(sales_amount) AS total_sales
FROM 
    sales_data
GROUP BY 
    product_category
HAVING 
    SUM(sales_amount) > 500000
ORDER BY 
    total_sales DESC;
    
--GROUP BY: Groups the data by product_category to calculate total sales for each category.
--HAVING: Filters the results to only include categories with total sales above $500,000.
--ORDER BY: Sorts the categories based on total sales in descending order, so the top-performing categories appear first.

--Use Case 2: Monthly Revenue Trends by Region
--Scenario: A retail company has monthly sales data over the past 4 years with columns like region, month, year, and revenue.

-- Objective: Analyze the revenue trends by region and identify regions that have consistently performed well.

SELECT 
    NVL(region, 'Unspecified') AS region, 
    year(transaction_date) as TXN_YR, 
    quarter(transaction_date) AS TXN_QTR,
    month(transaction_date) AS TXN_MNTH,
    count(distinct customer_id) as total_customer,
    count(transaction_id) as total_txns,
    sum(units_sold) as total_units_sold,
    round(SUM(sales_amount),0) AS total_rev,
    round(AVG(sales_amount),0) AS avg_rev,
    round(sum(units_sold)/count(transaction_id),0) as UPT,
    round(count(transaction_id)/ count(distinct customer_id),0) as TPC
     
FROM sales_data
GROUP BY region, year(transaction_date),quarter(transaction_date),month(transaction_date)
having UPT > 1
ORDER BY region, year(transaction_date),quarter(transaction_date),month(transaction_date);
    
--GROUP BY: Aggregates revenue data by region, year, and month to calculate monthly totals for each region.
--ORDER BY: Orders the result set by region, year, and month to visualize trends over time.

-- Use Case 3: Customer Lifetime Value (CLTV) Calculation
-- Scenario: You are working with customer transaction data over the last 4 years, with columns like customer_id, transaction_amount, transaction_date, and region.

-- Objective: Calculate the total value of each customer’s transactions over 4 years and filter for customers whose lifetime value is greater than $10,000.

SELECT 
    customer_id, 
    SUM(SALES_AMOUNT) AS lifetime_value
FROM 
    sales_data
GROUP BY 
    customer_id
HAVING 
    SUM(SALES_AMOUNT) > 10000
ORDER BY 
    lifetime_value DESC;
    
--GROUP BY: Groups data by customer_id to calculate total transaction amounts for each customer.
--HAVING: Filters customers whose lifetime transaction value exceeds $10,000.
---ORDER BY: Sorts customers by their lifetime value in descending order.

--Use Case 4: Product Inventory Turnover
--Scenario: You have inventory data with columns like product_id, month, year, units_sold, and units_in_stock.
--Objective: Identify products that have sold more than 1,000 units in any given month and order them by sales volume.

SELECT 
    product_id, 
    year(transaction_date) as TXN_YR, 
    month(transaction_date) AS TXN_MNTH,  
    SUM(units_sold) AS total_units_sold
FROM 
    SALES_DATA
GROUP BY 
    product_id,
    year(transaction_date),
    month(transaction_date)
HAVING 
    SUM(units_sold) > 10
ORDER BY 
    total_units_sold DESC;
    
--GROUP BY: Groups data by product_id, year, and month to calculate total units sold per product per month.
--HAVING: Filters products with sales greater than 1,000 units in any month.
--ORDER BY: Sorts products by sales volume, starting with the highest-selling products.
