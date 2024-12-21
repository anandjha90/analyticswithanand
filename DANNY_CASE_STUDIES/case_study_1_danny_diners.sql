CREATE OR REPLACE DATABASE DANNY_DB;
CREATE OR REPLACE SCHEMA DANNY_SCHEMA;
 

CREATE OR REPLACE TABLE menu (
  product_id INTEGER PRIMARY KEY,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE OR REPLACE TABLE members (
  customer_id VARCHAR(1) PRIMARY KEY,
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09'),
  ('C', '2021-01-08');

CREATE OR REPLACE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER,
  FOREIGN KEY (customer_id) REFERENCES members(customer_id),
  FOREIGN KEY (product_id) REFERENCES menu(product_id)
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');  

-- master table creation
CREATE OR REPLACE TABLE DANNY_DINERS_MASTER AS
    SELECT 
     s.*,
     mem.join_date,
     m.product_name,
     m.price
    FROM 
        sales as s
    LEFT JOIN 
        members as mem 
    ON s.customer_id = mem.customer_id
    LEFT JOIN menu as m 
    ON s.product_id = m.product_id;
  
SELECT * FROM DANNY_DINERS_MASTER;

-- Case Study Questions
-- Each of the following case study questions can be answered using a single SQL statement:

-- What is the total amount each customer spent at the restaurant?
SELECT 
  s.customer_id, 
  SUM(m.price) AS total_sales
FROM sales AS s
JOIN menu AS m
  ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1;

-- How many days has each customer visited the restaurant?
SELECT 
  customer_id, 
  COUNT(DISTINCT order_date) AS visit_count
FROM sales
GROUP BY customer_id;

-- What was the first item from the menu purchased by each customer?
WITH ordered_sales AS (
  SELECT 
    s.customer_id, 
    s.order_date, 
    m.product_name,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
  FROM sales AS s
  JOIN menu AS m 
  ON s.product_id = m.product_id
) 

SELECT 
  customer_id, 
  product_name
FROM ordered_sales
WHERE rank = 1
GROUP BY 1,2;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
  m.product_name,
  COUNT(s.product_id) AS most_purchased_item
FROM sales AS s
JOIN menu AS m
  ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY most_purchased_item DESC;
--LIMIT 1;

-- Which item was the most popular for each customer?
WITH most_popular AS (
  SELECT 
    s.customer_id, 
    m.product_name, 
    COUNT(m.product_id) AS order_count,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(m.product_id) DESC) AS rank
  FROM menu as m
  JOIN sales as s
    ON m.product_id = s.product_id
  GROUP BY s.customer_id, m.product_name
)

SELECT 
  customer_id, 
  product_name, 
  order_count
FROM most_popular 
WHERE rank = 1;

-- Which item was purchased first by the customer after they became a member?
WITH joined_as_member AS (
  SELECT
    m.customer_id, 
    s.product_id,
    ROW_NUMBER() OVER(PARTITION BY m.customer_id ORDER BY s.order_date) AS row_num
  FROM members as m
  JOIN sales as s
    ON m.customer_id = s.customer_id
    AND s.order_date > m.join_date
)

SELECT 
  customer_id, 
  product_name 
FROM joined_as_member
JOIN menu
  ON joined_as_member.product_id = menu.product_id
WHERE row_num = 1
ORDER BY customer_id ASC;

-- Which item was purchased just before the customer became a member?
WITH purchased_prior_member AS (
  SELECT 
    m.customer_id, 
    s.product_id,
    ROW_NUMBER() OVER(PARTITION BY m.customer_id ORDER BY s.order_date DESC) AS rank
  FROM members as m
  JOIN sales as s
    ON m.customer_id = s.customer_id
    AND s.order_date < m.join_date
)

SELECT 
  ppm.customer_id, 
  m.product_name 
FROM purchased_prior_member AS ppm
JOIN menu as m
  ON ppm.product_id = m.product_id
WHERE rank = 1
ORDER BY ppm.customer_id ASC;

-- What is the total items and amount spent for each member before they became a member?
SELECT 
  s.customer_id, 
  COUNT(s.product_id) AS total_items, 
  SUM(m.price) AS total_sales
FROM sales as s
JOIN members as mem ON s.customer_id = mem.customer_id
  AND s.order_date < mem.join_date
JOIN menu as m
  ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points_cte AS (
  SELECT 
    m.product_id, 
    CASE
      WHEN product_id = 1 THEN price * 20
      ELSE price * 10
    END AS points
  FROM menu as m
)

SELECT 
  s.customer_id, 
  SUM(points_cte.points) AS total_points
FROM sales as s
JOIN points_cte
  ON s.product_id = points_cte.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?  

WITH dates_cte AS (
  SELECT 
    customer_id, 
    join_date, 
    join_date + 6 AS valid_date, 
    DATE_TRUNC('month', '2021-01-31'::DATE) + interval '1 month' - interval '1 day' AS last_date
  FROM members as mem
)

SELECT 
  s.customer_id, 
  SUM(CASE
    WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
    WHEN s.order_date BETWEEN dates.join_date AND dates.valid_date THEN 2 * 10 * m.price
    ELSE 10 * m.price END) AS points
FROM sales as s
JOIN dates_cte AS dates
  ON s.customer_id = dates.customer_id
  AND s.order_date <= dates.last_date
JOIN menu as m
  ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- Bonus Questions
-- Join All The Things
-- Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)
SELECT 
  s.customer_id, 
  s.order_date,  
  m.product_name, 
  m.price,
  CASE
    WHEN mem.join_date > s.order_date THEN 'N'
    WHEN mem.join_date <= s.order_date THEN 'Y'
    ELSE 'N' END AS member_status
