import streamlit as st
import xml.etree.ElementTree as ET
import pandas as pd
from collections import deque
import os
import zipfile
import re

def getToolData(filePath):
    # Parse the XML
    file.seek(0)
    tree = ET.parse(filePath)
    root = tree.getroot()

    data = []

    # Iterate through all <Node> elements in the XML
    for node in root.findall('.//Node'):

        node_data = {}

        # Extract ToolID
        tool_id = node.get('ToolID')
        if tool_id is not None:
            node_data['ToolID'] = tool_id

        # Extract Plugin (inside GuiSettings)
        gui_settings = node.find('.//GuiSettings')
        if gui_settings is not None:
            node_data['Plugin'] = gui_settings.get('Plugin', '')

        tool_config = node.find('Properties')
        if tool_config is not None:
            node_data['Properties'] = ET.tostring(tool_config, encoding="unicode")

        data.append(node_data)


    df = pd.DataFrame(data)

    return df


def executionOrders(df):


    df = df[['Origin_ToolID', 'Destination_ToolID']]
    # Create an empty list to store the new rows
    df_new = []

    # Set to track rows that need to be removed (where destination matches the base part of origin)
    rows_to_remove = set()

    # Iterate over each row in the DataFrame
    for index, row in df.iterrows():
        origin_value = row['Origin_ToolID']

        # Check if the origin contains an underscore
        if isinstance(origin_value, str) and '_' in origin_value:
            # Extract the base origin value (before the underscore)
            base_origin, suffix = origin_value.split('_')

            # Find rows where the destination matches the base_origin (before underscore)
            matching_rows = df[df['Destination_ToolID'] == base_origin]

            # For each matching row, add new rows with the modified destination
            for _, match_row in matching_rows.iterrows():
                df_new.append([match_row['Origin_ToolID'], f"{base_origin}_{suffix}"])

            # Mark rows with matching destination to be removed
            rows_to_remove.add(base_origin)

    # Convert the new rows list into a DataFrame
    df_new = pd.DataFrame(df_new, columns=['Origin_ToolID', 'Destination_ToolID'])

    # Concatenate the modified rows
    final_df = pd.concat([df, df_new])

    # Remove rows for the destination matches the base_origin (before underscore)
    df_filtered = final_df[~final_df['Destination_ToolID'].isin(rows_to_remove)].reset_index(drop=True)

    dependencies = []
    tools = set()

    # Iterate through the rows of the DataFrame
    for index, row in df_filtered.iterrows():
        destination = row['Destination_ToolID']
        origin = row['Origin_ToolID']

        # Append (destination, origin) as a tuple to dependencies
        dependencies.append((destination, origin))

        # Add origin and destination to the tools set
        tools.add(origin)
        tools.add(destination)

    adj_list = {tool: [] for tool in tools}
    in_degree = {tool: 0 for tool in tools}
    for dependent, prerequisite in dependencies:
        adj_list[prerequisite].append(dependent)
        in_degree[dependent] += 1
    queue = deque([tool for tool in tools if in_degree[tool] == 0])
    executionOrder = []
    while queue:
        tool = queue.popleft()
        executionOrder.append(tool)
        for dependent in adj_list[tool]:
            in_degree[dependent] -= 1
            if in_degree[dependent] == 0:
                queue.append(dependent)
    if len(executionOrder) != len(tools):
        raise ValueError("Cycle detected in dependencies. Execution order not possible")

    # List where origin element is not in destination
    origin_not_in_destination = df_filtered['Origin_ToolID'][~df_filtered['Origin_ToolID'].isin(df_filtered['Destination_ToolID'])].tolist()

    # List where destination element is not in origin
    destination_not_in_origin = df_filtered['Destination_ToolID'][~df_filtered['Destination_ToolID'].isin(df_filtered['Origin_ToolID'])].tolist()



    return executionOrder,origin_not_in_destination,destination_not_in_origin



