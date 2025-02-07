import streamlit as st
import xml.etree.ElementTree as ET
import pandas as pd
from collections import deque
from datetime import datetime
import re
from io import BytesIO


def getToolData(filePath):
    # Parse the XML

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


def executionOrder(filePath):
    tree = ET.parse(filePath)
    root = tree.getroot()
    # Create a dictionary to map ToolID to its CTE name
    dependencies = []
    tools = set()

    # Populate the map with connections data
    connectionRoot = root.find('Connections')
    for conn in connectionRoot.findall('.//Connection'):
        origin_tool_id = conn.find('Origin').get('ToolID')
        destination_tool_id = conn.find('Destination').get('ToolID')

        # Assign a CTE name to each ToolID (use a set to avoid duplication)
        dependencies.append((destination_tool_id,origin_tool_id))
        tools.add(origin_tool_id)
        tools.add(destination_tool_id)

    adj_list = {tool: [] for tool in tools}
    in_degree = {tool: 0 for tool in tools}

    for dependent,prerequisite in dependencies:
        adj_list[prerequisite].append(dependent)
        in_degree[dependent]+=1
    queue = deque([tool for tool in tools if in_degree[tool]==0])
    executionOrder = []
    while queue:
        tool = queue.popleft()
        executionOrder.append(tool)
        for dependent in adj_list[tool]:
            in_degree[dependent]-=1
            if in_degree[dependent]==0:
                queue.append(dependent)
    if len(executionOrder)!=len(tools):
        raise ValueError("Cycle detected in dependencies. Execution order not possible")


    return executionOrder

## functionfor cleaning expression paramteres
def sanitize_expression(expression):
    """
    Converts Alteryx-style conditional expressions into SQL-compliant CASE statements.
    Handles NULL() to NULL and other transformations.
    """
    # Replace Alteryx "If-ElseIf-Endif" with SQL "CASE-WHEN"
    expression = re.sub(r"If (.*?) Then", r"CASE WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"ElseIf (.*?) Then", r"WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"Else", r"ELSE", expression, flags=re.IGNORECASE)
    expression = re.sub(r"Endif", r"END", expression, flags=re.IGNORECASE)
    
    # Handle NULL() conversion
    expression = re.sub(r"(?i)NULL\(\)", "NULL", expression)

    # Handle common logical operation
    expression = expression.replace("="," = ").replace("<>"," != ").replace(" And "," AND ").replace(" Or "," OR ")


    # Handle quotes (Alteryx &quot;)
    expression = expression.replace("&quot;", "'")

    # Fix potential SQL syntax issues (strip extra whitespace)
    return expression.strip()

# Function to parse the XML and generate SQL CTE for Filter
def generate_filter_cte(xml_data,previousToolId,toolId):
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
    filter_expression = sanitize_expression(expression_node.text.strip()) if expression_node.text else "1=1"

    cte_query = f"""
        {toolId} AS (
        SELECT *
        FROM {previousToolId}
        WHERE {filter_expression}
    )
    """
    return cte_query


# Function to parse the XML and generate SQL CTE for Formula
def generate_formula_cte(xml_data,previousToolId,toolId):
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
  
        sql_expression = sanitize_expression(expr_name)

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

# Function to iterate over each row and generate the correct CTE based on Plugin Name
def generate_ctes_for_plugin(df,executionOrder,parentMap):
    cteResults = {}
    for toolId in executionOrder:
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
                cteGenerated = generate_cte_for_Join(properties,rightToolID,leftToolID,toolId)
                cteResults[toolId] = cteGenerated

            elif pluginName =='AlteryxBasePluginsGui.AppendFields.AppendFields':
                # Handle AppendFields
                sourceToolID = parentMap[(parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Source')]['Origin_ToolID'].squeeze() if not parentMap[(parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Source')]['Origin_ToolID'].empty else None
                destinationToolID = parentMap[(parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Targets')]['Origin_ToolID'].squeeze() if not parentMap[(parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Targets')]['Origin_ToolID'].empty else None
                cteGenerated = generate_append_fields_cte(properties,sourceToolID,destinationToolID,toolId)
                cteResults[toolId] = cteGenerated
                
            else:
                'No function available for plugin ', pluginName, toolId

    df['CTE'] = df['ToolID'].map(cteResults)

    return df


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


def generate_append_fields_cte(properties,sourceToolID,destinationToolID,toolId):
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


def generate_cte_for_Join(xml_data,rightToolID,leftToolID,toolId):
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
        INNER JOIN {rightToolID} AS RightTable
        ON LeftTable."{join_field_left}" = RightTable."{join_field_right}"
    )
    """

    return cte_query


def connectionDetails(file,dfWithTool):
    # Parse the XML data

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

    return df_with_tool_name

if __name__ == "__main__":
    st.title('Alteryx Converter')
    fileNameList = st.file_uploader('Upload XML files', type=['yxmd','xml'], accept_multiple_files=True)

    if fileNameList:
        for file in fileNameList:
            st.write(getToolData(file))

            file.seek(0)
            executionOrder = executionOrder(file)

            plugin_functions = {
                'AlteryxBasePluginsGui.AlteryxSelect.AlteryxSelect': generate_cte_for_AlteryxSelect,
                'LockInGui.LockInSelect.LockInSelect': generate_cte_for_AlteryxSelect,
                'AlteryxSpatialPluginsGui.Summarize.Summarize': generate_cte_for_Summarize,
                'AlteryxBasePluginsGui.Formula.Formula': generate_formula_cte,
                'AlteryxBasePluginsGui.Filter.Filter' : generate_filter_cte
            }


            file.seek(0)
            df= getToolData(file)
            df['Source file'] = file.name

            file.seek(0)
            parentMap = connectionDetails(file,df)


            df = generate_ctes_for_plugin(df,executionOrder,parentMap)

            st.write(df)

            st.write(parentMap)
