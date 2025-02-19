import xml.etree.ElementTree as ET

def generate_cte_for_MultiFieldFormula(xml_data, previousToolId, toolId, prev_tool_fields):
    """
    Parses Alteryx Multi-Field Formula node from XML, extracts formula transformations dynamically,
    and generates an equivalent SQL CTE.

    - Extracts selected fields from XML.
    - Replaces [_CurrentField_] with actual field names.
    - Applies prefix/suffix if enabled.
    - Includes previousToolId for chaining transformations.
    """

    root = ET.fromstring(xml_data)

    # Find the correct node
    node = None
    for n in root.findall(".//Node"):
        if n.get("ToolID") == toolId:
            node = n
            break

    if node is None:
        raise ValueError(f"ToolID {toolId} not found in XML.")

    # Extract selected fields
    fields = [field.get("name") for field in node.findall(".//Fields/Field") if field.get("name") != "*Unknown"]

    # Extract expression and transform it
    expression_node = node.find(".//Expression")
    expression = expression_node.text if expression_node is not None else ""

    # Extract prefix/suffix settings
    new_field_prefix = node.find(".//NewFieldAddOn")
    new_field_prefix = new_field_prefix.text if new_field_prefix is not None else ""

    new_field_position = node.find(".//NewFieldAddOnPos")
    new_field_position = new_field_position.text if new_field_position is not None else "Suffix"

    # Determine if original fields should be kept
    copy_output = node.find(".//CopyOutput")
    copy_output = copy_output is not None and copy_output.get("value") == "True"

    # Generate transformed field names
    if new_field_position == "Prefix":
        transformed_fields = [f'{new_field_prefix}{field}' for field in fields]
    else:
        transformed_fields = [f'{field}{new_field_prefix}' for field in fields]

    # Apply formula to each selected field
    transformations = [
        f"{expression.replace('[_CurrentField_]', f'\"{field}\"')} AS \"{new_field}\""
        for field, new_field in zip(fields, transformed_fields)
    ]

    # Determine final field selection
    if copy_output:
        all_fields = prev_tool_fields + transformed_fields
    else:
        all_fields = transformed_fields

    fields_selection = ', '.join([f'"{field}"' for field in all_fields])

    # Generate SQL CTE
    cte_query = f"""
    -- Multi-Field Formula transformations applied
    CTE_{toolId} AS (
        SELECT {fields_selection}
        FROM CTE_{previousToolId}
    )
    """

    return all_fields, cte_query
