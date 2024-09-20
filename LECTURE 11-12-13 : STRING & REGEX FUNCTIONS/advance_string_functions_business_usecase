CREATE OR REPLACE FILE FORMAT my_csv_format
TYPE = 'CSV'
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
SKIP_HEADER = 1
FIELD_DELIMITER = ','
NULL_IF = ('\\N', 'NULL', '')
EMPTY_FIELD_AS_NULL = TRUE;


CREATE OR REPLACE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255)
);

INSERT INTO customers (customer_id, first_name, last_name, email)
VALUES 
(1001, NULL, 'Jha', 'anand.jha@gmail.com'),
(1002, 'Sameer',NULL, 'sameer_sahoo@yahoo.com'),
(1003, 'Sachin', NULL, 'sachin.oconnor@outlook.com');

INSERT INTO customers (customer_id, first_name, last_name, email)
VALUES 
(1004, 'Hemanth', 'Kulkarni', NULL),
(1005, 'Mayank', 'Agarwal', NULL);

delete from customers 
where last_name = 'Jha' OR first_name IN ('Sameer','Sachin');

CREATE OR REPLACE TABLE products (
    product_id INT PRIMARY KEY,
    product_sku VARCHAR(50),
    product_name VARCHAR(255)
);

INSERT INTO products (product_id, product_sku, product_name)
VALUES
(1101, 'MFGH-1234-Z-9876',NULL),
(1102, 'XYZG-5678-A-1234',NULL ),
(1103, 'TUMN-3456-C-4321',NULL );

SELECT * FROM products;

CREATE OR REPLACE TABLE customer_contact (
    customer_id INT PRIMARY KEY,
    phone_number VARCHAR(50)
);

INSERT INTO customer_contact (customer_id)
VALUES
(1001),
(1002),
(1003);

SELECT * FROM customer_contact;

CREATE OR REPLACE TABLE web_traffic (
    visit_id INT PRIMARY KEY,
    website_url VARCHAR(500)
);

INSERT INTO web_traffic (visit_id)
VALUES
(1001),
(1002),
(1003);

SELECT * FROM web_traffic;

CREATE OR REPLACE TABLE feedback (
    feedback_id INT PRIMARY KEY,
    customer_id INT,
    feedback_text VARCHAR(1000)
);

INSERT INTO feedback (feedback_id, customer_id)
VALUES
(1001, 346),
(1002, 592),
(1003, 876);

select * from customers;
select * from products;
select * from customer_contact;
select * from web_traffic;
select * from feedback;

-- Goal: Standardize names to Title Case.
-- Table: customers (customer_id, first_name, last_name, email)

-- 1. Standardizing names: Capitalize first letter, lowercase the rest
SELECT 
    INITCAP(first_name) AS standardized_first_name,
    INITCAP(last_name) AS standardized_last_name
FROM customers;

-- 2. Extract email domain
SELECT 
    email,
    SPLIT_PART(email, '@', 1) AS email_username,
    SPLIT_PART(email, '@', -1) AS email_domain
FROM customers;

-- 3. Concatenate full name
SELECT 
    INITCAP(first_name) AS standardized_first_name,
    INITCAP(last_name) AS standardized_last_name,
    CONCAT(first_name, ' ', last_name) AS full_name
FROM customers;

-- 4. Replace common typos in emails (e.g., 'gamil' -> 'gmail')
SELECT 
    REPLACE(email, 'gamil', 'gmail') AS corrected_email
FROM customers;

-- 5. Padding customer ID with leading zeros (useful for reporting)
SELECT 
    CUSTOMER_ID,
    LPAD(CAST(customer_id AS VARCHAR), 5, '*') AS left_padded_customer_id,
    RPAD(CAST(customer_id AS VARCHAR), 6, '0') AS right_padded_customer_id
FROM customers;


-- Table: products (product_id, product_sku, product_name)

-- 1. Extracting category from product SKU (e.g., 'ELEC-1234-B-9876' -> 'ELEC')
-- 2. Extracting numeric part from product SKU (e.g., 'ELEC-1234-B-9876' -> '1234')

