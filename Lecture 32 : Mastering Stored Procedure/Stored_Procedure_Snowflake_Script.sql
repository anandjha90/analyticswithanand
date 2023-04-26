drop database snowflake_stored_procedure;

CREATE DATABASE snowflake_stored_procedure;

USE snowflake_stored_procedure;

CREATE OR REPLACE PROCEDURE area_calc_proc()
  RETURNS VARCHAR
  LANGUAGE SQL
  AS
  $$
   
    DECLARE
      radius_of_circle FLOAT;
      area_of_circle FLOAT;
    BEGIN
      radius_of_circle := 3;
      area_of_circle := pi() * radius_of_circle * radius_of_circle;
      RETURN area_of_circle;
    END;
  $$
  ;
  
CALL  area_calc_proc();

CREATE OR REPLACE PROCEDURE myprocedure_param(inp_radius number(8,3))
  RETURNS VARCHAR
  LANGUAGE SQL
  AS
  $$
   
    DECLARE
      message VARCHAR;
      radius_of_circle FLOAT;
      area_of_circle FLOAT;
    BEGIN
      radius_of_circle := inp_radius ;
      area_of_circle := 3.14 * radius_of_circle * radius_of_circle;
      message := 'Area of circle with ' || inp_radius || ' is ' || area_of_circle;
      RETURN message;
    END;
  $$
  ;
  
CALL  myprocedure_param(8.76);

SHOW PROCEDURES; 

create or replace procedure myproc(from_table string, to_table string, count int)
  returns string
  language python
  runtime_version = '3.8'
  packages = ('snowflake-snowpark-python')
  handler = 'run'
as
$$
def run(session, from_table, to_table, count):
  session.table(from_table).limit(count).write.save_as_table(to_table)
  return "SUCCESS"
$$;

CALL myproc('table_a', 'table_b', 5);


create table  bank_details(
age int,
job varchar(30),
marital varchar(30),
education varchar(30),
`default` varchar(30),
balance int , 
housing varchar(30),
loan varchar(30) , 
contact varchar(30),
`day` int,
`month` varchar(30) , 
duration int , 
campaign int,
pdays int , 
previous int , 
poutcome varchar(30) , 
y varchar(30));

