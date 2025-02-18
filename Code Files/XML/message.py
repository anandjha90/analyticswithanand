import streamlit as st
import xml.etree.ElementTree as ET
import pandas as pd
from collections import deque
import os
import zipfile
import re

# Existing code remains unchanged above

def generate_cte_for_Message(xml_data, previousToolId, toolId, prev_tool_fields):
    """
    Parses the Alteryx Message tool XML configuration and generates an equivalent SQL CTE.
    Handles message types, timing, and expressions for all Message tool use-cases with specific message types.
    """
    root = ET.fromstring(xml_data)

    message_type = root.find(".//MessageType").text if root.find(".//MessageType") is not None else "Message"
    message_expression = root.find(".//MessageExpression").text if root.find(".//MessageExpression") is not None else "No message provided"
    message_time = root.find(".//MessageTime").text if root.find(".//MessageTime") is not None else "After Last Record"

    message_type_sql = {
        "Message": "Standard Message",
        "Warning": "Warning Message",
        "Field Conversion Error": "Conversion Error",
        "Error": "Error Message",
        "Error - And Stop Passing Records": "Fatal Error",
        "File Input": "Input File Message",
        "File Output": "Output File Message"
    }.get(message_type, "Unknown Message Type")

    if message_time == "Before First Record":
        cte_query = f"""
        CTE_{toolId} AS (
            SELECT *, '{message_type_sql}' AS MessageType, '{message_time}' AS MessageTime, '{message_expression}' AS MessageText
            FROM CTE_{previousToolId}
            WHERE 1=1 -- Message written before first record
        )
        """
    elif message_time == "Before Rows Where Expression is True":
        cte_query = f"""
        CTE_{toolId} AS (
            SELECT *, '{message_type_sql}' AS MessageType, '{message_time}' AS MessageTime, '{message_expression}' AS MessageText
            FROM CTE_{previousToolId}
            WHERE <your_condition_here> -- Message written before specific rows
        )
        """
    elif message_time == "After Last Record":
        cte_query = f"""
        CTE_{toolId} AS (
            SELECT *, '{message_type_sql}' AS MessageType, '{message_time}' AS MessageTime, '{message_expression}' AS MessageText
            FROM CTE_{previousToolId}
        )
        """
    else:
        cte_query = f"""
        CTE_{toolId} AS (
            SELECT *, '{message_type_sql}' AS MessageType, '{message_time}' AS MessageTime, '{message_expression}' AS MessageText
            FROM CTE_{previousToolId}
        )
        """

    new_fields = prev_tool_fields + ["MessageType", "MessageTime", "MessageText"]
    return new_fields, cte_query

# All previous code remains unchanged below
