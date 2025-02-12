import xml.etree.ElementTree as ET

def generate_cte_for_LockInInput(xml_data, toolId):
    """
    Parses the Alteryx LockInInput node from XML, extracts the SQL source query and connection info,
    and generates an equivalent CTE using ToolID.
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

    # Generate the CTE dynamically with connection info
    cte_query = f"""
    -- Connection: {connection_name}
    {toolId} AS (
        {sql_query}
    )
    """

    return cte_query
