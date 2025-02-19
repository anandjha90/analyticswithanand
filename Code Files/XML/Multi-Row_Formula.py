import xml.etree.ElementTree as ET

def generate_cte_for_MultiRowFormula(xml_data, previousToolId, toolId, prev_tool_fields):
    root = ET.fromstring(xml_data)
    
    if root is None:
        raise ValueError(f"ToolID {toolId} not found in XML.")
    
    # Extracting values from XML
    update_existing = root.find(".//UpdateField").get("value") == "True"
    existing_field = root.find(".//UpdateField_Name").text if update_existing else None
    new_field = root.find(".//CreateField_Name").text if not update_existing else None
    expression = root.find(".//Expression").text.strip()
    num_rows = root.find(".//NumRows").get("value")
    group_by_fields = [field.get("field") for field in root.findall(".//GroupByFields/Field")]

    # Cleaning up the expression
    expression = sanitize_expression_for_filter_formula(expression)

    # Generating SQL logic
    partition_clause = f"PARTITION BY {', '.join([f'\"{field}\"' for field in group_by_fields])}" if group_by_fields else ""
    lag_lead_function = expression.replace("[Row-1:", "LAG(").replace("[Row+1:", "LEAD(").replace("]", f", {num_rows}) OVER ({partition_clause} ORDER BY ROW_NUMBER() OVER())")

    # Determining selected fields
    if update_existing:
        transformations = f"{lag_lead_function} AS \"{existing_field}\""
        all_fields = prev_tool_fields  # Keeps original field structure
    else:
        transformations = f"{lag_lead_function} AS \"{new_field}\""
        all_fields = prev_tool_fields + [new_field]

    fields_selection = ', '.join([f'"{field}"' for field in all_fields])

    # Generating CTE query
    cte_query = f"""
    CTE_{toolId} AS (
        SELECT {fields_selection}
        FROM CTE_{previousToolId}
    )
    """

    return all_fields, cte_query