SELECT 
    product_sku,
    SPLIT_PART(product_sku, '-', 1) AS product_category_name_just_before_separator,
    SPLIT_PART(product_sku, '-', 2) AS product_category_code_just_after_separator,
    SPLIT_PART(product_sku, '-', 3) AS product_category_layer,
    SPLIT_PART(product_sku, '-', 4) AS product_category_auth_code,
    -- 3. Substring product SKU to extract specific positions
    SUBSTRING(product_sku, 8, 4) AS sku_numeric_part_invalid, -- don't use in this case as PRODUCT_SKU is not unifirm before -
    SUBSTRING(product_sku, -4, 4) AS sku_numeric_part_valid -- rather use this
FROM products;


-- 4. Upper-casing all product names (standardization)
SELECT
    product_name,
    INITCAP(product_name) AS standardized_product_name,
    LOWER(product_name) AS lowercased_product_name,
    UPPER(product_name) AS uppercased_product_name
FROM products;

-- 5. Searching for products by category (e.g., all 'TOOL' category products)
SELECT *
FROM products
WHERE POSITION('TOOL', product_sku) > 0;


-- Table: customer_contact (customer_id, phone_number)

-- 1. Removing special characters (e.g., '-', '(', ')') from phone numbers
SELECT *,
    REPLACE(REPLACE(REPLACE(phone_number, '-', ''), '(', ''), ')', '') AS clean_phone_number
FROM customer_contact;

-- 2. Extracting area code from phone numbers (e.g., '(987) 654-3210' -> '987')
SELECT * FROM customer_contact
WHERE phone_number LIKE '(%';

SELECT *,
    REPLACE(REPLACE(REPLACE(phone_number, '-', ''), '(', ''), ')', '') AS clean_phone_number,
    SUBSTRING(REPLACE(REPLACE(REPLACE(phone_number, '-', ''), '(', ''), ')', ''),1,3) AS area_code
FROM customer_contact;;

-- 3. Padding short phone numbers (e.g., '123456' -> '00000123456')
SELECT *,
    LPAD(REPLACE(phone_number, '-', ''), 10, '0') AS padded_phone_number
FROM customer_contact;

-- 4. Validating if phone number contains only digits (no letters) -- will be discussed later stage
SELECT 
    phone_number,
    CASE 
        WHEN REGEXP_LIKE(phone_number, '^[0-9]+$') THEN 'Valid'
        ELSE 'Invalid'
    END AS phone_validation
FROM customer_contact;

-- Table: web_traffic (visit_id, website_url)

-- 1. Removing 'http://' or 'https://' from URLs
SELECT 
    website_url,
    REPLACE(REPLACE(website_url, 'http://', ''), 'https://', '') AS clean_url
FROM web_traffic;

-- 2. Extracting domain from the URL (e.g., 'http://www.example.com' -> 'www.example.com')
SELECT 
   website_url,
    SPLIT_PART(website_url, '/', 3) AS domain
FROM web_traffic;

-- 3. Standardizing all URLs to lowercase
SELECT 
    LOWER(website_url) AS lowercased_url
FROM web_traffic;

-- 4. Checking if the URL contains a specific domain (e.g., 'example.com')
SELECT 
    website_url,
    POSITION('oliver.com', website_url) > 0 AS is_example_domain
FROM web_traffic;

-- 5. Extracting URL path (after the domain)
SELECT 
    website_url,
    SPLIT_PART(website_url, '/', 3) AS url_path
FROM web_traffic
WHERE POSITION('/', website_url) > 0;

-- Table: feedback (feedback_id, customer_id, feedback_text)

-- 1. Finding negative feedback by searching for keywords (e.g., 'bad', 'poor')
SELECT 
    feedback_id,
    feedback_text,
    CASE 
        WHEN POSITION('bad', LOWER(feedback_text)) > 0 OR POSITION('poor', LOWER(feedback_text)) > 0 THEN 'Negative'
        ELSE 'Neutral/Positive'
    END AS sentiment
FROM feedback;

