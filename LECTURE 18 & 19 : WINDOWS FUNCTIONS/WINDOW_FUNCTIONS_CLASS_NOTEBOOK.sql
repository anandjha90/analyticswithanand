-- ASSIGNING THE ACCOUNT TYPE 
USE ROLE ACCOUNTADMIN;

-- USING THE WAREHOUSE AVAILABLE
USE WAREHOUSE COMPUTE_WH;

-- CREATING A DATABASE NAMED AS SUBQUERIES_DATABASE
CREATE DATABASE IF NOT EXISTS WINDOW_FUNCTIONS_DB;

-- CREATING A SCHEMA NAMED AS SUBQUERIES_SCHEMA
CREATE SCHEMA IF NOT EXISTS WINDOW_FUNCTIONS_SCHEMA;

-- USING THE DATABASE CREATED
USE DATABASE WINDOW_FUNCTIONS_DB;

-- USING THE SCHEMA CREATED 
USE SCHEMA WINDOW_FUNCTIONS_SCHEMA;

-- Creating a table named as salestable
CREATE TABLE IF NOT EXISTS sales(
	sales_id INT PRIMARY KEY, 
    sales_person_name VARCHAR(250) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    quantity_sold INT NOT NULL, 
    amount decimal(10,2) NOT NULL
);

