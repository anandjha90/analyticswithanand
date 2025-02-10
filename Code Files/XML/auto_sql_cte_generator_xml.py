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
def sanitize_expression_for_filter_formula(expression):
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
    expression = expression.replace("=", " = ").replace("<>", " != ").replace(" And ", " AND ").replace(" Or ", " OR ")

    # Handle quotes (Alteryx &quot;)
    expression = expression.replace("&quot;", "'")

    # Fix potential SQL syntax issues (strip extra whitespace)
    return expression.strip()


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
    filter_expression = sanitize_expression_for_filter_formula(expression_node.text.strip()) if expression_node.text else "1=1"

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

        sql_expression = sanitize_expression_for_filter_formula(expr_name)

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
                'AlteryxBasePluginsGui.Filter.Filter': generate_cte_for_Filter
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
