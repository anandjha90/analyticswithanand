import xml.etree.ElementTree as ET
import re

def sanitize_expression_for_filter_formula(expression):
    """
    Converts Alteryx-style conditional expressions into SQL-compliant CASE statements.
    - Handles IF-THEN-ELSE-ENDIF transformations.
    - Converts NULL() to NULL.
    - Ensures proper SQL syntax.
    """

    if not expression:
        return ""

    # Convert Alteryx-style IF-THEN-ELSE-ENDIF into SQL CASE WHEN
    expression = re.sub(r"\bif\s+(.*?)\s+then", r"CASE WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\belseif\s+(.*?)\s+then", r"WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\belse", r"ELSE", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bendif", r"END", expression, flags=re.IGNORECASE)

    # Handle NULL() conversion
    expression = re.sub(r"(?i)NULL\(\)", "NULL", expression)

    # Standardize logical operators
    expression = expression.replace("=", " = ").replace("<>", " != ").replace(" And ", " AND ").replace(" Or ", " OR ")

    # Handle line breaks and extra spaces
    expression = expression.replace("\n", " ").replace("\r", " ").strip()

    return expression

def generate_cte_for_LockInFormula(xml_data, previousToolId, toolId):
    """
    Parses the Alteryx Formula node from XML, extracts all formula expressions, 
    sanitizes them, and generates an equivalent SQL CTE.
    
    - Converts Alteryx expressions to SQL CASE statements.
    - Includes previousToolId for chaining transformations.
    """

    root = ET.fromstring(xml_data)

    # Find the correct Node manually
    node = None
    for n in root.findall(".//Node"):
        if n.get("ToolID") == toolId:
            node = n
            break

    if node is None:
        raise ValueError(f"ToolID {toolId} not found in XML.")

    # Extract all FormulaField elements
    formula_fields = node.findall(".//FormulaField")

    if not formula_fields:
        raise ValueError(f"No formula fields found for ToolID {toolId}.")

    # Generate SQL expressions for each formula field
    formula_expressions = []
    for field in formula_fields:
        field_name = field.get("field")
        expression = field.get("expression")
        sanitized_expression = sanitize_expression_for_filter_formula(expression)

        formula_expressions.append(f"{sanitized_expression} AS \"{field_name}\"")

    # Ensure Previous Tool ID Exists (Formula transformations need input data)
    if not previousToolId:
        raise ValueError(f"ToolID {toolId} requires a Previous Tool ID for input data.")

    # Generate CTE dynamically
    cte_query = f"""
    -- Formula transformations applied using LockInFormula Tool
    {toolId} AS (
        SELECT 
            *,
            {',\n            '.join(formula_expressions)}
        FROM {previousToolId}
    )
    """

    return cte_query
