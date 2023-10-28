/*The Full Join (Also known as Full Outer join) includes the rows from both the tables. 
Wherever the rows do not match a null value is assigned to every column of the table that does not have a matching row. 
A Full join looks like a Right Join & Left Join combined together in one query. 

Syntax
The syntax of the Full join is as follows
 
SELECT <Columns>   
FROM tableA 
FULL JOIN tableB
ON (join_condition)

The matching rows from both tables
All the unmatched rows from Table A with null for columns from Table B
All the unmatched rows from Table B with null for columns from Table A
 
The join_condition defines the condition on which the tables are joined.

All the rows from both the tables are included in the final result. 
A NULL value is assigned to every column of the table that does not have a matching row based on the join condition.

The FULL OUTER JOIN & FULL JOIN are the same. The Keyword OUTER is optional

Sample database
Consider the following tables from the table reservation system of a restaurant. You can use the following script to create the database

CustomerType : Type of Customer like VIP / Regular etc
Customers List of customers with Customer Type.
Tables The list of tables available in the restaurant. CustomerID field indicates that the customer has reserved the table.
Orders : The orders placed by the customer
DiscVoucher The discounts slab based on the total value of the order

*/

create table customerType (
 CustomerTypeID int primary key, 
 Name varchar(10)
)
 
insert into customerType values (1,'VIP');
insert into customerType values (2,'Regular');
 
 
create table Customers (
   CustomerID int primary key,
   Name varchar(100),
   CustomerTypeID int null,
   CONSTRAINT FK_Customers_CustomerTypeID FOREIGN KEY (CustomerTypeID)
      REFERENCES customerType (CustomerTypeID)
);
 
insert into Customers values(1, 'Kevin Costner',1);
insert into Customers values(2, 'Akshay Kumar',2);
insert into Customers values(3, 'Sean Connery',1);
insert into Customers values(4, 'Sanjay Dutt',2);
insert into Customers values(5, 'Sharukh Khan',null);
 
 
create table Tables (
   TableNo int primary key,
   CustomerID int null,
   CONSTRAINT FK_Tables_CustomerID FOREIGN KEY (CustomerID)
      REFERENCES Customers (CustomerID)
);
 
insert into Tables values(1, null);
insert into Tables values(2, 1);
insert into Tables values(3, 2);
insert into Tables values(4, 5);
insert into Tables values(5, null);
 
 
create table Orders (
   OrderNo int primary key,
   OrderDate datetime,
   CustomerID int null,
   Amount decimal(10,2),
   CONSTRAINT FK_Orders_CustomerID FOREIGN KEY (CustomerID)
      REFERENCES Customers (CustomerID)
);
 
insert into Orders Values(1,'2019-12-10',1,5000);
insert into Orders Values(2,'2019-12-09',1,3000);
insert into Orders Values(3,'2019-12-10',2,7000);
insert into Orders Values(4,'2019-12-01',2,7000);
insert into Orders Values(5,'2019-12-10',3,1000);
insert into Orders Values(6,'2019-12-03',3,1000);
insert into Orders Values(7,'2019-12-10',4,3000);
insert into Orders Values(8,'2019-12-10',2,4000);
 
create table DiscVoucher (
   FromAmount decimal(10,0) ,
   UptoAmount decimal(10,0) ,
   Discount decimal(10,0)
);
 
insert into DiscVoucher Values(0,3000,0);
insert into DiscVoucher Values(3001,8000,10);
insert into DiscVoucher Values(8001,99999,25)  ;

--Query
--The following query joins the customers with the tables
 
Select C.CustomerID,C.Name, T.TableNo
From Customers C
full join Tables T on C.CustomerID=T.CustomerID;
 
--The above query returns all the customers & all the tables. 
--The result shows

/* Customers who have booked the tables (matching rows)
Customers who have not reserved the table. The Table No column has NULL Value
Unreserved tables. The customerID & Name column has NULL Values */

--Where clause
--By filtering out the results where CustomerID is null, it will return all the customers with reserved tables.
--The result is similar to what you get when you use the Left Join
Select C.CustomerID,C.Name, T.TableNo
From Customers C
full join Tables T on C.CustomerID=T.CustomerID
where  C.CustomerID is not null;


-- Similarly, by filtering out the result where Table No is null, the query will return the list of tables with the customer who booked it. 
--The result is similar to Right Join

Select C.CustomerID,C.Name, T.TableNo
From Customers C
full join Tables T on (C.CustomerID=T.CustomerID)
where  T.TableNo is not null;

-- Finally, filtering out both null customers and tableNo, you will get the result which is what you get when you use inner join
Select C.CustomerID,C.Name, T.TableNo
From Customers C
full join Tables T on C.CustomerID=T.CustomerID
where C.CustomerID is not null and T.TableNo is not null;
















