## functionfor cleaning expression paramteres
def sanitize_expression_for_filter_formula_dynamic_rename(expression, field_name=None):
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
    expression = re.sub(r"CONTAINS\(\s*['\"]([^'\"]+)['\"]\s*\)", rf"CONTAINS(\"{field_name}\", '\1')", expression,
                        flags=re.IGNORECASE)
    
    # Remove square brackets [] from field names
    expression = re.sub(r"\[(.*?)\]", r"\1", expression)

    # Convert Alteryx-style string concatenation (`+`) to Snowflake `CONCAT()`
    expression = re.sub(r"(\S+)\s*\+\s*(\S+)", r"CONCAT('\1', \2)", expression) # Handles general cases

    # Convert Alteryx-style IF-THEN-ELSE-ENDIF into SQL CASE WHEN
    expression = re.sub(r"(?i)if(.*?)then", r" CASE WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"(?i)elseif(.*?)then", r"WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"(?i)else", r"ELSE", expression, flags=re.IGNORECASE)
    expression = re.sub(r"(?i)endif", r"END", expression, flags=re.IGNORECASE)

    expression = re.sub(r"\bif\s+(.*?)\s+then", r" CASE WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\belseif\s+(.*?)\s+then", r"WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\belse", r"ELSE", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bendif", r"END", expression, flags=re.IGNORECASE)

    # Handle NULL() conversion
    expression = re.sub(r"(?i)NULL\(\)", "NULL", expression)

    # ✅ Ensure string literals in comparisons (`=`, `<>`, `IN`, `LIKE`) use single quotes
    expression = re.sub(r'=\s*"([^"]+)"', r"= '\1'", expression)
    expression = re.sub(r'<>\s*"([^"]+)"', r"<> '\1'", expression)
    expression = re.sub(r'IN\s*\(\s*"([^"]+)"\s*\)', r"IN ('\1')", expression, flags=re.IGNORECASE)
    expression = re.sub(r'LIKE\s*"([^"]+)"', r"LIKE '\1'", expression, flags=re.IGNORECASE)

    # Standardize logical operators
    expression = expression.replace("=", " = ").replace("<>", " != ").replace(" And ", " AND ").replace(" Or ", " OR ")

    # Ensure function names are formatted correctly (e.g., SUBSTRING, UPPER, LOWER, LEFT, RIGHT, LENGTH)
    expression = re.sub(r"\bSubstring\s*\(([^,]+),\s*([^,]+),\s*([^)]+)\)", r"SUBSTRING('\1', \2, \3)", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bUpper\s*\((.*?)\)", r"UPPER('\1')", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bLower\s*\((.*?)\)", r"LOWER('\1')", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bLeft\s*\(([^,]+),\s*([^,]+)\)", r"LEFT('\1', \2)", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bRight\s*\(([^,]+),\s*([^,]+)\)", r"RIGHT('\1', \2)", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bLength\s*\((.*?)\)", r"LENGTH('\1')", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bAbs\s*\((.*?)\)", r"ABS('\1')", expression, flags=re.IGNORECASE)

    # Handle line breaks and extra spaces
    expression = expression.replace("\n", " ").replace("\r", " ").strip()

    # Handle [_CurrentField_] replacement dynamically
    expression = expression.replace("[_CurrentField_]", '"_CurrentField_"')

    # Convert Row-based references (Multi-Row Formula)
    expression = re.sub(r"\[Row-([0-9]+):(.+?)\]", r"LAG(\2, \1) OVER ()", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\[Row\+([0-9]+):(.+?)\]", r"LEAD(\2, \1) OVER ()", expression, flags=re.IGNORECASE)

    return expression
