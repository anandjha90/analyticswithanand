-- drop database
DROP DATABASE IF EXISTS BikeStores;

-- drop tables
DROP TABLE IF EXISTS sales.order_items;
DROP TABLE IF EXISTS sales.orders;
DROP TABLE IF EXISTS production.stocks;
DROP TABLE IF EXISTS production.products;
DROP TABLE IF EXISTS production.categories;
DROP TABLE IF EXISTS production.brands;
DROP TABLE IF EXISTS sales.customers;
DROP TABLE IF EXISTS sales.staffs;
DROP TABLE IF EXISTS sales.stores;

-- drop the schemas
DROP SCHEMA IF EXISTS sales;
DROP SCHEMA IF EXISTS production;

-- CREATE DATABASE
CREATE DATABASE BikeStores;
USE BikeStores;	

-- create schemas
CREATE SCHEMA production;
CREATE SCHEMA sales;

-- create tables
CREATE OR REPLACE TABLE production.categories (
	category_id INT IDENTITY(1,1) PRIMARY KEY,
	category_name VARCHAR (255) NOT NULL
);

SELECT count(*) FROM    production.categories  ; -- 7

CREATE OR REPLACE TABLE production.brands (
	brand_id INT IDENTITY(1,1) PRIMARY KEY,
	brand_name VARCHAR (255) NOT NULL
);

SELECT count(*) FROM  production.brands ; -- 9