-- Inserting values into the table
INSERT INTO sales (sales_id, sales_person_name, product_name, location, quantity_sold, amount) VALUES
(1, 'Rajesh Sharma', 'Vadapav', 'Maharashtra', 30, 1500.00),
(2, 'Anjali Mehta', 'Vadapav', 'Gujarat', 25, 1250.00),
(3, 'Suresh Patil', 'Vadapav', 'Madhya Pradesh', 40, 2000.00),
(4, 'Priya Kumar', 'Vadapav', 'Rajasthan', 20, 1000.00),
(5, 'Manoj Gupta', 'Vadapav', 'Karnataka', 35, 1750.00),
(6, 'Rohit Singh', 'Vadapav', 'Uttar Pradesh', 50, 2500.00),
(7, 'Sunita Yadav', 'Vadapav', 'Punjab', 45, 2250.00),
(8, 'Vijay Deshmukh', 'Vadapav', 'Maharashtra', 60, 3000.00),
(9, 'Neha Verma', 'Vadapav', 'Tamil Nadu', 55, 2750.00),
(10, 'Karan Patel', 'Vadapav', 'Gujarat', 70, 3500.00),
(11, 'Arjun Reddy', 'Vadapav', 'Andhra Pradesh', 80, 4000.00),
(12, 'Nikita Jain', 'Vadapav', 'Delhi', 65, 3250.00),
(13, 'Vikas Malhotra', 'Vadapav', 'Haryana', 30, 1500.00),
(14, 'Shruti Rao', 'Vadapav', 'Telangana', 40, 2000.00),
(15, 'Akash Pandey', 'Vadapav', 'Uttar Pradesh', 45, 2250.00),
(16, 'Meera Shah', 'Vadapav', 'Maharashtra', 50, 2500.00),
(17, 'Ravi Sinha', 'Vadapav', 'Bihar', 35, 1750.00),
(18, 'Divya Kapoor', 'Vadapav', 'Punjab', 25, 1250.00),
(19, 'Amit Khanna', 'Vadapav', 'West Bengal', 60, 3000.00),
(20, 'Simran Kaur', 'Vadapav', 'Himachal Pradesh', 55, 2750.00),
(21, 'Deepak Bhatt', 'Vadapav', 'Uttarakhand', 20, 1000.00),
(22, 'Ayesha Khan', 'Vadapav', 'Maharashtra', 70, 3500.00),
(23, 'Pankaj Mishra', 'Vadapav', 'Odisha', 80, 4000.00),
(24, 'Ritika Joshi', 'Vadapav', 'Kerala', 65, 3250.00),
(25, 'Shivani Desai', 'Vadapav', 'Goa', 30, 1500.00),
(26, 'Abhinav Choudhary', 'Vadapav', 'Rajasthan', 40, 2000.00),
(27, 'Harsh Agarwal', 'Vadapav', 'Madhya Pradesh', 45, 2250.00),
(28, 'Tanya Srivastava', 'Vadapav', 'Uttar Pradesh', 50, 2500.00),
(29, 'Ramesh Joshi', 'Vadapav', 'Haryana', 35, 1750.00),
(30, 'Sneha Saxena', 'Vadapav', 'Karnataka', 25, 1250.00),
(31, 'Gaurav Nair', 'Vadapav', 'Tamil Nadu', 60, 3000.00),
(32, 'Anita Bhatia', 'Vadapav', 'Gujarat', 55, 2750.00),
(33, 'Puja Chatterjee', 'Vadapav', 'West Bengal', 70, 3500.00),
(34, 'Rahul Tripathi', 'Vadapav', 'Delhi', 80, 4000.00),
(35, 'Kavita Reddy', 'Vadapav', 'Andhra Pradesh', 65, 3250.00),
(36, 'Sanjay Iyer', 'Vadapav', 'Kerala', 30, 1500.00),
(37, 'Vidya Pillai', 'Vadapav', 'Karnataka', 40, 2000.00),
(38, 'Dinesh Chauhan', 'Vadapav', 'Punjab', 45, 2250.00),
(39, 'Rajiv Kapoor', 'Vadapav', 'Himachal Pradesh', 50, 2500.00),
(40, 'Mona Sharma', 'Vadapav', 'Uttarakhand', 35, 1750.00),
(41, 'Rahul Yadav', 'Vadapav', 'Bihar', 25, 1250.00),
(42, 'Ishita Gupta', 'Vadapav', 'Madhya Pradesh', 60, 3000.00),
(43, 'Nitin Shukla', 'Vadapav', 'Maharashtra', 55, 2750.00),
(44, 'Veena Singh', 'Vadapav', 'Rajasthan', 70, 3500.00),
(45, 'Ashok Nair', 'Vadapav', 'Tamil Nadu', 80, 4000.00),
(46, 'Rohini Kulkarni', 'Vadapav', 'Karnataka', 65, 3250.00),
(47, 'Shubham Rao', 'Vadapav', 'Telangana', 30, 1500.00),
(48, 'Nisha Patil', 'Vadapav', 'Maharashtra', 40, 2000.00),
(49, 'Keshav Sinha', 'Vadapav', 'Uttar Pradesh', 45, 2250.00),
(50, 'Payal Chauhan', 'Vadapav', 'Haryana', 50, 2500.00),
(51, 'Vikram Sharma', 'Samosa', 'Maharashtra', 30, 600.00),
(52, 'Pooja Mehta', 'Samosa', 'Gujarat', 25, 500.00),
(53, 'Sanjay Patil', 'Samosa', 'Madhya Pradesh', 40, 800.00),
(54, 'Deepika Kumar', 'Samosa', 'Rajasthan', 20, 400.00),
(55, 'Ankit Gupta', 'Samosa', 'Karnataka', 35, 700.00),
(56, 'Vivek Singh', 'Samosa', 'Uttar Pradesh', 50, 1000.00),
(57, 'Nidhi Yadav', 'Samosa', 'Punjab', 45, 900.00),
(58, 'Rakesh Deshmukh', 'Samosa', 'Maharashtra', 60, 1200.00),
(59, 'Seema Verma', 'Samosa', 'Tamil Nadu', 55, 1100.00),
(60, 'Abhay Patel', 'Samosa', 'Gujarat', 70, 1400.00),
(61, 'Vishal Reddy', 'Samosa', 'Andhra Pradesh', 80, 1600.00),
(62, 'Priyanka Jain', 'Samosa', 'Delhi', 65, 1300.00),
(63, 'Rahul Malhotra', 'Samosa', 'Haryana', 30, 600.00),
(64, 'Kriti Rao', 'Samosa', 'Telangana', 40, 800.00),
(65, 'Vishnu Pandey', 'Samosa', 'Uttar Pradesh', 45, 900.00),
(66, 'Radhika Shah', 'Samosa', 'Maharashtra', 50, 1000.00),
(67, 'Manish Sinha', 'Samosa', 'Bihar', 35, 700.00),
(68, 'Juhi Kapoor', 'Samosa', 'Punjab', 25, 500.00),
(69, 'Ashish Khanna', 'Samosa', 'West Bengal', 60, 1200.00),
(70, 'Ritu Kaur', 'Samosa', 'Himachal Pradesh', 55, 1100.00),
(71, 'Deepak Bhatt', 'Samosa', 'Uttarakhand', 20, 400.00),
(72, 'Alok Khan', 'Samosa', 'Maharashtra', 70, 1400.00),
(73, 'Harshit Mishra', 'Samosa', 'Odisha', 80, 1600.00),
(74, 'Lavanya Joshi', 'Samosa', 'Kerala', 65, 1300.00),
(75, 'Nikhil Desai', 'Samosa', 'Goa', 30, 600.00),
(76, 'Ishaan Choudhary', 'Samosa', 'Rajasthan', 40, 800.00),
(77, 'Prateek Agarwal', 'Samosa', 'Madhya Pradesh', 45, 900.00),
(78, 'Sneha Srivastava', 'Samosa', 'Uttar Pradesh', 50, 1000.00),
(79, 'Sumit Joshi', 'Samosa', 'Haryana', 35, 700.00),
(80, 'Megha Saxena', 'Samosa', 'Karnataka', 25, 500.00),
(81, 'Kunal Nair', 'Samosa', 'Tamil Nadu', 60, 1200.00),
(82, 'Tanvi Bhatia', 'Samosa', 'Gujarat', 55, 1100.00),
(83, 'Shalini Chatterjee', 'Samosa', 'West Bengal', 70, 1400.00),
(84, 'Naveen Tripathi', 'Samosa', 'Delhi', 80, 1600.00),
(85, 'Anusha Reddy', 'Samosa', 'Andhra Pradesh', 65, 1300.00),
(86, 'Ganesh Iyer', 'Samosa', 'Kerala', 30, 600.00),
(87, 'Swati Pillai', 'Samosa', 'Karnataka', 40, 800.00),
(88, 'Mohan Chauhan', 'Samosa', 'Punjab', 45, 900.00),
(89, 'Rohit Kapoor', 'Samosa', 'Himachal Pradesh', 50, 1200.00),
(90, 'Shalini Sharma', 'Samosa', 'Uttarakhand', 35, 701.00),
(91, 'Amit Yadav', 'Samosa', 'Bihar', 25, 502.00),
(92, 'Priya Gupta', 'Samosa', 'Madhya Pradesh', 60, 1210.00),
(93, 'Rajat Shukla', 'Samosa', 'Maharashtra', 55, 1110.00),
(94, 'Nikita Singh', 'Samosa', 'Rajasthan', 70, 1420.00),
(95, 'Siddharth Nair', 'Samosa', 'Tamil Nadu', 80, 1633.00),
(96, 'Pallavi Kulkarni', 'Samosa', 'Karnataka', 65, 1333.00),
(97, 'Varun Rao', 'Samosa', 'Telangana', 30, 601.00),
(98, 'Sneha Patil', 'Samosa', 'Maharashtra', 40, 807.00),
(99, 'Raj Sinha', 'Samosa', 'Uttar Pradesh', 45, 902.00),
(100, 'Komal Chauhan', 'Samosa', 'Haryana', 50, 1003.00),
(101, 'Rakesh Sharma', 'Dosa', 'Maharashtra', 20, 402.10),
(102, 'Aarti Mehta', 'Pani Puri', 'Gujarat', 35, 525.00),
(103, 'Siddharth Patil', 'Jalebi', 'Madhya Pradesh', 40, 803.00),
(104, 'Priya Kumar', 'Dosa', 'Rajasthan', 25, 509.00),
(105, 'Rohit Gupta', 'Pani Puri', 'Karnataka', 50, 70.00),
(106, 'Vikram Singh', 'Jalebi', 'Uttar Pradesh', 30, 610.00),
(107, 'Sunil Yadav', 'Dosa', 'Punjab', 60, 12.00),
(108, 'Nitin Deshmukh', 'Pani Puri', 'Maharashtra', 45, 6.00),
(109, 'Seema Verma', 'Jalebi', 'Tamil Nadu', 55, 1.00),
(110, 'Ankit Patel', 'Dosa', 'Gujarat', 70, 14.00),
(111, 'Praveen Reddy', 'Pani Puri', 'Andhra Pradesh', 80, 1.00),
(112, 'Nikita Jain', 'Jalebi', 'Delhi', 65, 130.00),
(113, 'Rakesh Malhotra', 'Dosa', 'Haryana', 30, 60.00),
(114, 'Pooja Rao', 'Pani Puri', 'Telangana', 40, 70.00),
(115, 'Ravi Pandey', 'Jalebi', 'Uttar Pradesh', 45, 91.00),
(116, 'Nidhi Shah', 'Dosa', 'Maharashtra', 50, 1001.00),
(117, 'Raj Sinha', 'Pani Puri', 'Bihar', 35, 525.00),
(118, 'Anjali Kapoor', 'Jalebi', 'Punjab', 25, 500.00),
(119, 'Amit Khanna', 'Dosa', 'West Bengal', 60, 1200.00),
(120, 'Ritu Kaur', 'Pani Puri', 'Himachal Pradesh', 55, 825.00),
(121, 'Deepak Bhatt', 'Jalebi', 'Uttarakhand', 20, 400.00),
(122, 'Ajay Khan', 'Dosa', 'Maharashtra', 70, 1400.00),
(123, 'Pankaj Mishra', 'Pani Puri', 'Odisha', 80, 1200.00),
(124, 'Lavanya Joshi', 'Jalebi', 'Kerala', 65, 1300.00),
(125, 'Ishaan Desai', 'Dosa', 'Goa', 30, 600.00),
(126, 'Ankit Choudhary', 'Pani Puri', 'Rajasthan', 40, 600.00),
(127, 'Ravi Agarwal', 'Jalebi', 'Madhya Pradesh', 45, 900.00),
(128, 'Sonal Srivastava', 'Dosa', 'Uttar Pradesh', 50, 1000.00),
(129, 'Sumit Joshi', 'Pani Puri', 'Haryana', 35, 525.00),
(130, 'Megha Saxena', 'Jalebi', 'Karnataka', 25, 500.00),
(131, 'Gaurav Nair', 'Dosa', 'Tamil Nadu', 60, 1200.00),
(132, 'Anita Bhatia', 'Pani Puri', 'Gujarat', 55, 825.00),
(133, 'Puja Chatterjee', 'Jalebi', 'West Bengal', 70, 1400.00),
(134, 'Rohit Tripathi', 'Dosa', 'Delhi', 80, 1600.00),
(135, 'Kavita Reddy', 'Pani Puri', 'Andhra Pradesh', 65, 975.00),
(136, 'Ganesh Iyer', 'Jalebi', 'Kerala', 30, 600.00),
(137, 'Vidya Pillai', 'Dosa', 'Karnataka', 40, 800.00),
(138, 'Dinesh Chauhan', 'Pani Puri', 'Punjab', 45, 675.00),
(139, 'Rajiv Kapoor', 'Jalebi', 'Himachal Pradesh', 50, 1000.00),
(140, 'Mona Sharma', 'Dosa', 'Uttarakhand', 35, 700.00),
(141, 'Rahul Yadav', 'Pani Puri', 'Bihar', 25, 375.00),
(142, 'Priya Gupta', 'Jalebi', 'Madhya Pradesh', 60, 1200.00),
(143, 'Rajat Shukla', 'Dosa', 'Maharashtra', 55, 1100.00),
(144, 'Nikita Singh', 'Pani Puri', 'Rajasthan', 70, 1050.00),
(145, 'Siddharth Nair', 'Jalebi', 'Tamil Nadu', 80, 1600.00),
(146, 'Pallavi Kulkarni', 'Dosa', 'Karnataka', 65, 1300.00),
(147, 'Varun Rao', 'Pani Puri', 'Telangana', 30, 450.00),
(148, 'Sneha Patil', 'Jalebi', 'Maharashtra', 40, 800.00),
(149, 'Keshav Sinha', 'Dosa', 'Uttar Pradesh', 45, 900.00),
(150, 'Komal Chauhan', 'Pani Puri', 'Haryana', 50, 750.00),
(151, 'Sumit Joshi', 'Pani Puri', 'Haryana', 35, 5233.00),
(152, 'Megha Saxena', 'Jalebi', 'Karnataka', 25, 521.00),
(153, 'Gaurav Nair', 'Dosa', 'Tamil Nadu', 60, 123.00),
(154, 'Anita Bhatia', 'Pani Puri', 'Gujarat', 55, 823.00),
(155, 'Puja Chatterjee', 'Jalebi', 'West Bengal', 70, 142.00),
(156, 'Rohit Tripathi', 'Dosa', 'Delhi', 80, 164.00),
(157, 'Kavita Reddy', 'Pani Puri', 'Andhra Pradesh', 65, 1745.00),
(158, 'Ganesh Iyer', 'Jalebi', 'Kerala', 30, 1223.00),
(159, 'Vidya Pillai', 'Dosa', 'Karnataka', 40, 81.00),
(160, 'Dinesh Chauhan', 'Pani Puri', 'Punjab', 45, 67.00),
(161, 'Rajiv Kapoor', 'Jalebi', 'Himachal Pradesh', 50, 10.00),
(162, 'Mona Sharma', 'Dosa', 'Uttarakhand', 35, 99.00),
(163, 'Rahul Yadav', 'Pani Puri', 'Bihar', 25, 382.00),
(164, 'Priya Gupta', 'Jalebi', 'Madhya Pradesh', 60, 140.00),
(165, 'Rajat Shukla', 'Dosa', 'Maharashtra', 55, 123.00),
(166, 'Nikita Singh', 'Pani Puri', 'Rajasthan', 70, 11.00),
(167, 'Siddharth Nair', 'Jalebi', 'Tamil Nadu', 80, 1610.00),
(168, 'Pallavi Kulkarni', 'Dosa', 'Karnataka', 65, 1320.00),
(169, 'Varun Rao', 'Pani Puri', 'Telangana', 30, 400.00),
(170, 'Sneha Patil', 'Jalebi', 'Maharashtra', 40, 81.00),
(171, 'Keshav Sinha', 'Dosa', 'Uttar Pradesh', 45, 91.00),
(172, 'Komal Chauhan', 'Pani Puri', 'Haryana', 50, 75.00),
(173, 'Karan Shah', 'Jalebi', 'Madhya Pradesh', 60, 140.00),
(174, 'Karan Shah', 'Dosa', 'Maharashtra', 55, 123.00),
(175, 'Karan Shah', 'Pani Puri', 'Rajasthan', 70, 11.00),
(176, 'Karan Shah', 'Jalebi', 'Tamil Nadu', 80, 1610.00),
(177, 'Karan Shah', 'Dosa', 'Karnataka', 65, 1320.00),
(178, 'Karan Shah', 'Pani Puri', 'Telangana', 30, 400.00),
(179, 'Karan Shah', 'Jalebi', 'Maharashtra', 40, 81.00),
(180, 'Varun Rao', 'Dosa', 'Uttar Pradesh', 45, 91.00),
(181, 'Varun Rao', 'Pani Puri', 'Haryana', 50, 75.00),
(182, 'Rajesh Sharma', 'Jalebi', 'Madhya Pradesh', 60, 140.00),
(183, 'Rajesh Sharma', 'Dosa', 'Maharashtra', 55, 123.00),
(184, 'Rajesh Sharma', 'Pani Puri', 'Rajasthan', 70, 11.00),
(185, 'Varun Rao', 'Jalebi', 'Tamil Nadu', 80, 1610.00),
(186, 'Sneha Patil', 'Dosa', 'Karnataka', 65, 1320.00),
(187, 'Sneha Patil', 'Pani Puri', 'Telangana', 30, 400.00),
(188, 'Raj Sinha', 'Jalebi', 'Maharashtra', 40, 81.00),
(189, 'Komal Chauhan', 'Dosa', 'Uttar Pradesh', 45, 91.00),
(190, 'Varun Rao', 'Pani Puri', 'Haryana', 50, 75.00);


