/* The Left join (or left outer join) is one of the most commonly used join statement in SQL Server. 
A join lets us combine results from two or more tables into a single result set. 
The left join includes all the results from the left table and includes only the matching rows from the right table. 

Syntax :
 
SELECT <Columns> 
FROM tableA 
LEFT JOIN tableB
ON (join_condition)
 
The join_condition defines the condition on which the tables are joined. The final result includes

All the rows from the left table. i.e tableA
Each row of the tableB is compared with the tableA. 
If the condition is evaluated to true, then the rows from the tableB are included in the result.  
A NULL value is assigned to every column of table B that does not have a matching row based on the join condition.
The LEFT Join is the same as LEFT OUTER JOIN. The keyword OUTER is optional.

CustomerType : Type of Customer like VIP / Regular etc
Customers List of customers with Customer Type.
Tables The list of tables available in the restaurant. CustomerID field indicates that the customer has reserved the table.
Orders : The orders placed by the customer
DiscVoucher The discounts slab based on the total value of the order
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


--Left Join Query
--We would like to know the list of all customers, along with their reserved table No.

Select C.CustomerID,C.Name, T.TableNo
From Customers C
left join Tables T on C.CustomerID = T.CustomerID;

--The result includes all the customers. But it returns the only the matching rows from the Tables.

--What if you change the order of the tables appearing in the query i.e. exchanges customers & tables as shown below
Select C.CustomerID,C.Name, T.TableNo
From Tables T
left join Customers C on C.CustomerID=T.CustomerID;

--The results are different from the above. The result includes all the tables and only matching rows from the customers.

/* WHERE Condition
The WHERE clause will filter the rows after the JOIN has occurred

For Example in the following query, the join happens first. 
The Where filter is applied to the join result to get the final output. 
The result of the following query is similar to the inner join query. */

Select C.CustomerID,C.Name, T.TableNo
From Customers C left join Tables T on C.CustomerID=T.CustomerID
Where TableNo is not null;

-- Difference between inner join and left join
Select C.CustomerID,C.Name, T.TableNo
From Customers C
join Tables T on C.CustomerID = T.CustomerID;
 
OR
 
Select C.CustomerID,C.Name, T.TableNo
From Tables T join Customers C on C.CustomerID = T.CustomerID;

-- In an inner join, result includes only the matching rows.
-- Order of the table is not important in the inner join

--Subquery in Left Join
 
Select Cu.CustomerID,Cu.Name, Ord.Amount
From Customers Cu
left join 
(Select CustomerID, Sum(Amount) As Amount
 From Orders 
 Group by CustomerID) as Ord On Cu.CustomerID = Ord.CustomerID;

-- Multiple Conditions

Select Cu.CustomerID,Cu.Name, Ord.OrderDate, Ord.Amount
From Customers Cu left join Orders Ord On (Cu.CustomerID= Ord.CustomerID and OrderDate='2019-12-10');


--Join Operator other than equality
--You can also have a logical operator other than equality in the join condition. 
--The following query returns the discount to be given to the customer based on their spend.

select Cu.CustomerID,Cu.Name, Ord.Amount, disc.Discount
From Customers Cu
Left join 
( Select CustomerID, Sum(Amount) As Amount
  From Orders
  Group by CustomerID) Ord On Cu.CustomerID = Ord.CustomerID
join DiscVoucher disc on ( ord.amount >= disc.FromAmount and ord.amount <= disc.UptoAmount);