-- 2. Counting the number of words in feedback (e.g., useful for text length analysis)
SELECT 
    feedback_id,
    feedback_text,
    SPLIT(feedback_text, ' ') as splitted_words,
    ARRAY_SIZE(SPLIT(feedback_text, ' ')) AS word_count
FROM feedback;

-- 3. Trimming extra spaces from feedback text
SELECT 
    TRIM(feedback_text) AS trimmed_feedback
FROM feedback;

-- 4. Replacing specific words in feedback (e.g., 'bad' -> 'poor')
SELECT 
    feedback_text,
    REPLACE(LOWER(feedback_text), 'bad', 'poor') AS updated_feedback
FROM feedback;

-- 5. Extracting first sentence from feedback (useful in summaries)
SELECT 
    feedback_text,
    SPLIT_PART(feedback_text, ',', 1) AS first_part_feedback,
    SPLIT_PART(feedback_text, ',', 2) AS second_part_feedback
FROM feedback;

-- Difference Between IFNULL() and COALESCE()
-- IFNULL(expr1, expr2): Checks the first expression (expr1). If it is NULL, it returns the second expression (expr2). It only takes two arguments.
-- COALESCE(expr1, expr2, ..., exprN): Evaluates multiple expressions and returns the first non-NULL value from the list. It can take multiple arguments, making it more ---------- flexible than IFNULL().

-- Table: customers (customer_id, first_name, last_name, email)

-- 1. Use IFNULL to handle missing first or last names
SELECT 
    customer_id,
    IFNULL(first_name, 'Unknown') AS first_name,
    IFNULL(last_name, 'Customer') AS last_name
FROM customers;

-- 2. Use COALESCE to combine first and last names, with defaults if either is NULL
SELECT 
    customer_id,
    COALESCE(first_name, 'Unknown') || ' ' || COALESCE(last_name, 'Customer') AS full_name
FROM customers;

-- 3. Use IFNULL to handle missing emails and set a default
SELECT 
    customer_id,
    IFNULL(email, 'noemail@example.com') AS email_address
FROM customers;

-- Table: products (product_id, product_sku, product_name)

-- 1. Use IFNULL to replace missing product names with 'No Name Available'
SELECT 
    product_id,
    product_sku,
    IFNULL(product_name, 'No Name Available') AS product_name
FROM products;

-- 2. Use COALESCE to handle product names and add a suffix for missing values
SELECT 
    product_id,
    product_sku,
    COALESCE(product_name, 'Unnamed Product') || ' (TBD)' AS product_display_name
FROM products
WHERE product_name IS NULL ;

-- Table: customer_contact (customer_id, phone_number)

-- 1. Use IFNULL to replace missing phone numbers with a default placeholder
SELECT 
    customer_id,
    IFNULL(phone_number, 'Not Provided') AS contact_number
FROM customer_contact;

-- 2. Use COALESCE to replace missing phone numbers and add a country code
SELECT 
    customer_id,
    COALESCE(phone_number, '+91-000-000-0000') AS validated_phone_number
FROM customer_contact;

-- Table: web_traffic (visit_id, website_url)

-- 1. Use IFNULL to replace missing URLs with a default homepage URL
SELECT 
    visit_id,
    IFNULL(website_url, 'http://default-homepage.com') AS validated_url
FROM web_traffic;

-- 2. Use COALESCE to replace missing URLs and log whether it's missing or not
SELECT 
    visit_id,
    COALESCE(website_url, 'http://unknown.com') AS url,
    CASE 
        WHEN website_url IS NULL THEN 'Missing URL' 
        ELSE 'Valid URL'
    END AS url_status
FROM web_traffic;


-- Table: feedback (feedback_id, customer_id, feedback_text)

-- 1. Use IFNULL to replace missing feedback with a default "No Feedback" message
SELECT 
    feedback_id,
    customer_id,
    IFNULL(feedback_text, 'No Feedback Provided') AS feedback_message
FROM feedback;