-- Understanding the basics of window functions 
/*
    Write a sql query to return the total amount sold per location 
*/
-- Using the traditional approach 
-- IT WORKS ON THE WHOLE DATASET AND THEN RETURNS THE AGGREGATION WITHOUT PRESERVING THE ROW IDENTITY
SELECT
    SALES_ID,
    LOCATION, 
    SUM(AMOUNT) AS TOTAL_AMOUNT
FROM SALES
GROUP BY LOCATION
ORDER BY TOTAL_AMOUNT ASC;

-- WINDOW FUNCTIONS 
/*
    SELECT
        COLUMN_1, 
        FUNCTION_NAME() OVER(PARTITION BY COLUMN* ORDER BY COLUMN* DESC/ASC) AS COLUMN_NAME
    FROM TABLE_NAME
*/
SELECT
    SALES_ID, 
    LOCATION, 
    SUM(AMOUNT) OVER(PARTITION BY LOCATION) AS TOTAL_AMOUNT
FROM SALES
ORDER BY LOCATION ASC;

SELECT LOCATION, COUNT(LOCATION)
FROM SALES 
GROUP BY LOCATION;


-- QUESTION 2
/*
    Show the sales_person_name, product_name, quantity_sold, and total quantity sold per 
    product across all locations.
*/
SELECT
    SALES_PERSON_NAME, 
    PRODUCT_NAME, 
    QUANTITY_SOLD, 
    SUM(QUANTITY_SOLD) AS TOTAL_QUANTITY
