def generate_cte_for_MultiFieldFormula(xml_data, previousToolId, toolId, prev_tool_fields):
    """
    Parses the Alteryx Multi-Field Formula tool XML configuration and generates an equivalent SQL CTE.
    Handles multiple fields, transformations, and new field name configurations.
    """
    root = ET.fromstring(xml_data)
    node = root.find(f".//Node[@ToolID='{toolId}']")
    
    if node is None:
        raise ValueError(f"ToolID {toolId} not found in XML.")
    
    fields = [field.get("name") for field in node.findall(".//Fields/Field") if field.get("name") != "*Unknown"]
    expression = node.find(".//Expression").text
    copy_output = node.find(".//CopyOutput").get("value") == "True"
    new_field_prefix = node.find(".//NewFieldAddOn").text or ""
    new_field_position = node.find(".//NewFieldAddOnPos").text or "Suffix"

    if new_field_position == "Prefix":
        transformed_fields = [f'{new_field_prefix}{field}' for field in fields]
    else:
        transformed_fields = [f'{field}{new_field_prefix}' for field in fields]
    
    transformations = [f"{expression.replace('[_CurrentField_]', f'"{field}"')} AS \"{new_field}\"" for field, new_field in zip(fields, transformed_fields)]

    fields_selection = ', '.join([f'"{field}"' for field in prev_tool_fields]) if copy_output else ', '.join([f'"{field}"' for field in fields])
    
    cte_query = f"""
    CTE_{toolId} AS (
        SELECT {fields_selection}, {', '.join(transformations)}
        FROM CTE_{previousToolId}
    )
    """
    
    new_fields = prev_tool_fields + transformed_fields if copy_output else transformed_fields
    return new_fields, cte_query
