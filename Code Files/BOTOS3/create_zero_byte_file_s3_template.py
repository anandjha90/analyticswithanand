CREATE OR REPLACE PROCEDURE create_zero_byte_file()
    RETURNS STRING
    LANGUAGE PYTHON
    EXECUTE AS CALLER
AS
$$
import boto3

# Initialize a session using your Snowflake credentials
session = boto3.Session(
    aws_access_key_id='YOUR_ACCESS_KEY',
    aws_secret_access_key='YOUR_SECRET_KEY',
    region_name='YOUR_REGION'
)

# Create an S3 client
s3 = session.client('s3')

# Define the bucket name and the key (file name)
bucket_name = 'your-bucket-name'
file_key = 'your-zero-byte-file.txt'

# Create a zero-byte file
s3.put_object(Bucket=bucket_name, Key=file_key, Body=b'')

return 'Zero-byte file created successfully!'
$$;