FROM SALES
GROUP BY SALES_PERSON_NAME, PRODUCT_NAME, QUANTITY_SOLD
ORDER BY SALES_PERSON_NAME ASC, PRODUCT_NAME DESC;

-- UNDERSTAND THE PARTITION BY THIS QUERY
SELECT
    SALES_PERSON_NAME, 
    PRODUCT_NAME, 
    QUANTITY_SOLD, 
    SUM(QUANTITY_SOLD) OVER(PARTITION BY SALES_PERSON_NAME, PRODUCT_NAME ORDER BY QUANTITY_SOLD) AS TOTAL_QUANTITY_SOLD
FROM SALES
ORDER BY SALES_PERSON_NAME ASC, PRODUCT_NAME ASC;

SELECT
    PRODUCT_NAME, 
    SUM(QUANTITY_SOLD) AS TOTAL_QTY
FROM SALES 
GROUP BY PRODUCT_NAME
ORDER BY PRODUCT_NAME ASC;


-- QUESTION 
/*
    Based on the data which you have display the sales_id,  sales_person_name, product_name, quantity_sold, total_quantity_sold. 
    Note that you need to display the running total of the quantity sold
*/
SELECT 
    SALES_ID, 
    SALES_PERSON_NAME,
    PRODUCT_NAME, 
    QUANTITY_SOLD, 
    SUM(QUANTITY_SOLD) OVER(PARTITION BY SALES_PERSON_NAME, PRODUCT_NAME ORDER BY SALES_ID ASC) AS TOTAL_QTY
