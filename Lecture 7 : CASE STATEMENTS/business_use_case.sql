/*
These queries illustrate various ways to use CASE statements with aggregate functions for business intelligence and decision-making in Snowflake. 
They span classification, bucketing, segmentation, and trend analysis, all critical for optimizing operations, understanding customers, and driving sales strategies.
*/


CREATE OR REPLACE TABLE sales_csv(
    sale_id INT AUTOINCREMENT PRIMARY KEY, -- Unique identifier for each sale
    sale_date DATE,                        -- Date of the sale
    product_id INT,                        -- Foreign key referencing the products table
    region_id INT,                         -- Foreign key referencing the regions table
    customer_id INT,                       -- Unique identifier for the customer
    quantity_sold INT,                     -- Quantity of products sold in the sale
    sale_amount DECIMAL(10, 2)             -- Total amount of the sale in currency
);



CREATE OR REPLACE TABLE products_csv (
    product_id INT AUTOINCREMENT PRIMARY KEY, -- Unique identifier for each product
    product_name VARCHAR(255),                -- Name of the product
    product_category VARCHAR(100)             -- Category of the product (e.g., Electronics)
);


CREATE OR REPLACE TABLE regions_csv (
    region_id INT AUTOINCREMENT PRIMARY KEY, -- Unique identifier for each region
    region_name VARCHAR(100)                 -- Name of the region (e.g., North America)
);


--Use Case 1: Classifying High, Medium, and Low Sales with CASE and Aggregate Functions
--You need to classify products into high, medium, and low sales tiers based on their total sales over the last 5 years.

-- Query: Sales Tiers Classification Using CASE
-- This query aggregates the sales amount for each product and classifies them into three sales categories based on thresholds.

SELECT
    p.product_name,
    p.product_category,
    SUM(s.sale_amount) AS total_sales,
    CASE 
        WHEN SUM(s.sale_amount) >= 50000 THEN 'High Sales'
        WHEN SUM(s.sale_amount) BETWEEN 20000 AND 49999 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM sales s
JOIN products p ON s.product_id = p.product_id
WHERE EXTRACT(YEAR FROM s.sale_date) >= YEAR(CURRENT_DATE) - 5
GROUP BY p.product_name, p.product_category
ORDER BY total_sales DESC;

-- This classifies products into sales categories:

-- High Sales: Total sales ≥ $50,000.
-- Medium Sales: Total sales between $20,000 and $49,999.
-- Low Sales: Total sales < $20,000.

--Use Case 2: Bucketing Transactions by Purchase Amount
-- You want to bucket transactions based on the sale_amount into ranges (e.g., low-value, mid-value, and high-value transactions) to understand customer purchasing behavior.

-- Query: Transaction Bucketing Using CASE
-- This query classifies individual sales transactions into different buckets.

SELECT
    s.sale_id,
    s.sale_date,
    s.sale_amount,
    CASE
        WHEN s.sale_amount >= 300 THEN 'High-Value Transaction'
        WHEN s.sale_amount BETWEEN 100 AND 299 THEN 'Mid-Value Transaction'
        ELSE 'Low-Value Transaction'
    END AS transaction_bucket
FROM sales s
WHERE EXTRACT(YEAR FROM s.sale_date) >= YEAR(CURRENT_DATE) - 5
ORDER BY s.sale_amount DESC;

--The CASE statement buckets transactions as:
-- High-Value Transaction: Sale amount ≥ $300.
-- Mid-Value Transaction: Sale amount between $100 and $299.
-- Low-Value Transaction: Sale amount < $100.

-- Use Case 3: Calculating Conversion Rate by Region Using CASE
-- You want to calculate the conversion rate (the number of sales with a positive quantity vs. total transactions) for each region. The goal is to analyze which 
-- regions are performing better.

-- Query: Conversion Rate Calculation Using CASE
-- This query calculates the conversion rate for each region, where a "conversion" is defined as a sale with a quantity greater than 0.


SELECT
    r.region_name,
    COUNT(CASE WHEN s.quantity_sold > 0 THEN 1 END) AS converted_sales,
    COUNT(*) AS total_sales,
    ROUND(COUNT(CASE WHEN s.quantity_sold > 0 THEN 1 END) / COUNT(*) * 100, 2) AS conversion_rate
FROM sales s
JOIN regions r ON s.region_id = r.region_id
WHERE EXTRACT(YEAR FROM s.sale_date) >= YEAR(CURRENT_DATE) - 5
GROUP BY r.region_name
ORDER BY conversion_rate DESC;

--The CASE statement counts the number of converted sales where quantity_sold > 0, and the conversion rate is the ratio of converted sales to total transactions.

