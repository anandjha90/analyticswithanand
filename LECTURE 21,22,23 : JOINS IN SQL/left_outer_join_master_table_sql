USE DATABASE DEMO_DATABASE;

CREATE OR REPLACE TABLE AJ_COMPLAIN
(
  ID	INT,
 ComplainDate VARCHAR(10),
 CompletionDate	VARCHAR(10),
 CustomerID	INT,
 BrokerID	INT,
 ProductID	INT,
 ComplainPriorityID	INT,
 ComplainTypeID	INT,
 ComplainSourceID	INT,
 ComplainCategoryID	INT,
 ComplainStatusID	INT,
 AdministratorID	STRING,
 ClientSatisfaction	VARCHAR(20),
 ExpectedReimbursement INT
);
---------------------------------------------------------------------------------------------------------


CREATE OR REPLACE TABLE AJ_CUSTOMER
(
CustomerID	INT,
LastName VARCHAR(60),
FirstName VARCHAR(60),
BirthDate VARCHAR(20) ,
Gender VARCHAR(20),
ParticipantType	VARCHAR(20),
RegionID	INT,
MaritalStatus VARCHAR(15));
---------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE AJ_BROKER
(
  BrokerID	INT,
  BrokerCode VARCHAR(70),
  BrokerFullName	VARCHAR(60),
  DistributionNetwork	VARCHAR(60),
  DistributionChannel	VARCHAR(60),
  CommissionScheme VARCHAR(50)

);
---------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE AJ_CATAGORIES
(
ID	INT,
Description_Categories VARCHAR2(200),
Active INT
);
---------------------------------------------------------------------------------------------------------

CREATE OR REPLACE TABLE AJ_PRIORITIES
(
ID	INT,
Description_Priorities VARCHAR(10)
);
---------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE AJ_PRODUCT
(
ProductID	INT,
ProductCategory	VARCHAR(60),
ProductSubCategory	VARCHAR(60),
Product VARCHAR(30)
);
---------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE AJ_REGION
(
  id INT,
  name	VARCHAR(50) ,
  county	VARCHAR(100),
  state_code	CHAR(5),
  state	VARCHAR (60),
  type	VARCHAR(50),
  latitude	NUMBER(11,4),
  longitude	NUMBER(11,4),
  area_code	INT,
  population	INT,
  Households	INT,
  median_income	INT,
  land_area	INT,
  water_area	INT,
  time_zone VARCHAR(70)
);
---------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE AJ_SOURCES
(
ID	INT,
Description_Source VARCHAR(20)
);
---------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE AJ_STATE_REGION
(
  State_Code VARCHAR(20),	
  State	 VARCHAR(20),
  Region VARCHAR(20)
);
---------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE AJ_STATUSES
(
  ID	INT,
  Description_Status VARCHAR(40));
---------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE AJ_TYPE
(
  ID INT	,
  Description_Type VARCHAR(20)
);
-------------------------------------------------------------------------------------------------------
SELECT * FROM AJ_COMPLAIN;
SELECT * FROM AJ_CUSTOMER;
SELECT * FROM AJ_BROKER;
SELECT * FROM AJ_CATAGORIES;
SELECT * FROM AJ_PRIORITIES;
SELECT * FROM AJ_PRODUCT;
SELECT * FROM AJ_REGION;
SELECT * FROM AJ_SOURCES;
SELECT * FROM AJ_STATE_REGION;
SELECT * FROM AJ_STATUSES;
SELECT * FROM AJ_TYPE;
SELECT * FROM AJ_CUST_MASTER;

CREATE OR REPLACE TABLE AJ_CUST_MASTER AS
SELECT COM.ID,COM.ComplainDate,COM.CompletionDate,CUS.LastName,
CUS.FirstName,CUS.Gender,BR.BrokerFullName,BR.CommissionScheme,
CAT.Description_Categories,SR.Region,ST.Description_Status,REG.state,PR.Product,
PRI.Description_Priorities,SUR.Description_Source,TY.Description_Type
FROM AJ_COMPLAIN COM 
LEFT OUTER JOIN AJ_CUSTOMER CUS ON COM.CustomerID = CUS.CustomerID
LEFT OUTER JOIN AJ_REGION REG ON CUS.RegionID = REG.id
LEFT OUTER JOIN AJ_STATE_REGION SR ON REG.state_code = SR.State_Code
LEFT OUTER JOIN AJ_BROKER BR ON COM.BrokerID = BR.BrokerID
LEFT OUTER JOIN AJ_CATAGORIES CAT ON COM.ComplainCategoryID = CAT.ID
LEFT OUTER JOIN AJ_PRIORITIES PRI ON COM.ComplainPriorityID = PRI.ID
LEFT OUTER JOIN AJ_PRODUCT PR ON COM.ProductID = PR.ProductID
LEFT OUTER JOIN AJ_SOURCES SUR ON COM.ComplainSourceID = SUR.ID
LEFT OUTER JOIN AJ_STATUSES ST ON COM.ComplainStatusID = ST.ID
LEFT OUTER JOIN AJ_TYPE TY ON COM.ComplainTypeID = TY.ID
;
