USE DATABASE DEMO_DATABASE;

CREATE or replace TABLE cows_one (cnumber_1 int, cbreed varchar(20));

INSERT INTO cows_one VALUES (1,'Holstein');
INSERT INTO cows_one VALUES (2,'Guernsey');
INSERT INTO cows_one VALUES (3,'Angus');

SELECT * FROM cows_one;

CREATE OR REPLACE TABLE cows_two (cnumber_2 int, breeds varchar(20));

INSERT INTO cows_two VALUES (2,'Jersey');
INSERT INTO cows_two VALUES (3,'Brown Swiss');
INSERT INTO cows_two VALUES (4,'Ayrshire');

SELECT * FROM cows_two;

--An inner join, also known as a simple join, returns rows from joined tables 
---that have matching rows. 
--It does not include rows from either table that have no matching rows in the other.

SELECT x.cnumber_1,x.cbreed,y.BREEDS FROM cows_one as x
INNER JOIN cows_two as y ON x.cnumber_1 = y.cnumber_2;

--A left outer join selects all the rows from the table on the left (cows_one in the sample), and displays the matching rows from the table on the right (cows_two).
--It displays an empty row for the table on the right if the table has no matching row for the table on the left.

/* In all cases, the order of evaluation is as follows:

              -- Evaluate all filters in the ON clause.
              -- Add in rows from the outer table (in this case, the left table in the left outer join) that do not match the filters.
              -- Apply the where clause to the results of the outer join. */


SELECT * FROM cows_one 
LEFT OUTER JOIN cows_two ON cows_one.cnumber = cows_two.cnumber;

--A right join selects all the rows from the table on the right (cows_two in our sample), and displays the matching rows from the table on the left (cows_one). 
-- It displays an empty row for the table on the left if the table has no matching value for the table on the right.

SELECT * FROM cows_one 
RIGHT OUTER JOIN cows_two ON cows_one.cnumber = cows_two.cnumber;

--A full outer join returns all joined rows from both tables, plus one row for each unmatched left row (extended with nulls on the right), 
--plus one row for each unmatched right row (extended with nulls on the left).


SELECT * FROM cows_one 
FULL OUTER JOIN cows_two ON cows_one.cnumber = cows_two.cnumber;


SELECT * FROM cows_one 
LEFT OUTER JOIN cows_two ON cows_one.cnumber = cows_two.cnumber AND cows_one.cnumber < 3;

SELECT * FROM cows_one 
LEFT OUTER JOIN cows_two ON cows_one.cnumber = cows_two.cnumber WHERE cows_one.cnumber < 3;

SELECT * FROM cows_one 
LEFT OUTER JOIN cows_two ON cows_one.cnumber = 
cows_two.cnumber AND cows_two.cnumber < 3;

SELECT * FROM cows_one 
LEFT OUTER JOIN cows_two ON cows_one.cnumber = cows_two.cnumber WHERE cows_two.cnumber < 3;


SELECT * FROM cows_one INNER JOIN cows_two USING (cnumber);

/* Conditions ON, USING, and NATURAL

You can use the join conditions ON, USING, and NATURAL to specify join criteria.

The ON clause is the most flexible. 
It can handle all join criteria, and, in certain cases, non-join criteria.
The USING and NATURAL clauses provide convenient ways to specify joins 
when the join columns have the same name.

Cross join : You cannot use an ON, USING, or NATURAL condition with a cross join.

------------------------------------------Inner join--------------------------------------------------
The following examples show inner joins. ON join_condition */
SELECT * FROM cows_one INNER JOIN cows_two 
ON cows_one.cnumber = cows_two.cnumber;

-- The following statement is equivalent:
SELECT * FROM cows_one, cows_two WHERE cows_one.cnumber = cows_two.cnumber;

-- USING join_column_list
SELECT * FROM cows_one INNER JOIN cows_two USING (cnumber_1);

--- NATURAL
SELECT * FROM cows_one NATURAL INNER JOIN cows_two;


----------------------------------------------Left outer join-----------------------------------------------------
-- The following examples show left outer joins.ON join_condition
   SELECT * FROM cows_one LEFT JOIN cows_two ON cows_one.cnumber = cows_two.cnumber;
   

-- USING join_column_list
SELECT * FROM cows_one LEFT JOIN cows_two USING (cnumber_1,cnumber_2);


-- NATURAL
SELECT * FROM cows_one NATURAL LEFT JOIN cows_two;


-----------------------------------------Right outer join---------------------------------------------
--The following examples show right outer joins. ON join_condition
SELECT * FROM cows_one RIGHT JOIN cows_two ON cows_one.cnumber = cows_two.cnumber;


--USING join_column_list
SELECT * FROM cows_one RIGHT JOIN cows_two USING (cnumber);

--NATURAL
SELECT * FROM cows_one NATURAL RIGHT JOIN cows_two;

--------------------------------------Full outer join-----------------------------------------------------------------
--The following examples show full outer joins.ON join_condition
SELECT * FROM cows_one FULL OUTER JOIN cows_two ON cows_one.cnumber = cows_two.cnumber;

--USING join_column_list
SELECT * FROM cows_one FULL OUTER JOIN cows_two USING (cnumber);

--NATURAL
SELECT * FROM cows_one NATURAL FULL OUTER JOIN cows_two;






