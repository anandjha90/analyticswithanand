-- Brief explanation of the column :
/*
SEQN = Respondent sequence number (
SMQ020 = Smoking
RIAGENDR = Gender
RIDAGEYR = Age (years)
DMDEDUC2 = Education level
BMXWT = Weight (kg)
BMXHT = Height (cm)
BMXBMI = BMI
*/
-- creating table
CREATE OR REPLACE TABLE NHANES_MANUAL_UPLOAD (
    SEQN INT NOT NULL PRIMARY KEY,
    ALQ101 FLOAT,
    ALQ110 FLOAT,
    ALQ130 FLOAT,
    SMQ020 INT,
    RIAGENDR INT,
    RIDAGEYR INT,
    RIDRETH1 INT,
    DMDCITZN FLOAT,
    DMDEDUC2 FLOAT,
    DMDMARTL FLOAT,
    DMDHHSIZ INT,
    WTINT2YR FLOAT,
    SDMVPSU INT,
    SDMVSTRA INT,
    INDFMPIR FLOAT,
    BPXSY1 FLOAT,
    BPXDI1 FLOAT,
    BPXSY2 FLOAT,
    BPXDI2 FLOAT,
    BMXWT FLOAT,
    BMXHT FLOAT,
    BMXBMI FLOAT,
    BMXLEG FLOAT,
    BMXARML FLOAT,
    BMXARMC FLOAT,
    BMXWAIST FLOAT,
    HIQ210 FLOAT
);

CREATE OR REPLACE TABLE NHANES_AUTO_UPLOAD LIKE NHANES_MANUAL_UPLOAD; -- just copy the structure(schema) without data 

--creating file format
create or replace file format csv_file_format
type='csv'
compression='none'
field_delimiter=','
field_optionally_enclosed_by='\042' -- double quotes ASCII value
skip_header=1;

-- ----------------------------------------------------AWS (S3) INTEGRATION------------------------------------------------------------------------
CREATE OR REPLACE STORAGE integration s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN ='arn:aws:iam::661806635168:role/banking_role' 
STORAGE_ALLOWED_LOCATIONS =('s3://ssbucketdemo/');

-- DESCRIBE THE INTEGRATION
DESC integration s3_int;
--STORAGE_AWS_IAM_USER_ARN : arn:aws:iam::084375577365:user/c5st0000-s

-- CREATION OF STAGING LAYER
CREATE OR REPLACE STAGE STG_NHANES
URL ='s3://ssbucketdemo'
file_format = csv_file_format
storage_integration = s3_int;

-- LIST STAGE
LIST @STG_NHANES;

-- SHOW STAGES
SHOW STAGES;

-- SNOWPIPE FOR COPYING DATA
-- CREATE SNOWPIPE THAT RECOGNISES CSV THAT ARE INGESTED FROM EXTERNAL STAGE AND COPIES THE DATA INTO EXISTING TABLE
--The AUTO_INGEST=true parameter specifies to read 
--- event notifications sent from an S3 bucket to an SQS queue when new data is ready to load.


CREATE OR REPLACE PIPE NHANES_SNOWPIPE AUTO_INGEST = TRUE AS
COPY INTO DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD --yourdatabase -- your schema ---your table
FROM '@STG_NHANES/NHANES/' --STAGE -- S3 bucket subfoldername 
FILE_FORMAT = csv_file_format; --YOUR CSV FILE FORMAT NAME


-- SHOW PIPES;
SHOW PIPES;

------PIPEREFRESH----------
ALTER PIPE NHANES_SNOWPIPE refresh;

-- check data
SELECT COUNT(*) FROM NHANES_AUTO_UPLOAD;

-- Following are some snowpipe command which will help you to check snowpipe status
select SYSTEM$PIPE_STATUS('NHANES_SNOWPIPE');

-- TO check data has been transferred in the last 1 hr
select * from table(information_schema.copy_history(table_name=>'NHANES_AUTO_UPLOAD', start_time=>
dateadd(hours, -1, current_timestamp())));

-- 3. Data Cleaning
select * from DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD limit 100; -- limit 100 records

-- DATA CLEANING
-- a) Handle Missing Values
--    Replace NULL values with appropriate defaults or mark them as UNKNOWN.

select ALQ101,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 1,2,9,'NULL' - 527
select ALQ110,COUNT(*)from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 1,2,9,7,'NULL' - 4004
select ALQ130,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 2356
select SMQ020,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- No Nulls,1,2,7,9
select ALQ130,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 2356
select DMDEDUC2,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 261
select DMDMARTL,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 261
select INDFMPIR,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 601
select BPXSY1,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 334
select BPXDI1,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 334
select BPXSY2,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 200
select BPXDI2,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 200
select BMXLEG,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 390
select BMXARML,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 308
select BMXARMC,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 308
select BMXWAIST,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1; -- 'NULL' - 367
select HIQ210,COUNT(*) from NHANES_AUTO_UPLOAD GROUP BY 1 ORDER BY 1;  -- 1,2,9,'NULL' - 1003