# Function to iterate over each row and generate the correct CTE based on Plugin Name
def generate_ctes_for_plugin(df,parentMap):
    cteResults = {}

    toolList = df['ToolID'].unique().tolist()

    for toolId in toolList:
        toolRow = df[df['ToolID'] == toolId]

        if toolRow is not None:
            pluginName = toolRow.iloc[0]['Plugin']
            properties= toolRow.iloc[0]['Properties']

            if pluginName in plugin_functions:
                previousToolId = parentMap[parentMap['Destination_ToolID'] == toolId]['Origin_ToolID'].squeeze() if not parentMap[parentMap['Destination_ToolID'] == toolId]['Origin_ToolID'].empty else None
                cteGenerated = plugin_functions[pluginName](properties,previousToolId,toolId)
                cteResults[toolId] = cteGenerated

            elif pluginName =='AlteryxBasePluginsGui.Join.Join':
                rightToolID = parentMap[(parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Right')]['Origin_ToolID'].squeeze() if not parentMap[(parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Right')]['Origin_ToolID'].empty else None
                leftToolID = parentMap[(parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Left')]['Origin_ToolID'].squeeze() if not parentMap[(parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Left')]['Origin_ToolID'].empty else None
                joinTypeList = parentMap[(parentMap['Origin_ToolID'].str.split('_').str[0] == toolId)]['Origin_Connection'].unique().tolist() if not parentMap[(parentMap['Origin_ToolID'].str.split('_').str[0] == toolId)]['Origin_Connection'].empty else []

                if len(joinTypeList)==1:
                    joinType = 'INNER JOIN' if joinTypeList[0] == 'Join' else 'RIGHT JOIN' if joinTypeList[0] == 'Right' else 'LEFT JOIN' if joinTypeList[0] == 'Left' else None
                    cteGenerated = generate_cte_for_Join(properties, rightToolID, leftToolID, toolId, joinType)
                    cteResults[toolId] = cteGenerated
                else:
                    joinDict = parentMap[parentMap['Origin_ToolID'].str.split('_').str[0] == toolId][['Origin_ToolID', 'Origin_Connection']]
                    for _, row in joinDict.iterrows():
                        join = row['Origin_Connection']
                        toolId = row['Origin_ToolID']
                        joinType = 'INNER JOIN' if join == 'Join' else 'RIGHT JOIN' if join == 'Right' else 'LEFT JOIN' if join == 'Left' else None
                        cteGenerated = generate_cte_for_Join(properties,rightToolID,leftToolID,toolId,joinType)

                        newRow =pd.DataFrame({'ToolID':[toolId],'Plugin':[pluginName],'Properties':[properties],'CTE':None})
                        df = pd.concat([df, newRow], ignore_index=True)

                        cteResults[toolId] = cteGenerated
            elif pluginName == 'AlteryxBasePluginsGui.AppendFields.AppendFields':
                # Handle AppendFields
                sourceToolID = parentMap[(parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Source')]['Origin_ToolID'].squeeze() if not parentMap[(parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Source')]['Origin_ToolID'].empty else None
                destinationToolID = parentMap[(parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Targets')]['Origin_ToolID'].squeeze() if not parentMap[(parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Targets')]['Origin_ToolID'].empty else None
                cteGenerated = generate_cte_for_AppendFields(properties, sourceToolID, destinationToolID, toolId)
                cteResults[toolId] = cteGenerated

            else:
                'No function available for plugin ', pluginName, toolId

    df['CTE'] = df['ToolID'].map(cteResults)

    return df

def generate_cte_for_LockInInput(xml_data, previousToolId, toolId):
    """
    Parses the Alteryx LockInInput node from XML, extracts the SQL source query and connection info,
    and generates an equivalent CTE using ToolID.
    
    - If `previousToolId` exists, it will be included in the generated query.

    # Find the node with the given ToolID
    node = root.find(f".//Node[@ToolID='{toolId}']")

    - If no `previousToolId`, it will be set to `None`.
    """
    root = ET.fromstring(xml_data)

    # Extract SQL Query
    query_element = root.find(".//Query")
    sql_query = query_element.text.strip() if query_element is not None else ""

    if not sql_query:
        raise ValueError("No SQL query found in the LockInInput configuration.")

    # Extract Connection Info
    connection_element = root.find(".//Connection")
    connection_name = connection_element.text.strip() if connection_element is not None else "Unknown_Connection"

    # If there is no previous tool, indicate it as None
    previous_tool_comment = f"-- Previous Tool ID: {previousToolId}" if previousToolId else "-- No Previous Tool ID"

    # Generate the CTE dynamically with connection info and previous tool ID
    cte_query = f"""
    -- Connection: {connection_name}
    {previous_tool_comment}
    {toolId} AS (
        {sql_query}
    )
    """

    return cte_query


