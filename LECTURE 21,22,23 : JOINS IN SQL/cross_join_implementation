/*
Cross join joins each row of one table with each row of another table. 
The result of the cross join is a Cartesian product (also called the cross product) of the two

Syntax
There are two syntaxes available for a cross join
 
Select [columns]
from TableA
cross join TableB

You can also use the tables in from clause, without a where clause.
 
Select [columns]
from TableA , TableB
 
The best example of a cross product is a deck of cards. 
It contains 13 cards with rank from A, K, Q, J, 10, 9, 8, 7, 6, 5, 4, 3 & 2. 
It contains a card suite of heart, diamond, club, and spade. 
The cartesian product of the above cards results in a 52 elements representing every card is a set.

The following queries create the sample database for our cross join. It contains two tables. cards & suites.
*/

create table cards 
(
 card char(2) primary key
);
 
insert into cards values ('A'), ('K'), ('Q'), ('J'),('10'),('9'),('8'),('7'),('6'),('5'),('4'),('3'),('2');
 
 
create table suites 
(
 suite char(1) primary key
);
 
insert into suites values ('S'), ('H'), ('D'), ('C');

--The following is the cross join of the above two tables.
 
select s.suite, c.card
from  cards c
cross join suites s;
 
OR 
 
select s.suite, c.card
from  cards c , suites s ;
 
--The query will result in all possible combination of cards & suites totaling 52 rows

-- We will create two new tables  for the demonstration of the cross join:
-- sales_organization table stores the sale organizations.
-- sales_channel table stores the sales channels.

-- The following statements create the sales_organization and sales_channel tables:

CREATE TABLE sales_organization (
	sales_org_id INT PRIMARY KEY,
	sales_org VARCHAR (255)
);

CREATE TABLE sales_channel (
	channel_id INT PRIMARY KEY,
	channel VARCHAR (255)
);

-- Suppose the company has two sales organizations that are Domestic and Export, which are in charge of sales in the domestic and international markets.

-- The following statement inserts two sales organizations into the sales_organization table:

INSERT INTO sales_organization (sales_org_id, sales_org)
VALUES
	(1, 'Domestic'),
	(2, 'Export');

-- The company can distribute goods via various channels such as wholesale, retail, eCommerce, and TV shopping.
-- The following statement inserts sales channels into the sales_channel table:

INSERT INTO sales_channel (channel_id, channel)
VALUES
	(1, 'Wholesale'),
	(2, 'Retail'),
	(3, 'eCommerce'),
	(4, 'TV Shopping');

-- To find the all possible sales channels that a sales organization can have, you use the CROSS JOIN to join the sales_organization table with the sales_channel table as follows:

SELECT sales_org,channel
FROM sales_organization
CROSS JOIN sales_channel; 

-- The result set includes all possible rows in the sales_organization and sales_channel tables.

-- The following query is equivalent to the statement that uses the CROSS JOIN clause above:

SELECT sales_org,channel
FROM sales_organization,sales_channel;

-- In some database systems such as PostgreSQL and Oracle, you can use the INNER JOIN clause with the condition that always evaluates to true to perform a cross join such as:

SELECT sales_org,channel
FROM sales_organization
INNER JOIN sales_channel ON 1 = 1;











