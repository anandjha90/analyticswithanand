CREATE OR REPLACE SCHEMA pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INTEGER PRIMARY KEY,
  registration_date DATE
);

INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');

DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER PRIMARY KEY,
  pizza_name TEXT
);
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER PRIMARY KEY,
  toppings TEXT
);
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER PRIMARY KEY,
  topping_name TEXT
);
INSERT INTO pizza_toppings
  (topping_id, topping_name)
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');  


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER PRIMARY KEY,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23),
  FOREIGN KEY (runner_id) REFERENCES runners(runner_id)
);

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER ,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP,
  FOREIGN KEY (pizza_id) REFERENCES pizza_names(pizza_id),
  FOREIGN KEY (pizza_id) REFERENCES pizza_recipes(pizza_id),
  FOREIGN KEY (order_id) REFERENCES runner_orders(order_id)
);

INSERT INTO customer_orders
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');

CREATE OR REPLACE TABLE RUNNERS_ORDERS_COPY AS
SELECT * FROM RUNNER_ORDERS;

-- CLEANING PICKUP_TIME AND CONVERTING INTO DATETIME
ALTER TABLE RUNNERS_ORDERS_COPY ADD COLUMN PICKUP_TIME_DATE_TIME DATETIME;

UPDATE RUNNERS_ORDERS_COPY
SET PICKUP_TIME_DATE_TIME = 
    CASE
        WHEN pickup_time is NULL or pickup_time like 'null' or TRIM(pickup_time) = '' then null
        ELSE TO_TIMESTAMP(pickup_time,'YYYY-MM-DD HH24:MI:SS')
    END;

ALTER TABLE RUNNERS_ORDERS_COPY DROP COLUMN pickup_time;
ALTER TABLE RUNNERS_ORDERS_COPY RENAME COLUMN PICKUP_TIME_DATE_TIME TO pickup_time;

--DISTANCE TO FLOAT 
ALTER TABLE RUNNERS_ORDERS_COPY ADD COLUMN DISTANCE_KM FLOAT;

UPDATE RUNNERS_ORDERS_COPY
SET DISTANCE_KM = 
    CASE
        WHEN distance is NULL or distance like 'null' or TRIM(distance) = '' then null
        ELSE TRY_CAST(REGEXP_REPLACE(distance,'[^0-9.]','') AS FLOAT)
    END;

ALTER TABLE RUNNERS_ORDERS_COPY DROP COLUMN distance;
ALTER TABLE RUNNERS_ORDERS_COPY RENAME COLUMN DISTANCE_KM TO distance;

-- DURATION TO INT
ALTER TABLE RUNNERS_ORDERS_COPY ADD COLUMN duration_int INT;

UPDATE RUNNERS_ORDERS_COPY
SET duration_int = 
    CASE
        WHEN duration is NULL or duration like 'null' or TRIM(duration) = '' then null
        ELSE TRY_CAST(REGEXP_REPLACE(duration,'[^0-9.]','') AS INT)
    END;

ALTER TABLE RUNNERS_ORDERS_COPY DROP COLUMN duration;
ALTER TABLE RUNNERS_ORDERS_COPY RENAME COLUMN duration_int TO duration;

CREATE OR REPLACE TABLE RUNNERS_ORDERS_CLEANED AS
SELECT order_id,runner_id,
    CASE 
       WHEN CANCELLATION is NULL or CANCELLATION like 'null' THEN ''
       ELSE CANCELLATION
    END AS CANCELLATION,
    CASE 
       WHEN pickup_time is NULL or pickup_time like 'null' THEN '9999-12-31 00:00:00'
       ELSE pickup_time
    END AS pickup_time,
    CASE 
       WHEN distance is NULL or distance like 'null' THEN 0
       ELSE distance
    END AS distance,
    CASE 
       WHEN duration is NULL or duration like 'null' THEN 0
       ELSE duration
    END AS duration
FROM RUNNERS_ORDERS_COPY;

DROP TABLE RUNNERS_ORDERS_COPY;

-- CLEANING CUSTOMERS ORDER 
CREATE OR REPLACE TABLE CUSTOMER_ORDERS_COPY AS
SELECT * FROM CUSTOMER_ORDERS;

CREATE OR REPLACE TABLE CUSTOMER_ORDERS_CLEANED AS
SELECT
      order_id,
      customer_id,
      pizza_id,
      CASE 
            WHEN exclusions is NULL or exclusions like 'null' THEN ''
            ELSE exclusions
      END AS exclusions,
      CASE 
             WHEN extras is NULL or extras like 'null' THEN ''
             ELSE extras
      END AS extras,
      order_time
FROM CUSTOMER_ORDERS_COPY;

DROP TABLE CUSTOMER_ORDERS_COPY;

-- A. Pizza Metrics
-- 1.How many pizzas were ordered?
SELECT COUNT(order_id) as total_pizza_ordered
FROM CUSTOMER_ORDERS_CLEANED;