FROM SALES
ORDER BY SALES_PERSON_NAME ASC, PRODUCT_NAME ASC, TOTAL_QTY ASC;



-- QUESTION 3
/*
    Show each salesperson’s quantity_sold, and the min and max quantity sold in their location.
*/
-- GET THE MAXIMUM AND MINIMUM QTY SOLD BY EACH SALES PERSON IN DIFFERENT LOCATION
SELECT
    SALES_PERSON_NAME,
    LOCATION,
    MIN(QUANTITY_SOLD) OVER(PARTITION BY LOCATION) AS MINIMUM_QTY,
    QUANTITY_SOLD AS QTY_SOLD,
    MAX(QUANTITY_SOLD) OVER(PARTITION BY LOCATION) AS MAXIMUM_QTY
FROM SALES
ORDER BY LOCATION ASC;


-- WINDOW FUNCTION SESSION 2
-- ASSIGNING THE ACCOUNT TYPE 
USE ROLE ACCOUNTADMIN;

-- USING THE WAREHOUSE AVAILABLE
USE WAREHOUSE COMPUTE_WH;

-- CREATING A DATABASE NAMED AS SUBQUERIES_DATABASE
CREATE DATABASE IF NOT EXISTS WINDOW_FUNCTIONS_DB_2;

-- USING THE DATABASE CREATED
USE DATABASE WINDOW_FUNCTIONS_DB_2;

