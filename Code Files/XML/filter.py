def generate_filter_cte(node, tool_id):
    """
    Generates SQL CTE for filter expressions found in the configuration.
    Sanitizes filter expressions for SQL compliance.
    """
    # Locate the Filter Configuration node
    expression_node = node.find('.//Configuration/Expression')
    
    if expression_node is None:
        return f"-- No filter configuration found for ToolID {tool_id}"

    # Sanitize and clean the filter expression
    filter_expression = sanitize_expression(expression_node.text.strip()) if expression_node.text else "1=1"

    cte_query = f"""
    CTE_Filter_{tool_id} AS (
        SELECT *
        FROM Previous_CTE_{tool_id}
        WHERE {filter_expression}
    )
    """
    return cte_query