-- 2.How many unique customer orders were made?
SELECT COUNT(distinct customer_id) as total_cust_ordered
FROM CUSTOMER_ORDERS_CLEANED;

-- 3.How many successful orders were delivered by each runner?
SELECT runner_id,count(order_id) as tot_successful_orders
FROM RUNNERS_ORDERS_CLEANED
WHERE distance != 0
group by 1
order by 1;


-- 4.How many of each type of pizza was delivered?
SELECT
     p.pizza_id,
     p.pizza_name,
     count(c.order_id) as total_pizza_delivered
FROM RUNNERS_ORDERS_CLEANED as r
JOIN customer_orders_cleaned as c ON r.order_id = c.order_id
JOIN pizza_names as p on c.pizza_id = p.pizza_id
WHERE r.distance != 0 
GROUP BY 1,2
ORDER BY 1,2;


-- 5.How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
     c.customer_id,
     p.pizza_name,
     count(c.order_id) as total_pizza_delivered
FROM customer_orders_cleaned as c
JOIN pizza_names as p on c.pizza_id = p.pizza_id
GROUP BY 1,2
ORDER BY 1,2;


-- 6.What was the maximum number of pizzas delivered in a single order?
with pizza_count_cte as
(
    select
          c.order_id,
          count(c.pizza_id) as pizza_per_order  
    from customer_orders_cleaned as c
    join runners_orders_cleaned as r on c.order_id = r.order_id
    where distance != 0
    group by c.order_id

)
select max(pizza_per_order)as pizz_count
from pizza_count_cte;

-- 7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
    c.customer_id,
    SUM(CASE WHEN c.exclusions <> '' or c.extras <> '' then 1 else 0 end) as atleast_1_change,
    SUM(CASE WHEN c.exclusions = '' AND c.extras = '' then 1 else 0 end) as no_change,
from customer_orders_cleaned as c
join runners_orders_cleaned as r on c.order_id = r.order_id
where distance != 0
group by 1
order by 1;


-- 8.How many pizzas were delivered that had both exclusions and extras?
SELECT
    SUM(CASE 
           WHEN c.exclusions IS NOT NULL AND c.extras IS NOT NULL THEN 1 
           ELSE 0 END) as pizza_count_w_exclusions_extras
from customer_orders_cleaned as c
join runners_orders_cleaned as r on c.order_id = r.order_id
where distance != 0 and exclusions <> '' and extras <> '';

-- 9.What was the total volume of pizzas ordered for each hour of the day?
SELECT
      DATE_PART(HOUR,ORDER_TIME) AS hour_of_day,
      count(pizza_id) as pizza_count
FROM customer_orders_cleaned
group by 1
order by 2 desc;

-- What was the volume of orders for each day of the week?
SELECT
     TO_CHAR(ORDER_TIME,'DY') AS DAY_OF_WEEK,
     COUNT(pizza_id) as tot_pizza_ordered
FROM customer_orders_cleaned
group by 1,2
order by 2 desc; 

-- B. Runner and Customer Experience
-- 1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT 
    WEEK(DATE_TRUNC('WEEK', DATEADD(DAY, 3, registration_date))) AS week_start_date,
    COUNT(runner_id) AS runners_signed_up
FROM runners
GROUP BY 1
ORDER BY 1;

-- 2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH TIME_TAKEN_CTE as
(
    SELECT
       c.order_id,
       r.runner_id,
       c.order_time,
       r.pickup_time,
       DATEDIFF(MINUTE,c.order_time,r.pickup_time) as pickup_min
    from customer_orders_cleaned as c
    join runners_orders_cleaned as r on c.order_id = r.order_id
    where r.distance != 0
    group by 1,2,3,4
)

select runner_id,ROUND(AVG(pickup_min),0) as avg_pickup_min
from TIME_TAKEN_CTE
group by 1 
order by 1;

-- 3.Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH prep_time_cte AS
(
    SELECT
       c.order_id,
       c.order_time,
       r.pickup_time,
       DATEDIFF(MINUTE,c.order_time,r.pickup_time) as prep_time_min,
       COUNT(c.pizza_id) as pizza_order
    from customer_orders_cleaned as c
    join runners_orders_cleaned as r on c.order_id = r.order_id
    where r.distance != 0
    group by 1,2,3

)
select pizza_order,ROUND(AVG(prep_time_min),0) as avg_prep_time_min
from prep_time_cte
group by 1;


-- 4.What was the average distance travelled for each customer?
    SELECT
       c.customer_id,
       ROUND(AVG(r.distance),0) as avg_distnace_km
    from customer_orders_cleaned as c
    join runners_orders_cleaned as r on c.order_id = r.order_id
    where r.distance != 0
    group by 1
    order by 2 desc;


-- 5.What was the difference between the longest and shortest delivery times for all orders?
SELECT 
    MAX(duration) -  MIN(duration) as delivery_time_diff
    FROM
    (
       SELECT order_id,duration
       from runners_orders_cleaned
       where duration !=0
    );

