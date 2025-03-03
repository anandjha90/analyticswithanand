import xml.etree.ElementTree as ET

# Mapping Alteryx formats to Snowflake formats
DATE_FORMAT_MAPPING = {
    "Month dd, yyyy": "Month DD, YYYY",
    "yyyy-MM-dd": "YYYY-MM-DD",
    "HH:mm:ss": "HH24:MI:SS",
    "yyyy-MM-dd hh:mm:ss": "YYYY-MM-DD HH24:MI:SS",
    "day, dd Month, yyyy": "Day, DD Month, YYYY",
    "MM-dd/yyyy": "MM-DD-YYYY"
}

def generate_cte_for_DateTime(xml_data, previousToolId, toolId, prev_tool_fields):
    """
    Parses the Alteryx DateTime tool XML configuration and generates an equivalent Snowflake SQL CTE.
    Handles conversions from Date/Time to String and vice versa.
    """
    root = ET.fromstring(xml_data)
    node = root.find(f".//Node[@ToolID='{toolId}']")
    
    if node is None:
        raise ValueError(f"ToolID {toolId} not found in XML.")
    
    config = node.find(".//Configuration")
    is_from = config.find(".//IsFrom").get("value") == "True"
    input_field = config.find(".//InputFieldName").text
    output_field = config.find(".//OutputFieldName").text
    format_string = config.find(".//Format").text

    # Convert Alteryx format to Snowflake format
    snowflake_format = DATE_FORMAT_MAPPING.get(format_string, format_string)

    # Generate the transformation logic
    if is_from:
        transformation = f"TO_CHAR(\"{input_field}\", '{snowflake_format}') AS \"{output_field}\""
    else:
        transformation = f"TO_DATE(\"{input_field}\", '{snowflake_format}') AS \"{output_field}\""

    # Generate CTE SQL query
    prev_fields_str = ", ".join(f'"{field}"' for field in prev_tool_fields)
    cte_query = f"""
    CTE_{toolId} AS (
        SELECT {prev_fields_str}, {transformation}
        FROM CTE_{previousToolId}
    )
    """

    # Update the field list
    new_fields = prev_tool_fields + [output_field]

    return new_fields, cte_query
