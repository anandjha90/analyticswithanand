## Monitoring Cortex Agent Requests
This reading covers the technical details of agent monitoring in Snowflake

## Why this matters
Agent monitoring provides the visibility you need to debug issues and improve performance. Understanding how Snowflake captures and stores trace data helps you get the most out of the monitoring interface.

## What you'll learn
The documentation covers what information gets logged in agent traces, how to access the monitoring pane in Snowsight, where trace data is stored, and the permissions required to view agent logs.

## Key concepts to understand
Snowflake automatically logs detailed traces of all agent conversations. These traces include the conversation history, the agent's planning process, tool selection and execution results, and final response generation. 
All of this data is stored in an event table called SNOWFLAKE.LOCAL.AI_OBSERVABILITY_EVENTS.

## Access requirements
To view agent monitoring data, you need OWNERSHIP or MONITOR privileges on the agent object, the CORTEX_USER database role, and the AI_OBSERVABILITY_EVENTS_LOOKUP application role. 
The documentation includes SQL commands for granting these privileges.

## Link to the documentation : https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-monitor

## How to use this resource
Pay particular attention to the access control section and verify you have the required privileges. This ensures you can follow along with the hands-on monitoring walkthrough without permission issues.