-- Update NULL values for categorical columns
UPDATE DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD
SET ALQ101 = COALESCE(ALQ101, 9), -- 9 indicates 'Unknown'
    ALQ110 = COALESCE(ALQ110, 9),
    DMDEDUC2 = COALESCE(DMDEDUC2, 9),
    HIQ210 = COALESCE(HIQ210, 9);

-- Replace NULL in numerical columns with meaningful values
UPDATE DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD
SET BMXBMI = COALESCE(BMXBMI, 0), -- Replace missing BMI with 0
    BMXWAIST = COALESCE(BMXWAIST, 0),
    BPXSY1 = COALESCE(BPXSY1, 0),
    BPXDI1 = COALESCE(BPXDI1, 0),
    INDFMPIR = COALESCE(INDFMPIR, 0);

-- b) Ensure Data Consistency
--   Convert numerical values that represent categories into meaningful labels using a lookup table or CASE.    
-- Create a view to add meaningful labels
CREATE OR REPLACE VIEW VW_NHANES_CLEANED AS
SELECT 
    SEQN,
    RIDAGEYR,
    CASE RIAGENDR 
        WHEN 1 THEN 'Male' 
        WHEN 2 THEN 'Female' 
        ELSE 'Unknown' 
    END AS Gender,
    BMXBMI,
    BMXWAIST,
    BPXSY1,
    BPXDI1,
    CASE ALQ101
        WHEN 1 THEN 'Yes'
        WHEN 2 THEN 'No'
        ELSE 'Unknown'
    END AS Alcohol_Consumption,
    CASE ALQ110
        WHEN 1 THEN 'Heavy Drinker'
        WHEN 2 THEN 'Moderate Drinker'
        WHEN 3 THEN 'Non-Drinker'
        ELSE 'Unknown'
    END AS Drinking_Frequency,
    CASE DMDEDUC2
        WHEN 1 THEN 'Less than 9th grade'
        WHEN 2 THEN '9-11th grade'
        WHEN 3 THEN 'High school graduate'
        WHEN 4 THEN 'Some college'
        WHEN 5 THEN 'College graduate or above'
        ELSE 'Unknown'
    END AS Education_Level,
    INDFMPIR,
    CASE HIQ210
        WHEN 1 THEN 'Insured'
        WHEN 2 THEN 'Uninsured'
        ELSE 'Unknown'
    END AS Insurance_Status
FROM DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD;

SELECT * FROM DEMO_DATABASE.DEMO_SCHEMA.VW_NHANES_CLEANED;

-- c) Remove Duplicates
--    Remove duplicates based on SEQN (unique identifier)
DELETE FROM DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD
WHERE SEQN IN (
    SELECT SEQN 
    FROM (
        SELECT SEQN, COUNT(*) AS cnt 
        FROM NHANES_AUTO_UPLOAD
        GROUP BY SEQN
        HAVING COUNT(*) > 1
    )
);

-- d) Validate Data Ranges
--    Ensure values fall within acceptable ranges and flag anomalies.
--    Add flags for anomalies
ALTER VIEW NHANES_AUTO_UPLOAD ADD COLUMN Anomaly_Flag STRING;

UPDATE NHANES_AUTO_UPLOAD
SET Anomaly_Flag = CASE
    WHEN RIDAGEYR < 0 OR RIDAGEYR > 120 THEN 'Invalid Age'
    WHEN BMXBMI < 10 OR BMXBMI > 70 THEN 'Extreme BMI'
    WHEN BPXSY1 < 50 OR BPXSY1 > 250 THEN 'Extreme Systolic BP'
    WHEN BPXDI1 < 30 OR BPXDI1 > 200 THEN 'Extreme Diastolic BP'
    ELSE NULL
END;

-- 4. Prepare Cleaned Data for Analysis
-- Create a new table with cleaned and transformed data for further analysis.
-- Save the cleaned dataset to a new table
CREATE OR REPLACE TABLE NHANES_AUTO_UPLOAD_CLEANED AS
SELECT * FROM VW_NHANES_CLEANED;


--------------------------------------- exploratory data analysis (EDA) -------------------------------------------------------------
/*
Steps to Replicate EDA Using SQL
Basic Descriptive Statistics:

Use SQL to calculate averages, medians, and standard deviations for key columns like BMXBMI, BPXSY1, and RIDAGEYR.
Analyze missing data using COUNT() and NULLIF().
Age and Gender Impact on BMI:

Group by age range and gender and calculate average BMI.
Socioeconomic and Health Metrics:

Create income brackets and analyze their relationship with BMI and blood pressure.
Hypertension and Lifestyle Factors:

Compare blood pressure levels for alcohol consumption categories.
Outlier Analysis:

Identify outliers using statistical thresholds (e.g., values greater than 3 standard deviations from the mean).
*/


