import boto3
import getpass
import snowflake.connector

# Establish the connection
conn = snowflake.connector.connect(
    account= 'prrgexw-hb87719',
    user='ANANDTIGERANALYTICS',
    password = getpass.getpass('Your Snowflake Password: ')
    warehouse='DEMO_WAREHOUSE',
    database='DEMO_DATABASE',
    schema='DEMO_SCHEMA',
    role='ACCOUNTADMIN'
)

# Test the connection
cursor = conn.cursor()
cursor.execute("SELECT CURRENT_VERSION()")
print(cursor.fetchone())

# Your Snowflake Password: ········
# ('8.45.1',)

def fetch_aws_credentials_from_snowflake():
        try:
            # Establish Snowflake connection
            conn = snowflake.connector.connect
            (
            account= 'prrgexw-hb87719',
            user='ANANDTIGERANALYTICS',
            password = getpass.getpass('Your Snowflake Password: '),
            warehouse='DEMO_WAREHOUSE',
            database='DEMO_DATABASE',
            schema='DEMO_SCHEMA',
            role='ACCOUNTADMIN'
            )

            # Query AWS credentials from a Snowflake table
            query = "SELECT aws_access_key, aws_secret_key, aws_session_token FROM your_credentials_table LIMIT 1;"
            cursor = conn.cursor()
            cursor.execute(query)
            row = cursor.fetchone()
            if row:
                return {
                    "aws_access_key": row[0],
                    "aws_secret_key": row[1],
                    "aws_session_token": row[2] if len(row) > 2 else None
                }
            else:
                raise ValueError("No credentials found in Snowflake.")
        except Exception as e:
            raise Exception(f"Error fetching credentials from Snowflake: {str(e)}")
        finally:
            cursor.close()
            conn.close()

    def create_zero_byte_file_in_s3(aws_access_key, aws_secret_key, aws_session_token):
        """
        Creates a zero-byte file in the specified AWS S3 bucket using boto3.
        
        Parameters:
        aws_access_key (str): AWS access key.
        aws_secret_key (str): AWS secret access key.
        aws_session_token (str, optional): AWS session token (for temporary credentials).
        
        Returns:
        str: Success or error message.
        """
        # Set up the boto3 session
        session = boto3.Session(
            aws_access_key_id=aws_access_key,
            aws_secret_access_key=aws_secret_key,
            aws_session_token=aws_session_token
        )
        s3 = session.client('s3')
        
        try:
            # Create a zero-byte object
            s3.put_object(Bucket=bucket_name, Key=file_name, Body=b'')
            return f"Zero-byte file '{file_name}' successfully created in bucket '{bucket_name}'."
        except Exception as e:
            return f"Error creating zero-byte file: {str(e)}"

    # Main procedure logic
    try:
        # Fetch AWS credentials from Snowflake
        aws_credentials = fetch_aws_credentials_from_snowflake()
        
        # Create a zero-byte file in S3
        result = create_zero_byte_file_in_s3(
            aws_credentials["aws_access_key"],
            aws_credentials["aws_secret_key"],
            aws_credentials.get("aws_session_token")
        )
        return result
    except Exception as e:
        return f"Error in stored procedure: {str(e)}"

# Example usage
if __name__ == "__main__":
    # Snowflake connection details
    sf_user = "your_snowflake_user"
    sf_password = "your_snowflake_password"
    sf_account = "your_snowflake_account"
    sf_database = "your_snowflake_database"
    sf_schema = "your_snowflake_schema"
    sf_warehouse = "your_snowflake_warehouse"
    sf_role = "your_snowflake_role"

    # AWS S3 bucket and file details
    bucket_name = "your-s3-bucket-name"
    file_name = "your-zero-byte-file.txt"

    # Call the stored procedure
    result = create_zero_byte_file(
        bucket_name, file_name,
        sf_user, sf_password, sf_account,
        sf_database, sf_schema, sf_warehouse, sf_role
    )
    print(result)
