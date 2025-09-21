CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    customer_id INT,
    employee_id INT,
    menu_id INT,
    quantity INT
);

CREATE TABLE menu (
    menu_id INT PRIMARY KEY,
    item_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2)
);


CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    position VARCHAR(50) NOT NULL
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    join_date DATE NOT NULL,
    loyalty_level VARCHAR(50),
    age INT,
    city VARCHAR(100)
);