-- Additional Complex Business Use Cases
-- 1. Cohort Analysis of Health Trends Over Age Groups
--    Analyze how key health metrics change as people age, broken down by income levels.

SELECT 
    CASE 
        WHEN RIDAGEYR BETWEEN 18 AND 30 THEN '18-30'
        WHEN RIDAGEYR BETWEEN 31 AND 40 THEN '31-40'
        WHEN RIDAGEYR BETWEEN 41 AND 50 THEN '41-50'
        WHEN RIDAGEYR BETWEEN 51 AND 60 THEN '51-60'
        WHEN RIDAGEYR BETWEEN 61 AND 70 THEN '61-70'
        ELSE '71-80'
    END AS Age_Group,
    ROUND(AVG(BMXBMI),2) AS Avg_BMI,
    ROUND(AVG(BPXSY1),2) AS Avg_Systolic_BP,
    ROUND(AVG(BPXDI1),2) AS Avg_Diastolic_BP,
    ROUND(AVG(INDFMPIR),2) AS Avg_Income
FROM DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD
GROUP BY 1
ORDER BY 1;


-- 2. Identifying High-Risk Groups for Hypertension
--    Filter individuals with systolic BP > 140 or diastolic BP > 90 and identify common traits.
SELECT 
    SEQN,
    RIDAGEYR AS Age,
    RIAGENDR AS Gender,
    BMXBMI AS BMI,
    BPXSY1 AS Systolic_BP,
    BPXDI1 AS Diastolic_BP,
    CASE 
        WHEN BPXSY1 > 140 OR BPXDI1 > 90 THEN 'Hypertensive'
        ELSE 'Normal'
    END AS BP_Category
FROM DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD
WHERE BPXSY1 IS NOT NULL AND BPXDI1 IS NOT NULL
ORDER BY BPXSY1 DESC, BPXDI1 DESC;

