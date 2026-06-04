import xml.etree.ElementTree as ET

def generate_cte_for_LockInInput(xml_data, previousToolId, toolId):
    """
    Parses the Alteryx LockInInput node from XML, extracts the SQL source query and connection info,
    and generates an equivalent CTE using ToolID.
    
    - If `previousToolId` exists, it will be included in the generated query.
    - If no `previousToolId`, it will be set to `None`.
    """
    root = ET.fromstring(xml_data)

    # Find the node with the given ToolID
    node = root.find(f".//Node[@ToolID='{toolId}']")

    if node is None:
        raise ValueError(f"ToolID {toolId} not found in XML.")

    # Extract SQL Query
    query_element = node.find(".//Query")
    sql_query = query_element.text.strip() if query_element is not None else ""

    if not sql_query:
        raise ValueError("No SQL query found in the LockInInput configuration.")

    # Extract Connection Info
    connection_element = node.find(".//Connection")
    connection_name = connection_element.text.strip() if connection_element is not None else "Unknown_Connection"

    # If there is no previous tool, indicate it as None
    previous_tool_comment = f"-- Previous Tool ID: {previousToolId}" if previousToolId else "-- No Previous Tool ID"

    # Generate the CTE dynamically with connection info and previous tool ID
    cte_query = f"""
    -- Connection: {connection_name}
    {previous_tool_comment}
    {toolId} AS (
        {sql_query}
    )
    """

    return cte_query
