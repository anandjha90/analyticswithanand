-- Assigning the role for the account 
USE ROLE ACCOUNTADMIN;


-- Assigning the warehouse to the account 
USE WAREHOUSE COMPUTE_WH;

-- Creating a database named as SALES_DATABASE
CREATE DATABASE IF NOT EXISTS SQL_CLASS_12;

-- CREATING a schema for the SALES_DATABASE 
CREATE SCHEMA IF NOT EXISTS SQL_CLASS_12_SCHEMA;

-- USING THE DATABASE CREATED SALES_DATABASE 
USE DATABASE SQL_CLASS_12;

-- USING THE SCHEMA CREATED SALES_SCHEMA
USE SCHEMA SQL_CLASS_12_SCHEMA;

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


-- STARTING WITH THE AGGREGATE FUNCTIONS

