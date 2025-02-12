import xml.etree.ElementTree as ET

def generate_cte_for_DataCleansing(xml_data, previousToolId, toolId):
    """
    Parses the Alteryx Data Cleansing node from XML, extracts cleansing operations only if they are active (True),
    and generates an equivalent SQL CTE using ToolID.
    
    - Extracts selected fields only if transformations are enabled.
    - Handles cleansing operations like replacing nulls, trimming spaces, case conversion, etc.
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

    # Extract selected fields for cleansing (only if enabled)
    fields_element = node.find(".//Value[@name='List Box (11)']")
    selected_fields = [f.strip('"') for f in fields_element.text.split(",")] if fields_element is not None and fields_element.text else []

    # Extract checkboxes only if their value is "True"
    replace_with_blank = node.find(".//Value[@name='Check Box (84)']")
    replace_with_zero = node.find(".//Value[@name='Check Box (117)']")
    trim_whitespace = node.find(".//Value[@name='Check Box (15)']")
    remove_letters = node.find(".//Value[@name='Check Box (53)']")
    remove_numbers = node.find(".//Value[@name='Check Box (58)']")
    remove_punctuation = node.find(".//Value[@name='Check Box (70)']")
    modify_case = node.find(".//Value[@name='Check Box (77)']")
    case_type = node.find(".//Value[@name='Drop Down (81)']")

    # SQL transformation rules
    sql_transformations = []

    for field in selected_fields:
        transformations = []
        
        if replace_with_blank is not None and replace_with_blank.text == "True":
            transformations.append(f"NULLIF({field}, '') AS {field}")

        if replace_with_zero is not None and replace_with_zero.text == "True":
            transformations.append(f"COALESCE({field}, 0) AS {field}")

        if trim_whitespace is not None and trim_whitespace.text == "True":
            transformations.append(f"TRIM({field}) AS {field}")

        if remove_letters is not None and remove_letters.text == "True":
            transformations.append(f"REGEXP_REPLACE({field}, '[A-Za-z]', '') AS {field}")

        if remove_numbers is not None and remove_numbers.text == "True":
            transformations.append(f"REGEXP_REPLACE({field}, '[0-9]', '') AS {field}")

        if remove_punctuation is not None and remove_punctuation.text == "True":
            transformations.append(f"REGEXP_REPLACE({field}, '[[:punct:]]', '') AS {field}")

        if modify_case is not None and modify_case.text == "True":
            if case_type is not None and case_type.text == "upper":
                transformations.append(f"UPPER({field}) AS {field}")
            elif case_type is not None and case_type.text == "lower":
                transformations.append(f"LOWER({field}) AS {field}")
            elif case_type is not None and case_type.text == "title":
                transformations.append(f"INITCAP({field}) AS {field}")

        # Only add transformations if at least one transformation is applied
        if transformations:
            sql_transformations.extend(transformations)

    # Ensure Previous Tool ID Exists (Data cleansing needs input data)
    if not previousToolId:
        raise ValueError(f"ToolID {toolId} requires a Previous Tool ID for input data.")

    # Generate CTE dynamically
    if sql_transformations:
        cte_query = f"""
        -- Data Cleansing transformations applied using Cleanse Tool
        {toolId} AS (
            SELECT 
                *,
                {',\n                '.join(sql_transformations)}
            FROM {previousToolId}
        )
        """
    else:
        cte_query = f"""
        -- No active data cleansing transformations for ToolID {toolId}
        {toolId} AS (
            SELECT * FROM {previousToolId}
        )
        """

    return cte_query