-- CREATING A SCHEMA NAMED AS SUBQUERIES_SCHEMA
CREATE SCHEMA IF NOT EXISTS WINDOW_FUNCTIONS_SCHEMA_2;

-- USING THE SCHEMA CREATED 
USE SCHEMA WINDOW_FUNCTIONS_SCHEMA_2;

-- QUESTION 
/*
Tables
* `Signups(user_id, time_stamp)`
* `Confirmations(user_id, time_stamp, action)`
Each user may request multiple confirmation messages (either 'confirmed' or 'timeout')
Task:
    Write a query to find the **confirmation rate** for each user, defined as:
    Confirmed messages / total confirmation requests (confirmed + timeout)
    If a user has no requests, their rate is 0.
    Round the result to 2 decimal places
    Return: `user_id` and `confirmation_rate` (in any order).
*/
CREATE OR REPLACE TABLE Signups (
    user_id INT PRIMARY KEY,
    time_stamp DATETIME
);

INSERT INTO Signups (user_id, time_stamp) VALUES
(3, '2020-03-21 10:16:13'),
(7, '2020-01-04 13:57:59'),
(2, '2020-07-29 23:09:44'),
(6, '2020-12-09 10:39:37');



CREATE OR REPLACE TABLE Confirmations (
    user_id INT,
    time_stamp DATETIME,
    action string,
    PRIMARY KEY (user_id, time_stamp),
    FOREIGN KEY (user_id) REFERENCES Signups(user_id)
);