def generate_cte_for_LockInFilter(xml_data, previousToolId, toolId):
    """
    Parses the Alteryx LockInFilter node from XML, extracts the filter condition,
    and generates an equivalent SQL CTE using ToolID.
    
    - Only processes when Mode is "Custom".
    - If `previousToolId` exists, it will be included in the generated query.
    - If no `previousToolId`, it raises an error as a filter must have an input.
    """
    root = ET.fromstring(xml_data)

    # Extract Mode (Only process if Mode = "Custom")
    mode_element = root.find(".//Mode")
    mode = mode_element.text.strip() if mode_element is not None else "Unknown"

    if mode != "Custom":
        return f"-- ToolID {toolId} is using Mode '{mode}', skipping filter extraction."

    # Extract Filter Expression
    expression_element = root.find(".//Expression")
    filter_expression = expression_element.text.strip() if expression_element is not None else ""

    if not filter_expression:
        raise ValueError(f"No filter expression found for ToolID {toolId}.")

    # Ensure Previous Tool ID Exists (Filters need input data)
    if not previousToolId:
        raise ValueError(f"ToolID {toolId} requires a Previous Tool ID to filter data.")

    # Generate CTE dynamically
    cte_query = f"""
    -- Filter applied using LockInFilter Tool (Mode: {mode})
    {toolId} AS (
        SELECT * 
        FROM {previousToolId}
        WHERE {filter_expression}
    )
    """

    return cte_query


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

def generate_cte_for_AlteryxSelect(xml_data,previousToolId,toolId):
    # Parse the XML data
    root = ET.fromstring(xml_data)

    # Extract the select fields
    select_fields = root.find('.//Configuration/SelectFields')
    # List to store the fields to be selected
    selected_columns = []

    # Iterate through each SelectField
    for field in select_fields.findall('SelectField'):
        field_name = field.get('field')
        selected = field.get('selected')
        rename = field.get('rename')

        # If selected is True, add to selected columns list
        if selected == "True":
            if rename is not None:
                selected_columns.append(f'"{field_name}" AS "{rename}"')
            else:
                selected_columns.append(f'"{field_name}"')

    # Generate the SQL CTE query string
    # Replace `YourTableName` with the actual table name in your context
    cte_query = f"""
        {toolId} AS (
            SELECT
                {', '.join(selected_columns)}
            FROM {previousToolId}  
        )
        """

    return cte_query


# Function to parse the XML and generate SQL CTE for GroupBy and Aggregation
def generate_cte_for_Summarize(xml_data,previousToolId,toolId):
    root = ET.fromstring(xml_data)

    # Extract SummarizeFields
    summarize_fields = root.find('.//Configuration/SummarizeFields')

    group_by_fields = []
    group_by_fields_before_rename = []
    aggregate_fields = []


    # Iterate through each SummarizeField
    for field in summarize_fields.findall('SummarizeField'):
        field_name = field.get('field')
        action = field.get('action')
        rename = field.get('rename')

        if action == "GroupBy":
            group_by_fields.append(f'"{field_name}" AS "{rename}"')
            group_by_fields_before_rename.append(f'"{field_name}"')
        elif action == "Sum":
            aggregate_fields.append(f'SUM("{field_name}") AS "{rename}"')
        elif action == "Count":
            aggregate_fields.append(f'COUNT("{field_name}") AS "{rename}"')
        elif action == "Min":
            aggregate_fields.append(f'MIN("{field_name}") AS "{rename}"')
        elif action == "Max":
            aggregate_fields.append(f'MAX("{field_name}") AS "{rename}"')
        elif action == "Avg":
            aggregate_fields.append(f'AVG("{field_name}") AS "{rename}"')



    # Generate the SQL CTE query string
    cte_query = f"""
    {toolId} AS (
        SELECT
            {', '.join(group_by_fields)},  -- Group By Fields
            {', '.join(aggregate_fields)}  -- Aggregated Fields
        FROM {previousToolId}
        GROUP BY
            {', '.join(group_by_fields_before_rename)}  -- Group By Fields Before Rename
    )
    """

    return cte_query

