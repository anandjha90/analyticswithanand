import xml.etree.ElementTree as ET

def generate_cte_for_Tile(xml_data, previousToolId, toolId, prev_tool_fields):
    """
    Parses the Alteryx Tile Tool XML configuration and generates an equivalent SQL CTE.
    Supports the following Tile Methods:
      - Equal Records
      - Equal Sum
      - Smart Tile
      - Unique Value
      - Manual Cutoffs
    """
    root = ET.fromstring(xml_data)
    node = root.find(f".//Node[@ToolID='{toolId}']")
    
    if node is None:
        raise ValueError(f"ToolID {toolId} not found in XML.")

    config = node.find(".//Configuration")
    if config is None:
        raise ValueError("Missing 'Configuration' section in XML.")

    tile_method = config.find("Method").text.strip() if config.find("Method") is not None else None
    group_fields_node = config.find("GroupFields")

    # Extract grouping fields and order change flag
    group_fields = [field.get("name") for field in group_fields_node.findall("Field")] if group_fields_node is not None else []
    order_changed = group_fields_node.get("orderChanged") if group_fields_node is not None else "False"

    # Default tile SQL column
    tile_column = f"Tile_{toolId}"

    # Handle different Tile Methods
    if tile_method == "EqualRecords":
        num_tiles = config.find(".//EqualRecords/NumTiles").get("value")
        equal_records_group_field = config.find(".//EqualRecords/EqualRecordsGroupField")
        group_by_clause = f'GROUP BY "{equal_records_group_field.text}"' if equal_records_group_field is not None else ''
        sql_expression = f"NTILE({num_tiles}) OVER (ORDER BY (SELECT NULL) {group_by_clause}) AS \"{tile_column}\""

    elif tile_method == "EqualSum":
        sum_field = config.find(".//EqualSum/SumField").text.strip()
        num_tiles = config.find(".//EqualSum/NumTiles").get("value")
        sql_expression = f"NTILE({num_tiles}) OVER (ORDER BY SUM(\"{sum_field}\") DESC) AS \"{tile_column}\""

    elif tile_method == "SmartTile":
        smart_field = config.find(".//SmartTile/Field").text.strip()
        name_field = config.find(".//SmartTile/NameField").text.strip() if config.find(".//SmartTile/NameField") is not None else "None"
        
        # Mapping name field behavior
        name_field_case = {
            "None": "",
            "Output": f", \"{tile_column}_Name\"",
            "Verbose": f", \"{tile_column}_Verbose\""
        }
        sql_expression = f"NTILE(7) OVER (ORDER BY STDDEV(\"{smart_field}\") DESC) AS \"{tile_column}\"{name_field_case.get(name_field, '')}"

    elif tile_method == "UniqueValue":
        unique_fields = [field.get("field") for field in config.findall(".//UniqueValue/UniqueFields/Field")]
        dont_sort = config.find(".//UniqueValue/DontSort").get("value") if config.find(".//UniqueValue/DontSort") is not None else "False"
        order_by_clause = "" if dont_sort == "True" else f"ORDER BY {', '.join(unique_fields)}"
        sql_expression = f"DENSE_RANK() OVER ({order_by_clause}) AS \"{tile_column}\""

    elif tile_method == "Manual":
        manual_field = config.find(".//Manual/Field").text.strip()
        cutoffs_text = config.find(".//Manual/Cutoffs").text.strip()
        cutoffs = [c.strip() for c in cutoffs_text.split("\n") if c.strip()]
        case_conditions = " ".join([f"WHEN \"{manual_field}\" <= {cutoff} THEN {i+1}" for i, cutoff in enumerate(cutoffs)])
        sql_expression = f"CASE {case_conditions} ELSE {len(cutoffs) + 1} END AS \"{tile_column}\""

    else:
        raise ValueError(f"Unsupported Tile Method: {tile_method}")

    # Construct final SQL query
    prev_fields_str = ", ".join(f'"{field}"' for field in prev_tool_fields)
    
    cte_query = f"""
    CTE_{toolId} AS (
        SELECT {prev_fields_str}, 
               {sql_expression}
        FROM CTE_{previousToolId}
    )
    """

    new_fields = prev_tool_fields + [tile_column]
    return new_fields, cte_query
