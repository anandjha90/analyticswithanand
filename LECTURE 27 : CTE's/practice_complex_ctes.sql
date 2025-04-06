-- ASSIGNING THE ACCOUNT TYPE 
USE ROLE ACCOUNTADMIN;

-- USING THE WAREHOUSE AVAILABLE
USE WAREHOUSE COMPUTE_WH;

-- CREATING A DATABASE NAMED AS SUBQUERIES_DATABASE
CREATE DATABASE IF NOT EXISTS SUBQUERIES_DATABASE;

-- CREATING A SCHEMA NAMED AS SUBQUERIES_SCHEMA
CREATE SCHEMA IF NOT EXISTS SUBQUERIES_SCHEMA;

-- USING THE DATABASE CREATED
USE DATABASE SUBQUERIES_DATABASE;

-- USING THE SCHEMA CREATED 
USE SCHEMA SUBQUERIES_SCHEMA;

-- CREATING THE TABLE CUSTOMERS
CREATE TABLE CUSTOMERS (
    CUSTOMER_ID INT PRIMARY KEY,
    CUSTOMER_NAME VARCHAR(100),
    CITY VARCHAR(50),
    COUNTRY VARCHAR(50),
    JOINED_DATE DATE
);

-- CREATING THE TABLE ORDERS
CREATE TABLE ORDERS (
    ORDER_ID INT PRIMARY KEY,
    CUSTOMER_ID INT,
    PRODUCT_ID INT,
    ORDER_DATE DATE,
    SHIP_DATE DATE,
    QUANTITY INT,
    FOREIGN KEY (CUSTOMER_ID) REFERENCES CUSTOMERS(CUSTOMER_ID)
);

-- CREATING THE TABLE PRODUCTS
CREATE TABLE PRODUCTS (
    PRODUCT_ID INT PRIMARY KEY,
    PRODUCT_NAME VARCHAR(100),
    CATEGORY VARCHAR(50),
    UNIT_PRICE DECIMAL(10, 2)
);

-- INSERTING VALUES INTO THE CUSTOMERS TABLE 
INSERT INTO CUSTOMERS (CUSTOMER_ID, CUSTOMER_NAME, CITY, COUNTRY, JOINED_DATE) VALUES
(1, 'John Doe', 'Toronto', 'Canada', '2022-01-15'),
(2, 'Jane Smith', 'New York', 'USA', '2021-03-22'),
(3, 'Carlos Lopez', 'Mexico City', 'Mexico', '2023-05-10'),
(4, 'Sophia Patel', 'London', 'UK', '2021-11-19'),
(5, 'Ahmed Khan', 'Mumbai', 'India', '2022-09-30'),
(6, 'Emily Johnson', 'Los Angeles', 'USA', '2022-05-05'),
(7, 'James Lee', 'Sydney', 'Australia', '2023-01-20'),
(8, 'Emma Wilson', 'Vancouver', 'Canada', '2021-08-14'),
(9, 'Mohammed Ali', 'Dubai', 'UAE', '2022-04-11'),
(10, 'Liu Wei', 'Beijing', 'China', '2021-12-28'),
(11, 'Olivia Brown', 'Melbourne', 'Australia', '2023-03-30'),
(12, 'Isabella Martinez', 'Madrid', 'Spain', '2022-07-25'),
(13, 'Liam Evans', 'Auckland', 'New Zealand', '2021-09-17'),
(14, 'Hannah Williams', 'Chicago', 'USA', '2022-02-18'),
(15, 'Arjun Gupta', 'Delhi', 'India', '2023-06-12'),
(16, 'Lucas Kim', 'Seoul', 'South Korea', '2021-10-21'),
(17, 'Eva Garcia', 'Barcelona', 'Spain', '2022-08-07'),
(18, 'David Thompson', 'Houston', 'USA', '2023-07-02'),
(19, 'Ava Adams', 'Boston', 'USA', '2021-11-30'),
(20, 'Noah Clark', 'San Francisco', 'USA', '2022-03-19'),
(21, 'Chloe Robinson', 'Paris', 'France', '2022-12-01'),
(22, 'Mia Turner', 'Rome', 'Italy', '2021-05-22'),
(23, 'Elijah Harris', 'Berlin', 'Germany', '2023-04-18'),
(24, 'Zara Ahmed', 'Cairo', 'Egypt', '2022-06-03'),
(25, 'William King', 'Dublin', 'Ireland', '2021-07-11'),
(26, 'Sophia Lee', 'Tokyo', 'Japan', '2023-08-29'),
(27, 'Benjamin Scott', 'Edinburgh', 'UK', '2021-01-08'),
(28, 'Lucas Anderson', 'Stockholm', 'Sweden', '2022-10-14'),
(29, 'Isla Perez', 'Buenos Aires', 'Argentina', '2023-02-25'),
(30, 'Ryan Baker', 'Cape Town', 'South Africa', '2021-09-05');

