/*
To provide a comprehensive example of the GROUP BY GROUPING SETS, ROLLUP, and CUBE clauses in Snowflake, let’s structure the use case around analyzing sales data across different regions, products, and time dimensions (e.g., years, quarters). 
This example will show how these clauses help to generate summaries of the data at different levels of aggregation.

Business Use Case:
Suppose you are a sales analyst at a retail company that operates across multiple regions, offering various products. 
You want to generate reports that summarize sales data across these dimensions:

Region
Product Category
Year
Quarter

Your task is to generate:

Regional and product-level summaries (using GROUPING SETS).
Hierarchical summaries by year, quarter, and region (using ROLLUP).
Comprehensive summaries that include all combinations of region, product, and time dimensions (using CUBE).

Data Structure:
Tables:

sales – This table contains transaction-level data for the last 5 years.
regions – Contains region details.
products – Contains product details.

*/
-- Table 1: sales - This table records each sale made over the last 5 years.

CREATE OR REPLACE TABLE sales (
    sale_id INT AUTOINCREMENT,
    sale_date DATE,
    product_id INT,
    region_id INT,
    quantity_sold INT,
    sale_amount DECIMAL(10,2)
);

--Table 2: regions - This table stores information about different regions.

CREATE OR REPLACE TABLE regions (
    region_id INT PRIMARY KEY,
    region_name STRING
);

-- Table 3: products - This table stores details of the products sold.

CREATE OR REPLACE TABLE products (
    product_id INT PRIMARY KEY,
    product_category STRING,
    product_name STRING
);


-- 1. GROUPING SETS Example: Regional and Product Summaries
-- This query generates summary reports for total sales by region, product category, and product name.

SELECT 
    r.region_name,
    p.product_category,
    p.product_name,
    SUM(s.sale_amount) AS total_sales,
    SUM(s.quantity_sold) AS total_quantity
FROM sales s
JOIN regions r ON s.region_id = r.region_id
JOIN products p ON s.product_id = p.product_id
GROUP BY 1,2,3
ORDER BY 1,2,3;


SELECT 
    r.region_name,
    p.product_category,
    p.product_name,
    SUM(s.sale_amount) AS total_sales,
    SUM(s.quantity_sold) AS total_quantity
FROM sales s
JOIN regions r ON s.region_id = r.region_id
JOIN products p ON s.product_id = p.product_id
GROUP BY GROUPING SETS (
    (r.region_name, p.product_category),  -- Summarize by region and product category
    (r.region_name, p.product_name)       -- Summarize by region and product name
);

--2. ROLLUP Example: Hierarchical Summaries by Year, Quarter, and Region
-- This query aggregates data first by year, then by quarter within each year, and finally by region within each quarter.

SELECT 
    EXTRACT(YEAR FROM s.sale_date) AS sale_year,
    EXTRACT(QUARTER FROM s.sale_date) AS sale_quarter,
    r.region_name,
    SUM(s.sale_amount) AS total_sales,
    SUM(s.quantity_sold) AS total_quantity
FROM sales s
JOIN regions r ON s.region_id = r.region_id
GROUP BY ROLLUP (
    EXTRACT(YEAR FROM s.sale_date),  -- Rollup by year
    EXTRACT(QUARTER FROM s.sale_date), -- Rollup by quarter
    r.region_name -- Rollup by region within each quarter
);

-- This will return summaries for each year, each year-quarter combination, and year-quarter-region combination.

-- 3. CUBE Example: Comprehensive Summaries of Sales
-- This query generates all possible combinations of aggregation for region, product category, and year.

SELECT 
    EXTRACT(YEAR FROM s.sale_date) AS sale_year,
    r.region_name,
    p.product_category,
    SUM(s.sale_amount) AS total_sales,
    SUM(s.quantity_sold) AS total_quantity
FROM sales s
JOIN regions r ON s.region_id = r.region_id
JOIN products p ON s.product_id = p.product_id
GROUP BY CUBE (
    EXTRACT(YEAR FROM s.sale_date),   -- Cube on year
    r.region_name,                    -- Cube on region
    p.product_category                -- Cube on product category
);
-- This will provide summaries for every combination of year, region, and product category.