FROM sales as s
LEFT JOIN members as mem
  ON s.customer_id = mem.customer_id
JOIN menu as m
  ON s.product_id = m.product_id
ORDER BY mem.customer_id, s.order_date;

-- Rank All the Things
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he --  expects null ranking values for the records when customers are not yet part of the loyalty program.

WITH customers_data AS (
  SELECT 
    s.customer_id, 
    s.order_date,  
    m.product_name, 
    m.price,
    CASE
      WHEN mem.join_date > s.order_date THEN 'N'
      WHEN mem.join_date <= s.order_date THEN 'Y'
      ELSE 'N' END AS member_status
  FROM sales as s
  LEFT JOIN members as mem
    ON s.customer_id = mem.customer_id
  JOIN menu as m
    ON s.product_id = m.product_id
  ORDER BY mem.customer_id, s.order_date
)

SELECT 
  *, 
  CASE
    WHEN member_status = 'N' then NULL
    ELSE RANK () OVER(PARTITION BY customer_id, member_status ORDER BY order_date) END AS ranking
FROM customers_data;

-- Insights
-- From the analysis, we discover a few interesting insights that would be certainly useful for Danny.
/*
- Customer B is the most frequent visitor with 6 visits in Jan 2021.
- Danny’s Diner’s most popular item is ramen, followed by curry and sushi.
- Customer A and C loves ramen whereas Customer B seems to enjoy sushi, curry and ramen equally. Who knows, I might be Customer B!
- Customer A is the 1st member of Danny’s Diner and his first order is curry. Gotta fulfill his curry cravings!
- The last item ordered by Customers A and B before they became members are sushi and curry. Does it mean both of these items are the deciding factor? It 
  must be really delicious for them to sign up as members!
- Before they became members, both Customers A and B spent $25 and $40.
- Throughout Jan 2021, their points for 
        Customer A: 860 
        Customer B: 940
        Customer C: 360.
- Assuming that members can earn 2x a week from the day they became a member with bonus 2x points for sushi, Customer A has 660 points and Customer B has 340 
  by the end of Jan 2021.
