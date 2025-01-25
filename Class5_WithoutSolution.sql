-- Assigning the role for the account 
USE ROLE ACCOUNTADMIN;


-- Assigning the warehouse to the account 
USE WAREHOUSE CLASS_5_WAREHOUSE;

-- Creating a database named as SALES_DATABASE
CREATE DATABASE IF NOT EXISTS SALES_DATABASE;

-- CREATING a schema for the SALES_DATABASE 
CREATE SCHEMA IF NOT EXISTS SALES_SCHEMA;

-- USING THE DATABASE CREATED SALES_DATABASE 
USE DATABASE SALES_DATABASE;

-- USING THE SCHEMA CREATED SALES_SCHEMA
USE SCHEMA SALES_SCHEMA;

-- CREATING A SCHEMA NAMED AS AUTO_INCREMENT_SEQUENCE
CREATE SEQUENCE AUTO_INCREMENT_SEQUENCE
START WITH 1 INCREMENT BY 1;

-- CREATING A TABLE NAMED AS SALES_TABLE 
CREATE TABLE IF NOT EXISTS sales (
    sale_id INT DEFAULT AUTO_INCREMENT_SEQUENCE.NEXTVAL PRIMARY KEY NOT NULL,
    order_id VARCHAR(100) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    product_name VARCHAR(150) NOT NULL,
    product_category VARCHAR(50),
    order_city VARCHAR(50),
    order_state VARCHAR(50),
    order_country VARCHAR(50),
    sales_channel VARCHAR(50),
    payment_method VARCHAR(50),
    feedback VARCHAR(255),
    sale_amount DECIMAL(10, 2),
    discount DECIMAL(5, 2),
    order_date DATE,
    shipping_date DATE
);

-- INSERTING VALUES INTO THE TABLE WHEN AUTO_INCREMENT / SEQUENCE IS USED 
INSERT 
INTO sales 
    (
        order_id, customer_name, product_name, product_category, order_city, order_state, order_country, 
        sales_channel, payment_method, feedback, sale_amount, discount, order_date, shipping_date
    )
