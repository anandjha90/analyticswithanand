-- Assigning the role for the account 
USE ROLE ACCOUNTADMIN;


-- Assigning the warehouse to the account 
USE WAREHOUSE COMPUTE_WH;

-- Creating a database named as SALES_DATABASE
CREATE DATABASE IF NOT EXISTS SQL_CLASS_8;

-- CREATING a schema for the SALES_DATABASE 
CREATE SCHEMA IF NOT EXISTS SQL_CLASS_8_SCHEMA;

-- USING THE DATABASE CREATED SALES_DATABASE 
USE DATABASE SQL_CLASS_8;

-- USING THE SCHEMA CREATED SALES_SCHEMA
USE SCHEMA SQL_CLASS_8_SCHEMA;

-- CREATING A TABLE FOR THE SESSION
CREATE TABLE SALES_TRANSACTIONS (
    TRANSACTION_ID INT PRIMARY KEY,
    CATEGORY VARCHAR(50),
    SUBCATEGORY VARCHAR(50),
    TRANSACTION_DATE DATE,
    DELIVERY_DATE DATE,
    QUANTITY INT,
    UNIT_PRICE DECIMAL(10, 2),
    TOTAL_SALE DECIMAL(15, 2)
);


-- INSERTING VALUES INTO THE SALES_TRANSACTION TABLE 
INSERT INTO SALES_TRANSACTIONS (TRANSACTION_ID, CATEGORY, SUBCATEGORY, TRANSACTION_DATE, DELIVERY_DATE, QUANTITY, UNIT_PRICE, TOTAL_SALE)
VALUES
(1, 'Electronics', 'Mobile', '2025-01-01', '2025-01-05', 2, 400.00, 800.00),
(2, 'Electronics', 'Laptop', '2025-01-03', '2025-01-10', 1, 1200.00, 1200.00),
(3, 'Home Appliances', 'Refrigerator', '2025-01-05', '2025-01-12', 1, 1500.00, 1500.00),
(4, 'Home Appliances', 'Washing Machine', '2025-01-07', '2025-01-15', 1, 800.00, 800.00),
(5, 'Furniture', 'Sofa', '2025-01-09', '2025-01-18', 1, 2000.00, 2000.00),
(6, 'Furniture', 'Dining Table', '2025-01-11', '2025-01-20', 1, 1500.00, 1500.00),
(7, 'Electronics', 'Mobile', '2025-01-13', '2025-01-20', 3, 350.00, 1050.00),
(8, 'Home Appliances', 'Microwave', '2025-01-15', '2025-01-22', 2, 250.00, 500.00),
(9, 'Furniture', 'Chair', '2025-01-17', '2025-01-24', 4, 150.00, 600.00),
(10, 'Electronics', 'Tablet', '2025-01-19', '2025-01-27', 2, 300.00, 600.00),
(11, 'Electronics', 'Headphones', '2025-01-21', '2025-01-28', 5, 100.00, 500.00),
(12, 'Electronics', 'Smartwatch', '2025-01-22', '2025-01-29', 2, 150.00, 300.00),
(13, 'Home Appliances', 'Air Conditioner', '2025-01-23', '2025-01-30', 1, 1200.00, 1200.00),
(14, 'Home Appliances', 'Vacuum Cleaner', '2025-01-24', '2025-01-31', 2, 300.00, 600.00),
(15, 'Furniture', 'Bookshelf', '2025-01-25', '2025-02-01', 1, 700.00, 700.00),
(16, 'Furniture', 'Bed', '2025-01-26', '2025-02-03', 1, 2500.00, 2500.00),
(17, 'Electronics', 'Mobile', '2025-01-27', '2025-02-04', 4, 380.00, 1520.00),
(18, 'Home Appliances', 'Refrigerator', '2025-01-28', '2025-02-05', 1, 1400.00, 1400.00),
(19, 'Furniture', 'Wardrobe', '2025-01-29', '2025-02-06', 1, 1800.00, 1800.00),
(20, 'Electronics', 'Smart TV', '2025-01-30', '2025-02-07', 1, 900.00, 900.00),
(21, 'Electronics', 'Mobile', '2025-01-31', '2025-02-08', 3, 400.00, 1200.00),
(22, 'Furniture', 'Couch', '2025-02-01', '2025-02-09', 2, 2200.00, 4400.00),
(23, 'Home Appliances', 'Washing Machine', '2025-02-02', '2025-02-10', 1, 850.00, 850.00),
(24, 'Home Appliances', 'Dishwasher', '2025-02-03', '2025-02-11', 1, 950.00, 950.00),
(25, 'Electronics', 'Camera', '2025-02-04', '2025-02-12', 1, 650.00, 650.00);


/*
    You are given the sales data of our company. Your job is to analyse the data and return us the analysis. 
    The first requirement is to, write a sql query to return us all the data that is just related to 'Furniture' and 'Home Appliances'.
    After returning that particular data we need to see the data where the transaction date is after '2025-01-15'.
    Return the result in desc order of total sales amount and categories. 
    Note that we need all the columns in the result. 
*/
SELECT *
FROM SALES_TRANSACTIONS
WHERE
    CATEGORY IN ('Furniture', 'Home Appliances')
    AND
    TRANSACTION_DATE > '2025-01-15'
ORDER BY TOTAL_SALE DESC, CATEGORY DESC
LIMIT 1;



-- AGGREGATE FUNCTIONS 
SELECT
    SUM(TOTAL_SALE) AS TOTAL_SALES_AMOUNT