insert into bank_details values
(44,'technician','single','secondary','no',29,'yes','no','unknown',5,'may',151,1,-1,0,'unknown','no'),
(33,'entrepreneur','married','secondary','no',2,'yes','yes','unknown',5,'may',76,1,-1,0,'unknown','no'),
(47,'blue-collar','married','unknown','no',1506,'yes','no','unknown',5,'may',92,1,-1,0,'unknown','no'),
(33,'unknown','single','unknown','no',1,'no','no','unknown',5,'may',198,1,-1,0,'unknown','no'),
(35,'management','married','tertiary','no',231,'yes','no','unknown',5,'may',139,1,-1,0,'unknown','no'),
(28,'management','single','tertiary','no',447,'yes','yes','unknown',5,'may',217,1,-1,0,'unknown','no'),
(42,'entrepreneur','divorced','tertiary','yes',2,'yes','no','unknown',5,'may',380,1,-1,0,'unknown','no'),
(58,'retired','married','primary','no',121,'yes','no','unknown',5,'may',50,1,-1,0,'unknown','no'),
(43,'technician','single','secondary','no',593,'yes','no','unknown',5,'may',55,1,-1,0,'unknown','no'),
(41,'admin.','divorced','secondary','no',270,'yes','no','unknown',5,'may',222,1,-1,0,'unknown','no'),
(29,'admin.','single','secondary','no',390,'yes','no','unknown',5,'may',137,1,-1,0,'unknown','no'),
(53,'technician','married','secondary','no',6,'yes','no','unknown',5,'may',517,1,-1,0,'unknown','no'),
(58,'technician','married','unknown','no',71,'yes','no','unknown',5,'may',71,1,-1,0,'unknown','no'),
(57,'services','married','secondary','no',162,'yes','no','unknown',5,'may',174,1,-1,0,'unknown','no'),
(51,'retired','married','primary','no',229,'yes','no','unknown',5,'may',353,1,-1,0,'unknown','no'),
(45,'admin.','single','unknown','no',13,'yes','no','unknown',5,'may',98,1,-1,0,'unknown','no'),
(57,'blue-collar','married','primary','no',52,'yes','no','unknown',5,'may',38,1,-1,0,'unknown','no'),
(60,'retired','married','primary','no',60,'yes','no','unknown',5,'may',219,1,-1,0,'unknown','no'),
(33,'services','married','secondary','no',0,'yes','no','unknown',5,'may',54,1,-1,0,'unknown','no'),
(28,'blue-collar','married','secondary','no',723,'yes','yes','unknown',5,'may',262,1,-1,0,'unknown','no'),
(56,'management','married','tertiary','no',779,'yes','no','unknown',5,'may',164,1,-1,0,'unknown','no'),
(32,'blue-collar','single','primary','no',23,'yes','yes','unknown',5,'may',160,1,-1,0,'unknown','no'),
(25,'services','married','secondary','no',50,'yes','no','unknown',5,'may',342,1,-1,0,'unknown','no'),
(40,'retired','married','primary','no',0,'yes','yes','unknown',5,'may',181,1,-1,0,'unknown','no'),
(44,'admin.','married','secondary','no',-372,'yes','no','unknown',5,'may',172,1,-1,0,'unknown','no'),
(39,'management','single','tertiary','no',255,'yes','no','unknown',5,'may',296,1,-1,0,'unknown','no'),
(52,'entrepreneur','married','secondary','no',113,'yes','yes','unknown',5,'may',127,1,-1,0,'unknown','no'),
(46,'management','single','secondary','no',-246,'yes','no','unknown',5,'may',255,2,-1,0,'unknown','no'),
(36,'technician','single','secondary','no',265,'yes','yes','unknown',5,'may',348,1,-1,0,'unknown','no'),
(57,'technician','married','secondary','no',839,'no','yes','unknown',5,'may',225,1,-1,0,'unknown','no'),
(49,'management','married','tertiary','no',378,'yes','no','unknown',5,'may',230,1,-1,0,'unknown','no'),
(60,'admin.','married','secondary','no',39,'yes','yes','unknown',5,'may',208,1,-1,0,'unknown','no'),
(59,'blue-collar','married','secondary','no',0,'yes','no','unknown',5,'may',226,1,-1,0,'unknown','no'),
(51,'management','married','tertiary','no',10635,'yes','no','unknown',5,'may',336,1,-1,0,'unknown','no'),
(57,'technician','divorced','secondary','no',63,'yes','no','unknown',5,'may',242,1,-1,0,'unknown','no'),
(25,'blue-collar','married','secondary','no',-7,'yes','no','unknown',5,'may',365,1,-1,0,'unknown','no'),
(53,'technician','married','secondary','no',-3,'no','no','unknown',5,'may',1666,1,-1,0,'unknown','no'),
(36,'admin.','divorced','secondary','no',506,'yes','no','unknown',5,'may',577,1,-1,0,'unknown','no'),
(37,'admin.','single','secondary','no',0,'yes','no','unknown',5,'may',137,1,-1,0,'unknown','no'),
(44,'services','divorced','secondary','no',2586,'yes','no','unknown',5,'may',160,1,-1,0,'unknown','no'),
(50,'management','married','secondary','no',49,'yes','no','unknown',5,'may',180,2,-1,0,'unknown','no'),
(60,'blue-collar','married','unknown','no',104,'yes','no','unknown',5,'may',22,1,-1,0,'unknown','no'),
(54,'retired','married','secondary','no',529,'yes','no','unknown',5,'may',1492,1,-1,0,'unknown','no'),
(58,'retired','married','unknown','no',96,'yes','no','unknown',5,'may',616,1,-1,0,'unknown','no'),
(36,'admin.','single','primary','no',-171,'yes','no','unknown',5,'may',242,1,-1,0,'unknown','no'),
(58,'self-employed','married','tertiary','no',-364,'yes','no','unknown',5,'may',355,1,-1,0,'unknown','no'),
(44,'technician','married','secondary','no',0,'yes','no','unknown',5,'may',225,2,-1,0,'unknown','no'),
(55,'technician','divorced','secondary','no',0,'no','no','unknown',5,'may',160,1,-1,0,'unknown','no'),
(29,'management','single','tertiary','no',0,'yes','no','unknown',5,'may',363,1,-1,0,'unknown','no'),
(54,'blue-collar','married','secondary','no',1291,'yes','no','unknown',5,'may',266,1,-1,0,'unknown','no'),
(48,'management','divorced','tertiary','no',-244,'yes','no','unknown',5,'may',253,1,-1,0,'unknown','no'),
(32,'management','married','tertiary','no',0,'yes','no','unknown',5,'may',179,1,-1,0,'unknown','no'),
(42,'admin.','single','secondary','no',-76,'yes','no','unknown',5,'may',787,1,-1,0,'unknown','no'),
(24,'technician','single','secondary','no',-103,'yes','yes','unknown',5,'may',145,1,-1,0,'unknown','no'),
(38,'entrepreneur','single','tertiary','no',243,'no','yes','unknown',5,'may',174,1,-1,0,'unknown','no'),
(38,'management','single','tertiary','no',424,'yes','no','unknown',5,'may',104,1,-1,0,'unknown','no'),
(47,'blue-collar','married','unknown','no',306,'yes','no','unknown',5,'may',13,1,-1,0,'unknown','no'),
(40,'blue-collar','single','unknown','no',24,'yes','no','unknown',5,'may',185,1,-1,0,'unknown','no'),
(46,'services','married','primary','no',179,'yes','no','unknown',5,'may',1778,1,-1,0,'unknown','no'),
(32,'admin.','married','tertiary','no',0,'yes','no','unknown',5,'may',138,1,-1,0,'unknown','no'),
(53,'technician','divorced','secondary','no',989,'yes','no','unknown',5,'may',812,1,-1,0,'unknown','no'),
(57,'blue-collar','married','primary','no',249,'yes','no','unknown',5,'may',164,1,-1,0,'unknown','no'),
(33,'services','married','secondary','no',790,'yes','no','unknown',5,'may',391,1,-1,0,'unknown','no'),
(49,'blue-collar','married','unknown','no',154,'yes','no','unknown',5,'may',357,1,-1,0,'unknown','no'),
(51,'management','married','tertiary','no',6530,'yes','no','unknown',5,'may',91,1,-1,0,'unknown','no'),
(60,'retired','married','tertiary','no',100,'no','no','unknown',5,'may',528,1,-1,0,'unknown','no'),
(59,'management','divorced','tertiary','no',59,'yes','no','unknown',5,'may',273,1,-1,0,'unknown','no'),
(55,'technician','married','secondary','no',1205,'yes','no','unknown',5,'may',158,2,-1,0,'unknown','no'),
(35,'blue-collar','single','secondary','no',12223,'yes','yes','unknown',5,'may',177,1,-1,0,'unknown','no'),
(57,'blue-collar','married','secondary','no',5935,'yes','yes','unknown',5,'may',258,1,-1,0,'unknown','no'),
(31,'services','married','secondary','no',25,'yes','yes','unknown',5,'may',172,1,-1,0,'unknown','no'),
(54,'management','married','secondary','no',282,'yes','yes','unknown',5,'may',154,1,-1,0,'unknown','no'),
(55,'blue-collar','married','primary','no',23,'yes','no','unknown',5,'may',291,1,-1,0,'unknown','no'),
(43,'technician','married','secondary','no',1937,'yes','no','unknown',5,'may',181,1,-1,0,'unknown','no'),
(53,'technician','married','secondary','no',384,'yes','no','unknown',5,'may',176,1,-1,0,'unknown','no'),
(44,'blue-collar','married','secondary','no',582,'no','yes','unknown',5,'may',211,1,-1,0,'unknown','no'),
(55,'services','divorced','secondary','no',91,'no','no','unknown',5,'may',349,1,-1,0,'unknown','no'),
(49,'services','divorced','secondary','no',0,'yes','yes','unknown',5,'may',272,1,-1,0,'unknown','no'),
(55,'services','divorced','secondary','yes',1,'yes','no','unknown',5,'may',208,1,-1,0,'unknown','no'),
(45,'admin.','single','secondary','no',206,'yes','no','unknown',5,'may',193,1,-1,0,'unknown','no'),
(47,'services','divorced','secondary','no',164,'no','no','unknown',5,'may',212,1,-1,0,'unknown','no'),
(42,'technician','single','secondary','no',690,'yes','no','unknown',5,'may',20,1,-1,0,'unknown','no'),
(59,'admin.','married','secondary','no',2343,'yes','no','unknown',5,'may',1042,1,-1,0,'unknown','yes'),
(46,'self-employed','married','tertiary','no',137,'yes','yes','unknown',5,'may',246,1,-1,0,'unknown','no'),
(51,'blue-collar','married','primary','no',173,'yes','no','unknown',5,'may',529,2,-1,0,'unknown','no'),
(56,'admin.','married','secondary','no',45,'no','no','unknown',5,'may',1467,1,-1,0,'unknown','yes'),
(41,'technician','married','secondary','no',1270,'yes','no','unknown',5,'may',1389,1,-1,0,'unknown','yes'),
(46,'management','divorced','secondary','no',16,'yes','yes','unknown',5,'may',188,2,-1,0,'unknown','no'),
(57,'retired','married','secondary','no',486,'yes','no','unknown',5,'may',180,2,-1,0,'unknown','no'),
(42,'management','single','secondary','no',50,'no','no','unknown',5,'may',48,1,-1,0,'unknown','no'),
(30,'technician','married','secondary','no',152,'yes','yes','unknown',5,'may',213,2,-1,0,'unknown','no'),
(60,'admin.','married','secondary','no',290,'yes','no','unknown',5,'may',583,1,-1,0,'unknown','no');

