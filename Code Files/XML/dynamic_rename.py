import xml.etree.ElementTree as ET

def generate_cte_for_DynamicRename(xml_data, previousToolId, toolId):
    """
    Parses the XML for Dynamic Rename transformation and generates a SQL CTE dynamically.
    Handles different rename modes: FirstRow, Formula, Add, Remove, RightInputMetadata, RightInputRows.
    """
    root = ET.fromstring(xml_data)

    # Extract rename mode
    rename_mode = root.find(".//RenameMode").text if root.find(".//RenameMode") is not None else "Unknown"

    # Extract input field names (before renaming) and remove "*Unknown" field
    input_fields = [field.get("name") for field in root.findall(".//Fields/Field") if field.get("name") != "*Unknown"]

    # Extract final output field names from <MetaInfo> (renamed fields)
    output_fields = [field.get("name") for field in root.findall(".//MetaInfo/RecordInfo/Field")]

    # Handle missing or extra fields to avoid index errors
    min_length = min(len(input_fields), len(output_fields))
    input_fields = input_fields[:min_length]
    output_fields = output_fields[:min_length]

    # Extract additional attributes based on Rename Mode
    expression = root.find(".//Expression").text if root.find(".//Expression") is not None else ""
    prefix_suffix_type = root.find(".//AddPrefixSuffix/Type")
    prefix_suffix_text = root.find(".//AddPrefixSuffix/Text")
    remove_suffix_text = root.find(".//RemovePrefixSuffix/Text")
    right_input_name = root.find(".//NamesFromMetadata/NewName")

    rename_mappings = []

    # Handle FirstRow rename mode
    if rename_mode == "FirstRow":
        rename_mappings = [
            f"\"{input_fields[i]}\" AS \"{output_fields[i]}\"" for i in range(min_length)
        ]
    
    # Handle Formula rename mode
    elif rename_mode == "Formula":
        rename_mappings = [
            f"CASE WHEN {expression.replace('[_CurrentField_]', f'\"{field}\"')} THEN \"{field}\" END AS \"{field}\""
            for field in input_fields
        ]

    # Handle Add Prefix/Suffix rename mode
    elif rename_mode == "Add":
        if prefix_suffix_type is not None and prefix_suffix_text is not None:
            if prefix_suffix_type.text == "Prefix":
                rename_mappings = [f"'{prefix_suffix_text.text}' || \"{field}\" AS \"{field}\"" for field in input_fields]
            else:
                rename_mappings = [f"\"{field}\" || '{prefix_suffix_text.text}' AS \"{field}\"" for field in input_fields]

    # Handle Remove Prefix/Suffix rename mode
    elif rename_mode == "Remove":
        if remove_suffix_text is not None:
            rename_mappings = [
                f"REPLACE(\"{field}\", '{remove_suffix_text.text}', '') AS \"{field}\"" for field in input_fields
            ]

    # Handle RightInputMetadata rename mode
    elif rename_mode == "RightInputMetadata":
        if right_input_name is not None:
            rename_mappings = [
                f"\"{right_input_name.text}\" AS \"{field}\"" for field in input_fields
            ]

    # Handle RightInputRows rename mode
    elif rename_mode == "RightInputRows":
        rename_mappings = [
            f"\"{field}\" AS \"{field}\"" for field in input_fields
        ]

    # Default case (if rename mode is unknown or not supported)
    if not rename_mappings:
        rename_mappings = [f"\"{field}\" AS \"{field}\"" for field in input_fields]

    # Generate SQL CTE dynamically
    cte_query = f"""
    {toolId} AS (
        SELECT 
            {',\n            '.join(rename_mappings)}
        FROM {previousToolId}
    )
    """

    return cte_query