INSERT INTO Confirmations (user_id, time_stamp, action) VALUES
(3, '2021-01-06 03:30:46', 'timeout'),
(3, '2021-07-14 14:00:00', 'timeout'),
(7, '2021-06-12 11:57:29', 'confirmed'),
(7, '2021-06-13 12:58:28', 'confirmed'),
(7, '2021-06-14 13:59:27', 'confirmed'),
(2, '2021-01-22 00:00:00', 'confirmed'),
(2, '2021-02-28 23:59:59', 'timeout');


/*
    Write a query to find the **confirmation rate** for each user, defined as:
    Confirmed messages / total confirmation requests (confirmed + timeout)
    If a user has no requests, their rate is 0.
*/

-- Write your MySQL query statement below
SELECT
    T1.USER_ID, 
    ROUND(
        DIV0
        (
            SUM(CASE WHEN T2.ACTION = 'confirmed' THEN 1 ELSE 0 END),
            COUNT(T2.ACTION)
        ), 2
    ) AS confirmation_rate
FROM SIGNUPS AS T1
LEFT JOIN CONFIRMATIONS AS T2
ON T1.USER_ID = T2.USER_ID
GROUP BY T1.USER_ID;




-- Window Functions 
-- Create the table
CREATE OR REPLACE TABLE SALES_DATA (
    SALE_ID INT,
    SALESPERSON STRING,
    REGION STRING,
    SALE_AMOUNT NUMBER(10,2)
);

-- Insert sample data
INSERT INTO SALES_DATA (SALE_ID, SALESPERSON, REGION, SALE_AMOUNT) VALUES
(1,  'Amit',    'North', 5000),
(2,  'Priya',   'South', 7000),
(3,  'Rohan',   'East',  6000),
(4,  'Anjali',  'North', 5000),
(5,  'Sameer',  'East',  8000),
(6,  'Meera',   'South', 7000),
(7,  'Vikram',  'North', 9000),
(8,  'Kunal',   'East',  6000),
(9,  'Neha',    'South', 8500),
(10, 'Aarav',   'North', 9000),
(11, 'Tanya',   'East',  8000),
(12, 'Rajesh',  'South', 7000),
(13, 'Nikhil',  'North', 5000),
(14, 'Simran',  'East',  6000),
(15, 'Manish',  'South', 8500),
(16, 'Dev',     'North', 9000),
(17, 'Isha',    'East',  8000),
(18, 'Alok',    'South', 8500),
(19, 'Ritu',    'North', 5000),
(20, 'Sneha',   'East',  6000);

-- Window functions  - concept of ranking window functions 
SELECT *
FROM SALES_DATA;


-- RANK 
/*
    Write a SQL query to return the sales person who did the most sales from our dataset.
*/
-- Query 
SELECT 
    SALESPERSON,
    SALE_AMOUNT
FROM SALES_DATA
ORDER BY SALE_AMOUNT DESC
LIMIT 1;


-- ROW_NUMBER()
   /*
        Row Number is nothing but a ranking window function which assigns a unique row number value based on the order by column we have mentioned. 
        1, 2, 3, 4, 5, 6, 7, ........, 99, 100.
   */
-- RANK()
-- DENSE_RANK()

SELECT
    SALESPERSON, 
    REGION,
    SALE_AMOUNT, 
    ROW_NUMBER() OVER(ORDER BY SALE_AMOUNT DESC) AS RANK_GIVEN
FROM SALES_DATA;