-- Use Case 4: Customer Loyalty Classification Using Transaction Counts
-- You want to classify customers into loyalty tiers based on the number of transactions they've made in the last 5 years. 
-- You’ll use the transaction counts to segment customers into three loyalty tiers.

-- Query: Loyalty Classification Using Transaction Counts and CASE
-- This query classifies customers into different loyalty tiers based on their transaction frequency.

SELECT
    s.customer_id,
    COUNT(s.sale_id) AS transaction_count,
    CASE 
        WHEN COUNT(s.sale_id) >= 50 THEN 'Platinum'
        WHEN COUNT(s.sale_id) BETWEEN 20 AND 49 THEN 'Gold'
        ELSE 'Silver'
    END AS loyalty_tier
FROM sales s
WHERE EXTRACT(YEAR FROM s.sale_date) >= YEAR(CURRENT_DATE) - 5
GROUP BY s.customer_id
ORDER BY transaction_count DESC;

-- Customers are classified into:

-- Platinum: 50 or more transactions.
-- Gold: 20–49 transactions.
-- Silver: Less than 20 transactions.

-- Use Case 5: Identifying Seasonal Sales Trends Using CASE
-- You want to classify sales transactions into seasonal categories (e.g., Spring, Summer, Fall, Winter) based on the sale date and analyze total sales per season.

-- Query: Seasonal Sales Classification Using CASE
-- This query uses the CASE statement to classify transactions into seasons based on the sale date and aggregates the sales for each season.

SELECT
    CASE
        WHEN EXTRACT(MONTH FROM s.sale_date) IN (3, 4, 5) THEN 'Spring'
        WHEN EXTRACT(MONTH FROM s.sale_date) IN (6, 7, 8) THEN 'Summer'
        WHEN EXTRACT(MONTH FROM s.sale_date) IN (9, 10, 11) THEN 'Fall'
        ELSE 'Winter'
    END AS season,
    SUM(s.sale_amount) AS total_sales,
    COUNT(s.sale_id) AS total_transactions
FROM sales s
WHERE EXTRACT(YEAR FROM s.sale_date) >= YEAR(CURRENT_DATE) - 5
GROUP BY season    
ORDER BY total_sales DESC;

/* This aggregates sales for each season:
Spring: March, April, May.
Summer: June, July, August.
Fall: September, October, November.
Winter: December, January, February.
*/

-- Use Case 6: Detecting Sales Outliers Using CASE
-- You need to identify outliers in the sales data where the sale_amount is significantly higher or lower than the average sale amount for a given product category.

-- Query: Outlier Detection Using CASE
-- This query uses the average sale amount for each product category and flags transactions where the sale amount is much higher or lower than the average.

SELECT
    p.product_category,
    s.sale_id,
    s.sale_amount,
    AVG(s.sale_amount) OVER (PARTITION BY p.product_category) AS avg_sale_amount,
    CASE 
        WHEN s.sale_amount >= AVG(s.sale_amount) OVER (PARTITION BY p.product_category) * 2 THEN 'High Outlier'
        WHEN s.sale_amount <= AVG(s.sale_amount) OVER (PARTITION BY p.product_category) / 2 THEN 'Low Outlier'
        ELSE 'Normal Sale'
    END AS sale_classification
FROM sales s
JOIN products p ON s.product_id = p.product_id
WHERE EXTRACT(YEAR FROM s.sale_date) >= YEAR(CURRENT_DATE) - 5
ORDER BY s.sale_amount DESC;

/*
This classifies transactions as:

High Outlier: Sale amount is more than twice the average.
Low Outlier: Sale amount is less than half the average.
Normal Sale: Sale amount is within the normal range.

*/

--Use Case 7: Customer Segmentation Based on Average Transaction Value
--You want to segment customers into high-value, medium-value, and low-value groups based on their average transaction value over the last 5 years.

--Query: Customer Segmentation Using Average Transaction Value and CASE
--This query calculates the average transaction value for each customer and segments them into different value tiers.

SELECT
    s.customer_id,
    AVG(s.sale_amount) AS avg_transaction_value,
    CASE 
        WHEN AVG(s.sale_amount) >= 300 THEN 'High-Value Customer'
        WHEN AVG(s.sale_amount) BETWEEN 100 AND 299 THEN 'Medium-Value Customer'
        ELSE 'Low-Value Customer'
    END AS customer_segment
FROM sales s
WHERE EXTRACT(YEAR FROM s.sale_date) >= YEAR(CURRENT_DATE) - 5
GROUP BY s.customer_id
ORDER BY avg_transaction_value DESC;

/*
High-Value Customer: Average transaction value ≥ $300.
Medium-Value Customer: Average transaction value between $100 and $299.
Low-Value Customer: Average transaction value < $100.
*/




