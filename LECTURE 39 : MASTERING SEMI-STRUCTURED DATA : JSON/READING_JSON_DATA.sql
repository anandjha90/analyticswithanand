CREATE OR REPLACE table parsing_json_data
( 
  src variant
)
AS
SELECT PARSE_JSON(column1) AS src
FROM VALUES
('{ 
    "date" : "2017-04-28", 
    "dealership" : "Valley View Auto Sales",
    "salesperson" : {
      "id": "55",
      "name": "Frank Beasley"
    },
    "customer" : [
      {"name": "Joyce Ridgely", "phone": "16504378889", "address": "San Francisco, CA"}
    ],
    "vehicle" : [
      {"make": "Honda", "model": "Civic", "year": "2017", "price": "20275", "extras":["ext warranty", "paint protection"]}
    ]
}'),
('{ 
    "date" : "2017-04-28", 
    "dealership" : "Tindel Toyota",
    "salesperson" : {
      "id": "274",
      "name": "Greg Northrup"
    },
    "customer" : [
      {"name": "Bradley Greenbloom", "phone": "12127593751", "address": "New York, NY"}
    ],
    "vehicle" : [
      {"make": "Toyota", "model": "Camry", "year": "2017", "price": "23500", "extras":["ext warranty", "rust proofing", "fabric protection"]}  
    ]
}') v;


SELECT * FROM parsing_json_data;

---- Traversing Semi-structured Data
--- Insert a colon : between the VARIANT column name and any first-level element: <column>:<level1_element>.


/* Note
In the following examples, the query output is enclosed in double quotes because the query output is VARIANT, not VARCHAR. (The VARIANT values are not strings; the VARIANT values contain strings.) Operators : and subsequent . and [] always return VARIANT values containing strings. */



SELECT src:dealership
FROM parsing_json_data
ORDER BY 1;


There are two ways to access elements in a JSON object:
Dot Notation (in this topic).
Bracket Notation (in this topic).

Important

Regardless of which notation you use, the column name is case-insensitive but element names are case-sensitive. 
For example, in the following list, the first two paths are equivalent, but the third is not:

src:salesperson.name
SRC:salesperson.name
SRC:Salesperson.Name


Dot Notation
Use dot notation to traverse a path in a JSON object: <column>:<level1_element>.<level2_element>.<level3_element>. 
Optionally enclose element names in double quotes: <column>:"<level1_element>"."<level2_element>"."<level3_element>".;

--Get the names of all salespeople who sold cars:;

SELECT src:salesperson.name
FROM parsing_json_data
ORDER BY 1;

Bracket Notation
Alternatively, use bracket notation to traverse the path in an object: <column>['<level1_element>']['<level2_element>']. Enclose element names in single quotes. Values are retrieved as strings.

Get the names of all salespeople who sold cars:;

SELECT src['salesperson']['name']
FROM parsing_json_data
ORDER BY 1;



Retrieving a Single Instance of a Repeating Element
Retrieve a specific numbered instance of a child element in a repeating array by adding a numbered predicate (starting from 0) to the array reference.

Note that to retrieve all instances of a child element in a repeating array, it is necessary to flatten the array. 


Get the vehicle details for each sale:;

SELECT src:customer[0].name, src:vehicle[0]
 FROM parsing_json_data
ORDER BY 1;

Get the price of each car sold:;
SELECT src:customer[0].name, src:vehicle[0].price
FROM parsing_json_data
ORDER BY 1;


Explicitly Casting Values
When you extract values from a VARIANT, you can explicitly cast the values to the desired data type. 
For example, you can extract the prices as numeric values and perform calculations on them:;

SELECT src:vehicle[0].price::NUMBER * 0.10 AS tax
FROM parsing_json_data
ORDER BY tax;

By default, when VARCHARs, DATEs, TIMEs, and TIMESTAMPs are retrieved from a VARIANT column, the values are surrounded by double quotes. 
You can eliminate the double quotes by explicitly casting the values. For example:;

SELECT src:dealership, src:dealership::VARCHAR
FROM parsing_json_data
ORDER BY 2;


Using the FLATTEN Function to Parse Arrays
Parse an array using the FLATTEN function. FLATTEN is a table function that produces a lateral view of a VARIANT, OBJECT, or ARRAY column. The function returns a row for each object, and the LATERAL modifier joins the data with any information outside of the object.

Get the names and addresses of all customers. Cast the VARIANT output to string values:;

SELECT
  value:name::string as "Customer Name",
  value:address::string as "Address"
  FROM parsing_json_data, LATERAL FLATTEN(INPUT => SRC:customer);

Using the FLATTEN Function to Parse Nested Arrays¶
The extras array is nested within the vehicle array in the sample data:

"vehicle" : [
     {"make": "Honda", "model": "Civic", "year": "2017", "price": "20275", "extras":["ext warranty", "paint protection"]}
   ]
Add a second FLATTEN clause to flatten the extras array within the flattened vehicle array and retrieve the “extras” purchased for each car sold:;

SELECT
  vm.value:make::string as make,
  vm.value:model::string as model,
  ve.value::string as "Extras Purchased"
  FROM
    parsing_json_data
    , LATERAL FLATTEN(INPUT => SRC:vehicle) vm
    , LATERAL FLATTEN(INPUT => vm.value:extras) ve
  ORDER BY make, model, "Extras Purchased";

  
