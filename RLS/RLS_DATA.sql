-- USE ROLE 
USE ROLE ACCOUNTADMIN;

-- USE WAREHOUSE 
USE WAREHOUSE COMPUTE_WH;

-- CREATING A DATABASE 
CREATE DATABASE IF NOT EXISTS POWERBI_RLS_DATABASE;

-- USE DATABASE 
USE DATABASE POWERBI_RLS_DATABASE;

-- CREATE SCHEMA FOR THE TODAYS CLASS
CREATE SCHEMA IF NOT EXISTS POWERBI_RLS_SCHEMA;

-- USE SCHEMA 
USE SCHEMA POWERBI_RLS_SCHEMA;

-- CREATING TABLE FOR EMPLOYEES
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY,
    EmployeeName VARCHAR(100),
    Role VARCHAR(50),
    ManagerID INT NULL,
    Email VARCHAR(100)
);

-- Insert data into Employees
INSERT INTO Employees (EmployeeID, EmployeeName, Role, ManagerID, Email) VALUES
(1, 'Karan Shah', 'CEO', NULL, 'karan04@02karan2001.onmicrosoft.com'),
(2, 'Bob Smith', 'VP of Sales', 1, 'bob@company.com'),
(3, 'Carol White', 'Sales Manager', 2, 'carol@company.com'),
(4, 'David Green', 'Sales Manager', 2, 'david@company.com'),
(5, 'Eve Adams', 'Sales Rep', 3, 'eve@company.com'),
(6, 'Frank Lee', 'Sales Rep', 4, 'frank@company.com'),
(7, 'Grace Miller', 'Sales Rep', 3, 'grace@company.com');

-- CREATING TABLE FOR Territories
CREATE TABLE Territories (
    TerritoryID INT PRIMARY KEY,
    TerritoryName VARCHAR(100),
    Region VARCHAR(100)
);

-- Insert data into Territories
INSERT INTO Territories (TerritoryID, TerritoryName, Region) VALUES
(1, 'North East', 'East'),
(2, 'South East', 'East'),
(3, 'West Coast', 'West'),
(4, 'Mid West', 'Central');

-- CREATING TABLE FOR SALES
CREATE TABLE Sales (
    SaleID INT PRIMARY KEY,
    SaleAmount DECIMAL(10, 2),
    SaleDate DATE,
    EmployeeID INT,
    TerritoryID INT,
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    FOREIGN KEY (TerritoryID) REFERENCES Territories(TerritoryID)
);

-- Insert data into Sales
INSERT INTO Sales (SaleID, SaleAmount, SaleDate, EmployeeID, TerritoryID) VALUES
(1, 50000, '2025-01-01', 5, 1),
(2, 75000, '2025-01-15', 6, 2),
(3, 60000, '2025-02-01', 7, 3),
(4, 45000, '2025-02-10', 6, 4),
(5, 90000, '2025-02-20', 5, 1),
(6, 30000, '2025-03-01', 7, 2);

