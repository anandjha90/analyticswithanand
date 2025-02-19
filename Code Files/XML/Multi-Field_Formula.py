def generate_cte_for_MultiFieldFormula(xml_data, previousToolId, toolId, prev_tool_fields):
    root = ET.fromstring(xml_data)
    
    if root is None:
        raise ValueError(f"ToolID {toolId} not found in XML.")
    
    fields = [field.get("name") for field in root.findall(".//Fields/Field") if field.get("name") != "*Unknown"]
    expression = root.find(".//Expression").text
    expression = sanitize_expression_for_filter_formula(expression)
    copy_output = root.find(".//CopyOutput").get("value") == "True"
    new_field_prefix = root.find(".//NewFieldAddOn")
    new_field_prefix = new_field_prefix.text if new_field_prefix is not None else ""
    new_field_position = root.find(".//NewFieldAddOnPos")
    new_field_position = new_field_position.text if new_field_position is not None else "Suffix"

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
