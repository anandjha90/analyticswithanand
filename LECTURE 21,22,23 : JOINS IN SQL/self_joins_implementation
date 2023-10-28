/*
Self Join is a join where a table is joined to itself. 

That is, both the tables in the join operations are the same. 

In a self join each row of the table is joined with itself if they satisfy the join condition

Examples of Self Join
There are many instances, where you need to self join a table. 
Usually when the table has a parent-child relationship with itself. 
In a parent-child relationship, the table will have FOREIGN KEY which references its own PRIMARY KEY.

For Example

Customer account in the bank with an introducer. The introducer must be a customer of the bank.
An employee with a supervisor or manager.
Department under another Department

Self Join Syntax
There is no special syntax for Self-join. It is just a normal join where first_table and second_table refers to the same table.
 
SELECT [colums]
FROM first_table 
[join_type] JOIN 
first_table 
[ON (join_condition)]

 There is no special self Join Syntax. There is no SELF JOIN keyword
The Alias for the table is a must as both tables are the same. Otherwise, it will result in an error
You can use the same table at multiple levels

*/
create OR REPLACE table Employees 
(
    EmployeeID int primary key,
    Name varchar(100),
    ManagerID int null,
    CONSTRAINT FK_ManagerID FOREIGN KEY (ManagerID)
         REFERENCES Employees (EmployeeID)
);
 
insert into Employees Values(1,'Kevin ',null);
insert into Employees Values(2,'Akshay',1);
insert into Employees Values(3,'Sandeep',2);
insert into Employees Values(4,'Swati',2);
insert into Employees Values(5,'Sunil',1);

--To get the Employees List, with the manager’s name we need to join the Employees table with itself as shown below.
Select e.EmployeeID,e.Name, m.EmployeeID as ManagerID, m.Name As Manager
from Employees e
left join Employees m on e.ManagerID = m.EmployeeID;

/* Now, let us consider another sample database, where the employee’s table has the DeptID column. 
The Manager of the department is stored in the third table DeptManager.
*/
 
create OR REPLACE table Dept (
   DeptID int primary key,
   Name varchar(100)
);
 
create OR REPLACE table Employees (
   EmployeeID int primary key,
   Name varchar(100),
   DeptID int null,
   CONSTRAINT FK_Employees_DeptID   FOREIGN KEY (DeptID) REFERENCES Dept (DeptID)
);
 
create or replace table DeptManager (
   DeptID int ,
   ManagerID int,
   primary key (DeptID, ManagerID),
   CONSTRAINT FK_DeptManager_DeptID   FOREIGN KEY (DeptID) REFERENCES Dept (DeptID),
   CONSTRAINT FK_DeptManager_ManagerID   FOREIGN KEY (ManagerID) REFERENCES Employees (EmployeeID)
);
 
insert into Dept Values(1,'Excutive');
insert into Dept Values(2,'HR');
 
insert into Employees Values(1,'Kevin ',1);
insert into Employees Values(2,'Akshay',1);
insert into Employees Values(3,'Sandeep',2);
insert into Employees Values(4,'Swati',2);
insert into Employees Values(5,'Sunil',2);
 
insert into DeptManager Values(1,1);
insert into DeptManager Values(2,2);

/* To get the employee list with dept name with the manager, we need to join

- Join the Dept table with the employee table to get the name of the dept. (based on DeptID)
- Get the ManagerID from DeptManager table joining it to the above result (based on DeptID)
- To get the Manager’s name Join the Employees table again on the ManagerID & EmployeeID

*/

Select e.EmployeeID,e.Name, d.Name, m.EmployeeID as ManagerID, m.Name As Manager
from Employees e
left join Dept d on e.DeptID =d.DeptID
left join DeptManager dm on e.DeptID = dm.DeptID
left join Employees m on m.EmployeeID = dm.ManagerID;

/* Now, if you notice the Employee Kevin is Manager of Executive Dept. 
Hence shown as Manager to himself, which is wrong. 
You can correct by ensuring that employeeID of the manager & employee cannot be the same 
(employee.employeeID <> Manager.EmployeeID) as shown in the query below. */
Select e.EmployeeID,e.Name, d.Name, m.EmployeeID as ManagerID, m.Name As Manager
from Employees e
left join Dept d on e.DeptID =d.DeptID
left join DeptManager dm on e.DeptID = dm.DeptID
left join Employees m on m.EmployeeID = dm.ManagerID and e.employeeID <> m.EmployeeID;

/*You can extend the above query, one step further by asking for Managers Department and his manager. 
That requires us to join the employee & dept table again as shown below */

Select e.EmployeeID,e.Name, d.Name as Dept, m.EmployeeID as ManagerID, m.Name As Manager, md.Name As ManagerDept, tm.Name as SrManager
from Employees e
left join Dept d on e.DeptID = d.DeptID
left join DeptManager dm on e.DeptID = dm.DeptID
left join Employees m on m.EmployeeID =dm.ManagerID  and e.employeeID <> m.EmployeeID
left join Dept md on md.DeptID = m.DeptID
left join DeptManager mdm on mdm.DeptID= md.DeptID
left join Employees tm on tm.EmployeeID = mdm.ManagerID  and m.employeeID <> tm.EmployeeID;










