import xml.etree.ElementTree as ET

def generate_cte_for_LockInFilter(xml_data, previousToolId, toolId):
    """
    Parses the Alteryx LockInFilter node from XML, extracts the filter condition,
    and generates an equivalent SQL CTE using ToolID.
    
    - Only processes when Mode is "Custom".
    - If `previousToolId` exists, it will be included in the generated query.
    - If no `previousToolId`, it raises an error as a filter must have an input.
    """
    root = ET.fromstring(xml_data)

    # Find the correct Node manually
    node = None
    for n in root.findall(".//Node"):
        if n.get("ToolID") == toolId:
            node = n
            break

    if node is None:
        raise ValueError(f"ToolID {toolId} not found in XML.")

    # Extract Mode (Only process if Mode = "Custom")
    mode_element = node.find(".//Mode")
    mode = mode_element.text.strip() if mode_element is not None else "Unknown"

    if mode != "Custom":
        return f"-- ToolID {toolId} is using Mode '{mode}', skipping filter extraction."

    # Extract Filter Expression
    expression_element = node.find(".//Expression")
    filter_expression = expression_element.text.strip() if expression_element is not None else ""

    if not filter_expression:
        raise ValueError(f"No filter expression found for ToolID {toolId}.")

    # Ensure Previous Tool ID Exists (Filters need input data)
    if not previousToolId:
        raise ValueError(f"ToolID {toolId} requires a Previous Tool ID to filter data.")

    # Generate CTE dynamically
    cte_query = f"""
    -- Filter applied using LockInFilter Tool (Mode: {mode})
    {toolId} AS (
        SELECT * 
        FROM {previousToolId}
        WHERE {filter_expression}
    )
    """

    return cte_query
