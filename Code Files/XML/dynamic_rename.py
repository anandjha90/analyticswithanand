import xml.etree.ElementTree as ET

def generate_cte_for_DynamicRename(xml_data, previousToolId, toolId):
    """
    Parses the XML for Dynamic Rename transformation and generates a SQL CTE dynamically.
    Handles different rename modes: FirstRow, Formula, Add, Remove, RightInputMetadata, RightInputRows.
    """
    root = ET.fromstring(xml_data)

    # Extract rename mode
    rename_mode = root.find(".//RenameMode").text if root.find(".//RenameMode") is not None else "Unknown"

    # Extract input field names (before renaming)
    input_fields = [field.get("name") for field in root.findall(".//Fields/Field")]

    # Extract final output field names from <MetaInfo> (renamed fields)
    output_fields = [field.get("name") for field in root.findall(".//MetaInfo/RecordInfo/Field")]

    # Ensure the number of input fields matches the number of output fields
    # if len(input_fields) != len(output_fields):
        # return f"-- Warning: Mismatch between input and output fields for ToolID {toolId}"

    # Adjust for any mismatches in input and output field lengths
    min_length = min(len(input_fields), len(output_fields))

    # Trim lists to the same size to prevent index errors
    input_fields = input_fields[:min_length]
    output_fields = output_fields[:min_length]

    # Extract additional attributes based on Rename Mode
    expression = root.find(".//Expression").text if root.find(".//Expression") is not None else ""
    prefix_suffix_type = root.find(".//AddPrefixSuffix/Type")
    prefix_suffix_text = root.find(".//AddPrefixSuffix/Text")
    remove_suffix_text = root.find(".//RemovePrefixSuffix/Text")
    right_input_name = root.find(".//NamesFromMetadata")

    # Handle FirstRow rename mode
    if rename_mode == "FirstRow":
        rename_mappings = ",\n            ".join(
            f"\"{input_fields[i]}\" AS \"{output_fields[i]}\"" for i in range(len(input_fields))
        )
    
    # Handle Formula rename mode
    elif rename_mode == "Formula":
        rename_mappings = ",\n            ".join(
            f"CASE WHEN {expression.replace('[_CurrentField_]', f'\"{field}\"')} THEN \"{field}\" END AS \"{field}\""
            for field in input_fields
        )

    # Handle Add Prefix/Suffix rename mode
    elif rename_mode == "Add":
        prefix_suffix_clause = f"\"{prefix_suffix_text.text}\" || \"{field}\"" if prefix_suffix_type.text == "Prefix" else f"\"{field}\" || \"{prefix_suffix_text.text}\""
        rename_mappings = ",\n            ".join(
            f"{prefix_suffix_clause} AS \"{field}\"" for field in input_fields
        )

    # Handle Remove Prefix/Suffix rename mode
    elif rename_mode == "Remove":
        rename_mappings = ",\n            ".join(
            f"REPLACE(\"{field}\", \"{remove_suffix_text.text}\", '') AS \"{field}\"" for field in input_fields
        )

    # Handle RightInputMetadata rename mode
    elif rename_mode == "RightInputMetadata":
        rename_mappings = ",\n            ".join(
            f"\"{right_input_name.find('NewName').text}\" AS \"{field}\"" for field in input_fields
        )

    # Handle RightInputRows rename mode
    elif rename_mode == "RightInputRows":
        rename_mappings = ",\n            ".join(
            f"\"{field}\" AS \"{field}\"" for field in input_fields  # This mode maps fields from right input
        )

    # Default case (if rename mode is unknown or not supported)
    else:
        rename_mappings = ",\n            ".join(f"\"{field}\" AS \"{field}\"" for field in input_fields)

    # Generate SQL CTE dynamically
    cte_query = f"""
    {toolId} AS (
        SELECT 
            {rename_mappings}
        FROM {previousToolId}
    )
    """

    return cte_query