-- INSERTING THE VALUES INTO THE ORDERS TABLE
INSERT INTO ORDERS (ORDER_ID, CUSTOMER_ID, PRODUCT_ID, ORDER_DATE, SHIP_DATE, QUANTITY)
VALUES
(1, 1, 101, '2024-01-01', '2024-01-05', 10),
(2, 2, 102, '2024-01-03', '2024-01-06', 5),
(3, 3, 103, '2024-01-05', '2024-01-10', 8),
(4, 4, 104, '2024-01-07', '2024-01-12', 3),
(5, 5, 105, '2024-01-10', '2024-01-15', 12),
(6, 6, 106, '2024-01-12', '2024-01-17', 20),
(7, 7, 107, '2024-01-14', '2024-01-18', 6),
(8, 8, 108, '2024-01-17', '2024-01-22', 15),
(9, 9, 109, '2024-01-18', '2024-01-23', 9),
(10, 10, 110, '2024-01-20', '2024-01-25', 18),
(11, 11, 111, '2024-01-23', '2024-01-28', 11),
(12, 12, 112, '2024-01-25', '2024-01-29', 7),
(13, 13, 113, '2024-01-27', '2024-02-01', 16),
(14, 14, 114, '2024-01-29', '2024-02-03', 4),
(15, 15, 115, '2024-01-31', '2024-02-05', 19),
(16, 16, 116, '2024-02-02', '2024-02-07', 6),
(17, 17, 117, '2024-02-04', '2024-02-08', 14),
(18, 18, 118, '2024-02-06', '2024-02-10', 9),
(19, 19, 119, '2024-02-08', '2024-02-13', 21),
(20, 20, 120, '2024-02-10', '2024-02-15', 17),
(21, 1, 101, '2024-02-12', '2024-02-17', 5),
(22, 2, 102, '2024-02-14', '2024-02-19', 7),
(23, 3, 103, '2024-02-15', '2024-02-21', 3),
(24, 4, 104, '2024-02-17', '2024-02-22', 11),
(25, 5, 105, '2024-02-18', '2024-02-23', 9),
(26, 6, 106, '2024-02-19', '2024-02-24', 10),
(27, 7, 107, '2024-02-20', '2024-02-25', 6),
(28, 8, 108, '2024-02-21', '2024-02-26', 15),
(29, 9, 109, '2024-02-22', '2024-02-27', 12),
(30, 10, 110, '2024-02-23', '2024-02-28', 18),
(31, 11, 111, '2024-02-24', '2024-03-01', 5),
(32, 12, 112, '2024-02-25', '2024-03-02', 14),
(33, 13, 113, '2024-02-26', '2024-03-03', 8),
(34, 14, 114, '2024-02-27', '2024-03-04', 16),
(35, 15, 115, '2024-02-28', '2024-03-05', 13),
(36, 16, 116, '2024-03-01', '2024-03-06', 20),
(37, 17, 117, '2024-03-02', '2024-03-07', 9),
(38, 18, 118, '2024-03-03', '2024-03-08', 4),
(39, 19, 119, '2024-03-04', '2024-03-09', 21),
(40, 20, 120, '2024-03-05', '2024-03-10', 18),
(41, 1, 101, '2024-03-06', '2024-03-11', 7),
(42, 2, 102, '2024-03-07', '2024-03-12', 11),
(43, 3, 103, '2024-03-08', '2024-03-13', 10),
(44, 4, 104, '2024-03-09', '2024-03-14', 15),
(45, 5, 105, '2024-03-10', '2024-03-15', 17),
(46, 6, 106, '2024-03-11', '2024-03-16', 13),
(47, 7, 107, '2024-03-12', '2024-03-17', 6),
(48, 8, 108, '2024-03-13', '2024-03-18', 9),
(49, 9, 109, '2024-03-14', '2024-03-19', 20),
(50, 10, 110, '2024-03-15', '2024-03-20', 12);

-- INSERTING VALUES INTO THE PRODUCTS TABLE
INSERT INTO PRODUCTS (PRODUCT_ID, PRODUCT_NAME, CATEGORY, UNIT_PRICE)
VALUES
(101, 'Laptop', 'Electronics', 800.00),
(102, 'Smartphone', 'Electronics', 600.00),
(103, 'Tablet', 'Electronics', 300.00),
(104, 'Headphones', 'Accessories', 50.00),
(105, 'Keyboard', 'Accessories', 30.00),
(106, 'Mouse', 'Accessories', 25.00),
(107, 'Smartwatch', 'Wearables', 200.00),
(108, 'Monitor', 'Electronics', 250.00),
(109, 'External Hard Drive', 'Storage', 100.00),
(110, 'USB-C Hub', 'Accessories', 20.00),
(111, 'Gaming Console', 'Gaming', 400.00),
(112, 'Router', 'Networking', 60.00),
(113, 'Bluetooth Speaker', 'Audio', 80.00),
(114, 'VR Headset', 'Gaming', 350.00),
(115, 'Smart Glasses', 'Wearables', 500.00),
(116, 'Action Camera', 'Cameras', 300.00),
(117, 'Drone', 'Cameras', 600.00),
(118, 'Smart Light Bulb', 'Home Automation', 40.00),
(119, 'Electric Kettle', 'Home Appliances', 35.00),
(120, 'Air Fryer', 'Home Appliances', 120.00),
(121, 'Fitness Tracker', 'Wearables', 150.00),
(122, 'Portable Projector', 'Home Entertainment', 450.00),
(123, 'Wireless Charger', 'Accessories', 25.00);


-- LET US START WITH SUBQUERIES 
-- QUERY 1
/*
    Find the top 5 customers who spent the most on orders, showing their name, total amount spent, and order count.
*/



-- QUERY 2
/*
    Find the products that were ordered more than the average quantity across all products and list the product name, category, and total quantity ordered.
*/



-- QUESTION 3
/*
    List the customers who have never ordered products from the 'Gaming' category. Show the customer name and the number of orders placed.
*/




-- Query 4
/*
    Find the most recent order for each customer, showing the customer name, product name, and order date.
*/




-- QUERY 5
/*
    List all the products that were never ordered
*/




-- QUERY 6
/*
    Find the customer(s) who placed the largest order (based on the total cost of the order). Show the customer name, order date, and total order value.
*/
