import xml.etree.ElementTree as ET

def generate_cte_for_CrossTab(xml_data, previousToolId, toolId):
    """
    Parses the XML for CrossTab transformation and generates a SQL CTE dynamically.
    Implements manual pivoting using CASE WHEN instead of PIVOT.
    """
    root = ET.fromstring(xml_data)

    # Extract group-by fields
    group_by_fields = [field.get("field") for field in root.findall(".//GroupFields/Field")]

    # Extract header field (column pivot)
    header_field = root.find(".//HeaderField").get("field")

    # Extract data field (values to be aggregated)
    data_field = root.find(".//DataField").get("field")

    # Extract aggregation method (e.g., Sum, Count, Max)
    aggregation_method = root.find(".//Methods/Method").get("method").upper()

    # Extract unique values for the header field (dynamic column names)
    unique_values = [field.get("name") for field in root.findall(".//RecordInfo/Field") 
                     if field.get("source").startswith("CrossTab:Header")]

    # Generate CASE WHEN conditions for each unique value
    case_statements = [
        f"{aggregation_method}(CASE WHEN \"{header_field}\" = '{val}' THEN \"{data_field}\" ELSE NULL END) AS \"{val}\""
        for val in unique_values
    ]

    # Generate SQL CTE dynamically
    cte_query = f"""
    {toolId} AS (
        SELECT 
            {', '.join(f'"{field}"' for field in group_by_fields)}, 
            {', '.join(case_statements)}
        FROM {previousToolId}
        GROUP BY {', '.join(f'"{field}"' for field in group_by_fields)}
    )
    """

    return cte_query
