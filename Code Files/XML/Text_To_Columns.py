def generate_cte_for_Text_To_Columns(xml_data, previousToolId, toolId, prev_tool_fields):
    """
    Parses the Alteryx Text To Columns tool XML configuration and generates an equivalent SQL CTE.
    Handles splitting columns based on delimiters, methods (split to columns or rows), and advanced options.
    Uses Snowflake SPLIT_PART() for column splits and STRING_TO_ARRAY() + UNNEST() for row splits.
    """
    root = ET.fromstring(xml_data)

    column_to_split_node = root.find(".//Field")
    if column_to_split_node is None:
        raise ValueError("Missing 'Field' element in XML configuration.")
    column_to_split = column_to_split_node.text

    delimiters_node = root.find(".//Delimeters")
    if delimiters_node is None or 'value' not in delimiters_node.attrib:
        raise ValueError("Missing 'Delimeters' element or attribute in XML configuration.")
    delimiters = delimiters_node.get("value")

    split_method = "Split to columns" if root.find(".//NumFields") is not None else "Split to rows"
    num_columns = int(root.find(".//NumFields").get("value")) if root.find(".//NumFields") is not None else 1
    output_root_name_node = root.find(".//RootName")
    output_root_name = output_root_name_node.text if output_root_name_node is not None else "Column"

    if split_method == "Split to columns":
        new_columns = [f'{output_root_name}_{i+1}' for i in range(num_columns)]
        
        # ✅ Ensure SPLIT_PART is sanitized correctly
        split_part_expressions = [
            sanitize_expression_for_snowflake(f'SPLIT_PART("{column_to_split}", \'{delimiters}\', {i+1}) AS "{col}"')
            for i, col in enumerate(new_columns)
        ]

        cte_query = f"""
        CTE_{toolId} AS (
            SELECT *,
                   {', '.join(split_part_expressions)}
            FROM CTE_{previousToolId}
        )
        """
    else:
        # ✅ Ensure STRING_TO_ARRAY() + UNNEST() is formatted correctly
        unnest_expression = sanitize_expression_for_snowflake(
            f'UNNEST(STRING_TO_ARRAY("{column_to_split}", \'{delimiters}\')) AS "{output_root_name}"'
        )

        cte_query = f"""
        CTE_{toolId} AS (
            SELECT *,
                   {unnest_expression}
            FROM CTE_{previousToolId}
        )
        """

    new_fields = prev_tool_fields + new_columns if split_method == "Split to columns" else prev_tool_fields + [output_root_name]
    return new_fields, cte_query
