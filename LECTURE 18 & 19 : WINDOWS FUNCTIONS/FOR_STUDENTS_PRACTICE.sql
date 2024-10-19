-- UNDERSTANDING WINDOW FUNCTIONS BY PRACTICE 


-- CREATING A DATABASE  
CREATE DATABASE IF NOT EXISTS  UnderstandingWindowFunctions;

-- USING THE CREATED DATABASE
USE UnderstandingWindowFunctions;



-- CREATING A TABLE NAMED AS SALES
CREATE TABLE IF NOT EXISTS FoodSales(
    CATEGORY VARCHAR(30),
    SUBCATEGORY VARCHAR(30),
    FOODNAME VARCHAR(30),
    TOTALQTY INT
);

-- INSERTING VALUES INTO THE SALES TABLE
INSERT INTO FoodSales (CATEGORY, SubCategory, FOODNAME, TOTALQTY)
VALUES
('Asian', 'Japanese', 'Sushi', 123),
('Asian', 'Chinese', 'Dumplings', 201),
('Asian', 'Thai', 'Pad Thai', 300),
('Asian', 'Japanese', 'Ramen', 179),
('Asian', 'Indian', 'Biryani', 210),
('Asian', 'Chinese', 'Chinese Noodles', 179),
('Asian', 'Korean', 'Kimchi', 300),
('Asian', 'Vietnamese', 'Spring Rolls', 98),
('Italian', 'Sicilian', 'Pizza', 257),
('Italian', 'Roman', 'Pasta', 301),
('Italian', 'Neapolitan', 'Lasagna', 141),
('Italian', 'Lombard', 'Risotto', 141),
('Italian', 'Venetian', 'Tiramisu', 310),
('Mexican', 'Tex-Mex', 'Tacos', 250),
('Mexican', 'Pueblan', 'Enchiladas', 220),
('Mexican', 'Jalisco', 'Guacamole', 190),
('Mexican', 'Oaxacan', 'Quesadilla', 160),
('Mediterranean', 'Levantine', 'Hummus', 130),
('Mediterranean', 'Middle Eastern', 'Falafel', 210),
('Mediterranean', 'Levantine', 'Tabbouleh', 140),
('Mediterranean', 'Middle Eastern', 'Shawarma', 180);




-- UNDERSTANDING THE PARTITION BY CLAUSE

SELECT * FROM FOODSALES;


-- QUESTION 1
/*
    Write a SQL query to rank the food items based on their quantity sold,
    with the highest quantity ranked as 1.
*/
-- NORMAL SOLUTION


-- NORMAL SOLUTION 2 


-- WINDOW FUNCTION SOLTUION




-- QUESTION 2
/*
    Write a SQL query to rank the food items sold based on thier total quantity.
    Note that you need to all the three ranking functions.
    
*/
-- SOLUTION


-- QUESTION 3
/*
    Write a SQL query to rank the food items sold based on thier total quantity.
    The ranking must be based on the CATEGORY OF THE FOODS and not the whole database
    Note that you need to all the three ranking functions.
*/
-- SOLUTION



-- QUESTION 4
/*
    Write a SQL query to rank the food items sold based on thier total quantity.
    The ranking must be based on the SUBCATEGORY OF THE FOODS and not the whole database
    Note that you need to all the three ranking functions.
*/
-- SOLUTION



-- QUESTION 4
/*
    Write a SQL query to rank the food items sold based on thier total quantity.
    You have to create 2 columns "Global Rank" and "Local Rank" and "Sub Local Rank"
    Global Rank is the overall rank. Local Rank is the Rank within its category, 
    "Sub Local Rank" is the rank within its subcategory 
*/
-- SOLUTION



-- QUESTION 5
/*
    Write a SQL query to retrive the top 2 selling products from the Asian and Italian category. 
    You need to retrieve the Foodname, categort, subcategory total qty. 
    You need to use the window functions and retrive the same.
    Order the table by the category name
*/
-- SOLUTION



-- LEAD() LAG()

-- CREATING ANOTHER TABLE
CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    EmployeeName VARCHAR(100),
    DepartmentName VARCHAR(100),
    Salary DECIMAL(10, 2),
    BonusAmount DECIMAL(10, 2)  -- New column added
);

-- INSERTING SOME VALUES INTO THE TABLE
INSERT INTO Employee (EmployeeID, EmployeeName, DepartmentName, Salary, BonusAmount)
VALUES
(1, 'John Doe', 'Sales', 55000.00, 5000.00),
(2, 'Jane Smith', 'Marketing', 62000.00, 6000.00),
(3, 'Michael Johnson', 'IT', 75000.00, 7000.00),
(4, 'Emily Davis', 'HR', 47000.00, 4000.00),
(5, 'James Brown', 'Finance', 68000.00, 6500.00),
(6, 'Olivia Garcia', 'IT', 79000.00, 7500.00),
(7, 'William Martinez', 'Sales', 54000.00, 5200.00),
(8, 'Sophia Robinson', 'Marketing', 60000.00, 5800.00),
(9, 'Liam Clark', 'HR', 50000.00, 4500.00),
(10, 'Isabella Rodriguez', 'Finance', 67000.00, 6300.00),
(11, 'Ethan Lee', 'Sales', 52000.00, 5100.00),
(12, 'Ava Walker', 'Marketing', 64000.00, 6200.00),
(13, 'Mason Hall', 'IT', 76000.00, 7200.00),
(14, 'Charlotte Young', 'HR', 49000.00, 4400.00),
(15, 'Logan Hernandez', 'Finance', 70000.00, 6800.00),
(16, 'Mia King', 'Sales', 56000.00, 5300.00),
(17, 'Lucas Wright', 'Marketing', 63000.00, 6000.00),
(18, 'Benjamin Green', 'IT', 80000.00, 7800.00),
(19, 'Ella Adams', 'HR', 48000.00, 4200.00),
(20, 'Alexander Scott', 'Finance', 72000.00, 7000.00);



-- QUESTION 6
/*
    Write a SQL query to display each employee's name, department, 
    and the salary of the next employee. 
    Use the LEAD() function and partition by DepartmentName.
*/
-- SOLUTION
    

-- QUESTION 7 
/*
    Write a SQL query to display each employee's name, department, 
    and the salary of the next employee in the same department. 
    Use the LEAD() function and partition by DepartmentName.
*/
-- SOLUTION



-- QUESTION 8
/*
    Finding bonus difference with the previous employee using LAG()
    Question:
    Write a SQL query to display each employee's name, their bonus amount, and the difference in bonus amount
    compared to the previous employee. Use LAG() to calculate the difference.
*/
-- SOLUTION


    
-- QUESTION 9
/*
    Write a SQL query to display each employee's name, their bonus amount, 
    and the bonus amount of the employee two positions ahead within their department. Use the LEAD() function with an offset of 2.
*/
-- SOLUTION



-- QUESTION 10
/*
    Write a SQL query to display each employee's name, their department, and the first bonus amount 
    within their department using the FIRST_VALUE() function.
*/
-- SOLUTION