FROM SALES_TRANSACTIONS;

SELECT
    COUNT(TRANSACTION_ID) AS TOTAL_ORDERS
FROM SALES_TRANSACTIONS;

-- WRITE A SQL QUERY TO FIND THE MINIMUM UNIT SOLD IN THE SALES DATA
SELECT
    MIN(QUANTITY) AS MINIMUM_QUANITY_SOLD
FROM SALES_TRANSACTIONS;

SELECT
    MAX(QUANTITY) AS MAX_QTY_SOLD
FROM SALES_TRANSACTIONS;

SELECT ROUND(AVG(TOTAL_SALE),2) AS TOTAL_SALES_AVG
FROM SALES_TRANSACTIONS;

-- GROUP BY
SELECT SUM(TOTAL_SALE)
FROM SALES_TRANSACTIONS;

SELECT 
    CATEGORY,
    SUM(TOTAL_SALE) AS TOTAL_SALES_AMOUNT
FROM SALES_TRANSACTIONS
GROUP BY CATEGORY;




-- Advancing the aggregate functions
-- QUERY 1
/*
    You are given the sales data of our company. We have business across multiple categories. We want to see the sum of total sale value 
    across each category. Give us the category which has highest sale at the top and then at the least one at the bottom.
*/
SELECT
    CATEGORY,
    SUM(total_sale) as total_Sale_value
FROM SALES_TRANSACTIONS
GROUP BY CATEGORY
ORDER BY SUM(TOTAL_SALE) DESC;






-- QUERY 2
/*
    Find the total quantity of products sold in each subcategory where the total sale amount is greater than $500.
    You need to return the result in the order of ascending of quantity sold.
*/
SELECT
    CATEGORY,
    SUBCATEGORY, 
    SUM(QUANTITY) AS TOTAL_QUANTITY 
FROM SALES_TRANSACTIONS 
WHERE TOTAL_SALE > 500
GROUP BY CATEGORY, SUBCATEGORY;








-- QUERY 3
/*
    Find the average sale price for each category, and display the results in descending order of the average sale price.
*/
SELECT
    CATEGORY,
    SUBCATEGORY,
    ROUND(AVG(TOTAL_SALE),2) AS AVG_SALE
FROM SALES_TRANSACTIONS
GROUP BY CATEGORY, SUBCATEGORY
ORDER BY AVG(TOTAL_SALE) DESC;








-- QUERY 4
/*
    Write a SQL query to return the maximum and the minimum sale from each subcategory. 
*/
SELECT 
    SUBCATEGORY,
    MIN(TOTAL_SALE) AS LOWEST_SALE,
    MAX(TOTAL_SALE) AS HIGHEST_SALE
FROM SALES_TRANSACTIONS
GROUP BY SUBCATEGORY
ORDER BY SUBCATEGORY;








-- QUERY 5
/*
    You are given the sales data of our company. We need to analyse the time series data of the sales.
    Count the number of transactions for each subcategory where the transaction date is after '2025-01-10'.
    You need to return the result of only subcategories where the total transaction count is greater than 1. 
    Return the result by sorting it in asc order of subcategories. 
*/
SELECT
    SUBCATEGORY,
    COUNT(TRANSACTION_ID) AS TOTAL_TRANSACTIONS
FROM SALES_TRANSACTIONS
WHERE TRANSACTION_DATE > '2025-01-10'
GROUP BY SUBCATEGORY
HAVING TOTAL_TRANSACTIONS > 1
ORDER BY SUBCATEGORY ASC;






-- QUERY 6
/*
    Write a query to calculate the total sales for each category, subcategory from the SALES_TRANSACTIONS table. 
    Also, make sure to include only those transactions where the TRANSACTION_DATE is after January 1, 2025, 
    and the total sales are greater than 1000. 
    Additionally, the result should be ordered by the total sales in descending order.
    But our main interest is to see the leading category, subcategory only.
*/
SELECT
    CATEGORY,
    SUBCATEGORY,
    SUM(TOTAL_SALE) AS TOTAL_SALE_AMOUNT
FROM SALES_TRANSACTIONS
WHERE TRANSACTION_DATE > '2025-01-01'
GROUP BY CATEGORY, SUBCATEGORY
HAVING SUM(TOTAL_SALE) > 1000
ORDER BY SUM(TOTAL_SALE) ASC;




-- QUERY 7
/*
    Write a query to find the average unit price (AVG(UNIT_PRICE)) of products for each subcategory, 
    but only for categories 'Electronics' and 'Furniture'. Include only those transactions where the 
    quantity is greater than 1, and sort the result by subcategory name in alphabetical order.
*/
SELECT
    SUBCATEGORY,
    QUANTITY,
    ROUND(AVG(UNIT_PRICE), 2) AS AVG_UNIT_PRICE
FROM SALES_TRANSACTIONS
WHERE
    CATEGORY IN ('Electronics', 'Furniture')
    AND
    QUANTITY > 1
    AND
    SUBCATEGORY = 'Mobile'
GROUP BY SUBCATEGORY, QUANTITY
ORDER BY SUBCATEGORY ASC;


SELECT * FROM SALES_TRANSACTIONS
WHERE SUBCATEGORY = 'Mobile'
order by quantity;





-- QUERY 8
/*
    Write a query to get the total sales (SUM(TOTAL_SALE)) for each category for transactions that 
    occurred between January 5, 2025, and January 15, 2025. Ensure the results are displayed in 
    ascending order of total sales.
*/