def generate_cte_for_Join(xml_data,rightToolID,leftToolID,toolId,joinType):
    root = ET.fromstring(xml_data)

    # Extract JoinInfo for left and right
    left_join_info = root.find('.//Configuration//JoinInfo[@connection="Left"]')
    right_join_info = root.find('.//Configuration//JoinInfo[@connection="Right"]')

    # Extract SelectFields for the selected fields
    select_fields = root.findall('.//SelectConfiguration//SelectFields//SelectField')

    # Collecting selected fields for SELECT statement
    left_fields = []
    right_fields = []

    for field in select_fields:
        field_name = field.get('field')
        selected = field.get('selected') == 'True'  # True/False as string

        if field_name.startswith("Left_") and selected:
            left_fields.append(f'"{field_name}"')
        elif field_name.startswith("Right_") and selected:
            right_fields.append(f'"{field_name}"')

    # Join condition between left and right tables
    join_field_left = left_join_info.find('Field').get('field')
    join_field_right = right_join_info.find('Field').get('field')

    # Generating the CTE query in the format you specified
    cte_query = f"""
    {toolId} AS (
        SELECT
            {', '.join(left_fields)},  -- Left Selected Fields
            {', '.join(right_fields)}  -- Right Selected Fields
        FROM {leftToolID} AS LeftTable
        {joinType} {rightToolID} AS RightTable
        ON LeftTable."{join_field_left}" = RightTable."{join_field_right}"
    )
    """

    return cte_query