VALUES
('ORD-1001', '  Alice Brown', 'iPhone 13', 'Electronics  ', 'New York', 'NY', 'USA', 'Online', 'Credit Card', '****Very Satisfied****', 999.99, 5.00, '2025-01-01', '2025-01-03'),
('ORD-1002', 'Bob Smith', 'MacBook Pro', 'Electronics ', 'San Francisco', 'CA', 'USA', 'Online', 'PayPal', 'Satisfied', 1999.99, 10.00, '2025-01-02', '2025-01-04'),
('ORD-1003', 'Charlie Green', 'Samsung Galaxy S21', 'Electronics', 'Los Angeles', 'CA', 'USA', 'Retail', 'Credit Card', 'Neutral', 799.99, 7.50, '2025-01-05', '2025-01-06'),
('ORD-1004', '   David White', 'Sony TV', 'Electronics', 'Miami', 'FL', 'USA', 'Retail', 'Debit Card', '****Very Satisfied****', 599.99, 15.00, '2025-01-10', '2025-01-12'),
('ORD-1005', 'Eva Black', 'HP Laptop', 'Electronics', 'Chicago', 'IL', 'USA', 'Online', 'Credit Card', 'Satisfied', 899.99, 12.50, '2025-01-11', '2025-01-13'),
('ORD-1006', ' Frank Johnson', 'Dell Monitor', 'Electronics', 'Dallas', 'TX', 'USA', 'Retail', 'Cash', 'Neutral', 299.99, 8.00, '2025-01-13', '2025-01-15'),
('ORD-1007', 'George King', 'iPad Pro', 'Electronics', 'Austin', 'TX', 'USA', 'Online', 'Credit Card', '****Very Satisfied---*', 799.99, 5.00, '2025-01-14', '2025-01-16'),
('ORD-1008', 'Hannah Baker', 'Kindle Paperwhite', 'Electronics   ', 'Boston', 'MA', 'USA', 'Retail', 'Debit Card', 'Satisfied', 129.99, 2.50, '2025-01-15', '2025-01-17'),
('ORD-1009', ' Ian Turner', 'Google Pixel 6', 'Electronics  ', 'Seattle', 'WA', 'USA', 'Online', 'PayPal', '****Very Satisfied****', 599.99, 7.00, '2025-01-18', '2025-01-20'),
('ORD-1010', '   Jane Doe', 'Amazon Echo', 'Electronics', 'Denver', 'CO', 'USA', 'Retail', 'Cash', 'Neutral', 99.99, 3.00, '2025-01-19', '2025-01-21'),
('ORD-1011', 'Kevin Hart', 'Fitbit Charge 4', 'Electronics', 'Phoenix', 'AZ', 'USA', 'Online', 'Credit Card', 'Satisfied', 149.99, 4.00, '2025-01-20', '2025-01-22'),
('ORD-1012', 'Lily James', 'Sony PlayStation 5', 'Electronics', 'Orlando', 'FL', 'USA', 'Retail', 'Credit Card', '###Very Satisfied***', 499.99, 15.00, '2025-01-22', '2025-01-25'),
('ORD-1013', '  Michael Scott', 'Xbox Series X', 'Electronics', 'Las Vegas', 'NV', 'USA', 'Online', 'PayPal', 'Satisfied', 499.99, 10.00, '2025-01-23', '2025-01-26'),
('ORD-1014', ' Nancy Drew', 'Dell XPS 13', 'Electronics', 'Chicago', 'IL', 'USA', 'Retail', 'Debit Card', '***Very Satisfied****', 1299.99, 20.00, '2025-01-24', '2025-01-27'),
('ORD-1015', ' Oliver Queen', 'HP Spectre x360', 'Electronics ', 'San Diego', 'CA', 'USA', 'Online', 'Credit Card', 'Neutral', 1399.99, 25.00, '2025-01-25', '2025-01-28'),
('ORD-1016', 'Paula White', 'Samsung Galaxy Tab S7', 'Electronics  ', 'Los Angeles', 'CA', 'USA', 'Retail', 'Cash', 'Satisfied', 649.99, 5.00, '2025-01-26', '2025-01-29'),
('ORD-1017', 'Quincy Jones', 'Microsoft Surface Pro 7', 'Electronics ', 'Houston', 'TX', 'USA', 'Online', 'Credit Card', '***Very Satisfied***', 899.99, 10.00, '2025-01-27', '2025-01-30'),
('ORD-1018', 'Rachel Green', 'Sony WH-1000XM4', 'Electronics', 'Atlanta', 'GA', 'USA', 'Retail', 'Credit Card', 'Neutral', 349.99, 8.00, '2025-01-28', '2025-01-31'),
('ORD-1019', 'Sam Wilson', 'Apple Watch Series 7', 'Electronics', 'Miami', 'FL', 'USA', 'Online', 'PayPal', 'Satisfied', 399.99, 5.50, '2025-01-29', '2025-02-01'),
('ORD-1020', 'Tina Fey', 'Google Nest Hub', 'Electronics', 'Portland', 'OR', 'USA', 'Retail', 'Credit Card', '####Very Satisfied****', 229.99, 4.50, '2025-01-30', '2025-02-02'),
('ORD-1021', '    Uma Thurman', 'MacBook Air', 'Electronics', 'New York', 'NY', 'USA', 'Online', 'Credit Card', '*Very Satisfied****', 1099.99, 15.00, '2025-02-01', '2025-02-03'),
('ORD-1022', '  Vin Diesel', 'iPhone 13 Pro Max', 'Electronics', 'Los Angeles', 'CA', 'USA', 'Retail', 'Debit Card', 'Satisfied', 1199.99, 20.00, '2025-02-02', '2025-02-05'),
('ORD-1023', ' Will Smith', 'GoPro HERO10', 'Electronics', 'Philadelphia', 'PA', 'USA', 'Online', 'PayPal', 'Neutral', 499.99, 5.00, '2025-02-03', '2025-02-06'),
('ORD-1024', ' Xavier Dolan', 'Canon EOS R6', 'Electronics', 'San Francisco', 'CA', 'USA', 'Retail', 'Credit Card', '----Very Satisfied*#**', 2499.99, 50.00, '2025-02-04', '2025-02-07'),
('ORD-1025', 'Yara Shahidi', 'Sony Alpha A7 III', 'Electronics', 'Austin', 'TX', 'USA', 'Online', 'Debit Card', 'Satisfied', 1999.99, 25.00, '2025-02-05', '2025-02-08'),
('ORD-1026', 'Zoe Saldana', 'Apple MacBook Pro', 'Electronics', 'Boston', 'MA', 'USA', 'Retail', 'Cash', '###Very Satisfied---', 2399.99, 35.00, '2025-02-06', '2025-02-09'),
('ORD-1027', 'Andrew Garfield', 'Samsung Galaxy Buds', 'Electronics', 'Chicago', 'IL', 'USA', 'Online', 'Credit Card', 'Neutral', 149.99, 3.00, '2025-02-07', '2025-02-10'),
('ORD-1028', 'Beyoncé Knowles', 'Microsoft Surface Laptop 4', 'Electronics', 'Houston', 'TX', 'USA', 'Retail', 'Credit Card', '**Very Satisfied**', 1299.99, 20.00, '2025-02-08', '2025-02-11'),
('ORD-1029', 'Chris Evans', 'Apple AirPods Max', 'Electronics', 'Miami', 'FL', 'USA', 'Online', 'PayPal', 'Satisfied', 549.99, 10.00, '2025-02-09', '2025-02-12'),
('ORD-1030', 'Diana Ross', 'Sony Bravia 55"', 'Electronics', 'Orlando', 'FL', 'USA', 'Retail', 'Debit Card', 'Very Satisfied', 999.99, 30.00, '2025-02-10', '2025-02-13'),
('ORD-1031', 'Emma Watson', 'Dell Alienware M15', 'Electronics', 'Seattle', 'WA', 'USA', 'Online', 'Credit Card', '**Very Satisfied**', 1799.99, 40.00, '2025-02-11', '2025-02-14'),
('ORD-1032', 'Frank Ocean', 'HP Omen 15', 'Electronics', 'San Diego', 'CA', 'USA', 'Retail', 'Credit Card', 'Neutral', 1699.99, 35.00, '2025-02-12', '2025-02-15'),
('ORD-1033', 'Gina Rodriguez', 'Logitech MX Master 3', 'Electronics', 'Denver', 'CO', 'USA', 'Online', 'Credit Card', 'Satisfied', 99.99, 2.00, '2025-02-13', '2025-02-16');


