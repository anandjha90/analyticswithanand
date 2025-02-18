def generate_cte_for_Message(xml_data, previousToolId, toolId, prev_tool_fields):
    """
    Parses the Alteryx Message tool XML configuration and generates an equivalent SQL CTE.
    Handles all Message tool use-cases based on the provided XML file.
    """
    root = ET.fromstring(xml_data)
    node = root.find(f".//Node[@ToolID='{toolId}']")
    
    if node is None:
        raise ValueError(f"ToolID {toolId} not found in XML.")

    message_time = node.find(".//When").text
    message_type = node.find(".//Type").text
    message_expression = node.find(".//MessageExpression").text

    # Map message types to SQL output
    message_type_sql = {
        "Message": "Standard Message",
        "Warning": "Warning Message",
        "Field Conversion Error": "Conversion Error",
        "Error": "Error Message",
        "Error - And Stop Passing Records": "Fatal Error",
        "File Input": "Input File Message",
        "File Output": "Output File Message"
    }.get(message_type, "Unknown Message Type")

    if message_time == "First":
        cte_query = f"""
        CTE_{toolId} AS (SELECT *, '{message_type_sql}' AS MessageType, '{message_time}' AS MessageTime, '{message_expression}' AS MessageText FROM CTE_{previousToolId})
        """
    elif message_time == "Filter":
        filter_condition = node.find(".//Filter").text
        cte_query = f"""
        CTE_{toolId} AS (SELECT *, '{message_type_sql}' AS MessageType, '{message_time}' AS MessageTime, '{message_expression}' AS MessageText FROM CTE_{previousToolId} WHERE {filter_condition})
        """
    elif message_time == "Last":
        cte_query = f"""
        CTE_{toolId} AS (SELECT *, '{message_type_sql}' AS MessageType, '{message_time}' AS MessageTime, '{message_expression}' AS MessageText FROM CTE_{previousToolId})
        """
    elif message_time == "All":
        cte_query = f"""
        CTE_{toolId} AS (SELECT *, '{message_type_sql}' AS MessageType, '{message_time}' AS MessageTime, '{message_expression}' AS MessageText FROM CTE_{previousToolId})
        """
    else:
        cte_query = f"-- Unsupported message time for ToolID {toolId}"

    new_fields = prev_tool_fields + ["MessageType", "MessageTime", "MessageText"]
    return new_fields, cte_query
