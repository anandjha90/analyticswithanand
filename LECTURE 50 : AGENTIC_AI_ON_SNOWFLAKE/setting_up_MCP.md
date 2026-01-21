## Setting Up for Model Context Protocol

## What you need to download
Download the quickstart resources zip file from the Snowflake Labs repository. This contains the SQL setup script and configuration files you'll need.

## Download link
https://github.com/Snowflake-Labs/sfquickstarts/blob/master/site/sfguides/src/get-started-with-openai-sdk-and-managed-mcp-for-cortex-agents/resources/get-started-with-openai-sdk-and-managed-mcp-for-cortex-agents.zip

## Steps to complete
1.Download the zip file from the link above

2.Extract the contents to a folder on your computer

3.Locate the file called mcp_setup.sql

4.Open Snowflake and create a new SQL worksheet

5.Copy the contents of mcp_setup.sql into the worksheet

6.Run the entire script to configure the required objects for MCP

## What the setup script does
The mcp_setup.sql script creates the necessary database objects, security integrations, and permissions for MCP to work with your Snowflake account. 
Running this script before the video ensures you can follow along with the MCP server creation and Cursor configuration without interruption.

## Verify the setup
After running the script, verify it completed successfully by checking for any error messages. If you encounter permission errors, you may need to run the script using a role with ACCOUNTADMIN privileges.

## Why this matters
MCP requires specific OAuth configurations and security integrations that take a few minutes to set up. 
Completing this preparation ahead of time lets you focus on understanding MCP concepts rather than troubleshooting setup issues.