/*
    Write a SQL query to return the top 3 sales person based on their sale_amount
*/
WITH CTE AS (
SELECT
    SALESPERSON, 
    SALE_AMOUNT, 
    ROW_NUMBER() OVER(ORDER BY SALE_AMOUNT DESC) AS RANK_GIVEN_USING_ROW_NUMBER
FROM SALES_DATA ) 
SELECT *
FROM CTE 
WHERE RANK_GIVEN_USING_ROW_NUMBER < 4;


-- RANK()
/*
    Rank is the function which assigns the rank based on the order by logic given to the function in the over clause. 
    The ranking is based on the factor two same ranks will be given to the row where the logic is same. 
    Rank function skips the number of same rank given to the next ranking number.
    RANK + NUMBER_OF_REP_IN_SAME_RANK
    EXAMPLE 
    9000 - 1ST RANK - 3 
    8500 - 2ND RANK - 1 + 3 = 4
*/
SELECT
    SALESPERSON, 
    SALE_AMOUNT, 
    ROW_NUMBER() OVER(ORDER BY SALE_AMOUNT DESC) AS RANK_GIVEN_USING_ROW_NUMBER,
    RANK() OVER(ORDER BY SALE_AMOUNT DESC) AS RANK_USING_RANK_FUNCTION
FROM SALES_DATA;


-- DENSE_RANK() 
/*
    Give the rank based on the logic given to the over clause and the order by part. 
    But it is also the function which does not skip the rank even if it was given more than 1 time. 
*/
SELECT
    SALESPERSON, 
    SALE_AMOUNT, 
    DENSE_RANK() OVER(ORDER BY SALE_AMOUNT DESC) AS RANK_GIVEN_USING_DENSE_RANK
FROM SALES_DATA;


SELECT
    SALESPERSON, 
    SALE_AMOUNT, 
    ROW_NUMBER() OVER(ORDER BY SALE_AMOUNT DESC) AS RANK_GIVEN_USING_RN_RANK,
    RANK() OVER(ORDER BY SALE_AMOUNT DESC) AS RANK_GIVEN_USING_RANK,
    DENSE_RANK() OVER(ORDER BY SALE_AMOUNT DESC) AS RANK_GIVEN_USING_DENSE_RANK
FROM SALES_DATA;

SELECT
    SALESPERSON, 
    REGION, 
    SALE_AMOUNT, 
    ROW_NUMBER() OVER(PARTITION BY REGION ORDER BY SALE_AMOUNT DESC) AS RANK_GIVEN_USING_RN_RANK
FROM SALES_DATA;

SELECT *
FROM SALES_DATA
WHERE SALE_AMOUNT = 9000;



-- CREATING TABLE
CREATE TABLE employees (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    department VARCHAR(50),
    age INT,
    salary DECIMAL(10, 2)
);


-- INSERTING VALUES 
INSERT INTO employees (id, name, department, age, salary) VALUES
(1, 'John Doe', 'HR', 30, 50000.00),
(2, 'Jane Smith', 'IT', 25, 70000.00),
(3, 'Michael Brown', 'Finance', 40, 85000.00),
(4, 'Emily Davis', 'IT', 35, 75000.00),
(5, 'Chris Johnson', 'HR', 28, 55000.00),
(6, 'Anna Wilson', 'Finance', 50, 90000.00),
(7, 'David Lee', 'IT', 45, 80000.00),
(8, 'Sophia King', 'HR', 26, 53000.00),
(9, 'James White', 'Finance', 38, 88000.00),
(10, 'Olivia Green', 'IT', 32, 72000.00);




-- LEAD()
/*
 We want to compare each employee’s salary with the salary of the next employee in the same department. 
 Can you show the employee's current salary along with the salary of the next employee within the same department?
*/
SELECT 
    id,
    name,
    department,
    salary,
    LEAD(salary, 1) OVER (ORDER BY salary DESC) AS next_employee_salary
FROM employees;


/*
    We want to track the salary progression of employees in the IT department. 
    For each employee, can you show their salary along with the salary of the next two employees in the IT department?
*/
SELECT 
    id,
    name,
    department,
    salary,
    LEAD(salary, 1) OVER (PARTITION BY department ORDER BY salary) AS next_employee_salary,
    LEAD(salary, 2) OVER (PARTITION BY department ORDER BY salary) AS second_next_employee_salary
FROM employees
WHERE department = 'IT';




















