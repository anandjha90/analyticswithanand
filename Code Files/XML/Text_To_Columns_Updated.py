import xml.etree.ElementTree as ET

def sanitize_expression_for_filter_formula_dynamic_rename(expression):
    """ Placeholder function to sanitize expressions dynamically. """
    return expression  # Modify as needed for your implementation

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

    extra_chars_option_node = root.find(".//ExtraCharacterOption")
    extra_chars_option = extra_chars_option_node.get("value") if extra_chars_option_node is not None else "Leave extra in last column"

    advanced_options = {
        "ignore_quotes": root.find(".//IgnoreQuotes") is not None,
        "ignore_single_quotes": root.find(".//IgnoreSingleQuotes") is not None,
        "ignore_parentheses": root.find(".//IgnoreParentheses") is not None,
        "ignore_brackets": root.find(".//IgnoreBrackets") is not None,
        "skip_empty_columns": root.find(".//SkipEmptyColumns") is not None,
    }

    # Ensure previous fields are explicitly listed in SELECT
    prev_fields_str = ", ".join(f'"{field}"' for field in prev_tool_fields)

    if split_method == "Split to columns":
        new_columns = [f'{output_root_name}_{i+1}' for i in range(num_columns)]

        split_part_expressions = [
            sanitize_expression_for_filter_formula_dynamic_rename(
                f'SPLIT_PART("{column_to_split}", \'{delimiters}\', {i+1}) AS "{col}"'
            )
            for i, col in enumerate(new_columns)
        ]

        # Handling extra characters options
        if extra_chars_option == "Drop extra with warning":
            split_part_expressions.append(sanitize_expression_for_filter_formula_dynamic_rename(
                f'CASE WHEN ARRAY_SIZE(STRING_TO_ARRAY("{column_to_split}", \'{delimiters}\')) > {num_columns} '
                f'THEN RAISE_WARNING("Extra columns dropped") END'
            ))
        elif extra_chars_option == "Error":
            split_part_expressions.append(sanitize_expression_for_filter_formula_dynamic_rename(
                f'CASE WHEN ARRAY_SIZE(STRING_TO_ARRAY("{column_to_split}", \'{delimiters}\')) > {num_columns} '
                f'THEN RAISE_ERROR("Too many columns") END'
            ))

        cte_query = f"""
        CTE_{toolId} AS (
            SELECT {prev_fields_str},
                   {', '.join(split_part_expressions)}
            FROM CTE_{previousToolId}
        )
        """

    else:  # Split to rows
        unnest_expression = sanitize_expression_for_filter_formula_dynamic_rename(
            f'UNNEST(STRING_TO_ARRAY("{column_to_split}", \'{delimiters}\')) AS "{output_root_name}"'
        )

        # Skip empty columns if enabled
        if advanced_options["skip_empty_columns"]:
            unnest_expression = sanitize_expression_for_filter_formula_dynamic_rename(
                f"(SELECT value FROM TABLE({unnest_expression}) WHERE value IS NOT NULL)"
            )

        cte_query = f"""
        CTE_{toolId} AS (
            SELECT {prev_fields_str},
                   {unnest_expression}
            FROM CTE_{previousToolId}
        )
        """

    new_fields = prev_tool_fields + new_columns if split_method == "Split to columns" else prev_tool_fields + [output_root_name]
    return new_fields, cte_query
