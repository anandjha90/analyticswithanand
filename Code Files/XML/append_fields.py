def generate_append_fields_cte(node, tool_id):
    """
    Generates SQL CTE for appending fields based on SelectField attributes.
    Only includes fields with selected="True".
    """
    select_fields_node = node.find('.//Configuration/SelectFields')

    if select_fields_node is None:
        return f"-- No append fields configuration found for ToolID {tool_id}"

    # Extract selected fields
    selected_fields = []
    for field in select_fields_node.findall('SelectField'):
        field_name = field.get('field')
        selected = field.get('selected')

        # Only include fields marked as selected
        if selected == "True":
            selected_fields.append(f'"{field_name}"')

    # Generate CTE query
    cte_query = f"""
    CTE_AppendFields_{tool_id} AS (
        SELECT 
            Previous_CTE.*, {', '.join(selected_fields)}
        FROM Previous_CTE_{tool_id}
    )
    """
    return cte_query
