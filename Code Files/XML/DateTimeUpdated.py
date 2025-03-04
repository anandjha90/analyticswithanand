import xml.etree.ElementTree as ET
import re

# ✅ Function to Convert Alteryx DateTime Formats to Snowflake-Compatible Formats
def sanitize_datetime_format(alteryx_format, is_input=True):
    """
    Converts Alteryx DateTime format specifiers into Snowflake-compatible format.
    Handles DateTimeToString and StringToDateTime conversions.
    - On input: Standardizes equivalent separators.
    - On output: Keeps separators exactly as they are.
    - Handles 2-digit year (`yy`) mapping to correct range.
    """

    # ✅ Standardize separators (ONLY for input formats)
    if is_input:
        # Replace '-' with '/', as both are equivalent
        alteryx_format = re.sub(r"[-]", "/", alteryx_format)

        # Remove unnecessary white spaces
        alteryx_format = re.sub(r"\s+", " ", alteryx_format.strip())

    # ✅ Mapping of Alteryx format specifiers to Snowflake format specifiers
    format_mappings = {
        # ✅ Days
        "d": "D", "dd": "DD", "day": "Day", "dy": "DY", "EEEE": "Day",

        # ✅ Months
        "M": "FMMonth", "MM": "MM", "MMM": "Mon", "MMMM": "Mon", "Mon": "Mon", "Month": "Month",

        # ✅ Years
        "yy": "YY",  # 2-digit year (Handled separately)
        "yyyy": "YYYY",

        # ✅ Hours (12-hour & 24-hour)
        "H": "FMHH24", "HH": "HH24", "hh": "HH12", "ahh": "AM",

        # ✅ Minutes & Seconds
        "mm": "MI", "ss": "SS",

        # ✅ Subseconds / Precision
        "ffff": "FF"
    }

    # ✅ Replace Alteryx format specifiers with Snowflake equivalents
    for alteryx_fmt, sql_fmt in format_mappings.items():
        alteryx_format = alteryx_format.replace(alteryx_fmt, sql_fmt)

    # ✅ Handle Custom Wildcard Case (*)
    alteryx_format = alteryx_format.replace("*", "")

    return alteryx_format

def generate_cte_for_DateTime(xml_data, previousToolId, toolId, prev_tool_fields):
    """
    Parses the Alteryx DateTime Tool XML configuration and generates an equivalent SQL CTE.
    Handles:
      - DateTime to String conversion (TO_CHAR)
      - String to DateTime conversion (TO_DATE)
      - Custom DateTime formats
      - Language-based formatting
      - Extracts attributes in a specific order
    """
    root = ET.fromstring(xml_data)

    # ✅ Extract attributes in the required order
    config_node = root.find(".//Configuration")
    if config_node is None:
        raise ValueError("Missing 'Configuration' element in XML configuration.")

    isFrom = config_node.find(".//IsFrom")
    isFrom = isFrom.get("value").strip().lower() == "true" if isFrom is not None else False  # Default: False

    input_field_node = config_node.find(".//InputFieldName")
    input_field = input_field_node.text.strip() if input_field_node is not None else None

    language_node = config_node.find(".//Language")
    language = language_node.text.strip() if language_node is not None else None  # Not used for Snowflake

    format_node = config_node.find(".//Format")
    datetime_format = format_node.text.strip() if format_node is not None else None

    output_field_node = config_node.find(".//OutputFieldName")
    output_field = output_field_node.text.strip() if output_field_node is not None else "DateTime_Out"

    # ✅ Validation Checks
    if not input_field or not datetime_format:
        raise ValueError("Missing required fields: 'InputFieldName' or 'Format'.")

    # ✅ Convert Alteryx datetime format to Snowflake format
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
