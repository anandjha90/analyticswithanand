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
      - Uses IsFrom = 'True' for DateTimeToString and 'False' for StringToDateTime
    """
    root = ET.fromstring(xml_data)

    # ✅ Identify the Mode (DateTime to String OR String to DateTime)
    conversion_type_node = root.find(".//DateTimeMode")
    if conversion_type_node is None:
        raise ValueError("Missing 'DateTimeMode' element in XML configuration.")
    
    conversion_type = conversion_type_node.text.strip()  # "DateTimeToString" or "StringToDateTime"

    # ✅ Identify the Field to Convert
    input_field_node = root.find(".//InputField")
    if input_field_node is None or not input_field_node.text:
        raise ValueError("Missing 'InputField' element in XML configuration.")
    
    input_field = input_field_node.text.strip()

    # ✅ Identify the Output Field Name
    output_field_node = root.find(".//OutputField")
    output_field = output_field_node.text.strip() if output_field_node is not None and output_field_node.text else "DateTime_Out"

    # ✅ Identify DateTime Format
    format_node = root.find(".//DateTimeFormat")
    if format_node is None or not format_node.text:
        raise ValueError("Missing 'DateTimeFormat' element in XML configuration.")
    
    datetime_format = format_node.text.strip()

    # ✅ Sanitize the Format (Convert Alteryx format specifiers to SQL-compatible format)
    sql_datetime_format = sanitize_datetime_format(datetime_format)

    # ✅ Determine `IsFrom` Field (Boolean Conversion)
    isFrom = "True" if conversion_type == "DateTimeToString" else "False"

    # ✅ Generate SQL Expression with proper sanitization
    if conversion_type == "DateTimeToString":
        sql_expression = f"TO_CHAR('{input_field}', '{sql_datetime_format}') AS \"{output_field}\""
    elif conversion_type == "StringToDateTime":
        sql_expression = f"TO_DATE('{input_field}', '{sql_datetime_format}') AS \"{output_field}\""
    else:
        raise ValueError(f"Invalid DateTimeMode: {conversion_type}")

    # ✅ Apply sanitize_expression_for_filter_formula_dynamic_rename
    sql_expression = sanitize_expression_for_filter_formula_dynamic_rename(sql_expression)

    # ✅ Construct the SQL CTE
    prev_fields_str = ", ".join(f'"{field}"' for field in prev_tool_fields)
    
    cte_query = f"""
    CTE_{toolId} AS (
        SELECT {prev_fields_str},
               {sql_expression},
               '{isFrom}' AS "IsFrom"
        FROM CTE_{previousToolId}
    )
    """

    new_fields = prev_tool_fields + [output_field, "IsFrom"]
    return new_fields, cte_query

# ✅ Function to Convert Alteryx DateTime Formats to SQL-Compatible Formats
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
