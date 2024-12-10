import boto3
import botocore
from botocore.config import Config
import getpass
import snowflake.connector
import pandas as pd
import os
from io import StringIO
import csv

# 'C:\\Users\\Anand Jha\\Downloads'
os.getcwd() 

# Set up AWS credentials manually (only for testing)
aws_access_key_id = '**************' -- your access id
aws_secret_access_key = '****************************' -- your secret acces key
region_name = 'us-east-1'  # Replace with your region 

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

# creating S3 bucket with a unique name
s3.create_bucket(Bucket='s3demobucketpy')

# ACCESSING SPECIFIC BUCKET INFO

# Specify the name of your S3 bucket
bucket_name = 'ssbucketdemo'
# List all objects in the specific S3 bucket
response = s3.list_objects_v2(Bucket=bucket_name)
# Print object keys (file names)
if 'Contents' in response:
    for obj in response['Contents']:
        print(f"Object Key: {obj['Key']}")
else:
    print("No objects found in the bucket.")

# UPLOADING A FILE IN A SPECIFIC BUCKET

# Specify the name of your S3 bucket and the file to upload
bucket_name = 'ssbucketdemo'
file_name = 'C:/Users/Anand Jha/Downloads/sales_data_df2.csv'
s3_object_name = 'NHANES/sales_data_df2.csv'  # This is the key in S3 or specific folder name followed by file name inside a bucket folder

# Upload the file to the specified bucket
s3.upload_file(file_name, bucket_name, s3_object_name)

print(f"File '{file_name}' uploaded to S3 bucket '{bucket_name}' as '{s3_object_name}'.")
# File 'C:/Users/Anand Jha/Downloads/sales_data_df2.csv' uploaded to S3 bucket 'ssbucketdemo' as 'NHANES/sales_data_df2.csv'.

# DOWNLOADING A FILE FROM A SPECIFIC BUCKET

# Specify the name of your S3 bucket and the file to download
bucket_name = 'ssbucketdemo'
s3_object_name = 'NHANES/sales_data_df2.csv'  # The key in S3
download_path = 'E:/Tiger_Analytics/BOTOS3'  # Local path to save the downloaded file

# Download the file from the S3 bucket
s3.download_file(bucket_name, s3_object_name, download_path)

print(f"File '{s3_object_name}' downloaded from S3 bucket '{bucket_name}' to '{download_path}'.")
# File 'NHANES/sales_data_df2.csv' downloaded from S3 bucket 'ssbucketdemo' to 'E:/Tiger_Analytics/BOTOS3'.

# deleting A FILE FROM A SPECIFIC BUCKET
# Specify the name of your S3 bucket and the object to delete
bucket_name = 'ssbucketdemo'
s3_object_name = 'NHANES/sales_data_df2.csv'  # The key of the object to delete

# Delete the object from the S3 bucket
s3.delete_object(Bucket=bucket_name, Key=s3_object_name)

print(f"Object '{s3_object_name}' deleted from S3 bucket '{bucket_name}'.")
# Object 'NHANES/sales_data_df2.csv' deleted from S3 bucket 'ssbucketdemo'.

## CREATING A ZERO_BYTE_FILE IN S3
# to create a zero-byte file (empty file) in S3:

# Define the bucket and file name
bucket_name = 'ssbucketdemo'
file_name = 'your-zero-byte-file.txt'

# Create a zero-byte file
s3.put_object(Bucket=bucket_name, Key=file_name, Body=b'')
print(f"Zero-byte file '{file_name}' created in bucket '{bucket_name}'.")
# Zero-byte file 'your-zero-byte-file.txt' created in bucket 'ssbucketdemo'

