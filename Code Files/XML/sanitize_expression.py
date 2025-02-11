import re

def sanitize_expression_for_filter_formula(expression, field_name=None):
    """
    Converts Alteryx-style conditional expressions into SQL-compliant CASE statements.
    - Handles IF-THEN-ELSE-ENDIF transformations.
    - Converts NULL() to NULL.
    - Ensures CONTAINS function has the correct field reference.
    """

    if not expression:
        return ""

    # Replace [_CurrentField_] with actual field name if provided
    if field_name:
        expression = expression.replace("[_CurrentField_]", f"\"{field_name}\"")

    # Ensure CONTAINS function has the field name as the first argument
    expression = re.sub(r"CONTAINS\(\s*['\"]([^'\"]+)['\"]\s*\)", 
                        rf"CONTAINS(\"{field_name}\", '\1')", 
                        expression, flags=re.IGNORECASE)

    # Convert Alteryx-style IF-THEN-ELSE-ENDIF into SQL CASE WHEN
    expression = re.sub(r"If\s+(.*?)\s+Then", r"CASE WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"ElseIf\s+(.*?)\s+Then", r"WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"Else", r"ELSE", expression, flags=re.IGNORECASE)
    expression = re.sub(r"Endif", r"END", expression, flags=re.IGNORECASE)

    # Handle NULL() conversion
    expression = re.sub(r"(?i)NULL\(\)", "NULL", expression)

    # Standardize logical operators
    expression = expression.replace("=", " = ").replace("<>", " != ").replace(" And ", " AND ").replace(" Or ", " OR ")

    # Handle quotes (Alteryx &quot;)
    expression = expression.replace("&quot;", "'")

    # Fix potential SQL syntax issues (strip extra whitespace)
    return expression.strip()
