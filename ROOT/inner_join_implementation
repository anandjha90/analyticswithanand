/* The inner join is one of the most commonly used join statement in SQL Server. A join lets us combine results from two or more tables into a single result set. It includes only those results which are common to both the tables. This article explores the inner join in more detail with examples.

Syntax
The following is the syntax of inner join.
 
SELECT <Columns> 
FROM tableA 
INNER JOIN tableB
ON (join_condition)

The join_condition defines the condition on which the tables are joined. This condition is evaluated for each row of the result. If the condition is evaluated to true, then the rows are joined and added to the result set.

If the conditions do not match, then the rows are ignored and not added to the result set

The word INNER is not necessary as it is the default. Hence the following statement is the same as the above 

Sample database
Consider the following tables from the table reservation system of a restaurant

CustomerType : Customers are defined as VIP / Regular
Customers List of customers with Customer Type.
Tables The list of tables available in the restaurant. CustomerID field indicates that the customer has reserved the table.
Orders : The orders placed by the customer
DiscVoucher The discounts are offered based on the total value of the order

*/
create or replace table customerType (
 CustomerTypeID int primary key, 
 Name varchar(10)
);
 
insert into customerType values (1,'VIP');
insert into customerType values (2,'Regular');
 
 
create or replace table Customers (
   CustomerID int primary key,
   Name varchar(100),
   CustomerTypeID int null,
   CONSTRAINT FK_Customers_CustomerTypeID FOREIGN KEY (CustomerTypeID) REFERENCES customerType (CustomerTypeID)
);
 
insert into Customers values(1, 'Kevin Costner',1);
insert into Customers values(2, 'Akshay Kumar',2);
insert into Customers values(3, 'Sean Connery',1);
insert into Customers values(4, 'Sanjay Dutt',2);
insert into Customers values(5, 'Sharukh Khan',null);
 
 
create table Tables (
   TableNo int primary key,
   CustomerID int null,
   CONSTRAINT FK_Tables_CustomerID FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID)
);
 
insert into Tables values(1, null);
insert into Tables values(2, 1);
insert into Tables values(3, 2);
insert into Tables values(4, 5);
insert into Tables values(5, null);
 
 
create or replace table Orders (
   OrderNo int primary key,
   OrderDate datetime,
   CustomerID int null,
   Amount decimal(10,2),
   CONSTRAINT FK_Orders_CustomerID FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID)
);
 
insert into Orders Values(1,'2019-12-10',1,5000);
insert into Orders Values(2,'2019-12-09',1,3000);
insert into Orders Values(3,'2019-12-10',2,7000);
insert into Orders Values(4,'2019-12-01',2,7000);
insert into Orders Values(5,'2019-12-10',3,1000);
insert into Orders Values(6,'2019-12-03',3,1000);
insert into Orders Values(7,'2019-12-10',4,3000);
insert into Orders Values(8,'2019-12-10',2,4000);
 
create or replace table DiscVoucher (
   FromAmount decimal(10,0) ,
   UptoAmount decimal(10,0) ,
   Discount decimal(10,0)
);
 
insert into DiscVoucher Values(0,3000,0);
insert into DiscVoucher Values(3001,8000,10);
insert into DiscVoucher Values(8001,99999,25) ;


-- Query
-- As said earlier, the inner join returns the rows which have related rows in the joined table. 
-- Rows that do not have any relation to the other table are left out.
-- The following query returns the list of customers who have reserved a table.

Select C.CustomerID,C.Name, T.TableNo
From Customers C
join Tables T on C.CustomerID=T.CustomerID;

-- You can also make use of where clause instead of join clause as shown below. Snowflake /sql server is smart enough to do an inner join.
select C.CustomerID,C.Name,T.TableNo
From Customers C ,Tables T Where C.CustomerID=T.CustomerID;
 
-- Inner join 3 or more tables
-- You can join more than 3 tables in an join. 
-- The syntax is as shown below. You can also mix other types of joins  snowflake/sql server allows joining data from up to 256 tables.
 
/* SELECT <Columns> 
FROM first_table 
INNER JOIN second_table 
ON (join_condition)
INNER JOIN third_table 
ON (join_condition)
INNER JOIN fourth_table 
ON (join_condition) */

-- To get reserved tables with customer name & customer type, we need to join all the three tables together as shown below 
-- Note that the customer Sharukh khan ( CustomerID 5 ) has Customer Type as NULL.

Select Cu.CustomerID,Cu.Name, Tb.TableNo, ct.Name as CustomerType
From Customers Cu
join Tables Tb on Cu.CustomerID=Tb.CustomerID
join customerType ct on Cu.CustomerTypeID=ct.CustomerTypeID;

-- Analysis:
-- The interesting thing about the result is that CustomerID 5 (Sharukh Khan) does not appear in the result although he as reserved a table.
-- The Customers & tables have three matching rows. 
-- Hence the first inner join returns three rows. 
-- The result is joined with the CustomerType table. 
-- Customer with ID 5 does not have Customer Type, hence it is discarded and only two rows are returned.

/* Subquery in a Join
Instead of a table, you can make use of a subquery.

We have the Orders table in our sample database. it contains the date of order, customerID and amount of Order. 
We would like to find out the total order placed by each customer. */

--Query
-- We sum the amount field customer wise to arrive at the total order. 
-- We then join it with the customer table from where we can get the name as shown below

Select Cu.CustomerID,Cu.Name, Ord.Amount
From Customers Cu
join ( Select CustomerID, Sum(Amount) As Amount
       From Orders 
       Group by CustomerID) Ord On Cu.CustomerID= Ord.CustomerID;


-- Further, we can join the CustomerType table to know the type of customer as shown below
 
Select Cu.CustomerID,Cu.Name, Ord.Amount, ct.Name as CustomerType
From Customers Cu
join ( Select CustomerID, Sum(Amount) As Amount
       From Orders 
       Group by CustomerID) Ord On Cu.CustomerID= Ord.CustomerID
join customerType ct on cu.CustomerTypeID = ct.CustomerTypeID;

--Multiple Conditions in Join
--You can use more than one condition in the join condition. 
--The following query joins the customer table with the order table using both the CustomerId and OrderDate column.
select Cu.CustomerID,Cu.Name, Ord.OrderDate, Ord.Amount
From Customers Cu
join Orders Ord On Cu.CustomerID = Ord.CustomerID and OrderDate='2019-12-10';

-- An interesting point to note here is that the customer with id 2 appears twice in the result. 
-- Because the orders table has two matching records. Hence the final result includes both the records.

-- Comparison in join condition
-- We only looked at the equality operator in the join condition. Now let us see an example of other logical operators.

-- The customers are given a discount voucher based on their spend. We need to join the DiscVoucher table to find out the discount.
select Cu.CustomerID,Cu.Name, Ord.Amount, disc.Discount
From Customers Cu
join ( Select CustomerID, Sum(Amount) As Amount
       From Orders 
       Group by CustomerID) Ord On Cu.CustomerID= Ord.CustomerID
join DiscVoucher disc on (ord.amount >= disc.FromAmount and ord.amount <= disc.UptoAmount);













