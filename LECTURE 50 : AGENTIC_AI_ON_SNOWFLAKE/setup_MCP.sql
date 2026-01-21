-- It is a standard that lets AI tools talk to data sources
-- One integration works everywhere
-- MCP = USB for AI
-- One standard protocol, works with any MCP client & connects to any MCP server

-- MCP Architecture Server(Snowflake) -> The server exposes capabilities as tools
-- Query this database, search these documents, run this agent.
-- Protocol(MCP) -> Client(Claude, Cursor,ChatGPT, custom tools, etc.) - any AI application that supports MCP.
-- MCP brings your data to those tools without even logging to snowflake.
-- The client discovers what tools the server offers, then it calls those tools
-- The client doesn't need to know anything about Snowflake
-- Your agent is now available through MCP
-- Any client that supports the protocol can use it.

-- MCP Security : OAuth 2.0 authentication + Snowflake RBAC enforced + All requests logged

-- MCP request flow:
-- A user in Cloud Desktop wants sales data
-- Cloud sends a request to the Snowflake MCP server
-- The server checks authentication, verifies the user's role, calls the agent, get results, returns them to Cloud, and Cloud shows the user.

CREATE OR REPLACE SECURITY INTEGRATION SALES_MCP_OAUTH
    TYPE = OAUTH
    ENABLED = TRUE
    OAUTH_CLIENT = CUSTOM
    OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
    OAUTH_REDIRECT_URI = 'http://localhost:3000/oauth/callback'
    OAUTH_ALLOW_NON_TLS_REDIRECT_URI = TRUE  -- Allow HTTP for localhost development
    OAUTH_ISSUE_REFRESH_TOKENS = TRUE
    OAUTH_REFRESH_TOKEN_VALIDITY = 86400
    COMMENT = 'OAuth integration for Sales Intelligence MCP Server - Local Development';

-- Retrieve OAuth client credentials (SAVE THESE!)
SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('SALES_MCP_OAUTH');

-- "OAUTH_CLIENT_SECRET_2":"uo0gJnFA31i+VSDeQf3O40eRy2HnXUvGPMb0T5qWvfA=",
-- "OAUTH_CLIENT_SECRET":"5dEZfW9QZJRoi0g7/jOp7kZFTM8FzWBm07okaGby78s=",
-- "OAUTH_CLIENT_ID":"/OHDJzCXeqIW9NutUIj7zH2QLIc="}

-- ============================================
-- CREATE MCP SERVER WITH TOOLS
-- ============================================

-- Create the MCP Server that exposes Cortex Agent
CREATE OR REPLACE MCP SERVER SALES_INTELLIGENCE_MCP
    FROM SPECIFICATION $$
    tools:
      # Cortex Agent for sales intelligence
      - name: "sales-intelligence-agent"
        type: "CORTEX_AGENT_RUN"
        identifier: "SALES_INTELLIGENCE.DATA.SALES_AGENT"
        description: "AI agent for sales intelligence that can search conversations, analyze metrics, and query sales data"
        title: "Sales Intelligence Agent"
    $$;

-- Grant permissions
GRANT USAGE ON MCP SERVER SALES_INTELLIGENCE.DATA.SALES_INTELLIGENCE_MCP TO ROLE SALES_INTELLIGENCE_ROLE;

-- Grant access to OAuth integration
GRANT USAGE ON INTEGRATION SALES_MCP_OAUTH TO ROLE SALES_INTELLIGENCE_ROLE;

GRANT USAGE ON AGENT SALES_AGENT TO ROLE SALES_INTELLIGENCE_ROLE;

-- Verify the configuration
DESC SECURITY INTEGRATION SALES_MCP_OAUTH;

-- View the created MCP server
SHOW MCP SERVERS IN SCHEMA SALES_INTELLIGENCE.DATA;

-- Describe the MCP server to see its configuration
DESCRIBE MCP SERVER SALES_INTELLIGENCE_MCP;


SELECT SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('SALES_MCP_OAUTH');