select * from bank_details;
select count(*)  from bank_details;

/*
In this modified version of the stored procedure, the res variable is explicitly declared as a RESULTSET data type. 
The RESULTSET data type represents an unbounded set of rows, which is suitable for storing the result of a 
SELECT statement that returns multiple rows.

After the res variable is assigned the result of the SELECT statement, 
it is returned as a table using the RETURN TABLE clause. 
The RETURN TABLE clause converts the RESULTSET data type to a table that can be used as the output of the stored procedure.
*/


CREATE OR REPLACE PROCEDURE GET_ALL_RECORDS_FROM_TABLE()
RETURNS TABLE(age int, job varchar(30), marital varchar(30), education varchar(30), `default` varchar(30), balance int,
housing varchar(30), loan varchar(30), contact varchar(30), `day` int, `month` varchar(30), duration int,
campaign int, pdays int, previous int, poutcome varchar(30), y varchar(30))
LANGUAGE SQL
AS
$$
DECLARE
  res RESULTSET;
BEGIN
  res := (SELECT * FROM bank_details);
  RETURN TABLE(res);
END;
$$;

select distinct job from bank_details;

CALL GET_ALL_RECORDS_FROM_TABLE();

CREATE OR REPLACE PROCEDURE GET_AVG_BALANCE(job_role varchar(30))
RETURNS NUMBER(10,3)
--LANGUAGE SQL
AS
$$
DECLARE
  avg_balance NUMBER(10,3);