-- 6.What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
    r.runner_id,
    c.customer_id,
    c.order_id,
    r.distance as distance_km,
    r.duration as duration_min,
    (r.duration / 60) as duration_hr,
    ROUND(r.distance/r.duration * 60,2) as avg_speed,
    COUNT(c.order_id) as pizza_count
    from customer_orders_cleaned as c
    join runners_orders_cleaned as r on c.order_id = r.order_id
    where r.distance != 0
    group by 1,2,3,4,5,6,7;


-- 7.What is the successful delivery percentage for each runner?
SELECT
     runner_id,
     ROUND(100 * SUM(CASE WHEN distance !=0 then 1 else 0 end)/ count(*),0) as success_perc
FROM runners_orders_cleaned
group by 1;

--C. Ingredient Optimisation
-- clening required
/*Data cleaning for this part
Cleaning pizza_recipes table by creating a clean temp table
Splitting comma delimited lists into rows
RTRIM :         Used to remove all whitespace characters from the trailing position (right positions) of the string.
String_split : A table-valued function that splits a string into rows of substrings, based on a specified separator character.
*/

SELECT 
       pizza_id, 
       RTRIM(topping_id.value) as topping_id,
       topping_name 
FROM pizza_recipes pp
--CROSS APPLY string_split(p.toppings, ',') as topping_id
INNER JOIN pizza_toppings pt ON TRIM(topping_id.value) = p2.topping_id;



-- 1.What are the standard ingredients for each pizza?
SELECT pizza_id, String_agg(topping_name,',') as Standard_toppings
FROM #pizza_recipes
GROUP BY pizza_id;


-- What was the most commonly added extra?
select 
    e.topping_id, 
    p.topping_name, 
    count(*) as extra_toppings_time 
from extras e 
inner join pizza_toppings p on e.topping_id = p.topping_id
group by e.topping_id, p.topping_name
order by(count(*)) desc;


-- What was the most common exclusion?



-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"


-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?


-- D. Pricing and Ratings
-- 1.If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
with pizza_cost_cte as (
    select 
        pizza_id, 
        pizza_name,
    case when pizza_name = 'Meatlovers' THEN 12 ELSE 10 END AS pizza_cost
from pizza_names 
)

select sum(pc.pizza_cost) as total
from customer_orders_cleaned cu 
join runners_orders_cleaned r on cu.order_id = r.order_id
join pizza_cost_cte pc on cu.pizza_id = pc.pizza_id
where r.distance != 0;



-- 2.What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
with pizza_cost as 
(
    select 
        pizza_id, 
        pizza_name,
    case when pizza_name = 'Meatlovers' THEN 12 ELSE 10 END AS cost
    from pizza_names 
) ,
pizza_extras as
(
    select 
            extras,
            len(replace(cu.extras,', ','' )) as extras_count,
            case when extras = '' then pc.cost else pc.cost + len(replace(cu.extras,', ','' )) end as pizza_cost
    from customer_orders_cleaned cu 
    inner join pizza_cost pc on cu.pizza_id = pc.pizza_id
    inner join runners_orders_cleaned r on cu.order_id = r.order_id
where r.distance != 0
)
--select * from cte2;
select sum(pizza_cost) as total from pizza_extras;


-- 3.The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
CREATE OR REPLACE TABLE ratings 
 (order_id INTEGER,
  rating INTEGER);
INSERT INTO ratings
 (order_id ,rating)
VALUES 
(1,3),
(2,4),
(3,5),
(4,2),
(5,1),
(6,3),
(7,4),
(8,1),
(9,3),
(10,5); 
SELECT * from ratings;

-- 4.Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas

SELECT 
        c.customer_id,
        c.order_id, 
        ro.runner_id, 
        r.rating, 
        c.order_time, 
        ro.pickup_time, 
        DATEDIFF(MINUTE, c.order_time, ro.pickup_time) AS time_order_pickup,
        ro.duration, 
        round(avg(ro.distance/ro.duration*60),2) as avg_Speed, 
        COUNT(c.pizza_id) AS Pizza_Count
FROM customer_orders_cleaned AS c
LEFT JOIN runners_orders_cleaned ro ON c.order_id = ro.order_id 
LEFT JOIN ratings r ON c.order_id = r.order_id
WHERE ro.distance != 0
GROUP BY 1,2, 3,4,5, 6,7,8
ORDER BY c.customer_id;


-- 5.If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - -- how much money does Pizza Runner have left over after these deliveries?
WITH pizza_price_cte as(
    select 
        cu.order_id,
        sum(case when pizza_name = 'Meatlovers' THEN 12 else 10 end )as pizza_price
    from pizza_names AS pn
    join customer_orders_cleaned cu on cu.pizza_id = pn.pizza_id
group by cu.order_id
)
select  
    sum(pp.pizza_price) as revenue,
    sum(r.distance*0.3) as total_cost,
    sum(pp.pizza_price) - sum( r.distance*0.3) as profit
from  runners_orders_cleaned as r 
join pizza_price_cte as pp on r.order_id = pp.order_id
where r.distance != 0;


-- E. Bonus Questions
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen --  if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

