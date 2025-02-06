import re

def sanitize_expression(expression):
    """
    Converts Alteryx-style conditional expressions into SQL-compliant CASE statements.
    Handles NULL() to NULL and other transformations.
    """
    # Replace Alteryx "If-ElseIf-Endif" with SQL "CASE-WHEN"
    expression = re.sub(r"If (.*?) Then", r"CASE WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"ElseIf (.*?) Then", r"WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"Else", r"ELSE", expression, flags=re.IGNORECASE)
    expression = re.sub(r"Endif", r"END", expression, flags=re.IGNORECASE)
    
    # Handle NULL() conversion
    expression = re.sub(r"(?i)NULL\(\)", "NULL", expression)
    
    # Handle quotes (Alteryx &quot;)
    expression = expression.replace("&quot;", "'")

    return expression

def generate_formula_cte(node, tool_id):
    # Locate the FormulaFields section
    formula_fields_node = node.find('.//Configuration/FormulaFields')
    
    if formula_fields_node is None:
        return f"-- No formula configuration found for ToolID {tool_id}"

    formula_expressions = []

    # Extract each formula field and generate SQL expressions
    for field in formula_fields_node.findall('FormulaField'):
        field_name = field.get('field')
        expression = field.get('expression')

        # Clean up the expression to match SQL syntax
        sql_expression = sanitize_expression(expression)

        formula_expressions.append(f"{sql_expression} AS \"{field_name}\"")

    # Create the CTE query
    cte_query = f"""
    CTE_Formula_{tool_id} AS (
        SELECT 
            {', '.join(formula_expressions)}
        FROM Previous_CTE_{tool_id}
    )
    """
    return cte_query
