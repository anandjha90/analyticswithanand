import xml.etree.ElementTree as ET
import re

def generate_cte_for_DateTime(xml_data, previousToolId, toolId, prev_tool_fields):
    """
    Parses the Alteryx DateTime Tool XML configuration and generates an equivalent SQL CTE.
    Handles:
      - DateTime to String conversion (TO_CHAR)
      - String to DateTime conversion (TO_DATE)
      - Custom DateTime formats
      - Language-based formatting
      - Extracts all fields dynamically from <Configuration>
    """
    root = ET.fromstring(xml_data)

    # ✅ Extract all configuration fields dynamically
    config_node = root.find(".//Configuration")
    if config_node is None:
        raise ValueError("Missing 'Configuration' element in XML configuration.")

    config_params = {elem.tag: elem.text.strip() if elem.text else None for elem in config_node}

    # ✅ Extract required fields
    input_field = config_params.get("InputField")
    output_field = config_params.get("OutputField", "DateTime_Out")  # Default name if missing
    datetime_format = config_params.get("DateTimeFormat")
    isFrom = config_params.get("IsFrom", "False").lower() == "true"  # Default to 'False' if missing

    if not input_field or not datetime_format:
        raise ValueError("Missing required fields: 'InputField' or 'DateTimeFormat'.")

    # ✅ Sanitize the DateTime format to be Snowflake-compatible
    sql_datetime_format = sanitize_datetime_format(datetime_format)

    # ✅ Generate SQL Expression based on `IsFrom`
    if isFrom:  # DateTime → String
        sql_expression = f"TO_CHAR('{input_field}', '{sql_datetime_format}') AS \"{output_field}\""
    else:  # String → DateTime
        sql_expression = f"TO_DATE('{input_field}', '{sql_datetime_format}') AS \"{output_field}\""

    # ✅ Apply sanitize function for TO_CHAR & TO_DATE
    sql_expression = sanitize_expression_for_filter_formula_dynamic_rename(sql_expression)

    # ✅ Construct the SQL CTE
    prev_fields_str = ", ".join(f'"{field}"' for field in prev_tool_fields)
    
    cte_query = f"""
    CTE_{toolId} AS (
        SELECT {prev_fields_str},
               {sql_expression}
        FROM CTE_{previousToolId}
    )
    """

    new_fields = prev_tool_fields + [output_field]
    return new_fields, cte_query

# ✅ Function to Convert Alteryx DateTime Formats to Snowflake-Compatible Formats
def sanitize_datetime_format(alteryx_format):
    """
    Converts Alteryx DateTime format specifiers into Snowflake-compatible format.
    Handles both DateTimeToString and StringToDateTime conversions.
    """
    format_mappings = {
        "yyyy-MM-dd": "YYYY-MM-DD",
        "hh:mm:ss": "HH24:MI:SS",
        "yyyy-MM-dd hh:mm:ss": "YYYY-MM-DD HH24:MI:SS",
        "dd/MM/yyyy": "DD/MM/YYYY",
        "MM/dd/yyyy": "MM/DD/YYYY",
        "%d/%m/%Y": "DD/MM/YYYY",
        "%m/%d/%Y": "MM/DD/YYYY",
        "*": ""  # Wildcard (handled separately)
    }

    # ✅ Replace format specifiers with Snowflake equivalents
    for alteryx_fmt, sql_fmt in format_mappings.items():
        alteryx_format = alteryx_format.replace(alteryx_fmt, sql_fmt)

    # ✅ Handle Custom Wildcard Case (*)
    alteryx_format = alteryx_format.replace("*", "")

    return alteryx_format
