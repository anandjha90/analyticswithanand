----------------------------------------------------AWS (S3) INTEGRATION------------------------------------------------------------------------
CREATE OR REPLACE STORAGE integration s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN ='arn:aws:iam::441615131317:role/retailrole' 
STORAGE_ALLOWED_LOCATIONS =('s3://retailraw/');

DESC integration s3_int;


CREATE OR REPLACE STAGE RETAIL
URL ='s3://retailraw'
file_format = CSV
storage_integration = s3_int;

LIST @RETAIL;

SHOW STAGES;