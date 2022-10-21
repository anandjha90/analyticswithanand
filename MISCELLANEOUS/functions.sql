create function pi_udf()
  returns float
  as '3.141592654::FLOAT'
  ;
  
--Create a simple SQL table UDF that returns hard-coded values:
create function simple_table_function ()
  returns table (x integer, y integer)
  as
  $$
    select 1, 2
    union all
    select 3, 4
  $$
  ;

select * from table(simple_table_function());

--Create a UDF that accepts multiple parameters:
create function multiply1 (a number, b number)
  returns number
  comment='multiply two numbers'
  as 'a * b';

select * from table(multiply1());

--Create a SQL table UDF named get_countries_for_user that returns the results of a query:

create or replace function get_countries_for_user ( id number )
  returns table (country_code char, country_name varchar)
  as 'select distinct c.country_code, c.country_name
      from user_addresses a, countries c
      where a.user_id = id
      and c.country_code = a.country_code';
  }