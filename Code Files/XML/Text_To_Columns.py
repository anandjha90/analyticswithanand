def generate_cte_for_Text_To_Columns(xml_data, previousToolId, toolId, prev_tool_fields):
    """
    Parses the Alteryx Text To Columns tool XML configuration and generates an equivalent SQL CTE.
    Handles splitting columns based on delimiters, methods (split to columns or rows), and advanced options.
    """
    root = ET.fromstring(xml_data)

    column_to_split = root.find(".//Field").text
    delimiters = root.find(".//Delimeters").get("value")
    split_method = "Split to columns" if root.find(".//NumFields") is not None else "Split to rows"
    num_columns = int(root.find(".//NumFields").get("value")) if root.find(".//NumFields") is not None else 1
    output_root_name = root.find(".//RootName").text or "Column"

    flags = int(root.find(".//Flags").get("value")) if root.find(".//Flags") is not None else 0

    ignore_quotes = bool(flags & 1)
    skip_empty = bool(flags & 16)

    if split_method == "Split to columns":
        new_columns = [f'{output_root_name}_{i+1}' for i in range(num_columns)]
        cte_query = f"""
        CTE_{toolId} AS (
            SELECT *,
                   {', '.join([f'SPLIT_PART("{column_to_split}", \'{delimiters}\', {i+1}) AS \"{col}\"' for i, col in enumerate(new_columns)])}
            FROM CTE_{previousToolId}
        )
        """
    else:
        cte_query = f"""
        CTE_{toolId} AS (
            SELECT *,
                   UNNEST(STRING_TO_ARRAY("{column_to_split}", '{delimiters}' {', NULL' if skip_empty else ''})) AS "{output_root_name}"
            FROM CTE_{previousToolId}
        )
        """

    new_fields = prev_tool_fields + new_columns if split_method == "Split to columns" else prev_tool_fields + [output_root_name]
    return new_fields, cte_query