-- 2. Use COALESCE to combine multiple fields: feedback and default message if missing
SELECT 
    feedback_id,
    customer_id,
    COALESCE(feedback_text, 'Feedback not submitted yet') AS customer_feedback
FROM feedback;

/*
General Use Case: Combining IFNULL() and COALESCE() in Business Logic
Scenario: Prioritizing Multiple Fields for Customer Information
Problem: You may need to extract customer contact information from multiple sources (phone, email, etc.).
Solution: Use COALESCE() to prioritize which field to use for contacting the customer (e.g., phone first, email second).
*/
-- Table: customers (customer_id, email)
-- Table: customer_contact (customer_id, phone_number)

-- Prioritize contact info: use phone if available, otherwise use email
SELECT 
    c.customer_id,
    cc.phone_number,
    c.emaiL,
    COALESCE(cc.phone_number, c.email, 'No Contact Info Available') AS preferred_contact_method
FROM customers c
LEFT JOIN customer_contact cc
ON c.customer_id = cc.customer_id;

CREATE OR REPLACE TABLE sales (
    sale_id INT AUTOINCREMENT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    sale_amount DECIMAL(10, 2),
    sales_date DATE
);

CREATE OR REPLACE TABLE sales_string (
    sale_id INT AUTOINCREMENT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    sale_amount DECIMAL(10, 2),
    sales_date_string STRING
);

CREATE OR REPLACE TABLE sales_data (
    sale_id INT,
    sale_date DATE,
    product_name VARCHAR,
    sale_amount DECIMAL(10, 2),
    customer_id INT
);

/*
Let’s consider a business use case where we need to analyze sales trends over the years, extract year and month from the sale date,
and present the total sales amount for each month formatted in a user-friendly way.
*/
SELECT TO_CHAR(TO_DATE('2024-09-21', 'YYYY-MM-DD'), 'YYYYMMDD') AS DATE_AS_CHAR;
SELECT TO_CHAR(TO_DATE('2024-09-21', 'YYYY-MM-DD'), 'YYYY') AS DATE_YEAR;
SELECT TO_CHAR(TO_DATE('2024-09-21', 'YYYY-MM-DD'), 'YYYY-MM') AS DATE_YEAR_MON;
SELECT TO_CHAR(TO_DATE('2024-09-21', 'YYYY-MM-DD'), 'Mon') AS DATE_AS_MONTH;
SELECT TO_NUMBER(TO_CHAR(TO_DATE('9999-12-31', 'YYYY-MM-DD'), 'YYYYMMDD')) AS date_as_integer;

SELECT 
    TO_CHAR(sales_date, 'YYYY-MM') AS sale_month,   -- Format the date as Year-Month
    SUM(sale_amount) AS total_sales,               -- Calculate total sales amount for the month
    COUNT(sale_id) AS total_transactions           -- Count the number of transactions
FROM sales
WHERE sales_date >= TO_DATE(DATEADD(YEAR, -3, CURRENT_DATE())) -- Filter for the last 3 years
GROUP BY sale_month
ORDER BY sale_month;

CREATE OR REPLACE TABLE orders_details (
    order_id INT PRIMARY KEY,
    order_date DATE,
    customer_id VARCHAR(50),
    order_amount DECIMAL(10, 2)
);

/*
Business Use Case
Consider a retail business that wants to analyze sales trends over the last three years. 
They want to categorize orders by year and month, compute total sales, and display the results in a more readable format.
*/

SELECT TO_CHAR(order_date, 'YYYY') AS sales_year FROM orders_details;
SELECT TO_CHAR(order_date, 'YYYY-MM') AS sales_year_mm FROM orders_details;
SELECT TO_CHAR(order_date, 'YYYY-MON') AS sales_year_month FROM orders_details;

SELECT 
    TO_CHAR(order_date, 'YYYY') AS sales_year,
    TO_CHAR(order_date, 'MM') AS sales_month,
    TO_CHAR(order_date, 'Mon') AS sales_month_name,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(order_amount),0) AS total_sales_rs,
    ROUND(AVG(order_amount),0) AS average_order_value_rs
