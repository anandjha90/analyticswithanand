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
CREATE OR REPLACE TABLE DANNY_DINER_MASTER AS
SELECT DISTINCT
     s.*,
     mem.join_date,
     m.price,
     m.product_name
FROM sales as s 
LEFT JOIN members as mem ON s.customer_id = mem.customer_id
LEFT JOIN menu as m ON s.product_id = m.product_id;



-- Case Study Questions
-- Each of the following case study questions can be answered using a single SQL statement:

-- What is the total amount each customer spent at the restaurant?

/* Approach :
tables required : menu (price),sales(customer_id)
joins required : yes
type : inner
*/

--using joins
SELECT
    s.customer_id,
    SUM(m.price) AS amt_spent
FROM sales as s
INNER JOIN menu as m ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1;

-- using master table conecpt
SELECT
    customer_id,
    SUM(price) AS amt_spent
FROM DANNY_DINER_MASTER
GROUP BY 1
ORDER BY 2 DESC;


-- How many days has each customer visited the restaurant?
/*
    Approach :
    Tables Required : sales
    Columns Required : customer_id & order_date
    JOINS TYpe If Required : Not Required
    Aggregate Function If Req: Yes (group by)
    Window Fuinction If Req: NA
*/

SELECT
     customer_id,
     count(distinct order_date) as tot_visits
FROM sales
group by 1
order by 2 desc;
    
    
*/


-- What was the first item & last item from the menu purchased by each customer?
/*
    Approach :
    Logic : Order_date -> min & max
    Tables Required : menu & sales 
    Columns Required : customer_id,product_name
    JOINS TYpe If Required : Yes INNER JOIN
    Aggregate Function If Req: Yes (custmer_id) may be or may not --  NOT POSSIBLE 
    Window Fuinction If Req: ROW_NUMBER(),RANK(),DENSE_RANK(),FIRST_VAUE,LAST_VALUE -- any of these 
    SUB-QUERY/CTE Required : 

*/
;

-- CUSTOMER_ID , FIRST_ITEM_ORDERED,LAST_ITEM_ORDERED, FIRST_ORDER_DATE,LAST_ORDERED_DATE
SELECT 
    


FROM sales as s
INNER JOIN menu as m ON s.product_id = m.product_id



SELECT 
    s.customer_id,
    --m.product_name as item_ordered,
    MIN(s.order_date) as FIRST_ITEM_DATE,
    MAX(s.order_date) as LAST_ITEM_DATE
FROM sales as s
INNER JOIN menu as m ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1;

WITH ordered_item AS
(
    SELECT
      s.customer_id,
      s.order_date,
      m.product_name,
      ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as rn_asc,
      ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) as rn_desc,

    FROM sales as s
    join menu as m ON s.product_id = m.product_id   

)
SELECT 
     customer_id,
     MAX(CASE WHEN rn_asc = 1 THEN product_name END) AS first_item,
     MAX(CASE WHEN rn_asc = 1 THEN order_date END) AS first_ordered_date,
     MAX(CASE WHEN rn_desc = 1 THEN product_name END) AS last_item,
     MAX(CASE WHEN rn_desc = 1 THEN order_date END) AS last_ordered_date
FROM
     ordered_item
GROUP BY 1;


-- What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
     m.product_name,
     COUNT(s.product_id) as most_purchased_item
FROM sales as s
JOIN menu as m ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2 DESC;


-- Which item was the most popular for each customer?
-- client is asking what all columns ? -- customer_id,product_name,count
select 
    customer_id,
    product_name,
    orders_count
from    
(
select 
     s.customer_id,
     m.product_name,
     count(m.product_id) as orders_count,
     DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(m.product_id) DESC) as ord_rnk

FROM sales as s
JOIN menu as m ON s.product_id = m.product_id
group by 1,2
) as out
WHERE out.ord_rnk = 1;


-- Which item was purchased first by the customer after they became a member?
select 
    customer_id,
    product_name
FROM
(
SELECT
     mem.customer_id,
     s.order_date,
     m.product_name,
     DENSE_RANK() OVER(PARTITION BY s.customer_id order by s.order_date) as rnk
FROM sales as s
JOIN members as mem ON s.customer_id = mem.customer_id
JOIN menu as m on m.product_id = s.product_id
WHERE s.order_date >= mem.join_date
) as out
WHERE out.rnk = 1;

-- Which item was purchased just before the customer became a member?
select 
    customer_id,
    product_name
FROM
(
SELECT
     mem.customer_id,
     s.order_date,
     m.product_name,
     DENSE_RANK() OVER(PARTITION BY s.customer_id order by s.order_date) as rnk
FROM sales as s
JOIN members as mem ON s.customer_id = mem.customer_id
JOIN menu as m on m.product_id = s.product_id
WHERE s.order_date < mem.join_date
) as out
WHERE out.rnk = 1;


-- What is the total items and amount spent for each member before they became a member?
SELECT 
    s.customer_id,
    count(s.product_id) as tot_items,
    SUM(m.price) as tot_sales
FROM sales as s
JOIN members as mem ON s.customer_id = mem.customer_id AND s.order_date < mem.join_date
JOIN menu as m on m.product_id = s.product_id 
group by 1
order by 1;



-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with points_cte as
(
SELECT
     product_id,
     CASE
          WHEN product_id = 1 THEN price * 20
          ELSE price * 10
     END AS points
     FROM menu
)

select 
     s.customer_id,
     SUM(pt.points) as tot_points
from sales as s
join points_cte as pt ON s.product_id = pt.product_id
group by 1
order by 1;

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?  

with dates_cte as
(
   select
        customer_id,
        join_date,
        join_date + 6 as first_week_after_join_date,
        DATE_TRUNC('month','2021-01-31'::DATE) + interval '1 month' - interval '1 day' as last_date
   from members
  
)

    SELECT 
        s.customer_id,
        SUM(CASE 
                WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
                WHEN s.order_date BETWEEN dt.join_date AND dt.first_week_after_join_date then 2 * 10 * m.price
                ELSE 10 * m.price END) AS points
    FROM sales as s
    join dates_cte as dt ON s.customer_id = dt.customer_id AND s.order_date <= dt.last_date
    join menu as m on s.product_id = m.product_id
    group by 1;


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
      END AS member_status    
FROM sales as s
join members as mem on s.customer_id = mem.customer_id
join menu as m on s.product_id = m.product_id;


-- Rank All the Things
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he --  expects null ranking values for the records when customers are not yet part of the loyalty program.
with CUST_DATA AS
(
SELECT 
      s.customer_id,
      s.order_date,
      m.product_name,
      m.price,
      CASE
          WHEN mem.join_date > s.order_date THEN 'N'
          WHEN mem.join_date <= s.order_date THEN 'Y'
      END AS member_status    
FROM sales as s
join members as mem on s.customer_id = mem.customer_id
join menu as m on s.product_id = m.product_id
)

SELECT *,
       CASE WHEN member_status = 'N' then NULL
       ELSE RANK() OVER(PARTITION BY customer_id,member_status order by order_date) end as ranking
from CUST_DATA;


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