-- Checking all the rows in the table 
SELECT * FROM sales;



-- Starting with the String Functions

-- QUERY 1
/*
    Write a sql query to retrieve the sales_id, customer_name, order_state from the sales table. 
    The client has notified us that the column customer_name has an issue, it contains unwanted space in the beginning
    The client wants to see the names of the customer only.
    Also the client wants to have the data of only state 'CA', and the data needs to be displayed based on sales id from highest to lowest 
*/




-- QUERY 2
/*
    Write a sql query to retrieve the sales_id, product_category from the sales table. 
    The client has notified us that the column product_category has an issue, it contains unwanted space in the end
    The client wants to see the names of the product_category only.
    Also the client wants to have the data of only state ('CA', 'TX', 'WA') and the payment must be done by credit card. 
    The data needs to be displayed based on sales id from highest to lowest 
*/




-- QUERY 3
/*
    Write a sql query to retrieve the sales_id, customer name, and feedback column from the sales table. 
    The client has notified us that the column feedback has an issue, it contains unwanted characters like *, -, # both in the start and end.
    The client wants to see the names of the Feedback category only. 
*/




-- UPDATING THE COLUMNS 
UPDATE SALES
SET FEEDBACK = TRIM(FEEDBACK, ('*#-'));

UPDATE SALES
SET PRODUCT_CATEGORY = RTRIM(PRODUCT_CATEGORY);

UPDATE SALES
SET CUSTOMER_NAME = LTRIM(CUSTOMER_NAME);



-- QUERY 4 -- (SPLIT())
/*
    Retrieve the following columns from the sales table. Columns: - Sale_ID, Order_id, Customer_name, Order_State, Sales_Channel, Payment_Method.
    There is a issue in the sales table, we were supposed to get the first name, and the last name. 
    So, create a column which can separate the first name and last name.
    Expected Output: - 
    Alice Brown -> ["Alice", "Brown"]
    Solution: - 
*/




-- QUERY 5 (SPLIT_PART())
/*
    Display the following columns (sale_id, customer_name, order_state, sales_channel) from the sales table.
    But there was a mistake done by the database designing team. We wanted columns customer_name, first name, last name.
    But we only got customer_name. Display the other two columns as well.
    Note that we want to see the data only from the Online channel.
    
*/




-- QUERY 6 (CONCAT())
/*
    Display the following queries from the sales table. 
    1. Sales_id, 
    2. Order_id, 
    3. Customer_name, 
    4. Product_name, 
    5. Payment_Method
    6. Sales_Channel
    7. Order_state,
    8. Order_country
    We need to also display another column which must be the ORDER_STATE - ORDER_COUNTRY and name the column as (State_and_country)
    We need to filter the select query such that we only get the data of Credit Card payment, and the channel must be online.
    Also, we need to sort the displayed data based on the sales_id as DESC order.
    
*/




-- QUERY 7
/*
    There is a requirement of the client to analyse the data based on the location. 
    The client has provided you the sales data of their company. 
    Based on the first talks with the client we came to know that client wants the following columns
    1. SALE_ID
    2. ORDER_ID, 
    3. PRODUCT_NAME, 
    4. ORDER_CITY, 
    5. ORDER_STATE, 
    6. ORDER_COUNTRY, 
    7. SALES_AMOUNT,
    8. Feedback
    The client has requested that he does not want to see three different columns for city, state,and country.
    Intead he gave a solution to display only one column where the values will be "city, state, country".
    Also the client wants to see only the data of customers which were 'Very Satisfied' and also 'Neutral'
*/




-- QUERY 8
/*
    Write a sql query to print the customer names from the sales table. 
    Also we need to print the length of the customer_name, as we want to identify the longest name in the data
    Return the result ordered by the length of the customer_name
*/




-- QUERY 9
/*
    Write a SQL query to check if the customer name starts with letter 'B' or not.
    Retrieve only the columns Customer_name, and the checker column.
*/




-- QUERY 10
/*
    Write a SQL query to convert all the CITY names into the upper case.
    For example, NEW YORK. 
    Note that we only need to see the city column and the uppercase column.
*/




-- QUERY 11
/*
    Write a SQL query to display the columns as lower case column, We need to display the country column as lower case column.
*/