FROM orders_details
WHERE order_date >= TO_DATE('2021-01-01', 'YYYY-MM-DD')
GROUP BY 1,2,3
ORDER BY 1,2,3;


/*
TO_DATE() Function Use Case
Use Case:
The company has inconsistent date formats across different systems. 
Some dates are stored as strings like '2022/05/03' or '05-03-2022', and they need to standardize these into proper DATE data type.
*/
-- Convert a string date to a DATE format (YYYY-MM-DD)
SELECT 
    sale_id,
    TO_CHAR(SALES_DATE, 'YYYY/MM/DD') AS sales_date
FROM sales;

-- Handling inconsistent date formats by trying multiple formats
SELECT 
    sale_id,
    CASE
        WHEN TRY_TO_DATE(sales_date_string, 'YYYY-MM-DD') IS NOT NULL THEN TO_DATE(sales_date_string, 'YYYY-MM-DD')
        WHEN TRY_TO_DATE(sales_date_string, 'MM-DD-YYYY') IS NOT NULL THEN TO_DATE(sales_date_string, 'MM-DD-YYYY')
        ELSE NULL
    END AS standardized_date
FROM sales_string;

/*
TO_CHAR() Function Use Case
Use Case:
For a business dashboard, the company needs to display sales dates in a more readable format, such as "15th April, 2021". The TO_CHAR() function is used to format dates as strings.
*/

-- Convert date to string with custom formatting (e.g., '15th April, 2021')
SELECT
    sale_id,
    sales_date,
    TO_CHAR(sales_date, 'DDth Month, YYYY') AS formatted_sales_date
FROM sales;

/*
TO_VARCHAR() Function Use Case
Use Case:
The company needs to group sales by month and year for monthly reporting, but some sales dates are stored as VARCHAR. 
The TO_VARCHAR() function is used to extract the year and month from these string-formatted dates.
*/

-- Convert date to string and extract year and month
SELECT
    sale_id,
    TO_VARCHAR(sales_date, 'YYYY-MM') AS sales_year_month
FROM sales;

-- Group sales by year and month (for reporting)
SELECT 
    TO_VARCHAR(sales_date, 'YYYY-MM') AS sales_year_month,
    COUNT(*) AS total_sales,
    SUM(sale_amount) AS total_revenue
FROM sales
GROUP BY TO_VARCHAR(sales_date, 'YYYY-MM')
ORDER BY sales_year_month;

/*
Complex Business Use Case with SQL Query
Scenario: Year-over-Year Sales Growth Analysis
The business wants to calculate year-over-year (YoY) growth in sales. 
The challenge is to standardize sales dates from inconsistent formats and then calculate the YoY percentage change.
*/

SELECT TO_DATE(SALES_DATE_STRING, 'YYYY-MM-DD') AS sales_year_month FROM SALES_STRING;

WITH standardized_sales AS (
    SELECT
        sale_id,
        sale_amount,
        -- Standardize the sales date by handling inconsistent date formats
        CASE
            WHEN TRY_TO_DATE(sales_date_string, 'YYYY-MM-DD') IS NOT NULL THEN TO_DATE(sales_date_string, 'YYYY-MM-DD')
            ELSE NULL
        END AS sales_date
    FROM sales_string
),
monthly_sales AS (
    SELECT
        TO_VARCHAR(sales_date, 'YYYY-MM') AS sales_year_month,
        SUM(sale_amount) AS total_sales
    FROM standardized_sales
    WHERE sales_date IS NOT NULL
    GROUP BY TO_VARCHAR(sales_date, 'YYYY-MM')
)
-- Calculate Year-over-Year percentage change in sales
SELECT
    sales_year_month,
    total_sales,
    LAG(total_sales, 12) OVER (ORDER BY sales_year_month) AS sales_last_year,
    ROUND(((total_sales - LAG(total_sales, 12) OVER (ORDER BY sales_year_month)) / LAG(total_sales, 12) OVER (ORDER BY sales_year_month)) * 100, 2
    ) AS yoy_sales_growth
FROM monthly_sales
ORDER BY sales_year_month;
