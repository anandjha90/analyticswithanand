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

-- Case Study Questions
-- This case study has LOTS of questions - they are broken up by area of focus including:

-- Pizza Metrics
-- Runner and Customer Experience
-- Ingredient Optimisation
-- Pricing and Ratings
-- Bonus DML Challenges (DML = Data Manipulation Language)
-- Each of the following case study questions can be answered using a single SQL statement.

-- Note :  Before you start writing your SQL queries however - you might want to investigate the data, you may want to do something with some of those null 
-- values and data types in the customer_orders and runner_orders tables!

-- Lets Go
-- Before we start with the solutions, we investigate the data and found that there are some cleaning and transformation to do, specifically on the
        -- null values and data types in the customer_orders table
        -- null values and data types in the runner_orders table
        -- Alter data type in pizza_names table
        
-- Firstly, to clean up exclusions and extras in the customer_orders we create a cleaned table
CREATE OR REPLACE TABLE customer_orders_cleaned AS
SELECT order_id, customer_id, pizza_id, 
  CASE 
    WHEN exclusions IS null OR exclusions LIKE 'null' THEN ' '
    ELSE exclusions
    END AS exclusions,
  CASE 
    WHEN extras IS NULL or extras LIKE 'null' THEN ' '
    ELSE extras 
    END AS extras, 
  order_time
FROM customer_orders;

SELECT * FROM customer_orders_cleaned;

-- Then, we clean the runner_orders table with CASE WHEN and TRIM and create runner_orders_cleaned table.
-- In summary,
--      pickup_time — Remove nulls and replace with ‘ ‘
--      distance — Remove ‘km’ and nulls
--      duration — Remove ‘minutes’ and nulls
--      cancellation — Remove NULL and null and replace with ‘ ‘

-- Then, we alter the date according to its correct data type.
-- pickup_time to DATETIME type

CREATE OR REPLACE TABLE RUNNERS_ORDER_COPY AS
SELECT * FROM RUNNER_ORDERS;

ALTER TABLE RUNNERS_ORDER_COPY ADD COLUMN pickup_time_datetime DATETIME;

UPDATE RUNNERS_ORDER_COPY
SET pickup_time_datetime = CASE
    WHEN pickup_time IS NULL OR pickup_time LIKE 'null' OR TRIM(pickup_time) = '' THEN NULL -- Handle NULL and blank values
    ELSE TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS')                                 -- Convert valid date strings
END;

ALTER TABLE RUNNERS_ORDER_COPY DROP COLUMN pickup_time;

ALTER TABLE RUNNERS_ORDER_COPY RENAME COLUMN pickup_time_datetime TO pickup_time;

-- distance to FLOAT type
ALTER TABLE RUNNERS_ORDER_COPY ADD COLUMN distance_km_float FLOAT;

UPDATE RUNNERS_ORDER_COPY
SET distance_km_float = CASE
    WHEN TRIM(distance) = '' OR distance IS NULL OR distance LIKE 'null' THEN NULL
    ELSE TRY_CAST(REGEXP_REPLACE(distance, '[^0-9.]', '') AS FLOAT)
END;

ALTER TABLE RUNNERS_ORDER_COPY DROP COLUMN distance;
ALTER TABLE RUNNERS_ORDER_COPY RENAME COLUMN distance_km_float TO distance_km;

-- duration to INT type
ALTER TABLE RUNNERS_ORDER_COPY ADD COLUMN duration_min_int INT;

UPDATE RUNNERS_ORDER_COPY
SET duration_min_int = CASE
    WHEN TRIM(duration) = '' OR duration IS NULL or duration LIKE 'null' THEN NULL
    ELSE TRY_CAST(REGEXP_REPLACE(duration, '[^0-9.]', '') AS INT)
END;

ALTER TABLE RUNNERS_ORDER_COPY DROP COLUMN duration;
ALTER TABLE RUNNERS_ORDER_COPY RENAME COLUMN duration_min_int TO duration_min;

-- cleaned runner_orders_table
CREATE OR REPLACE TABLE runner_orders_cleaned AS
SELECT order_id, runner_id, 
  CASE 
    WHEN cancellation IS NULL or cancellation LIKE 'null' THEN ''
    ELSE cancellation 
  END AS cancellation,
  CASE 
    WHEN pickup_time IS NULL or pickup_time LIKE 'null' THEN '9999-12-31 00:00:00' 
    ELSE pickup_time 
    END AS pickup_time,
  CASE 
    WHEN distance_km IS NULL or distance_km LIKE 'null' THEN 0
    ELSE distance_km 
    END AS distance_km, 
  CASE 
    WHEN duration_min IS NULL or duration_min LIKE 'null' THEN 0
    ELSE duration_min 
  END AS duration_min   
FROM RUNNERS_ORDER_COPY;

SELECT * FROM runner_orders_cleaned;

-- delete the backup table once cleaning done no need to keep it
DROP TABLE RUNNERS_ORDER_COPY;

-- A. Pizza Metrics
-- 1.How many pizzas were ordered?


-- 2.How many unique customer orders were made?

-- 3.How many successful orders were delivered by each runner?

-- 4.How many of each type of pizza was delivered?

-- 5.How many Vegetarian and Meatlovers were ordered by each customer?

-- 6.What was the maximum number of pizzas delivered in a single order?


-- 7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?


-- 8.How many pizzas were delivered that had both exclusions and extras?

-- 9.What was the total volume of pizzas ordered for each hour of the day?

-- 10.What was the volume of orders for each day of the week?



-- B. Runner and Customer Experience
-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)


-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?


-- Is there any relationship between the number of pizzas and how long the order takes to prepare?


-- What was the average distance travelled for each customer?


-- What was the difference between the longest and shortest delivery times for all orders?


-- What was the average speed for each runner for each delivery and do you notice any trend for these values?


-- What is the successful delivery percentage for each runner?


--C. Ingredient Optimisation
-- What are the standard ingredients for each pizza?


-- What was the most commonly added extra?

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
-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?


-- What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra


-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
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

-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much 
-- money does Pizza Runner have left over after these deliveries?



-- E. Bonus Questions
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen --  if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

