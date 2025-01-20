# import thenecessary library
import boto3
import botocore
from botocore.config import Config
import getpass
import snowflake.connector
import pandas as pd
import os
from io import StringIO
import csv


# Establish the connection
conn = snowflake.connector.connect(
    account= 'your_account_name',
    user='your_user_name',
    password = getpass.getpass('Your Snowflake Password: '),
    warehouse='your_warehouse',
    database='your_database',
    schema='your_schema',
    role='your_role'
)

# Test the connection
cursor = conn.cursor()
cursor.execute("SELECT CURRENT_VERSION()")
print(cursor.fetchone())

# Set up AWS credentials manually (only for testing)
aws_access_key_id = 'your_secret_key'
aws_secret_access_key = 'your_aws_secret_access_key' 
region_name = 'your_region_name' 

# Create a session using the manual credentials
session = boto3.Session(
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    region_name=region_name
)

# Create an S3 client
s3 = session.client('s3')

# Now you can use the S3 client to perform operations to list all buckets
response = s3.list_buckets()
print(response)

# ACCESSING SPECIFIC BUCKET INFO

# Specify the name of your S3 bucket
bucket_name = 'czec-banking'
# List all objects in the specific S3 bucket
response = s3.list_objects_v2(Bucket=bucket_name)
# Print object keys (file names)
if 'Contents' in response:
    for obj in response['Contents']:
        print(f"Object Key: {obj['Key']}")
else:
    print("No objects found in the bucket.")

tables = ['sales_region_data', 'customer_data']  # Add all your table names here

# iterate through all the tables available in snowflake for which you want to extract data and put it in aws s3 specific folder inside a bucket
# Export data to S3
for table in tables:
    file_name = f"{table}.csv"
    export_query = f"""
    COPY INTO @my_external_stage/{file_name} -- create a stage my_external_stage in snowflake by referring code files
    FROM (SELECT * FROM {table})
    OVERWRITE=TRUE;
    """
    conn.cursor().execute(export_query)   -- export the data into respective s3 bucket folder
    print(f"Exported {table} data to S3 as {file_name}")

print("All tables exported successfully!")