BEGIN
  SELECT AVG(balance) INTO avg_balance FROM bank_details WHERE job =: job_role; 
  RETURN avg_balance;
END;
$$;

--WHILE READING INPUT PARAMTERS GIVE =: VAR_NAME

CALL GET_AVG_BALANCE('admin.');

CALL GET_AVG_BALANCE();






 

-- Calling the stored procedure
CALL SELECT_REC();



-- Calling the stored procedure
CALL AVG_BAL_JOBROLE();




/* This shows a more realistic example that includes a call to the JavaScript API.
A more extensive version of this procedure could allow a user to insert data into a table that the user didn’t
have privileges to insert into directly. 
JavaScript statements could check the input parameters and execute the SQL INSERT only if certain requirements were met.
*/

create or replace procedure stproc1(FLOAT_PARAM1 FLOAT)
    returns string
    language javascript
    strict
    execute as owner
    as
    $$
    var sql_command = 
     "INSERT INTO stproc_test_table1 (num_col1) VALUES (" + FLOAT_PARAM1 + ")";
    try {
        snowflake.execute (
            {sqlText: sql_command}
            );
        return "Succeeded.";   // Return a success/error indicator.
        }
    catch (err)  {
        return "Failed: " + err;   // Return a success/error indicator.
        }
    $$
    ;

CALL stproc1(3.56);