## functionfor cleaning expression paramteres
def sanitize_expression_for_filter_formula_dynamic_rename(expression, field_name=None):
    """
    Converts Alteryx-style conditional expressions into SQL-compliant CASE statements.
    - Handles IF-THEN-ELSE-ENDIF transformations.
    - Converts NULL() to NULL.
    - Ensures CONTAINS function has the correct field reference.
    """

    if not expression:
        return ""

    # Replace [_CurrentField_] with actual field name if provided
    if field_name:
        expression = expression.replace("[_CurrentField_]", f"\"{field_name}\"")

    # Ensure CONTAINS function has the field name as the first argument
    expression = re.sub(r"CONTAINS\(\s*['\"]([^'\"]+)['\"]\s*\)", 
                        rf"CONTAINS(\"{field_name}\", '\1')", 
                        expression, flags=re.IGNORECASE)

    # Convert Alteryx-style IF-THEN-ELSE-ENDIF into SQL CASE WHEN
    expression = re.sub(r"If\s+(.*?)\s+Then", r"CASE WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"ElseIf\s+(.*?)\s+Then", r"WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"Else", r"ELSE", expression, flags=re.IGNORECASE)
    expression = re.sub(r"Endif", r"END", expression, flags=re.IGNORECASE)

    # Handle NULL() conversion
    expression = re.sub(r"(?i)NULL\(\)", "NULL", expression)

    # Standardize logical operators
    expression = expression.replace("=", " = ").replace("<>", " != ").replace(" And ", " AND ").replace(" Or ", " OR ")

    # Handle quotes (Alteryx &quot;)
    expression = expression.replace("&quot;", "'")

    # Fix potential SQL syntax issues (strip extra whitespace)
    return expression.strip()

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
    
    # Handle Formula rename mode with sanitized expressions
    elif rename_mode == "Formula":
        rename_mappings = [
            f"{sanitize_expression_for_filter_formula_dynamic_rename(expression, field)} AS \"{field}\""
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

# Function to parse the XML and generate SQL CTE for Filter
def generate_cte_for_Filter(xml_data, previousToolId, toolId):
    """
    Generates SQL CTE for filter expressions found in the configuration.
    Sanitizes filter expressions for SQL compliance.
    """
    root = ET.fromstring(xml_data)

    # Locate the Filter Configuration node
    expression_node = root.find('.//Configuration/Expression')

    if expression_node is None:
        return f"-- No filter configuration found for ToolID {toolId}"

    # Sanitize and clean the filter expression
    filter_expression = sanitize_expression_for_filter_formula_dynamic_rename(expression_node.text.strip()) if expression_node.text else "1=1"

    cte_query = f"""
        {toolId} AS (
        SELECT *
        FROM {previousToolId}
        WHERE {filter_expression}
    )
    """
    return cte_query


# Function to parse the XML and generate SQL CTE for Formula
def generate_cte_for_Formula(xml_data, previousToolId, toolId):
    root = ET.fromstring(xml_data)

    # Extract SummarizeFields
    formula_fields = root.find('.//Configuration/FormulaFields')

    if formula_fields is None:
        return f"-- No formula configuration found for ToolID {toolId}"

    formula_expr = []

    # Extract each formula field and generate SQL expressions
    for field in formula_fields.findall('FormulaField'):
        expr_name = field.get('expression')
        field_name = field.get('field')

        sql_expression = sanitize_expression_for_filter_formula_dynamic_rename(expr_name)

        formula_expr.append(f"{sql_expression} AS \"{field_name}\"")

    # Generate the SQL CTE query string
    cte_query = f"""
        {toolId} AS  (
        SELECT 
            {', '.join(formula_expr)}
        FROM {previousToolId} 
    )
    """
    return cte_query


def generate_cte_for_AppendFields(properties,sourceToolID,destinationToolID,toolId):
    """
    Generates SQL CTE for appending fields based on SelectField attributes.
    Only includes fields with selected="True".
    """

    # Parse the XML data
    root = ET.fromstring(properties)

    select_fields_node = root.find('.//Configuration/SelectFields')

    if select_fields_node is None:
        return f"-- No append fields configuration found for ToolID {toolId}"

    # Extract selected fields
    selected_fields = []
    for field in select_fields_node.findall('SelectField'):
        field_name = field.get('field')
        selected = field.get('selected')

        # Only include fields marked as selected
        if selected == "True":
            selected_fields.append(f'"{field_name}"')

    # Generate CTE query
    cte_query = f"""
    {toolId} AS (
        SELECT 
            {sourceToolID}.*, {', '.join(selected_fields)}
        FROM {sourceToolID}
    )
    """
    return cte_query


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

    # Extract sorting fields and order direction
    sort_fields = [(field.get("field"), field.get("order")) for field in root.findall(".//SortInfo/Field")]

    # Generate ORDER BY clause dynamically
    order_by_clause = ", ".join(f"\"{field}\" {order}" for field, order in sort_fields) if sort_fields else ""

    # Generate SQL CTE dynamically
    cte_query = f"""
    {toolId} AS (
        SELECT 
            {', '.join(f'"{field}"' for field in group_by_fields)}, 
            {', '.join(case_statements)}
        FROM {previousToolId}
        GROUP BY {', '.join(f'"{field}"' for field in group_by_fields)}
        {f'ORDER BY {order_by_clause}' if order_by_clause else ''}
    )
    """

    return cte_query

import xml.etree.ElementTree as ET

def generate_cte_for_DataCleansing(xml_data, previousToolId, toolId):
    """
    Parses the Alteryx Data Cleansing node from XML, extracts cleansing operations only if they are active (True),
    and generates an equivalent SQL CTE using ToolID.
    
    - Extracts selected fields only if transformations are enabled.
    - Handles cleansing operations like replacing nulls, trimming spaces, case conversion, etc.
    """

    root = ET.fromstring(xml_data)

    # Extract selected fields for cleansing (only if enabled)
    fields_element = root.find(".//Value[@name='List Box (11)']")
    selected_fields = [f.strip('"') for f in fields_element.text.split(",")] if fields_element is not None and fields_element.text else []

    # Extract checkboxes only if their value is "True"
    replace_with_blank = root.find(".//Value[@name='Check Box (84)']")
    replace_with_zero = root.find(".//Value[@name='Check Box (117)']")
    trim_whitespace = root.find(".//Value[@name='Check Box (15)']")
    remove_letters = root.find(".//Value[@name='Check Box (53)']")
    remove_numbers = root.find(".//Value[@name='Check Box (58)']")
    remove_punctuation = root.find(".//Value[@name='Check Box (70)']")
    modify_case = root.find(".//Value[@name='Check Box (77)']")
    case_type = root.find(".//Value[@name='Drop Down (81)']")

    # SQL transformation rules
    sql_transformations = []

    for field in selected_fields:
        transformations = []
        
        if replace_with_blank is not None and replace_with_blank.text == "True":
            transformations.append(f"NULLIF({field}, '') AS {field}")

        if replace_with_zero is not None and replace_with_zero.text == "True":
            transformations.append(f"COALESCE({field}, 0) AS {field}")

        if trim_whitespace is not None and trim_whitespace.text == "True":
            transformations.append(f"TRIM({field}) AS {field}")

        if remove_letters is not None and remove_letters.text == "True":
            transformations.append(f"REGEXP_REPLACE({field}, '[A-Za-z]', '') AS {field}")

        if remove_numbers is not None and remove_numbers.text == "True":
            transformations.append(f"REGEXP_REPLACE({field}, '[0-9]', '') AS {field}")

        if remove_punctuation is not None and remove_punctuation.text == "True":
            transformations.append(f"REGEXP_REPLACE({field}, '[[:punct:]]', '') AS {field}")

        if modify_case is not None and modify_case.text == "True":
            if case_type is not None and case_type.text == "upper":
                transformations.append(f"UPPER({field}) AS {field}")
            elif case_type is not None and case_type.text == "lower":
                transformations.append(f"LOWER({field}) AS {field}")
            elif case_type is not None and case_type.text == "title":
                transformations.append(f"INITCAP({field}) AS {field}")

        # Only add transformations if at least one transformation is applied
        if transformations:
            sql_transformations.extend(transformations)

    # Ensure Previous Tool ID Exists (Data cleansing needs input data)
    if not previousToolId:
        raise ValueError(f"ToolID {toolId} requires a Previous Tool ID for input data.")

    # Generate CTE dynamically
    if sql_transformations:
        cte_query = f"""
        -- Data Cleansing transformations applied using Cleanse Tool
        {toolId} AS (
            SELECT 
                *,
                {',\n                '.join(sql_transformations)}
            FROM {previousToolId}
        )
        """
    else:
        cte_query = f"""
        -- No active data cleansing transformations for ToolID {toolId}
        {toolId} AS (
            SELECT * FROM {previousToolId}
        )
        """

    return cte_query

def connectionDetails(file,dfWithTool):
    # Parse the XML data
    file.seek(0)
    tree = ET.parse(file)
    root = tree.getroot()

    # Initialize an empty list to store the connection data
    data = []
    connectionRoot = root.find('Connections')
    for connection in connectionRoot.findall('.//Connection'):

        # Get the connection name if it exists
        connection_name = connection.get('name', None)

        # Get the details of the origin and destination tools
        origin_tool_id = connection.find('Origin').get('ToolID')
        origin_connection = connection.find('Origin').get('Connection')

        destination_tool_id = connection.find('Destination').get('ToolID')
        destination_connection = connection.find('Destination').get('Connection')

        # Store the data in the list
        data.append({
            'Connection_Name': connection_name,
            'Origin_ToolID': origin_tool_id,
            'Origin_Connection': origin_connection,
            'Destination_ToolID': destination_tool_id,
            'Destination_Connection': destination_connection
        })

    # Convert the data list into a pandas DataFrame
    df = pd.DataFrame(data)

    dfWithTool=dfWithTool[['ToolID', 'Plugin']]
    df_with_tool_name = df.merge(dfWithTool, left_on='Destination_ToolID', right_on='ToolID', how='left')
    df_with_tool_name.drop(columns='ToolID', inplace=True)




    for index, row in df_with_tool_name[df_with_tool_name['Plugin'] == 'AlteryxBasePluginsGui.Join.Join'].iterrows():
        destination = row['Destination_ToolID']

        # Find the rows where the destination matches origin
        matching_rows = df_with_tool_name[df_with_tool_name['Origin_ToolID'] == destination]

        # Check if there are multiple matching rows with different originConnections
        if len(matching_rows) > 1 and len(matching_rows['Origin_Connection'].unique()) > 1:
            # Modify the origin column by appending originConnection if needed
            for _, match_row in matching_rows.iterrows():
                # Only modify the origin if originConnection is different
                if match_row['Origin_Connection'] != row['Origin_Connection']:
                    df_with_tool_name.at[match_row.name, 'Origin_ToolID'] = f"{match_row['Origin_ToolID']}_{match_row['Origin_Connection']}"

    return df_with_tool_name


def finalCTEGeneration(df,executionOrder, inputNodes, outputNodes):
    # Initialize the result string
    result = ""
    results_dict = {}

    # Iterate over the elements in the list
    for i, item in enumerate(executionOrder):
        # Find the corresponding value in the dataframe
        value = df.loc[df['ToolID'] == item, 'CTE'].values[0]

        # Convert value to string to avoid TypeError
        value = str(value)

        # Add the value to the result string
        if i > 0:
            result += ',\n'
        result += value

        if item in outputNodes:
            results_dict[item] = result


    return result,results_dict


# Function to create SQL files for each dictionary (cteDictionary) and place them in a folder
def create_sql_files_for_uploaded_file(file, cteDictionary, folder_name):
    # Create a folder for the uploaded file (based on the file name)
    if not os.path.exists(folder_name):
        os.makedirs(folder_name)

    # Create SQL files for each key in the cteDictionary
    for key, sql_query in cteDictionary.items():
        file_path = os.path.join(folder_name, f"{key}.sql")
        with open(file_path, 'w') as sql_file:
            sql_file.write(sql_query)

    return folder_name


# Function to create a zip file containing all folders
def create_zip_of_folders(fileNameList, cteDictionaries):
    # Create a zip file to store all folders
    zip_filename = "Workflows converted to CTE's.zip"

    with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for idx, (file, cteDictionary) in enumerate(zip(fileNameList, cteDictionaries)):
            # Use the sanitized file name as the folder name
            folder_name = file.name  # Folder name is based on the file name
            folder_path = create_sql_files_for_uploaded_file(file, cteDictionary, folder_name)

            if folder_path:
                # Add the folder and its contents to the zip file, preserving folder structure
                for root, _, files in os.walk(folder_path):
                    for file in files:
                        # Use arcname to ensure the file paths inside the zip preserve the folder structure
                        zipf.write(os.path.join(root, file), arcname=os.path.join(folder_name, file))

    return zip_filename

if __name__ == "__main__":
    st.title('Alteryx Converter')
    fileNameList = st.file_uploader('Upload XML files', type=['yxmd','xml'], accept_multiple_files=True)

    cteDictionaries = []  # This will store the cteDictionary for each file

    if fileNameList:
        for file in fileNameList:

            st.write(getToolData(file))

            plugin_functions = {
                'AlteryxBasePluginsGui.AlteryxSelect.AlteryxSelect': generate_cte_for_AlteryxSelect,
                'LockInGui.LockInSelect.LockInSelect': generate_cte_for_AlteryxSelect,
                'AlteryxSpatialPluginsGui.Summarize.Summarize': generate_cte_for_Summarize,
                'AlteryxBasePluginsGui.Formula.Formula': generate_cte_for_Formula,
                'AlteryxBasePluginsGui.Filter.Filter': generate_cte_for_Filter,
                'AlteryxBasePluginsGui.CrossTab.CrossTab' : generate_cte_for_CrossTab,
                'AlteryxBasePluginsGui.DynamicRename.DynamicRename' : generate_cte_for_DynamicRename,
                'LockInGui.LockInInput.LockInInput' : generate_cte_for_LockInInput,
                'LockInGui.LockInFilter.LockInFilter' : generate_cte_for_LockInFilter,
                'AlteryxBasePluginsGui.Macro.Macro' : generate_cte_for_DataCleansing
            }

            df= getToolData(file)

            parentMap = connectionDetails(file,df)

            executionOrder, inputNodes, outputNodes = executionOrders(parentMap)

            df = generate_ctes_for_plugin(df,parentMap)

            cte, cteDictionary = finalCTEGeneration(df, executionOrder, inputNodes, outputNodes)

            cteDictionaries.append(cteDictionary)

            st.write(df)
            st.write(parentMap)
            st.write(executionOrder)
            st.write(inputNodes)
            st.write(outputNodes)
            st.write(cte)
            st.write(cteDictionary)


        zip_file_path = create_zip_of_folders(fileNameList, cteDictionaries)

        # Provide the zip file for download
        with open(zip_file_path, "rb") as f:
            st.download_button("Download All SQL Files", f, file_name=zip_file_path)
