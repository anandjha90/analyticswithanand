CREATE DATABASE IF NOT EXISTS market_and_products;

USE market_and_products;


# Creating the table Markets table
CREATE TABLE IF NOT EXISTS markets_table(
	market_code VARCHAR(50),
    market_name VARCHAR(50),
    market_type VARCHAR(20),
    PRIMARY KEY (market_code)
);

# Inserting rows into the dataset 
INSERT INTO markets_table (market_code, market_name, market_type)
VALUES 
('Mark001', 'Chennai', 'South'),
('Mark002', 'Mumbai', 'Central'),
('Mark003', 'Ahmedabad', 'North'),
('Mark004', 'Delhi NCR', 'North'),
('Mark005', 'Kanpur', 'North'),
('Mark006', 'Bengaluru', 'South'),
('Mark007', 'Bhopal', 'Central'),
('Mark008', 'Lucknow', 'North'),
('Mark009', 'Patna', 'North'),
('Mark010', 'Kochi', 'South'),
('Mark011', 'Nagpur', 'Central'),
('Mark012', 'Surat', 'North'),
('Mark013', 'Bhopal', 'Central'),
('Mark014', 'Hyderabad', 'South'),
('Mark015', 'Bhubaneshwar', 'South'),
('Mark097', 'New York', NULL),
('Mark999', 'Paris', NULL);

# Creating the table products table
CREATE TABLE IF NOT EXISTS products_table(
	product_code VARCHAR(50),
    product_name VARCHAR(50),
    product_type VARCHAR(20),
    PRIMARY KEY (product_code)
);

#  Inserting Values into the products_table 
INSERT INTO products_table (product_code, product_name, product_type)
VALUES 
('Prod001', 'Product A', 'Own Brand'),
('Prod002', 'Product B', 'Own Brand'),
('Prod003', 'Product C', 'Own Brand'),
('Prod004', 'Product D', 'Own Brand'),
('Prod005', 'Product E', 'Own Brand'),
('Prod006', 'Product F', 'Own Brand'),
('Prod007', 'Product G', 'Own Brand'),
('Prod008', 'Product H', 'Own Brand'),
('Prod009', 'Product I', 'Own Brand'),
('Prod010', 'Product J', 'Own Brand'),
('Prod011', 'Product K', 'Own Brand'),
('Prod012', 'Product L', 'Own Brand'),
('Prod013', 'Product M', 'Own Brand'),
('Prod014', 'Product N', 'Own Brand'),
('Prod015', 'Product O', 'Own Brand'),
('Prod016', 'Product P', 'Own Brand'),
('Prod017', 'Product Q', 'Own Brand'),
('Prod018', 'Product R', 'Own Brand'),
('Prod019', 'Product S', 'Own Brand'),
('Prod020', 'Product T', 'Own Brand'),
('Prod021', 'Product U', 'Own Brand'),
('Prod022', 'Product V', 'Distribution'),
('Prod023', 'Product W', 'Distribution'),
('Prod024', 'Product X', 'Distribution'),
('Prod025', 'Product Y', 'Distribution'),
('Prod026', 'Product Z', 'Distribution'),
('Prod027', 'Product AA', 'Distribution'),
('Prod028', 'Product BB', 'Distribution'),
('Prod029', 'Product CC', 'Distribution'),
('Prod030', 'Product DD', 'Distribution'),
('Prod031', 'Product EE', 'Distribution'),
('Prod032', 'Product FF', 'Distribution'),
('Prod033', 'Product GG', 'Distribution'),
('Prod034', 'Product HH', 'Own Brand'),
('Prod035', 'Product II', 'Own Brand'),
('Prod036', 'Product JJ', 'Own Brand'),
('Prod037', 'Product KK', 'Own Brand'),
('Prod038', 'Product LL', 'Own Brand'),
('Prod039', 'Product MM', 'Own Brand'),
('Prod040', 'Product NN', 'Own Brand'),
('Prod041', 'Product OO', 'Own Brand'),
('Prod042', 'Product PP', 'Own Brand'),
('Prod043', 'Product QQ', 'Own Brand'),
('Prod044', 'Product RR', 'Own Brand'),
('Prod045', 'Product SS', 'Own Brand'),
('Prod046', 'Product TT', 'Own Brand'),
('Prod047', 'Product UU', 'Own Brand'),
('Prod048', 'Product VV', 'Own Brand'),
('Prod049', 'Product WW', 'Own Brand'),
('Prod050', 'Product XX', 'Own Brand'),
('Prod051', 'Product YY', 'Own Brand'),
('Prod052', 'Product ZZ', 'Own Brand'),
('Prod053', 'Product AAA', 'Own Brand'),
('Prod054', 'Product BBB', 'Own Brand'),
('Prod055', 'Product CCC', 'Own Brand'),
('Prod056', 'Product DDD', 'Own Brand'),
('Prod057', 'Product EEE', 'Own Brand'),
('Prod058', 'Product FFF', 'Own Brand'),
('Prod059', 'Product GGG', 'Own Brand'),
('Prod060', 'Product HHH', 'Own Brand'),
('Prod061', 'Product III', 'Own Brand'),
('Prod062', 'Product JJJ', 'Own Brand'),
('Prod063', 'Product KKK', 'Own Brand'),
('Prod064', 'Product LLL', 'Own Brand'),
('Prod065', 'Product MMM', 'Own Brand'),
('Prod066', 'Product NNN', 'Distribution'),
('Prod067', 'Product OOO', 'Distribution'),
('Prod068', 'Product PPP', 'Distribution'),
('Prod069', 'Product QQQ', 'Distribution'),
('Prod070', 'Product RRR', 'Distribution'),
('Prod071', 'Product SSS', 'Distribution'),
('Prod072', 'Product TTT', 'Distribution'),
('Prod073', 'Product UUU', 'Distribution'),
('Prod074', 'Product VVV', 'Distribution'),
('Prod075', 'Product WWW', 'Distribution'),
('Prod076', 'Product XXX', 'Distribution'),
('Prod077', 'Product YYY', 'Distribution'),
('Prod078', 'Product ZZZ', 'Own Brand'),
('Prod079', 'Product AAAA', 'Own Brand'),
('Prod080', 'Product BBBB', 'Own Brand'),
('Prod081', 'Product CCCC', 'Own Brand'),
('Prod082', 'Product DDDD', 'Own Brand'),
('Prod083', 'Product EEEE', 'Own Brand'),
('Prod084', 'Product FFFF', 'Own Brand'),
('Prod085', 'Product GGGG', 'Own Brand'),
('Prod086', 'Product HHHH', 'Own Brand'),
('Prod087', 'Product IIII', 'Own Brand'),
('Prod088', 'Product JJJJ', 'Own Brand'),
('Prod089', 'Product KKKK', 'Own Brand'),
('Prod090', 'Product LLLL', 'Own Brand'),
('Prod091', 'Product MMMM', 'Own Brand'),
('Prod092', 'Product NNNN', 'Own Brand'),
('Prod093', 'Product OOOO', 'Own Brand'),
('Prod094', 'Product PPPP', 'Own Brand'),
('Prod095', 'Product QQQQ', 'Own Brand'),
('Prod096', 'Product RRRR', 'Own Brand'),
('Prod097', 'Product SSSS', 'Own Brand'),
('Prod098', 'Product TTTT', 'Own Brand'),
('Prod099', 'Product UUUU', 'Own Brand'),
('Prod100', 'Product VVVV', 'Own Brand');

Show tables;

SELECT * FROM markets_table;

SELECT * FROM products_table;


