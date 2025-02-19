def sanitize_expression_for_filter_formula_dynamic_rename(expression):
    """
    Converts Alteryx-style conditional expressions into SQL-compliant CASE statements.
    Handles:
    - IF-THEN-ELSE-ENDIF to CASE-WHEN-THEN-ELSE-END.
    - NULL() to NULL.
    - [_CurrentField_] replacement for Multi-Field Formula.
    - Row-based references ([Row-1:Field]) to LAG/LEAD for Multi-Row Formula.
    """

    if not expression:
        return ""

    # Replace [_CurrentField_] with actual field name if provided
    if field_name:
        expression = expression.replace("[_CurrentField_]", f"\"{field_name}\"")

    # Ensure CONTAINS function has the field name as the first argument
      expression = re.sub(r"CONTAINS\(\s*['\"]([^'\"]+)['\"]\s*\)", rf"CONTAINS(\"{field_name}\", '\1')", expression, flags=re.IGNORECASE)

    # Convert Alteryx-style IF-THEN-ELSE-ENDIF into SQL CASE WHEN
    expression = re.sub(r"(?i)if(.*?)then", r"CASE WHEN \1 THEN", expression,flags=re.IGNORECASE)
    expression = re.sub(r"(?i)elseif(.*?)then", r"WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"(?i)else", r"ELSE", expression,flags=re.IGNORECASE)
    expression = re.sub(r"(?i)endif", r"END", expression,flags=re.IGNORECASE)

    expression = re.sub(r"\bif\s+(.*?)\s+then", r"CASE WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\belseif\s+(.*?)\s+then", r"WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\belse", r"ELSE", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bendif", r"END", expression, flags=re.IGNORECASE)

    # Handle NULL() conversion
    expression = re.sub(r"(?i)NULL\(\)", "NULL", expression)

    # Standardize logical operators
    expression = expression.replace("=", " = ").replace("<>", " != ").replace(" And ", " AND ").replace(" Or ", " OR ")

    # Handle [_CurrentField_] replacement dynamically
    expression = expression.replace("[_CurrentField_]", '"_CurrentField_"')

    # Convert Row-based references (Multi-Row Formula)
    expression = re.sub(r"\[Row-([0-9]+):(.+?)\]", r"LAG(\2, \1) OVER ()", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\[Row\+([0-9]+):(.+?)\]", r"LEAD(\2, \1) OVER ()", expression, flags=re.IGNORECASE)

    # Handle line breaks and extra spaces
    expression = expression.replace("\n", " ").replace("\r", " ").strip()

    return expression
