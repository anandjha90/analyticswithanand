/* A view allows the result of a query to be accessed as if it were a table. 
The query is specified in the CREATE VIEW statement.

Views serve a variety of purposes, including combining, segregating, and protecting data. 
For example, you can create separate views that meet the needs of different types of employees, such as doctors and accountants at a hospital:

*/

create table hospital_table (patient_id integer,
                             patient_name varchar, 
                             billing_address varchar,
                             diagnosis varchar, 
                             treatment varchar,
                             cost number(10,2));
insert into hospital_table 
        (patient_id, patient_name, billing_address, diagnosis, treatment, cost) 
    values
        (1, 'Mark Knopfler', '1982 Telegraph Road', 'Industrial Disease', 
            'a week of peace and quiet', 2000.00),
        (2, 'Guido van Rossum', '37 Florida St.', 'python bite', 'anti-venom', 
            70000.00);
            
SELECT * FROM  hospital_table; 
SELECT * FROM DOCTOR_VIEW;
SELECT * FROM accountant_view;

create view doctor_view as
    select patient_id, patient_name, diagnosis, treatment from hospital_table;

create view accountant_view as
    select patient_id, patient_name, billing_address, cost from hospital_table;
    
    
    

-- A view can be used almost anywhere that a table can be used (joins, subqueries, etc.). For example, using the views created above:

--Show all of the types of medical problems for each patient:
select distinct diagnosis from doctor_view;

--Show the cost of each treatment (without showing personally identifying information about specific patients):
select treatment, cost 
from doctor_view as dv, accountant_view as av
where av.patient_id = dv.patient_id;

/*
Views Enable Writing More Modular Code
Views help you to write clearer, more modular SQL code. For example, suppose that your hospital database has a table 
listing information about all employees. You can create views to make it convenient to extract information about 
only the medical staff or only the maintenance staff. You can even create hierarchies of views.

For example, you can create one view for the doctors, and one for the nurses, and then create 
the medical_staff view by referring to the doctors view and nurses view: */

create table employees (id integer, title varchar);
insert into employees (id, title) values
    (1, 'doctor'),
    (2, 'nurse'),
    (3, 'janitor')
    ;

create view doctors as select * from employees where title = 'doctor';
create view nurses as select * from employees where title = 'nurse';
create view medical_staff as
    select * from doctors
    union
    select * from nurses
    ;

select * 
    from medical_staff
    order by id;
    
/*
Views Allow Granting Access to a Subset of a Table
Views allow you to grant access to just a portion of the data in a table(s). 

For example, suppose that you have a table of medical patient records. 
The medical staff should have access to all of the medical information (for example, diagnosis) but not the financial information 
(for example, the patient'92s credit card number). 

The accounting staff should have access to the billing-related information, such as the costs of 
each of the prescriptions given to the patient, but not to the private medical data, 
such as diagnosis of a mental health condition. You can create two separate views, 
one for the medical staff, and one for the billing staff, so that each of those roles sees only the information 
needed to perform their jobs. Views allow this because you can grant privileges 
on a particular view to a particular role, without the grantee role having privileges on the table(s) underlying the view.

In the medical example:

The medical staff would not have privileges on the data table(s), but would have privileges on the view showing diagnosis and treatment.

The accounting staff would not have privileges on the data table(s), but would have privileges on the view showing billing information.

Limitations on Views
The definition for a view cannot be updated 
(i.e. you cannot use ALTER VIEW or ALTER MATERIALIZED VIEW to change the definition of a view). 
To change a view definition, you must recreate the view with the new definition.

Changes to a table are not automatically propagated to views created on that table. 
For example, if you drop a column in a table, the views on that table might become invalid.

Views are read-only (i.e. you cannot execute DML commands directly on a view). 
However, you can use a view in a subquery within a DML statement that updates the underlying base table. For example:

*/
delete from hospital_table 
    where cost > (select avg(cost) from accountant_view);
