-- USE ROLE 
USE ROLE ACCOUNTADMIN;

-- USE WAREHOUSE 
USE WAREHOUSE COMPUTE_WH;

-- CREATING A DATABASE 
CREATE DATABASE IF NOT EXISTS JOINS_IN_SQL;

-- USE DATABASE 
USE DATABASE JOINS_IN_SQL;

-- CREATE SCHEMA FOR THE TODAYS CLASS
CREATE SCHEMA IF NOT EXISTS JOINS_SCHEMA;

-- USE SCHEMA 
USE SCHEMA JOINS_SCHEMA;

-- CREATING A TABLE NAMED CUSTOMERS
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(50),
    Country VARCHAR(50)
);

-- CREATING A TABLE NAMED ORDERS
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    OrderDate DATE,
    CustomerID INT,
    Amount DECIMAL(10, 2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- INSERTING VALUES INSIDE TABLE CUSTOMER
INSERT INTO Customers (CustomerID, CustomerName, Country)
VALUES
(1, 'John Doe', 'USA'),
(2, 'Jane Smith', 'UK'),
(3, 'David Brown', 'Canada'),
(4, 'Emily White', 'Australia'),
(5, 'Michael Green', 'USA'),
(6, 'Anna Taylor', 'USA'),
(7, 'Robert King', 'UK'),
(8, 'Laura Wilson', 'Australia'),
(9, 'James Davis', 'Canada'),
(10, 'Sophia Harris', 'USA');

-- INSERTING VALUES INTO TABLE ORDERS
INSERT INTO Orders (OrderID, OrderDate, CustomerID, Amount)
VALUES
(101, '2025-01-10', 1, 250.75),
(102, '2025-01-15', 2, 320.00),
(103, '2025-01-20', 3, 450.50),
(104, '2025-02-01', 1, 120.90),
(105, '2025-02-05', 2, 310.50),
(106, '2025-02-10', NULL, 299.99),
(107, '2025-02-15', 4, 400.25),
(108, '2025-02-20', 5, 150.00),
(109, '2025-02-25', 7, 500.75),
(110, '2025-03-01', 6, 225.50),
(111, '2025-03-05', 9, 600.00),
(112, '2025-03-10', NULL, 450.00),
(113, '2025-03-12', 8, 350.00);