CREATE OR REPLACE TABLE production.products (
	product_id INT IDENTITY(1,1) PRIMARY KEY,
	product_name VARCHAR (255) NOT NULL,
	brand_id INT NOT NULL,
	category_id INT NOT NULL,
	model_year SMALLINT NOT NULL,
	list_price DECIMAL (10, 2) NOT NULL,
	FOREIGN KEY (category_id) REFERENCES production.categories (category_id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (brand_id) REFERENCES production.brands (brand_id) ON DELETE CASCADE ON UPDATE CASCADE
);

SELECT count(*) FROM   production.products  ; -- 321
SELECT * FROM   production.products ;

CREATE OR REPLACE TABLE sales.customers (
	customer_id INT IDENTITY(1,1) PRIMARY KEY,
	first_name VARCHAR (255) NOT NULL,
	last_name VARCHAR (255) NOT NULL,
	phone VARCHAR (25),
	email VARCHAR (255) NOT NULL,
	street VARCHAR (255),
	city VARCHAR (50),
	state VARCHAR (25),
	zip_code VARCHAR (5)
);
SELECT count(*) FROM   sales.customers  ; -- 1445

CREATE OR REPLACE TABLE sales.stores (
	store_id INT IDENTITY(1,1) PRIMARY KEY,
	store_name VARCHAR (255) NOT NULL,
	phone VARCHAR (25),
	email VARCHAR (255),
	street VARCHAR (255),
	city VARCHAR (255),
	state VARCHAR (10),
	zip_code VARCHAR (5)
);
SELECT count(*) FROM    sales.stores   ; -- 3

CREATE OR REPLACE TABLE sales.staffs (
	staff_id INT IDENTITY(1,1) PRIMARY KEY,
	first_name VARCHAR (50) NOT NULL,
	last_name VARCHAR (50) NOT NULL,
	email VARCHAR (255) NOT NULL UNIQUE,
	phone VARCHAR (25),
	active tinyint NOT NULL,
	store_id INT NOT NULL,
	manager_id INT,
	FOREIGN KEY (store_id) REFERENCES sales.stores (store_id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (manager_id) REFERENCES sales.staffs (staff_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- SALES.STAFFS

CREATE OR REPLACE TABLE sales.orders (
	order_id INT IDENTITY(1,1) PRIMARY KEY,
	customer_id INT,
	order_status tinyint NOT NULL,
	-- Order status: 1 = Pending; 2 = Processing; 3 = Rejected; 4 = Completed
	order_date DATE NOT NULL,
	required_date DATE NOT NULL,
	shipped_date DATE NOT NULL,
	store_id INT NOT NULL,
	staff_id INT NOT NULL,
	FOREIGN KEY (customer_id) REFERENCES sales.customers (customer_id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (store_id) REFERENCES sales.stores (store_id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (staff_id) REFERENCES sales.staffs (staff_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);
SELECT count(*) FROM    sales.orders  ; -- 1615

CCREATE OR REPLACE TABLE sales.order_items (
	order_id INT,
	item_id INT,
	product_id INT NOT NULL,
	quantity INT NOT NULL,
	list_price DECIMAL (10, 2) NOT NULL,
	discount DECIMAL (4, 2) NOT NULL DEFAULT 0,
	PRIMARY KEY (order_id, item_id),
	FOREIGN KEY (order_id) REFERENCES sales.orders (order_id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (product_id) REFERENCES production.products (product_id) ON DELETE CASCADE ON UPDATE CASCADE
);
SELECT count(*) FROM   sales.order_items ; -- 4722

CREATE OR REPLACE TABLE production.stocks (
	store_id INT,
	product_id INT,
	quantity INT,
	PRIMARY KEY (store_id, product_id),
	FOREIGN KEY (store_id) REFERENCES sales.stores (store_id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (product_id) REFERENCES production.products (product_id) ON DELETE CASCADE ON UPDATE CASCADE
);
------------------------------------------------------------------- final master table ------------------------------------------------------------
CREATE OR REPLACE TABLE bike_store_master AS
SELECT 
    -- From categories table
    cat.category_id,
    cat.category_name,

    -- From brands table
    br.brand_id,
    br.brand_name,

    -- From products table
    prod.product_id,
    prod.product_name,
    prod.model_year,
    prod.list_price AS product_list_price,

    -- From customers table
    cust.customer_id,
    cust.first_name AS customer_first_name,
    cust.last_name AS customer_last_name,
    cust.phone AS customer_phone,
    cust.email AS customer_email,
    cust.street AS customer_street,
    cust.city AS customer_city,
    cust.state AS customer_state,
    cust.zip_code AS customer_zip_code,

    -- From stores table
    store.store_id,
    store.store_name,
    store.phone AS store_phone,
    store.email AS store_email,
    store.street AS store_street,
    store.city AS store_city,
    store.state AS store_state,
    store.zip_code AS store_zip_code,

    -- From staffs table
    staff.staff_id,
    staff.first_name AS staff_first_name,
    staff.last_name AS staff_last_name,
    staff.email AS staff_email,
    staff.phone AS staff_phone,
    staff.active AS staff_active,
    staff.manager_id,

    -- From orders table
    ord.order_id,
    ord.order_status,
    ord.order_date,
    ord.required_date,
    ord.shipped_date,

    -- From order_items table
    oi.item_id,
    oi.quantity AS order_item_quantity,
    oi.list_price AS order_item_list_price,
    oi.discount AS order_item_discount,

    -- From stocks table
    stock.quantity AS stock_quantity

FROM 
    production.categories AS cat
LEFT JOIN 
    production.products AS prod ON cat.category_id = prod.category_id
LEFT JOIN 
    production.brands AS br ON prod.brand_id = br.brand_id
LEFT JOIN 
    sales.order_items AS oi ON prod.product_id = oi.product_id
LEFT JOIN 
    sales.orders AS ord ON oi.order_id = ord.order_id
LEFT JOIN 
    sales.customers AS cust ON ord.customer_id = cust.customer_id
LEFT JOIN 
    sales.stores AS store ON ord.store_id = store.store_id
LEFT JOIN 
    sales.staffs AS staff ON ord.staff_id = staff.staff_id
LEFT JOIN 
    production.stocks AS stock ON prod.product_id = stock.product_id AND store.store_id = stock.store_id
ORDER BY 
    cat.category_id, br.brand_id, prod.product_id, cust.customer_id, ord.order_id, oi.item_id;
    
/*
Explanation
JOINs:

We’re joining categories and products on category_id, and then joining products to brands on brand_id.
We join products to order_items on product_id, and order_items to orders on order_id.
orders links to customers by customer_id, and to stores by store_id.
orders links to staffs by staff_id, and finally, products joins with stocks by product_id and store_id.
LEFT JOIN: Used for tables where data may not always exist (e.g., order_items, orders, customers).

Aliases: To avoid column name conflicts, I've added aliases where necessary (e.g., product_list_price, customer_first_name, etc.).

ORDER BY: Arranges the final output for clarity.

This query creates a final_master table that contains all columns from the specified tables, according to the relationships defined in your schema.
*/

select * from BIKESTORES.PUBLIC.BIKE_STORE_MASTER;