-- 3. Income Inequality in Healthcare Access
--    Compare the prevalence of health insurance coverage across income levels.
SELECT 
    CASE 
        WHEN INDFMPIR < 1 THEN 'Low Income'
        WHEN INDFMPIR BETWEEN 1 AND 3 THEN 'Middle Income'
        ELSE 'High Income'
    END AS Income_Bracket,
    COUNT(HIQ210) AS Total_Respondents,
    SUM(CASE WHEN HIQ210 = 1 THEN 1 ELSE 0 END) AS Insured,
    SUM(CASE WHEN HIQ210 = 2 THEN 1 ELSE 0 END) AS Uninsured,
    ROUND(SUM(CASE WHEN HIQ210 = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(HIQ210), 2) AS Percent_Insured
FROM DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD
GROUP BY 1
ORDER BY 1;

-- 4. Correlation Analysis Using SQL
--    Calculate correlation coefficients between income and key health metrics.

WITH Stats AS (
    SELECT 
        ROUND(AVG(INDFMPIR),2) AS Avg_Income,
        ROUND(STDDEV(INDFMPIR),2) AS StdDev_Income,
        ROUND(AVG(BMXBMI),2) AS Avg_BMI,
        ROUND(STDDEV(BMXBMI),2) AS StdDev_BMI,
        ROUND(CORR(INDFMPIR, BMXBMI),4) AS Corr_Income_BMI,
        ROUND(CORR(INDFMPIR, BPXSY1),4) AS Corr_Income_Systolic_BP
    FROM DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD
)
SELECT * FROM Stats;

-- 5. Predicting Obesity Risk Factors
--    Identify factors most associated with high BMI levels (>30).

SELECT 
    CASE 
        WHEN BMXBMI > 30 THEN 'Obese'
        ELSE 'Non-Obese'
    END AS Obesity_Status,
    ROUND(AVG(RIDAGEYR),0) AS Avg_Age,
    ROUND(AVG(INDFMPIR),2) AS Avg_Income,
    ROUND(AVG(BPXSY1),2) AS Avg_Systolic_BP,
    ROUND(AVG(BPXDI1),2) AS Avg_Diastolic_BP
FROM DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD
GROUP BY 1
ORDER BY 1;

-- Which demographic groups (age, gender, income) are at the highest risk for obesity?
SELECT 
    Gender,
    CASE 
        WHEN RIDAGEYR BETWEEN 18 AND 30 THEN '18-30'
        WHEN RIDAGEYR BETWEEN 31 AND 40 THEN '31-40'
        WHEN RIDAGEYR BETWEEN 41 AND 50 THEN '41-50'
        WHEN RIDAGEYR BETWEEN 51 AND 60 THEN '51-60'
        WHEN RIDAGEYR BETWEEN 61 AND 70 THEN '61-70'
        ELSE '71-80'
    END AS Age_Group,
    CASE 
        WHEN INDFMPIR < 1 THEN 'Low Income'
        WHEN INDFMPIR BETWEEN 1 AND 3 THEN 'Middle Income'
        ELSE 'High Income'
    END AS Income_Bracket,
    COUNT(*) AS Obese_Count,
    ROUND(AVG(BMXBMI),2) AS Avg_BMI
FROM DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD_CLEANED
WHERE BMXBMI > 30
GROUP BY 1, 2, 3
ORDER BY Obese_Count DESC;

-- 6. Hypertension Prevalence Analysis
-- What percentage of the population suffers from hypertension?

SELECT 
    COUNT(*) AS Total_Respondents,
    SUM(CASE WHEN BPXSY1 > 140 OR BPXDI1 > 90 THEN 1 ELSE 0 END) AS Hypertensive_Count,
    ROUND(SUM(CASE WHEN BPXSY1 > 140 OR BPXDI1 > 90 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Hypertension_Percentage
FROM DEMO_DATABASE.DEMO_SCHEMA.NHANES_AUTO_UPLOAD_CLEANED;

-- 7. Alcohol Consumption and Health Impact
-- Business Question:How does alcohol consumption status impact blood pressure and BMI?

SELECT 
    Alcohol_Consumption,
    ROUND(AVG(BMXBMI),2) AS Avg_BMI,
    ROUND(AVG(BPXSY1),2) AS Avg_Systolic_BP,
    ROUND(AVG(BPXDI1),2) AS Avg_Diastolic_BP,
    COUNT(*) AS Respondents
FROM NHANES_AUTO_UPLOAD_CLEANED
GROUP BY 1
ORDER BY 1;

-- 7. Outlier Analysis for BMI
-- Business Question:Which individuals have extreme BMI values (outliers)?

WITH Stats AS (
    SELECT 
        ROUND(AVG(BMXBMI),2) AS Avg_BMI,
        ROUND(STDDEV(BMXBMI),2) AS StdDev_BMI
    FROM NHANES_AUTO_UPLOAD_CLEANED
),
Outliers AS (
    SELECT 
        SEQN,
        RIDAGEYR AS Age,
        Gender,
        BMXBMI,
        CASE 
            WHEN BMXBMI > (Avg_BMI + 3 * StdDev_BMI) THEN 'High Outlier'
            WHEN BMXBMI < (Avg_BMI - 3 * StdDev_BMI) THEN 'Low Outlier'
        END AS Outlier_Type
    FROM NHANES_AUTO_UPLOAD_CLEANED, Stats
    WHERE BMXBMI > (Avg_BMI + 3 * StdDev_BMI) OR BMXBMI < (Avg_BMI - 3 * StdDev_BMI)
)
SELECT * FROM Outliers;

-- 8. Trend Analysis: BMI and Education Level
-- Business Question:Does education level affect BMI?

SELECT 
    Education_Level,
    ROUND(AVG(BMXBMI),2) AS Avg_BMI,
    COUNT(*) AS Respondents
FROM NHANES_AUTO_UPLOAD_CLEANED
GROUP BY Education_Level
ORDER BY AVG(BMXBMI) DESC;

-- 9. Predicting Obesity from Multiple Factors
-- Business Question:What are the key factors contributing to obesity?
SELECT 
    Gender,
    CASE 
        WHEN RIDAGEYR BETWEEN 18 AND 30 THEN '18-30'
        WHEN RIDAGEYR BETWEEN 31 AND 40 THEN '31-40'
        WHEN RIDAGEYR BETWEEN 41 AND 50 THEN '41-50'
        WHEN RIDAGEYR BETWEEN 51 AND 60 THEN '51-60'
        WHEN RIDAGEYR BETWEEN 61 AND 70 THEN '61-70'
        ELSE '71-80'
    END AS Age_Group,
    CASE 
        WHEN INDFMPIR < 1 THEN 'Low Income'
        WHEN INDFMPIR BETWEEN 1 AND 3 THEN 'Middle Income'
        ELSE 'High Income'
    END AS Income_Bracket,
    ROUND(AVG(BPXSY1),2) AS Avg_Systolic_BP,
    ROUND(AVG(BPXDI1),2) AS Avg_Diastolic_BP,
    COUNT(*) AS Obesity_Count
FROM NHANES_AUTO_UPLOAD_CLEANED
WHERE BMXBMI > 30
GROUP BY 1, 2, 3
ORDER BY Obesity_Count DESC;

