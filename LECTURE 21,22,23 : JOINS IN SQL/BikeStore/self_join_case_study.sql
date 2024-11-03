----------------------------------------------------------------------------case study ------------------------------------------------------------------------
/*
The staffs table stores the staff information such as id, first name, last name, and email. 
It also has a column named manager_id that specifies the direct manager. 
For example, Mireya reports to Fabiola because the value in the manager_id of Mireya is Fabiola.
Fabiola has no manager, so the manager id column has a NULL.

To get who reports to whom, you use the self join as shown in the following query:
*/

SELECT
    e.first_name || ' ' || e.last_name AS employee,
    m.first_name || ' ' || m.last_name AS manager
FROM BIKESTORES.SALES.STAFFS AS e
INNER JOIN BIKESTORES.SALES.STAFFS AS m ON m.staff_id = e.manager_id
ORDER BY manager;

/*
In this example, we referenced to the staffs table twice: one as e for the employees and the other as m for the managers. 
The join predicate matches employee and manager relationship using the values in the e.manager_id and m.staff_id columns.
The employee column does not have Fabiola Jackson because of the INNER JOIN effect. 

If you replace the INNER JOIN clause by the LEFT JOIN clause as shown in the following query, 
you will get the result set that includes Fabiola Jackson in the employee column:
*/

SELECT
    e.first_name || ' ' || e.last_name AS employee,
    m.first_name || ' ' || m.last_name AS manager
FROM sales.staffs e
LEFT JOIN sales.staffs m ON m.staff_id = e.manager_id
ORDER BY manager;


-- Using self join to compare rows within a table

--The following statement uses the self join to find the customers located in the same city.

SELECT
 c1.city,
 c1.first_name || ' ' ||  c1.last_name customer_1,
 c2.first_name || ' ' ||  c2.last_name customer_2
FROM sales.customers c1
INNER JOIN sales.customers c2 ON c1.customer_id > c2.customer_id
AND c1.city = c2.city
ORDER BY
 city,customer_1,customer_2;

/*
The following condition makes sure that the statement doesn’t compare the same customer: c1.customer_id > c2.customer_id

And the following condition matches the city of the two customers: AND c1.city = c2.city

Note that if you change the greater than ( > ) operator by the not equal to (<>) operator, you will get more rows:

-- The following query returns the customers located in Albany:
*/

SELECT
 customer_id, first_name || ' ' ||  last_name AS c,city
FROM sales.customers
WHERE city = 'Albany'
ORDER BY c;

-- Let’s see the difference between > and <> in the ON clause by limiting to one city to make it easier for comparison.

-- This query uses ( >) operator in the ON clause:
SELECT
 c1.city,
 c1.first_name || ' ' || c1.last_name customer_1,
 c2.first_name || ' ' || c2.last_name customer_2
FROM sales.customers c1
INNER JOIN sales.customers c2 ON c1.customer_id > c2.customer_id
AND c1.city = c2.city
WHERE c1.city = 'Albany'
ORDER BY c1.city, customer_1, customer_2;


-- This query uses ( <>) operator in the ON clause:
SELECT
 c1.city,
 c1.first_name || ' ' || c1.last_name customer_1,
 c2.first_name || ' ' || c2.last_name customer_2
FROM sales.customers c1
INNER JOIN sales.customers c2 ON c1.customer_id <> c2.customer_id
AND c1.city = c2.city
WHERE c1.city = 'Albany'
ORDER BY c1.city, customer_1, customer_2;
