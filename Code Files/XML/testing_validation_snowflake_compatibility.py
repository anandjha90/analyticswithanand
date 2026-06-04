# Sample CTE Output after extraction

CTE_15 AS  (
        SELECT 
           "PolM_Sub_Seg", "Expected Claims", "Expected Claims_Sub_Seg", "Incr (Decr) IBNR", "Business Unit"
           ,
           Incr (Decr) IBNR * (Expected Claims/Expected Claims_Sub_Seg) AS "Ceded IBNR by Treaty", 
           CASE WHEN  LEFT('Treaty', 3)  =  'AML'  THEN 'Assumed' ELSE CASE WHEN  LEFT('Treaty', 3)  =  'CML'  THEN 'Ceded' ELSE NULL END AS "Business_Type", 
           CASE WHEN  LEFT('Treaty', 1)  =  'C'  THEN RIGHT('Treaty', LENGTH('Treaty')-1) ELSE Treaty END AS "Treaty", 
           LEFT('Treaty', 2) AS "CO", 
           CONCAT('PolM_Sub_Seg', 'L') AS "Product", 
           "PL001" AS "BU", 
           CONCAT('Treaty', 'S') AS "TREATY3", 
           Ceded IBNR by Treaty AS "Round", 
           ABS('Round') AS "ABS"
        FROM CTE_14 
    )
## Incorrect Output 
 "Incr (Decr) IBNR""*""(Expected Claims"/Expected Claims_Sub_Seg) AS "Ceded IBNR by Treaty"

## functionfor cleaning expression paramteres
def sanitize_expression_for_filter_formula_dynamic_rename_backup(expression, field_name=None):
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
    expression = re.sub(r"\bSplit_Part\s*\(([^,]+),\s*([^,]+),\s*([^,]+)\)", r"SPLIT_PART(\1, \2, \3)", expression, flags=re.IGNORECASE)

    # Handle line breaks and extra spaces
    expression = expression.replace("\n", " ").replace("\r", " ").strip()

    # Handle [_CurrentField_] replacement dynamically
    expression = expression.replace("[_CurrentField_]", '"_CurrentField_"')

    # Convert Row-based references (Multi-Row Formula)
    expression = re.sub(r"\[Row-([0-9]+):(.+?)\]", r"LAG(\2, \1) OVER ()", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\[Row\+([0-9]+):(.+?)\]", r"LEAD(\2, \1) OVER ()", expression, flags=re.IGNORECASE)

    return expression

    # ✅ Convert Alteryx-style string concatenation (`+`) to Snowflake `CONCAT()`
    def replace_concat(match):
        first_param = match.group(1).strip()
        second_param = match.group(2).strip()

        def process_param(param):
            """Ensure the parameter is enclosed in single quotes if it's a string literal, otherwise double quotes if it's a column name."""
            # ✅ If the parameter is already in single quotes, keep it unchanged
            if param.startswith("'") and param.endswith("'"):
                return param  
            # ✅ If the parameter is in double quotes, convert it to single quotes
            elif param.startswith('"') and param.endswith('"'):
                return f"'{param[1:-1]}'"  
            # ✅ Otherwise, assume it's a column and wrap in double quotes
            else:
                return f'"{param}"'  

        first_param = process_param(first_param)
        second_param = process_param(second_param)

        return f"CONCAT({first_param}, {second_param})"

    expression = re.sub(r"(\S+)\s*\+\s*(\S+)", replace_concat, expression)

def wrap_fields_in_quotes(expression):
    """
    Ensures field names in calculations are enclosed in double quotes.
    - Keeps existing quoted fields unchanged.
    - Ignores function names and operators.
    """
    tokens = re.split(r'(\s*[\+\-\*/]\s*)', expression)  # Split by mathematical operators

    def process_token(token):
        token = token.strip()
        # ✅ If token is already quoted, return as is
        if token.startswith('"') and token.endswith('"'):
            return token  
        # ✅ If token is a numeric value, function call, or empty, return as is
        if re.match(r"^\d+(\.\d+)?$", token) or re.match(r"^[A-Za-z_]+\(", token) or token == "":
            return token  
        # ✅ Wrap unquoted field names in double quotes
        return f'"{token}"'

    # ✅ Rebuild the expression with properly quoted fields
    return ''.join([process_token(token) for token in tokens])

def sanitize_expression_for_snowflake(expression):
    """
    Converts Alteryx-style expressions into Snowflake-compatible SQL expressions.
    - Ensures field names in calculations are enclosed in double quotes.
    - Converts Alteryx IF-THEN-ELSE-ENDIF to SQL CASE-WHEN-THEN-ELSE-END.
    - Ensures both parameters in CONCAT() are enclosed in single quotes if they are literals.
    """

    if not expression:
        return ""

    # ✅ Ensure calculations have double-quoted field names
    expression = re.sub(r'([\w\s\(\)]+)\s*([\+\-\*/])\s*([\w\s\(\)]+)', 
                        lambda m: wrap_fields_in_quotes(m.group(0)), expression)

    return expression.strip()
    


