import streamlit as st
import xml.etree.ElementTree as ET
import pandas as pd
from collections import deque
import os
import zipfile
import re
import networkx as nx
import html


def getToolData(XMlfile):
    # Parse the XML
    file.seek(0)
    tree = ET.parse(XMlfile)
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

        # Extract Macro related data
        plugin_value = node.find(".//GuiSettings").get("Plugin")
        if plugin_value is None:
            node_str = ET.tostring(node, encoding='unicode')
            # match = re.findall(r'EngineSettings\s+Macro="[^"]+"', node_str)
            match = re.findall(r'EngineSettings\s+Macro\s*=\s*"([^\.]+)', node_str)
            node_data['Plugin'] = match[0]

        data.append(node_data)

    df = pd.DataFrame(data)

    df['ColumnsList'] = [[] for _ in range(len(df))]
    df['toolPluginName'] = df['Plugin'].apply(lambda x: x.split('.')[-1] if '.' in x else x)

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
    origin_not_in_destination = df_filtered['Origin_ToolID'][
        ~df_filtered['Origin_ToolID'].isin(df_filtered['Destination_ToolID'])].tolist()

    # List where destination element is not in origin
    destination_not_in_origin = df_filtered['Destination_ToolID'][
        ~df_filtered['Destination_ToolID'].isin(df_filtered['Origin_ToolID'])].tolist()

    return executionOrder, origin_not_in_destination, destination_not_in_origin, df_filtered


# Function to iterate over each row and generate the correct CTE based on Plugin Name
def generate_ctes_for_plugin(df, parentMap, functionCallOrderList):
    cteResults = {}

    for toolId in functionCallOrderList:
        toolRow = df[df['ToolID'] == toolId]

        if toolRow is not None:
            pluginName = toolRow.iloc[0]['Plugin']
            properties = toolRow.iloc[0]['Properties']

            if pluginName in plugin_functions:
                toolName = df[df['ToolID'] == toolId]['toolPluginName'].tolist()[0]
                previousToolId = parentMap[parentMap['Destination_ToolID'] == toolId]['Origin_ToolID'].squeeze() if not \
                    parentMap[parentMap['Destination_ToolID'] == toolId]['Origin_ToolID'].empty else None
                previousToolColList = df[df['ToolID'] == previousToolId]['ColumnsList'].tolist()[0]
                previousToolName = df[df['ToolID'] == previousToolId]['toolPluginName'].tolist()[0]
                colListGenerated, cteGenerated = plugin_functions[pluginName](properties, previousToolId, toolId,
                                                                              previousToolColList, toolName,
                                                                              previousToolName)
                cteResults[toolId] = cteGenerated

                # Iterate through each row and update Columns based on ToolID
                for index, row in df.iterrows():
                    if row['ToolID'] == toolId:  # Check for a single ToolID match
                        df.at[index, 'ColumnsList'] = colListGenerated

            elif pluginName == 'AlteryxBasePluginsGui.DbFileInput.DbFileInput':
                colListGenerated = generate_cte_for_DBFileInput(properties, toolId)
                # Iterate through each row and update Columns based on ToolID
                for index, row in df.iterrows():
                    if row['ToolID'] == toolId:  # Check for a single ToolID match
                        df.at[index, 'ColumnsList'] = colListGenerated


            elif pluginName == 'LockInGui.LockInInput.LockInInput':
                colListGenerated, cteGenerated = generate_cte_for_LockInInput(properties, toolId)
                cteResults[toolId] = cteGenerated
                # Iterate through each row and update Columns based on ToolID
                for index, row in df.iterrows():
                    if row['ToolID'] == toolId:  # Check for a single ToolID match
                        df.at[index, 'ColumnsList'] = colListGenerated

            elif pluginName == 'AlteryxBasePluginsGui.TextInput.TextInput':
                colListGenerated, cteGenerated = generate_cte_for_TextInput(properties, toolId)
                cteResults[toolId] = cteGenerated
                # Iterate through each row and update Columns based on ToolID
                for index, row in df.iterrows():
                    if row['ToolID'] == toolId:  # Check for a single ToolID match
                        df.at[index, 'ColumnsList'] = colListGenerated


            elif pluginName == 'AlteryxBasePluginsGui.Join.Join':
                rightToolID = parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Right')][
                    'Origin_ToolID'].squeeze() if not parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Right')][
                    'Origin_ToolID'].empty else None
                rightToolName = df[df['ToolID'] == rightToolID]['toolPluginName'].tolist()[0]
                leftToolID = parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Left')][
                    'Origin_ToolID'].squeeze() if not parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Left')][
                    'Origin_ToolID'].empty else None
                leftToolName = df[df['ToolID'] == leftToolID]['toolPluginName'].tolist()[0]
                joinTypeList = parentMap[(parentMap['Origin_ToolID'].str.split('_').str[0] == toolId)][
                    'Origin_Connection'].unique().tolist() if not \
                    parentMap[(parentMap['Origin_ToolID'].str.split('_').str[0] == toolId)][
                        'Origin_Connection'].empty else []
                left_previousToolColList = df[df['ToolID'] == leftToolID]['ColumnsList'].tolist()[0]
                right_previousToolColList = df[df['ToolID'] == rightToolID]['ColumnsList'].tolist()[0]

                if len(joinTypeList) == 1:
                    joinType = 'INNER JOIN' if joinTypeList[0] == 'Join' else 'RIGHT JOIN' if joinTypeList[
                                                                                                  0] == 'Right' else 'LEFT JOIN' if \
                        joinTypeList[0] == 'Left' else None
                    colListGenerated, cteGenerated = generate_cte_for_Join(properties, rightToolID, leftToolID, toolId,
                                                                           joinType, left_previousToolColList,
                                                                           right_previousToolColList, rightToolName,
                                                                           leftToolName)
                    cteResults[toolId] = cteGenerated

                    for index, row in df.iterrows():
                        if row['ToolID'] == toolId:  # Check for a single ToolID match
                            df.at[index, 'ColumnsList'] = colListGenerated
                else:
                    joinDict = parentMap[parentMap['Origin_ToolID'].str.split('_').str[0] == toolId][
                        ['Origin_ToolID', 'Origin_Connection']]
                    for _, row in joinDict.iterrows():
                        join = row['Origin_Connection']
                        toolId = row['Origin_ToolID']
                        joinType = 'INNER JOIN' if join == 'Join' else 'RIGHT JOIN' if join == 'Right' else 'LEFT JOIN' if join == 'Left' else None
                        colListGenerated, cteGenerated = generate_cte_for_Join(properties, rightToolID, leftToolID,
                                                                               toolId, joinType,
                                                                               left_previousToolColList,
                                                                               right_previousToolColList, rightToolName,
                                                                               leftToolName)

                        newRow = pd.DataFrame({'ToolID': [toolId], 'Plugin': [pluginName], 'Properties': [properties],
                                               'ColumnsList': [[]], 'CTE': None, 'toolPluginName': ['Join']})
                        df = pd.concat([df, newRow], ignore_index=True)

                        cteResults[toolId] = cteGenerated

                        for index, row in df.iterrows():
                            if row['ToolID'] == toolId:  # Check for a single ToolID match
                                df.at[index, 'ColumnsList'] = colListGenerated



            elif pluginName == 'AlteryxBasePluginsGui.AppendFields.AppendFields':
                # Handle AppendFields
                sourceToolID = parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Source')][
                    'Origin_ToolID'].squeeze() if not parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Source')][
                    'Origin_ToolID'].empty else None
                sourceToolName = df[df['ToolID'] == sourceToolID]['toolPluginName'].tolist()[0]
                targetToolID = parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Targets')][
                    'Origin_ToolID'].squeeze() if not parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Targets')][
                    'Origin_ToolID'].empty else None
                targetToolName = df[df['ToolID'] == targetToolID]['toolPluginName'].tolist()[0]
                sourceToolColList = df[df['ToolID'] == sourceToolID]['ColumnsList'].tolist()[0]
                TargetToolColList = df[df['ToolID'] == targetToolID]['ColumnsList'].tolist()[0]
                colListGenerated, cteGenerated = generate_cte_for_AppendFields(properties, sourceToolID, targetToolID,
                                                                               toolId, sourceToolColList,
                                                                               TargetToolColList, sourceToolName,
                                                                               targetToolName)
                cteResults[toolId] = cteGenerated
                # Iterate through each row and update Columns based on ToolID
                for index, row in df.iterrows():
                    if row['ToolID'] == toolId:  # Check for a single ToolID match
                        df.at[index, 'ColumnsList'] = colListGenerated


            elif pluginName == 'LockInGui.LockInJoin.LockInJoin':
                rightToolID = parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Right')][
                    'Origin_ToolID'].squeeze() if not parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Right')][
                    'Origin_ToolID'].empty else None
                rightToolName = df[df['ToolID'] == rightToolID]['toolPluginName'].tolist()[0]
                leftToolID = parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Left')][
                    'Origin_ToolID'].squeeze() if not parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Left')][
                    'Origin_ToolID'].empty else None
                leftToolName = df[df['ToolID'] == leftToolID]['toolPluginName'].tolist()[0]

                left_previousToolColList = df[df['ToolID'] == leftToolID]['ColumnsList'].tolist()[0]
                right_previousToolColList = df[df['ToolID'] == rightToolID]['ColumnsList'].tolist()[0]

                colListGenerated, cteGenerated = generate_cte_for_LockInJoin(properties, rightToolID, leftToolID,
                                                                             toolId, left_previousToolColList,
                                                                             right_previousToolColList, rightToolName,
                                                                             leftToolName)
                cteResults[toolId] = cteGenerated

                for index, row in df.iterrows():
                    if row['ToolID'] == toolId:  # Check for a single ToolID match
                        df.at[index, 'ColumnsList'] = colListGenerated

            elif pluginName == 'AlteryxBasePluginsGui.Union.Union':
                unionList = parentMap[parentMap['Destination_ToolID'] == toolId][
                    'Origin_ToolID'].unique().tolist() if not parentMap[parentMap['Destination_ToolID'] == toolId][
                    'Origin_Connection'].empty else []
                unionItems = {}
                for item in unionList:
                    matched_row = df[df['ToolID'] == item]
                    if not matched_row.empty:
                        unionItems[item] = matched_row['ColumnsList'].values[0]

                colListGenerated, cteGenerated = generate_cte_for_Union(properties, unionItems, toolId, parentMap, df)
                cteResults[toolId] = cteGenerated

                # Iterate through each row and update Columns based on ToolID
                for index, row in df.iterrows():
                    if row['ToolID'] == toolId:  # Check for a single ToolID match
                        df.at[index, 'ColumnsList'] = colListGenerated

            elif pluginName == 'AlteryxBasePluginsGui.Unique.Unique':
                previousToolId = parentMap[parentMap['Destination_ToolID'] == toolId]['Origin_ToolID'].squeeze() if not \
                    parentMap[parentMap['Destination_ToolID'] == toolId]['Origin_ToolID'].empty else None
                previousToolName = df[df['ToolID'] == previousToolId]['toolPluginName'].tolist()[0]
                uniqueTypeList = parentMap[(parentMap['Origin_ToolID'].str.split('_').str[0] == toolId)][
                    'Origin_Connection'].unique().tolist() if not \
                    parentMap[(parentMap['Origin_ToolID'].str.split('_').str[0] == toolId)][
                        'Origin_Connection'].empty else []
                previousToolColList = df[df['ToolID'] == previousToolId]['ColumnsList'].tolist()[0]
                if len(uniqueTypeList) == 1:
                    uniqueType = uniqueTypeList[0]
                    colListGenerated, cteGenerated = generate_cte_for_Unique(properties, previousToolId, toolId,
                                                                             uniqueType, previousToolColList,
                                                                             previousToolName)
                    for index, row in df.iterrows():
                        if row['ToolID'] == toolId:  # Check for a single ToolID match
                            df.at[index, 'ColumnsList'] = colListGenerated

                    cteResults[toolId] = cteGenerated
                else:
                    uniqueDict = parentMap[parentMap['Origin_ToolID'].str.split('_').str[0] == toolId][
                        ['Origin_ToolID', 'Origin_Connection']]
                    for _, row in uniqueDict.iterrows():
                        uniqueType = row['Origin_Connection']
                        toolId = row['Origin_ToolID']
                        colListGenerated, cteGenerated = generate_cte_for_Unique(properties, previousToolId, toolId,
                                                                                 uniqueType, previousToolColList,
                                                                                 previousToolName)

                        newRow = pd.DataFrame({'ToolID': [toolId], 'Plugin': [pluginName], 'Properties': [properties],
                                               'ColumnsList': [colListGenerated], 'CTE': None,
                                               'toolPluginName': ['Unique']})
                        df = pd.concat([df, newRow], ignore_index=True)
                        cteResults[toolId] = cteGenerated

            elif pluginName == 'AlteryxBasePluginsGui.Filter.Filter':
                previousToolId = parentMap[parentMap['Destination_ToolID'] == toolId]['Origin_ToolID'].squeeze() if not \
                    parentMap[parentMap['Destination_ToolID'] == toolId]['Origin_ToolID'].empty else None
                previousToolName = df[df['ToolID'] == previousToolId]['toolPluginName'].tolist()[0]
                toolName = 'Filter'
                filterTypeList = parentMap[(parentMap['Origin_ToolID'].str.split('_').str[0] == toolId)][
                    'Origin_Connection'].unique().tolist() if not \
                    parentMap[(parentMap['Origin_ToolID'].str.split('_').str[0] == toolId)][
                        'Origin_Connection'].empty else []
                previousToolColList = df[df['ToolID'] == previousToolId]['ColumnsList'].tolist()[0]
                if len(filterTypeList) == 1:
                    filterType = filterTypeList[0]
                    colListGenerated, cteGenerated = generate_cte_for_Filter(properties, previousToolId, toolId,
                                                                             filterType, previousToolColList, toolName,
                                                                             previousToolName)
                    for index, row in df.iterrows():
                        if row['ToolID'] == toolId:  # Check for a single ToolID match
                            df.at[index, 'ColumnsList'] = colListGenerated

                    cteResults[toolId] = cteGenerated
                else:
                    filterDict = parentMap[parentMap['Origin_ToolID'].str.split('_').str[0] == toolId][
                        ['Origin_ToolID', 'Origin_Connection']]
                    for _, row in filterDict.iterrows():
                        filterType = row['Origin_Connection']
                        toolId = row['Origin_ToolID']
                        colListGenerated, cteGenerated = generate_cte_for_Filter(properties, previousToolId, toolId,
                                                                                 filterType, previousToolColList,
                                                                                 toolName, previousToolName)

                        newRow = pd.DataFrame({'ToolID': [toolId], 'Plugin': [pluginName], 'Properties': [properties],
                                               'ColumnsList': [colListGenerated], 'CTE': None,
                                               'toolPluginName': ['Filter']})
                        df = pd.concat([df, newRow], ignore_index=True)
                        cteResults[toolId] = cteGenerated






            elif pluginName == 'LockInGui.LockInFilter.LockInFilter':
                previousToolId = parentMap[parentMap['Destination_ToolID'] == toolId]['Origin_ToolID'].squeeze() if not \
                    parentMap[parentMap['Destination_ToolID'] == toolId]['Origin_ToolID'].empty else None
                previousToolName = df[df['ToolID'] == previousToolId]['toolPluginName'].tolist()[0]
                toolName = 'LockInFilter'
                filterTypeList = parentMap[(parentMap['Origin_ToolID'].str.split('_').str[0] == toolId)][
                    'Origin_Connection'].unique().tolist() if not \
                    parentMap[(parentMap['Origin_ToolID'].str.split('_').str[0] == toolId)][
                        'Origin_Connection'].empty else []
                previousToolColList = df[df['ToolID'] == previousToolId]['ColumnsList'].tolist()[0]
                if len(filterTypeList) == 1:
                    filterType = filterTypeList[0]
                    colListGenerated, cteGenerated = generate_cte_for_Filter(properties, previousToolId, toolId,
                                                                             filterType, previousToolColList, toolName,
                                                                             previousToolName)
                    for index, row in df.iterrows():
                        if row['ToolID'] == toolId:  # Check for a single ToolID match
                            df.at[index, 'ColumnsList'] = colListGenerated

                    cteResults[toolId] = cteGenerated
                else:
                    filterDict = parentMap[parentMap['Origin_ToolID'].str.split('_').str[0] == toolId][
                        ['Origin_ToolID', 'Origin_Connection']]
                    for _, row in filterDict.iterrows():
                        filterType = row['Origin_Connection']
                        toolId = row['Origin_ToolID']
                        colListGenerated, cteGenerated = generate_cte_for_Filter(properties, previousToolId, toolId,
                                                                                 filterType, previousToolColList,
                                                                                 toolName, previousToolName)

                        newRow = pd.DataFrame({'ToolID': [toolId], 'Plugin': [pluginName], 'Properties': [properties],
                                               'ColumnsList': [colListGenerated], 'CTE': None,
                                               'toolPluginName': ['LockInFilter']})
                        df = pd.concat([df, newRow], ignore_index=True)
                        cteResults[toolId] = cteGenerated


            elif pluginName == 'AlteryxBasePluginsGui.FindReplace.FindReplace':
                TargetsToolId = parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Targets')][
                    'Origin_ToolID'].squeeze()
                SourceToolId = parentMap[
                    (parentMap['Destination_ToolID'] == toolId) & (parentMap['Destination_Connection'] == 'Source')][
                    'Origin_ToolID'].squeeze()
                TargetsToolColList = df[df['ToolID'] == TargetsToolId]['ColumnsList'].tolist()[0]
                SourceToolColList = df[df['ToolID'] == SourceToolId]['ColumnsList'].tolist()[0]

                colListGenerated, cteGenerated = generate_cte_for_FindReplace(properties, toolId, TargetsToolId,
                                                                              TargetsToolColList, SourceToolId,
                                                                              SourceToolColList)
                for index, row in df.iterrows():
                    if row['ToolID'] == toolId:  # Check for a single ToolID match
                        df.at[index, 'ColumnsList'] = colListGenerated

                cteResults[toolId] = cteGenerated

            elif pluginName == 'AlteryxBasePluginsGui.JoinMultiple.JoinMultiple':

                joinMultipleDict = parentMap[parentMap['Destination_ToolID'] == toolId][
                    ['Origin_ToolID', 'Connection_Name']]
                # Remove the '#' and convert the column to int type
                joinMultipleDict['Order'] = joinMultipleDict['Connection_Name'].str.replace('#', '').astype(int)
                merged_df = pd.merge(joinMultipleDict, df[['ToolID', 'ColumnsList', 'toolPluginName']],
                                     left_on='Origin_ToolID',
                                     right_on='ToolID', how='inner')
                merged_df.drop(columns=['ToolID'], inplace=True)
                sorted_df = merged_df.sort_values(by='Order')

                colListGenerated, cteGenerated = generate_cte_for_JoinMultiple(properties, toolId, sorted_df)
                cteResults[toolId] = cteGenerated
                # Iterate through each row and update Columns based on ToolID
                for index, row in df.iterrows():
                    if row['ToolID'] == toolId:  # Check for a single ToolID match
                        df.at[index, 'ColumnsList'] = colListGenerated

            # else:
            #     'No function available for plugin ', pluginName, toolId

    df['CTE'] = df['ToolID'].map(cteResults)

    return df


def generate_cte_for_AlteryxSelect(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    # Parse the XML data
    root = ET.fromstring(xml_data)

    # Extract the select fields
    select_fields = root.find('.//Configuration/SelectFields')
    # List to store the fields to be selected
    selected_columns = []
    Selected_true_fields = {}
    Selected_false_fields = []
    current_tool_fields = []
    # Iterate through each SelectField
    for field in select_fields.findall('SelectField'):
        field_name = field.get('field')
        selected = field.get('selected')
        rename = field.get('rename')

        # If selected is True, add to selected columns list
        if selected == "True" and field_name.upper() != '*UNKNOWN':
            if rename is not None:
                Selected_true_fields[field_name] = rename
                # selected_columns.append(f'"{field_name}" AS "{rename}"')
            else:
                Selected_true_fields[field_name] = field_name
                # selected_columns.append(f'"{field_name}"')
        elif selected == 'False' and field_name.upper() != '*UNKNOWN':
            Selected_false_fields.append(field_name)
        elif (selected == "True" and field_name.upper() == '*UNKNOWN'):
            for field in prev_tool_fields:
                if (field not in Selected_false_fields and field not in Selected_true_fields.keys()):
                    selected_columns.append(f'"{field}"')
                    current_tool_fields.append(field)
                elif (field not in Selected_false_fields and field in Selected_true_fields.keys()):
                    if (Selected_true_fields[field] == field):
                        selected_columns.append(f'"{field}"')
                    else:
                        selected_columns.append(f'"{field}" AS "{Selected_true_fields[field]}"')
                    current_tool_fields.append(Selected_true_fields[field])
        elif (selected == "False" and field_name.upper() == '*UNKNOWN'):
            for k, v in Selected_true_fields.items():
                current_tool_fields.append(v)
                if (k == v):
                    selected_columns.append(f'"{k}"')
                else:
                    selected_columns.append(f'"{k}" AS "{v}"')

    # Generate the SQL CTE query string
    # Replace `YourTableName` with the actual table name in your context
    cte_query = f"""
        {toolName}_{toolId} AS (
            SELECT
                {', '.join(selected_columns)}
            FROM {previousToolName}_{previousToolId}  
        )
        """

    return current_tool_fields, cte_query


# Function to parse the XML and generate SQL CTE for GroupBy and Aggregation
def generate_cte_for_Summarize(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    # Extract SummarizeFields
    summarize_fields = root.find('.//Configuration/SummarizeFields')

    group_by_fields = []
    group_by_fields_before_rename = []
    aggregate_fields = []
    current_tool_fields = []

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

        current_tool_fields.append(f'{rename}')

    # Generate the SQL CTE query string
    cte_query = f"""
    {toolName}_{toolId} AS (
        SELECT
            {', '.join(group_by_fields)},  -- Group By Fields
            {', '.join(aggregate_fields)}  -- Aggregated Fields
        FROM {previousToolName}_{previousToolId}
        GROUP BY
            {', '.join(group_by_fields_before_rename)}  -- Group By Fields Before Rename
    )
    """

    return current_tool_fields, cte_query


def generate_cte_for_Rank(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    GroupFields = root.find('.//Configuration/GroupFields')
    SortInfo = root.find('.//Configuration/SortInfo')
    Mode = root.find('.//Configuration/Mode').get('value')

    group_by_fields = []
    current_tool_fields = []
    current_tool_fields.extend(prev_tool_fields)

    for field in GroupFields.findall('Field'):
        field_name = field.get('field')
        group_by_fields.append(f'"{field_name}"')

    orderDict = {}
    modifiedCompetitionRank = []
    for field in SortInfo.findall('Field'):
        field_name = field.get('field')
        order = field.get('order')
        order = 'ASC' if order == 'Ascending' else 'DESC' if order == 'Descending' else None

        orderDict[field_name] = order
        modifiedCompetitionRank.append(f"{field_name}")

    rankByQuery = ", ".join([f'"{key}" {value}' for key, value in orderDict.items()])

    if Mode == 'Standard':
        if not group_by_fields:
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT
                    {', '.join(prev_tool_fields)},
                    RANK() OVER(ORDER BY {rankByQuery}) AS "{Mode}Ranking"
                FROM {previousToolName}_{previousToolId}
            )
            """
        else:
            cte_query = f"""
                    {toolName}_{toolId} AS (
                        SELECT
                            {', '.join(prev_tool_fields)},
                            RANK() OVER(PARTITION BY {', '.join(group_by_fields)} ORDER BY {rankByQuery}) AS "{Mode}Ranking"
                        FROM {previousToolName}_{previousToolId}
                    )
                    """
        current_tool_fields.append(f'"{Mode}Ranking"')

    elif Mode == 'Ordinal':
        if not group_by_fields:
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT
                    {', '.join(prev_tool_fields)},
                    ROW_NUMBER() OVER(ORDER BY {rankByQuery}) AS "{Mode}Ranking"
                FROM {previousToolName}_{previousToolId}
            )
            """
        else:
            cte_query = f"""
                    {toolName}_{toolId} AS (
                        SELECT
                            {', '.join(prev_tool_fields)},
                            ROW_NUMBER() OVER(PARTITION BY {', '.join(group_by_fields)} ORDER BY {rankByQuery}) AS "{Mode}Ranking"
                        FROM {previousToolName}_{previousToolId}
                    )
                    """
        current_tool_fields.append(f'"{Mode}Ranking"')

    elif Mode == 'Dense':
        if not group_by_fields:
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT
                    {', '.join(prev_tool_fields)},
                    DENSE_RANK() OVER(ORDER BY {rankByQuery}) AS "{Mode}Ranking"
                FROM {previousToolName}_{previousToolId}
            )
            """
        else:
            cte_query = f"""
                    {toolName}_{toolId} AS (
                        SELECT
                            {', '.join(prev_tool_fields)},
                            DENSE_RANK() OVER(PARTITION BY {', '.join(group_by_fields)} ORDER BY {rankByQuery}) AS "{Mode}Ranking"
                        FROM {previousToolName}_{previousToolId}
                    )
                    """
        current_tool_fields.append(f'"{Mode}Ranking"')

    elif Mode == 'Competition':
        if not group_by_fields:
            cte_query = f"""
                {toolName}_{toolId} AS (
                    SELECT {', '.join(prev_tool_fields)},
                    LAST_VALUE(ROWNUMMCR) OVER (PARTITION BY {', '.join(modifiedCompetitionRank)} ORDER BY ROWNUMMCR) AS "ModifiedCompetitionRanking"
                    FROM(
                        SELECT
                            {', '.join(prev_tool_fields)},
                            ROW_NUMBER() OVER (ORDER BY {rankByQuery}) AS ROWNUMMCR
                        FROM {previousToolName}_{previousToolId}
                        )
                )
                """
        else:
            cte_query = f"""
                    {toolName}_{toolId} AS (
                        SELECT {', '.join(prev_tool_fields)},
                        LAST_VALUE(ROWNUMMCR) OVER (PARTITION BY {', '.join(modifiedCompetitionRank)} ORDER BY ROWNUMMCR) AS "ModifiedCompetitionRanking"
                        FROM(
                            SELECT
                                {', '.join(prev_tool_fields)},
                                ROW_NUMBER() OVER (PARTITION BY {', '.join(group_by_fields)} ORDER BY {rankByQuery}) AS ROWNUMMCR
                            FROM {previousToolName}_{previousToolId}
                            )
                    )
                    """
        current_tool_fields.append(f'"ModifiedCompetitionRanking"')

    elif Mode == 'Fractional':
        if not group_by_fields:
            cte_query = f"""
                {toolName}_{toolId} AS (
                    SELECT {', '.join(prev_tool_fields)},
                    CAST((FIRST_VALUE(ROWNUMFR) OVER (PARTITION BY {', '.join(modifiedCompetitionRank)} ORDER BY ROWNUMFR) + LAST_VALUE(ROWNUMFR) OVER (PARTITION BY {', '.join(modifiedCompetitionRank)} ORDER BY ROWNUMFR))/2 as float) AS "FractionalRanking"
                    FROM(
                        SELECT
                            {', '.join(prev_tool_fields)},
                            ROW_NUMBER() OVER (ORDER BY {rankByQuery}) AS ROWNUMFR
                        FROM {previousToolName}_{previousToolId}
                        )
                )
                """
        else:
            cte_query = f"""
                    {toolName}_{toolId} AS (
                    SELECT {', '.join(prev_tool_fields)},
                        CAST((FIRST_VALUE(ROWNUMFR) OVER (PARTITION BY {', '.join(modifiedCompetitionRank)} ORDER BY ROWNUMFR) + LAST_VALUE(ROWNUMFR) OVER (PARTITION BY {', '.join(modifiedCompetitionRank)} ORDER BY ROWNUMFR))/2 as float) AS "FractionalRanking"
                        FROM(
                            SELECT
                                {', '.join(prev_tool_fields)},
                                ROW_NUMBER() OVER (PARTITION BY {', '.join(group_by_fields)} ORDER BY {rankByQuery}) AS ROWNUMFR
                            FROM {previousToolName}_{previousToolId}
                            )
                        )
                        """
        current_tool_fields.append(f'"FractionalRanking"')

    return current_tool_fields, cte_query


def generate_cte_for_MultiFieldBinning(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    binningColumns = root.find(".//Value[@name='List Box (297)']").text.strip()
    equalRecord = root.find(".//Value[@name='Radio Button (299)']").text.strip()
    equalRecordTileCount = root.find(".//Value[@name='Numeric Up Down (298)']").text.strip()
    equalInterval = root.find(".//Value[@name='Radio Button (301)']").text.strip()
    equalIntervalTileCount = root.find(".//Value[@name='Numeric Up Down (300)']").text.strip()

    current_tool_fields = []
    current_tool_fields.extend(prev_tool_fields)

    # Split the string by commas to separate the key-value pairs
    binningColumnsList = binningColumns.split(',')

    # Initialize an empty list to store keys with True values
    binningColumnsListTrue = []

    # Loop through each pair, split it by the '=' character, and check if the value is True
    for pair in binningColumnsList:
        key, value = pair.split('=')
        if value == 'True':
            binningColumnsListTrue.append(key)

    if equalRecord == 'True':
        NtileCols = []

        # Add NTILE for each value in binningColumnsListTrue list
        for col in binningColumnsListTrue:
            NtileCols.append(f"""NTILE({equalRecordTileCount}) OVER (ORDER BY "{col}" DESC) AS "{col}_Tile_Num" """)
            current_tool_fields.append(f"{col}_Tile_Num")

        cte_query = f"""
        {toolName}_{toolId} AS (
            SELECT
                {', '.join(prev_tool_fields)},
                {'\n, '.join(NtileCols)}
            FROM {previousToolName}_{previousToolId}
        )
        """

    elif equalInterval == 'True':
        for col in binningColumnsListTrue:
            current_tool_fields.append(f"{col}_Tile_Num")

        # Initialize the SQL query string
        query = f"WITH BinningRangeData AS (\n"

        # Generate the MIN and MAX expressions for each column dynamically
        for col in binningColumnsListTrue:
            query += f"""  SELECT MIN("{col}") AS "min_value_{col}", MAX("{col}") AS "max_value_{col}",\n"""

        # Remove the trailing comma from the last column MIN/MAX expression
        query = query.rstrip(",\n") + "\n"
        query += f"FROM {previousToolName}_{previousToolId}\n)"

        # Add the SELECT statement and bin calculation logic for each column
        query += f"""\nSELECT\n {', '.join(prev_tool_fields)},"""

        for col in binningColumnsListTrue:
            query += f"""
            CASE
                WHEN "{col}" = "max_value_{col}" THEN {equalIntervalTileCount}
                ELSE FLOOR(("{col}" - "min_value_{col}") / (("max_value_{col}" - "min_value_{col}") / {equalIntervalTileCount})) + 1
            END AS "{col}_Tile_Num",\n"""

        # Remove the trailing comma from the last bin_number column
        query = query.rstrip(",\n") + "\n"
        query += f"FROM {previousToolName}_{previousToolId}, BinningRangeData\n"

        cte_query = f"""
        {toolName}_{toolId} AS (
            {query}
        )
        """

    return current_tool_fields, cte_query


def generate_cte_for_RandomRecords(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    Number = root.find(".//Value[@name='Number']").text.strip()
    NNumber = int(root.find(".//Value[@name='NNumber']").text.strip())
    Percent = root.find(".//Value[@name='Percent']").text.strip()
    NPercent = int(root.find(".//Value[@name='NPercent']").text.strip())
    Deterministic = root.find(".//Value[@name='Deterministic']").text.strip()
    Seed = int(root.find(".//Value[@name='Seed']").text.strip())

    current_tool_fields = []
    current_tool_fields.extend(prev_tool_fields)

    if Percent == 'True':
        if Deterministic == 'False':
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT
                    {', '.join(prev_tool_fields)}
                FROM {previousToolName}_{previousToolId}
                SAMPLE({NPercent})

            )
            """
        elif Deterministic == 'True':
            NpercentSeed = NPercent / 100
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT
                    {', '.join(prev_tool_fields)}
                FROM {previousToolName}_{previousToolId}
                WHERE RANDOM({Seed}) <= {NpercentSeed}

            )
            """

    elif Number == 'True':
        if Deterministic == 'False':
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT
                    {', '.join(prev_tool_fields)}
                FROM {previousToolName}_{previousToolId}
                ORDER BY RANDOM()
                LIMIT {NNumber}
            )
            """
        elif Deterministic == 'True':
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT
                    {', '.join(prev_tool_fields)}
                FROM {previousToolName}_{previousToolId}
                ORDER BY RANDOM({Seed})
                LIMIT {NNumber}
            )
            """

    return current_tool_fields, cte_query


def generate_cte_for_CountRecords(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    current_tool_fields = ['Count']

    # Generate the SQL CTE query string
    cte_query = f"""
    {toolName}_{toolId} AS (
        SELECT
            COUNT(*) AS "Count"
        FROM {previousToolName}_{previousToolId}
        )
    """

    return current_tool_fields, cte_query


def generate_cte_for_LockInJoin(xml_data, rightToolID, leftToolID, toolId, left_prev_tool_fields,
                                right_prev_tool_fields, rightToolName, leftToolName):
    root = ET.fromstring(xml_data)

    JoinMode = root.find(".//JoinMode").text
    joinType = 'INNER JOIN' if JoinMode == 'INNER' else 'FULL OUTER JOIN' if JoinMode == 'FULL' else 'LEFT JOIN' if JoinMode == 'LEFT' else 'RIGHT JOIN' if JoinMode == 'RIGHT' else 'UNKNOWN JOIN'

    # Extract JoinInfo for left and right
    left_join_info = root.find('.//Configuration//JoinInfo[@connection="Left"]')
    right_join_info = root.find('.//Configuration//JoinInfo[@connection="Right"]')

    leftJoinFields = []
    for field in left_join_info.findall('Field'):
        field_name = field.get('field')
        leftJoinFields.append(f'"{field_name}"')
    rightJoinFields = []
    for field in right_join_info.findall('Field'):
        field_name = field.get('field')
        rightJoinFields.append(f'"{field_name}"')

    joinCondition = ' AND '.join(
        [f"LeftTable.{left} = RightTable.{right}" for left, right in zip(leftJoinFields, rightJoinFields)])

    cte_query = f"""
                LockInJoin_{toolId} AS (
                    SELECT
                    {', '.join([f"LeftTable.{left}" for left in left_prev_tool_fields])}
                    {', '.join([f"RightTable.{right}" for right in right_prev_tool_fields])}
                    FROM {leftToolName}_{leftToolID} AS LeftTable
                    {joinType} {rightToolName}_{rightToolID} AS RightTable
                    ON {joinCondition}
                    )
                """

    current_tool_fields = []

    return current_tool_fields, cte_query


def generate_cte_for_Join(xml_data, rightToolID, leftToolID, toolId, joinType, left_prev_tool_fields,
                          right_prev_tool_fields, rightToolName, leftToolName):
    root = ET.fromstring(xml_data)

    # Extract JoinInfo for left and right
    left_join_info = root.find('.//Configuration//JoinInfo[@connection="Left"]')
    right_join_info = root.find('.//Configuration//JoinInfo[@connection="Right"]')

    leftJoinFields = []
    for field in left_join_info.findall('Field'):
        field_name = field.get('field')
        leftJoinFields.append(f'"{field_name}"')
    rightJoinFields = []
    for field in right_join_info.findall('Field'):
        field_name = field.get('field')
        rightJoinFields.append(f'"{field_name}"')

    joinCondition = ' AND '.join(
        [f"LeftTable.{left} = RightTable.{right}" for left, right in zip(leftJoinFields, rightJoinFields)])

    # Extract SelectFields for the selected fields
    select_fields = root.findall('.//SelectConfiguration//SelectFields//SelectField')

    # Collecting selected fields for SELECT statement
    left_fields = []
    right_fields = []

    Selected_right_true_fields = {}
    Selected_left_true_fields = {}

    Selected_right_false_fields = []
    Selected_left_false_fields = []

    current_tool_fields = []

    left_prev_tool_fields_with_ref = ['LeftTable."' + i + '"' for i in left_prev_tool_fields]
    right_prev_tool_fields_with_ref = ['RightTable."' + i + '"' for i in right_prev_tool_fields]

    for field in select_fields:
        field_name = field.get('field')
        selected = field.get('selected')
        selected_rename = field.get('rename')
        # selected_input = field.get('input')
        selected_input = ""
        if (field.find('input') is not None):
            selected_input = field.get('input')
        if selected_input == '':
            if (field_name[:5].upper() == "LEFT_"):
                selected_input = "Left_"
            elif (field_name[:6].upper() == "RIGHT_"):
                selected_input = "Right_"
        if (selected == 'True' and field_name.upper() != '*UNKNOWN'):
            if (selected_rename is not None and selected_input == 'Left_'):
                Selected_left_true_fields[field_name[5:]] = selected_rename
            elif (selected_rename is None and selected_input == 'Left_'):
                Selected_left_true_fields[field_name[5:]] = field_name[5:]
            elif (selected_rename is not None and selected_input == 'Right_'):
                Selected_right_true_fields[field_name[6:]] = selected_rename
            elif (selected_rename is None and selected_input == 'Right_'):
                Selected_right_true_fields[field_name[6:]] = field_name[6:]
        elif selected == 'False' and field_name.upper() != '*UNKNOWN':
            if (selected_input == 'Left_'):
                Selected_left_false_fields.append(field_name[5:])
            elif (selected_input == 'Right_'):
                Selected_right_false_fields.append(field_name[6:])
        elif (selected == "True" and field_name.upper() == '*UNKNOWN'):
            for field in left_prev_tool_fields:
                if (field not in Selected_left_false_fields and field not in Selected_left_true_fields.keys()):
                    left_fields.append(f'LeftTable."{field}"')
                    current_tool_fields.append(field)
                elif (field not in Selected_left_false_fields and field in Selected_left_true_fields.keys()):
                    if (Selected_left_true_fields[field] == field):
                        left_fields.append(f'LeftTable."{field}"')
                    else:
                        left_fields.append(f'LeftTable."{field}" AS "{Selected_left_true_fields[field]}"')
                    current_tool_fields.append(Selected_left_true_fields[field])
            for field in right_prev_tool_fields:
                if (field not in Selected_right_false_fields and field not in Selected_right_true_fields.keys()):
                    right_fields.append(f'RightTable."{field}"')
                    current_tool_fields.append(field)
                elif (field not in Selected_right_false_fields and field in Selected_right_true_fields.keys()):
                    if (Selected_right_true_fields[field] == field):
                        right_fields.append(f'RightTable."{field}"')
                    else:
                        right_fields.append(f'RightTable."{field}" AS "{Selected_right_true_fields[field]}"')
                    current_tool_fields.append(Selected_right_true_fields[field])
        elif (selected == "False" and field_name.upper() == '*UNKNOWN'):
            for k, v in Selected_left_true_fields.items():
                current_tool_fields.append(v)
                if (k == v):
                    left_fields.append(f'LeftTable."{k}"')
                else:
                    left_fields.append(f'LeftTable."{k}" AS "{v}"')
            for k, v in Selected_right_true_fields.items():
                current_tool_fields.append(v)
                if (k == v):
                    right_fields.append(f'RightTable."{k}"')
                else:
                    right_fields.append(f'RightTable."{k}" AS "{v}"')

        # if field_name.startswith("Left_") and selected:
        #     left_fields.append(f'LeftTable."{field_name}"')
        # elif field_name.startswith("Right_") and selected:
        #     right_fields.append(f'RightTable."{field_name}"')

    # Join condition between left and right tables
    join_field_left = left_join_info.find('Field').get('field')
    join_field_right = right_join_info.find('Field').get('field')

    if joinType == 'LEFT JOIN':
        cte_query = f"""
            Join_{toolId} AS (
                SELECT
                    {', '.join(left_prev_tool_fields_with_ref)}  -- Left Selected Fields

                FROM {leftToolName}_{leftToolID} AS LeftTable
                {joinType} {rightToolName}_{rightToolID} AS RightTable
                ON {joinCondition}
                WHERE RightTable."{join_field_right}" IS NULL
            )
            """
    elif joinType == 'RIGHT JOIN':
        cte_query = f"""
            Join_{toolId} AS (
                SELECT

                    {', '.join(right_prev_tool_fields_with_ref)}  -- Right Selected Fields
                FROM {leftToolName}_{leftToolID} AS LeftTable
                {joinType} {rightToolName}_{rightToolID} AS RightTable
                ON {joinCondition}
                WHERE LeftTable."{join_field_right}" IS NULL
            )
            """
    elif joinType == 'INNER JOIN':
        cte_query = f"""
        Join_{toolId} AS (
            SELECT
                {', '.join(left_fields)},  -- Left Selected Fields
                {', '.join(right_fields)}  -- Right Selected Fields
            FROM {leftToolName}_{leftToolID} AS LeftTable
            {joinType} {rightToolName}_{rightToolID} AS RightTable
            ON {joinCondition}
        )
        """
    if joinType == 'LEFT JOIN':
        return left_prev_tool_fields, cte_query
    elif joinType == 'RIGHT JOIN':
        return right_prev_tool_fields, cte_query
    return current_tool_fields, cte_query


def generate_cte_for_Union(xml_data, unionItems, toolId, parentMap, df):
    root = ET.fromstring(xml_data)

    mode = root.find(".//Mode").text
    OutputMode = root.find(".//ByName_OutputMode").text

    if mode == 'ByName' and OutputMode == 'All':
        # Step 1: Initialize an empty list to hold all columns, ensuring unique columns only
        all_columns = []

        # Iterate through each table's columns and add them to the list
        for columns in unionItems.values():
            for col in columns:
                if col not in all_columns:
                    all_columns.append(col)  # Add column only if it's not already in the list

        # Initialize an empty list to hold the SQL parts
        sql_parts = []

        # Iterate over the dictionary and generate SELECT queries for each table
        for table, columns in unionItems.items():
            select_columns = []
            toolName = df[df['ToolID'] == table]['toolPluginName'].tolist()[0]
            # Align the columns with the full column set and fill missing columns with NULL
            for col in all_columns:
                if col in columns:
                    select_columns.append(f'"{col}"')  # If column exists in table, use it
                else:
                    select_columns.append(f'NULL AS "{col}"')  # Fill missing column with NULL

            # Step 6: Generate the SQL for this table
            sql_parts.append(f"SELECT {', '.join(select_columns)} FROM {toolName}_{table}")

        # Join the individual SELECT queries with UNION ALL to combine the results
        final_sql = "\n UNION ALL\n".join(sql_parts)

    elif mode == 'ByName' and OutputMode == 'Subset':
        # Step 1: Identify the common columns between all tables
        all_columns = set(unionItems[list(unionItems.keys())[0]])  # Start with the first table's columns
        for columns in unionItems.values():
            all_columns.intersection_update(columns)  # Keep only the common columns

        common_columns = list(all_columns)  # Convert to a list for ordered column selection

        # Step 2: Initialize an empty list to hold the SQL parts
        sql_parts = []

        # Step 3: Iterate over the dictionary and generate SELECT queries for each table
        for table, columns in unionItems.items():
            select_columns = []
            toolName = df[df['ToolID'] == table]['toolPluginName'].tolist()[0]
            # Step 4: For each common column, check if it exists in the table
            for col in common_columns:
                if col in columns:
                    select_columns.append(f'"{col}"')  # If the column exists in this table, use it
                else:
                    select_columns.append(f'NULL AS "{col}"')  # Otherwise, add NULL with the column name

            # Step 5: Generate the SQL for this table
            sql_parts.append(f"SELECT {', '.join(select_columns)} FROM {toolName}_{table}")

        # Step 6: Join the individual SELECT queries with UNION ALL
        final_sql = "\n UNION ALL \n".join(sql_parts)

    elif mode == 'ByPos' and OutputMode == 'All':
        # Step 1: Find the maximum number of columns among all tables
        max_columns = max(len(columns) for columns in unionItems.values())

        # Initialize the list to hold the SQL SELECT parts for each table
        sql_parts = []

        # Step 2: Loop through each table in the dictionary
        for table_name, columns in unionItems.items():
            table_select = []
            toolName = df[df['ToolID'] == table_name]['toolPluginName'].tolist()[0]
            # Step 3: For each column position, check if the table has it
            for i in range(max_columns):
                if i < len(columns):
                    # If the table has the column at this position, include it
                    table_select.append(f'"{columns[i]}"')
                else:
                    # Otherwise, fill with NULL for missing columns
                    table_select.append("NULL")

            # Step 4: Generate SQL for this table
            sql_parts.append(f"SELECT {', '.join(table_select)} FROM {toolName}_{table_name}")

        # Step 5: Combine all the SELECT queries using UNION
        final_sql_ = "\nUNION ALL\n".join(sql_parts)

        # Create an empty list to store the final columns
        all_columns = []

        for i in range(max_columns):
            for table_name, columns in unionItems.items():
                if i < len(columns):  # If the table has a column for this position
                    all_columns.append(columns[i])
                    break

        sql_statement = ", ".join([f"${i + 1} AS {col}" for i, col in enumerate(all_columns)])
        final_sql = f"SELECT {sql_statement} FROM ({final_sql_})"


    elif mode == 'ByPos' and OutputMode == 'Subset':
        # Step 1: Find the maximum number of columns among all tables
        min_columns = min(len(columns) for columns in unionItems.values())

        # Initialize the list to hold the SQL SELECT parts for each table
        sql_parts = []

        # Step 2: Loop through each table in the dictionary
        for table_name, columns in unionItems.items():
            table_select = []
            toolName = df[df['ToolID'] == table_name]['toolPluginName'].tolist()[0]
            # Step 3: For each column position, check if the table has it
            for i in range(min_columns):
                table_select.append(f'"{columns[i]}"')

            # Step 4: Generate SQL for this table
            sql_parts.append(f"SELECT {', '.join(table_select)} FROM {toolName}_{table_name}")

        # Step 5: Combine all the SELECT queries using UNION
        final_sql_ = "\nUNION ALL\n".join(sql_parts)

        # Create an empty list to store the final columns
        all_columns = []

        for i in range(min_columns):
            for table_name, columns in unionItems.items():
                all_columns.append(columns[i])
                break

        sql_statement = ", ".join([f"${i + 1} AS {col}" for i, col in enumerate(all_columns)])
        final_sql = f"SELECT {sql_statement} FROM ({final_sql_})"


    elif mode == 'Manual' and OutputMode == 'All':
        # Initialize an empty list to hold all SQL queries
        sql_queries = []

        # Iterate over all MetaInfo blocks
        for meta_info in root.findall(".//MetaInfo"):
            # Extract the MetaInfo name (e.g., #1, #4)
            meta_name = meta_info.get('name')

            # Extract the field names
            fields = [f'"{field.get('name')}"' for field in meta_info.findall(".//Field")]

            # Fetch the corresponding row from the DataFrame based on the meta_name (connection_name)
            connection_row = \
                parentMap[
                    (parentMap['Connection_Name'] == meta_name) & (parentMap['Destination_ToolID'] == toolId)].iloc[0]

            # Get origin and destination from the DataFrame
            origin = connection_row['Origin_ToolID']
            toolName = df[df['ToolID'] == origin]['toolPluginName'].tolist()[0]

            # Construct the SELECT statement for the current MetaInfo
            sql_query = f"SELECT {', '.join(fields)} FROM {toolName}_{origin}"

            # Add the SQL query to the list
            sql_queries.append(sql_query)

        final_sql = "\nUNION ALL\n".join(sql_queries)

        # Dynamically find the first MetaInfo element
        first_meta_info = root.find(".//MetaInfo")

        # Extract field names from the first MetaInfo dynamically
        all_columns = [field.get("name") for field in first_meta_info.findall(".//Field")]

    cte_query = f"""
    Union_{toolId} AS (
        {final_sql}
    )
    """

    return all_columns, cte_query


def get_input_field_name_join_multiple(field_name):
    connection = ""
    if (field_name.count('_') >= 2):
        first_index = field_name.index('_')
        second_index = field_name.index('_', first_index + 1)
        connection = field_name[first_index + 1:second_index]
        field_name = field_name[second_index + 1:]
    return connection, field_name


def generate_cte_for_JoinMultiple(xml_data, toolId, sorted_df):
    # Parse the XML data
    root = ET.fromstring(xml_data)

    JoinByRecPos = root.find('.//Configuration/JoinByRecPos').get('value')
    OutputJoinOnly = root.find('.//Configuration/OutputJoinOnly').get('value')
    current_tool_fields = []
    if JoinByRecPos == 'False':
        # Initialize an empty dictionary
        joinconnection_dict = {}

        JoinFields = root.find('.//Configuration/JoinFields')
        # Iterate through each JoinInfo element
        for join_info in JoinFields.findall('JoinInfo'):
            # Extract connection attribute value
            joinconnection = join_info.get('connection')

            # Extract the field values inside this JoinInfo
            fields = [field.attrib['field'] for field in join_info.findall('Field')]

            # Populate the dictionary
            joinconnection_dict[joinconnection] = fields

        joinConnectionDF = pd.DataFrame(list(joinconnection_dict.items()), columns=['Connection_Name', 'joincolumns'])
        joinConnectionDFFinal = pd.merge(sorted_df, joinConnectionDF, on='Connection_Name', how='inner')

        connection_field_dict = {}
        only_true_fields = {}
        for _, row in joinConnectionDFFinal.iterrows():
            connection_field_dict[row["Connection_Name"]] = row["ColumnsList"].copy()
            only_true_fields[row["Connection_Name"]] = []

        select_fields = root.findall('.//SelectConfiguration//SelectFields//SelectField')
        final_fields = []

        for field in select_fields:
            field_name = field.get('field')
            selected = field.get('selected')
            selected_rename = field.get('rename')

            if (selected == 'True' and field_name.upper() != '*UNKNOWN'):
                connection_number, field_name = get_input_field_name_join_multiple(field_name)
                if (connection_number in connection_field_dict.keys()):
                    if (selected_rename is not None):
                        for i in range(len(connection_field_dict[connection_number])):
                            if (connection_field_dict[connection_number][i] == field_name):
                                connection_field_dict[connection_number][i] = field_name + ' AS ' + selected_rename
                        only_true_fields[connection_number].append(field_name + ' AS ' + selected_rename)
                    else:
                        only_true_fields[connection_number].append(field_name)
            elif (selected == 'False' and field_name.upper() != '*UNKNOWN'):
                connection_number, field_name = get_input_field_name_join_multiple(field_name)
                if (connection_number in connection_field_dict.keys()):
                    if (field_name in connection_field_dict[connection_number]):
                        connection_field_dict[connection_number].remove(field_name)
            if (field_name.upper() == '*UNKNOWN'):
                if (selected == 'True'):
                    for connection_number, field_list in connection_field_dict.items():
                        connection_number_tool_id_list = \
                        joinConnectionDFFinal[joinConnectionDFFinal["Connection_Name"] == connection_number][
                            "Origin_ToolID"].tolist()
                        origin_tool_name_list = joinConnectionDFFinal[joinConnectionDFFinal["Connection_Name"] == connection_number][
                            "toolPluginName"].tolist()
                        connection_number_tool_id = ""
                        origin_tool_name = ""
                        if (len(connection_number_tool_id_list) > 0):
                            connection_number_tool_id = connection_number_tool_id_list[0]
                            origin_tool_name = origin_tool_name_list[0]
                        for field in field_list:
                            if (' AS ' in field):
                                final_fields.append(
                                    origin_tool_name + '_' + connection_number_tool_id + '."' + field.split(' AS ')[0] + '" AS "' +
                                    field.split(' AS ')[1] + '"')
                                current_tool_fields.append(field.split(' AS ')[1])
                            else:
                                final_fields.append(origin_tool_name + '_' + connection_number_tool_id + '."' + field + '"')
                                current_tool_fields.append(field)
                elif (selected == 'False'):
                    for connection_number, field_list in only_true_fields.items():
                        connection_number_tool_id_list = \
                        joinConnectionDFFinal[joinConnectionDFFinal["Connection_Name"] == connection_number][
                            "Origin_ToolID"].tolist()
                        origin_tool_name_list = joinConnectionDFFinal[joinConnectionDFFinal["Connection_Name"] == connection_number][
                            "toolPluginName"].tolist()
                        connection_number_tool_id = ""
                        origin_tool_name = ""
                        if (len(connection_number_tool_id_list) > 0):
                            connection_number_tool_id = connection_number_tool_id_list[0]
                            origin_tool_name = origin_tool_name_list[0]
                        for field in field_list:
                            if (' AS ' in field):
                                final_fields.append(
                                    origin_tool_name + '_' + connection_number_tool_id + '."' + field.split(' AS ')[0] + '" AS "' +
                                    field.split(' AS ')[1] + '"')
                                current_tool_fields.append(field.split(' AS ')[1])
                            else:
                                final_fields.append(origin_tool_name + '_' + connection_number_tool_id + '."' + field + '"')
                                current_tool_fields.append(field)

        if OutputJoinOnly == 'False':
            # Start the SQL query with the first table
            if (len(final_fields) > 0):
                sql_query = f"SELECT {', '.join(final_fields)}\nFROM {joinConnectionDFFinal.iloc[0]['toolPluginName']}_{joinConnectionDFFinal.iloc[0]['Origin_ToolID']}\n"
            else:
                sql_query = f"SELECT *\nFROM {joinConnectionDFFinal.iloc[0]['toolPluginName']}_{joinConnectionDFFinal.iloc[0]['Origin_ToolID']}\n"
            # Iterate over the other tables and add FULL OUTER JOINs
            for i in range(1, len(joinConnectionDFFinal)):
                table1 = joinConnectionDFFinal.iloc[i - 1]
                table2 = joinConnectionDFFinal.iloc[i]

                # Creating the ON condition for the join
                join_conditions = " AND ".join(
                    [
                        f'{table1['toolPluginName']}_{table1['Origin_ToolID']}."{join_col1}" = {table2['toolPluginName']}_{table2['Origin_ToolID']}."{join_col2}"'
                        for join_col1, join_col2 in
                        zip(table1['joincolumns'], table2['joincolumns'])])

                # Append the FULL OUTER JOIN clause
                sql_query += f"\nFULL OUTER JOIN {table2['toolPluginName']}_{table2['Origin_ToolID']} ON {join_conditions}\n"


        elif OutputJoinOnly == 'True':
            # Start the SQL query with the first table
            if (len(final_fields) > 0):
                sql_query = f"SELECT {', '.join(final_fields)}\nFROM {joinConnectionDFFinal.iloc[0]['toolPluginName']}_{joinConnectionDFFinal.iloc[0]['Origin_ToolID']}\n"
            else:
                sql_query = f"SELECT *\nFROM {joinConnectionDFFinal.iloc[0]['toolPluginName']}_{joinConnectionDFFinal.iloc[0]['Origin_ToolID']}\n"
            # Iterate over the other tables and add FULL OUTER JOINs
            for i in range(1, len(joinConnectionDFFinal)):
                table1 = joinConnectionDFFinal.iloc[i - 1]
                table2 = joinConnectionDFFinal.iloc[i]

                # Creating the ON condition for the join
                join_conditions = " AND ".join(
                    [
                        f'{table1['toolPluginName']}_{table1['Origin_ToolID']}."{join_col1}" = {table2['toolPluginName']}_{table2['Origin_ToolID']}."{join_col2}"'
                        for join_col1, join_col2 in
                        zip(table1['joincolumns'], table2['joincolumns'])])

                # Append the FULL OUTER JOIN clause
                sql_query += f"\nINNER JOIN {table2['toolPluginName']}_{table2['Origin_ToolID']} ON {join_conditions}\n"

        cte_query = f"""
                JoinMultiple_{toolId} AS (
                {sql_query}
                )
                """
    elif JoinByRecPos == 'True':
        cte_query = ''

    return current_tool_fields, cte_query


def generate_cte_for_Sort(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    sort_fields = root.find('.//Configuration/SortInfo')

    orderDict = {}

    for field in sort_fields.findall('Field'):
        field_name = field.get('field')
        order = field.get('order')
        order = 'ASC' if order == 'Ascending' else 'DESC' if order == 'Descending' else None

        orderDict[field_name] = order

    orderByQuery = ", ".join([f'"{key}" {value}' for key, value in orderDict.items()])

    cte_query = f"""
    {toolName}_{toolId} AS (
        SELECT
            {', '.join(prev_tool_fields)}
        FROM {previousToolName}_{previousToolId}
        ORDER BY
            {orderByQuery}
    )
    """

    return prev_tool_fields, cte_query


def generate_cte_for_LockInStreamOut(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    sort_fields = root.find('.//Configuration/Sort/SortInfo')
    sortFlag = root.find('.//Configuration/Sort').get('value')

    if sortFlag == 'True':
        orderDict = {}

        for field in sort_fields.findall('Field'):
            field_name = field.get('field')
            order = field.get('order')
            order = 'ASC' if order == 'Ascending' else 'DESC' if order == 'Descending' else None

            orderDict[field_name] = order

        orderByQuery = ", ".join([f'"{key}" {value}' for key, value in orderDict.items()])

        cte_query = f"""
        {toolName}_{toolId} AS (
            SELECT
                {', '.join(prev_tool_fields)}
            FROM {previousToolName}_{previousToolId}
            ORDER BY
                {orderByQuery}
        )
        """
    elif sortFlag == 'False':
        cte_query = f"""
                {toolName}_{toolId} AS (
                    SELECT
                        {', '.join(prev_tool_fields)}
                    FROM {previousToolName}_{previousToolId}
                )
                """

    return prev_tool_fields, cte_query


def generate_cte_for_Unique(xml_data, previousToolId, toolId, uniqueType, prev_tool_fields, previousToolName):
    root = ET.fromstring(xml_data)

    # Extract SummarizeFields
    uniquefields = root.find('.//Configuration/UniqueFields')

    unique_check_fields = []

    for field in uniquefields.findall('Field'):
        field_name = field.get('field')
        unique_check_fields.append(f'"{field_name}"')

    if uniqueType == 'Unique':
        cte_query = f"""
        Unique_{toolId} AS (
            SELECT DISTINCT
                {', '.join(prev_tool_fields)}
            FROM {previousToolName}_{previousToolId}
        )
        """

    elif uniqueType == 'Duplicates':
        cte_query = f"""
        Unique_{toolId} AS (
            SELECT DISTINCT
                {', '.join(prev_tool_fields)} 
            FROM {previousToolName}_{previousToolId}
           QUALIFY DENSE_RANK() OVER (PARTITION BY {', '.join(unique_check_fields)}) > 1
        )
        """

    return prev_tool_fields, cte_query


def generate_cte_for_WeightedAvg(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    # Extracting the values for each field
    Value = root.find(".//Value[@name='Value']").text
    Weight = root.find(".//Value[@name='Weight']").text
    OutputFieldName = root.find(".//Value[@name='OutputFieldName']").text
    GroupFields = root.find(".//Value[@name='GroupFields']").text
    group_by_fields = []
    current_tool_fields = []

    if GroupFields is not None:
        # Parse the string as XML
        xml_data2 = f"""<Properties><SummarizeField field="{GroupFields}" action="GroupBy"/></Properties>"""
        root2 = ET.fromstring(xml_data2)

        # Extracting the values for each field
        for field in root2.findall('.//SummarizeField'):
            field_name = field.get('field')
            group_by_fields.append(f'"{field_name}"')

    # Generate the SQL CTE query string
    if not GroupFields:
        cte_query = f"""
        {toolName}_{toolId} AS (
            SELECT
            SUM("{Value}" * "{Weight}") / SUM("{Weight}") AS "{OutputFieldName}"
            FROM {previousToolName}_{previousToolId}
            )
        """
        current_tool_fields.append(f'"{OutputFieldName}"')

    else:
        cte_query = f"""
                {toolName}_{toolId} AS (
                    SELECT {', '.join(group_by_fields)},
                    SUM("{Value}" * "{Weight}") / SUM("{Weight}") AS "{OutputFieldName}"
                    FROM {previousToolName}_{previousToolId}
                    GROUP BY {', '.join(group_by_fields)} 
                    )
                """
        current_tool_fields.extend(group_by_fields)
        current_tool_fields.append(f'"{OutputFieldName}"')

    return current_tool_fields, cte_query


def generate_cte_for_SelectRecords(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    # Extracting the values for each field
    Value = root.find(".//Value[@name='Ranges']").text

    values = Value.split('\n')

    current_tool_fields = []
    current_tool_fields.extend(prev_tool_fields)

    # Construct the CTE query for each value
    queries = []
    for value in values:
        if '-' in value:  # Handle ranges like '109-113' or '-87'
            if value.startswith('-'):  # Handle the case like '-87' (up to row 87)
                row_limit = value[1:]  # Get the absolute number after the '-'
                transformed_value = f"ROW_NUMBER() OVER(ORDER BY NULL) <= {row_limit}"
            else:  # Handle range like '109-113'
                start, end = value.split('-')
                transformed_value = f"ROW_NUMBER() OVER(ORDER BY NULL) BETWEEN {start} AND {end}"
        elif '+' in value:  # Handle cases like '20000+'
            number = value[:-1]  # Remove the '+' sign
            transformed_value = f"ROW_NUMBER() OVER(ORDER BY NULL) > {number}"
        else:  # Handle a single number like '5'
            transformed_value = f"ROW_NUMBER() OVER(ORDER BY NULL) = {value}"

        # Generate the SQL for the current value
        final_query = f"""
        SELECT {', '.join(prev_tool_fields)}
        FROM {previousToolName}_{previousToolId}
        QUALIFY {transformed_value}
        """
        queries.append(final_query)

    # If the values list contains more than one item, combine them using UNION
    if len(values) > 1:
        cte_query = f"""
        {toolName}_{toolId} AS (
            {'\n UNION \n'.join(queries)}
        )
        """
    else:
        # If only one value, just return the single CTE
        cte_query = f"""
        {toolName}_{toolId} AS (
            {queries[0]}
        )
        """

    return current_tool_fields, cte_query


def generate_cte_for_FindReplace(xml_data, toolId, TargetsToolId, TargetsToolColList, SourceToolId, SourceToolColList):
    root = ET.fromstring(xml_data)

    fieldFind = root.find(".//FieldFind").text
    fieldSearch = root.find(".//FieldSearch").text
    replaceFoundField = root.find(".//ReplaceFoundField").text
    findMode = root.find(".//FindMode").text
    noCase = root.find('.//NoCase').get('value')
    matchWholeWord = root.find('.//MatchWholeWord').get('value')
    replaceMode = root.find(".//ReplaceMode").text
    replaceMultipleFound = root.find('.//ReplaceMultipleFound').get('value')

    ReplaceAppendFields = root.find('.//Configuration/ReplaceAppendFields')
    replace_append_fields = []
    for field in ReplaceAppendFields.findall('Field'):
        field_name = field.get('field')
        replace_append_fields.append(f'"{field_name}"')

    current_tool_fields = []

    if findMode == 'FindAny' and noCase == 'True':
        cte_query = f"""
                    replacements AS (
                        SELECT {fieldSearch}, {replaceFoundField}
                        FROM CTE_{SourceToolId}
            ),
            CTE_{toolId} AS (
                SELECT 
                     {', '.join(TargetsToolColList)}

                    -- Apply all replacements dynamically by chaining REPLACE functions
                    {{% set replace_chain = "{fieldFind}" %}}

                    {{% for row in replacements %}}
                        {{% set replace_chain = "REGEX_REPLACE(" + replace_chain + ", '" + row.{fieldSearch} + "', '" + row.{replaceFoundField} + "',1,0,'i')" %}}
                    {{% endfor %}}

                    {{ replace_chain }} AS updated_acct_holder  -- Apply all replacements dynamically
                FROM
                    CTE_{TargetsToolId} t
            )
                """

    elif findMode == 'FindAny' and noCase == 'False':
        cte_query = f"""
                    replacements AS (
                        SELECT {fieldSearch}, {replaceFoundField}
                        FROM CTE_{SourceToolId}
            ),
            CTE_{toolId} AS (
                SELECT 
                     {', '.join(TargetsToolColList)}

                    -- Apply all replacements dynamically by chaining REPLACE functions
                    {{% set replace_chain = "{fieldFind}" %}}

                    {{% for row in replacements %}}
                        {{% set replace_chain = "REGEX_REPLACE(" + replace_chain + ", '" + row.{fieldSearch} + "', '" + row.{replaceFoundField} + "',1,0,'c')" %}}
                    {{% endfor %}}

                    {{{{ replace_chain }}}} AS {fieldFind}
                FROM
                    CTE_{TargetsToolId} t
            )
                """
    else:
        cte_query = ''

    return current_tool_fields, cte_query


def generate_cte_for_Transpose(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    KeyFields = root.find('.//Configuration/KeyFields')
    DataFields = root.find('.//Configuration/DataFields')

    key_fields = []
    data_fields = []

    for field in KeyFields.findall('Field'):
        field_name = field.get('field')
        key_fields.append(f'"{field_name}"')

    for field in DataFields.findall('Field'):
        field_name = field.get('field')
        selected = field.get('selected')
        if selected == 'True' and field_name != '*Unknown':
            data_fields.append(f'"{field_name}"')

    cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT
                    {', '.join(key_fields)},"Name","Value"
                FROM 
                (
                SELECT 
                {', '.join(key_fields)},
                {', '.join(data_fields)}
                FROM
                {previousToolName}_{previousToolId}
                )
                UNPIVOT 
                ("Value" FOR "Name" IN ({', '.join(data_fields)}))
                )
            """
    current_tool_fields = []
    current_tool_fields.extend(key_fields)
    current_tool_fields.extend(["Name", "Value"])
    return current_tool_fields, cte_query


def generate_cte_for_RunningTotal(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    groupByFields = root.find('.//Configuration/GroupByFields')
    runningTotalFields = root.find('.//Configuration/RunningTotalFields')

    group_by_fields = []
    running_total_fields = []

    for field in groupByFields.findall('Field'):
        field_name = field.get('field')
        group_by_fields.append(f'"{field_name}"')

    for field in runningTotalFields.findall('Field'):
        field_name = field.get('field')
        running_total_fields.append(f'{field_name}')

    # Generate the SQL CTE query string
    if not group_by_fields:
        cte_query = f"""
        {toolName}_{toolId} AS (
            SELECT
                {', '.join(prev_tool_fields)},
                {', '.join([f'SUM({field}) OVER () AS RunTot_{field}' for field in running_total_fields])}
            FROM {previousToolName}_{previousToolId}
            )
        """
    else:
        cte_query = f"""
                {toolName}_{toolId} AS (
                    SELECT
                        {', '.join(prev_tool_fields)},
                        {',\n '.join([f'SUM({field}) OVER (PARTITION BY {", ".join(group_by_fields)}) AS RunTot_{field}' for field in running_total_fields])}
                    FROM {previousToolName}_{previousToolId}
                    )
                """

    current_tool_fields = []
    current_tool_fields.extend(prev_tool_fields)

    for field in running_total_fields:
        current_tool_fields.append(f'RunTot_{field}')

    return current_tool_fields, cte_query


def generate_cte_for_RecordID(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    groupByFields = root.find('.//Configuration/GroupFields')

    group_by_fields = []
    FieldName = root.find(".//FieldName").text
    StartValue = int(root.find(".//StartValue").text)
    Position = int(root.find(".//Position").text)
    current_tool_fields = []

    for field in groupByFields.findall('Field'):
        field_name = field.get('name')
        group_by_fields.append(f'"{field_name}"')

    if Position == 0:
        if StartValue <= 0:
            if not group_by_fields:
                cte_query = f"""
                {toolName}_{toolId} AS (
                    SELECT
                    ROW_NUMBER() OVER(ORDER BY NULL)  - ({StartValue} - 1) AS {FieldName},
                    {', '.join(prev_tool_fields)}
                    FROM {previousToolName}_{previousToolId}
                    )
                """
                current_tool_fields.append(FieldName)
                current_tool_fields.extend(prev_tool_fields)

            else:
                cte_query = f"""
                        {toolName}_{toolId} AS (
                            SELECT ROW_NUMBER() OVER(PARTITION BY {', '.join(group_by_fields)} ORDER BY {', '.join(group_by_fields)}) - ({StartValue} - 1) AS {FieldName},
                            {', '.join(prev_tool_fields)}
                                FROM {previousToolName}_{previousToolId}
                            )
                        """
                current_tool_fields.append(FieldName)
                current_tool_fields.extend(prev_tool_fields)

        elif StartValue >= 1:
            if not group_by_fields:
                cte_query = f"""
                {toolName}_{toolId} AS (
                    SELECT ROW_NUMBER() OVER(ORDER BY NULL)  + ({StartValue} - 1) AS {FieldName},
                    {', '.join(prev_tool_fields)}
                    FROM {previousToolName}_{previousToolId}
                    )
                """
                current_tool_fields.append(FieldName)
                current_tool_fields.extend(prev_tool_fields)
            else:
                cte_query = f"""
                        {toolName}_{toolId} AS (
                            SELECT ROW_NUMBER() OVER(PARTITION BY {', '.join(group_by_fields)} ORDER BY {', '.join(group_by_fields)}) + ({StartValue} - 1) AS {FieldName},
                            {', '.join(prev_tool_fields)}
                            FROM {previousToolName}_{previousToolId}
                            )
                        """
                current_tool_fields.append(FieldName)
                current_tool_fields.extend(prev_tool_fields)

    elif Position == 1:
        if StartValue <= 0:
            if not group_by_fields:
                cte_query = f"""
                {toolName}_{toolId} AS (
                    SELECT
                        {', '.join(prev_tool_fields)},
                        ROW_NUMBER() OVER(ORDER BY NULL) - ({StartValue} - 1) AS {FieldName}
                    FROM {previousToolName}_{previousToolId}
                    )
                """
                current_tool_fields.extend(prev_tool_fields)
                current_tool_fields.append(FieldName)
            else:
                cte_query = f"""
                        {toolName}_{toolId} AS (
                            SELECT
                                {', '.join(prev_tool_fields)},
                                ROW_NUMBER() OVER(PARTITION BY {', '.join(group_by_fields)} ORDER BY {', '.join(group_by_fields)}) - ({StartValue} - 1) AS {FieldName}
                            FROM {previousToolName}_{previousToolId}
                            )
                        """
                current_tool_fields.extend(prev_tool_fields)
                current_tool_fields.append(FieldName)

        elif StartValue >= 1:
            if not group_by_fields:
                cte_query = f"""
                {toolName}_{toolId} AS (
                    SELECT
                        {', '.join(prev_tool_fields)},
                        ROW_NUMBER() OVER(ORDER BY NULL) + ({StartValue} - 1) AS {FieldName}
                    FROM {previousToolName}_{previousToolId}
                    )
                """
                current_tool_fields.extend(prev_tool_fields)
                current_tool_fields.append(FieldName)
            else:
                cte_query = f"""
                        {toolName}_{toolId} AS (
                            SELECT
                                {', '.join(prev_tool_fields)},
                                ROW_NUMBER() OVER(PARTITION BY {', '.join(group_by_fields)} ORDER BY {', '.join(group_by_fields)}) + ({StartValue} - 1) AS {FieldName}
                            FROM {previousToolName}_{previousToolId}
                            )
                        """
                current_tool_fields.extend(prev_tool_fields)
                current_tool_fields.append(FieldName)

    return current_tool_fields, cte_query


def generate_cte_for_Imputation(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    fieldsToImpute = root.find(".//Value[@name='listbox Select Incoming Fields']").text.strip()
    incomingReplaceNullFlag = root.find(".//Value[@name='radio Null Value']").text.strip()
    incomingReplaceFlag = root.find(".//Value[@name='radio User Specified Replace From Value']").text.strip()
    incomingReplaceValue = root.find(".//Value[@name='updown User Replace Value']").text.strip()
    meanFlag = root.find(".//Value[@name='radio Mean']").text.strip()
    medianFlag = root.find(".//Value[@name='radio Median']").text.strip()
    modeFlag = root.find(".//Value[@name='radio Mode']").text.strip()
    userSpecifiedReplaceFlag = root.find(".//Value[@name='radio User Specified Replace With Value']").text.strip()
    userSpecifiedReplaceValue = root.find(".//Value[@name='updown User Replace With Value']").text.strip()
    imputeIndicatorFlag = root.find(".//Value[@name='checkbox Impute Indicator']").text.strip()
    imputedValuesSeparateFieldFlag = root.find(".//Value[@name='checkbox Imputed Values Separate Field']").text.strip()

    input_field_list = [item.strip('"') for item in fieldsToImpute.split(",")]
    current_tool_fields = []

    if incomingReplaceNullFlag == 'True' and userSpecifiedReplaceFlag == 'True':
        coalesce_exprs = [f"COALESCE({col}, {userSpecifiedReplaceValue}) AS {col}" for col in input_field_list]
        cte_query = f"""{toolName}_{toolId} AS (
                             SELECT {', \n'.join(coalesce_exprs)} "
                             FROM {previousToolName}_{previousToolId})"""

    elif incomingReplaceNullFlag == 'True' and (meanFlag == "True" or medianFlag == "True" or modeFlag == "True"):
        operation = "AVG" if meanFlag == "True" else "MEDIAN" if medianFlag == "True" else "MODE" if modeFlag == "True" else ""
        coalesce_exprs = [
            f"COALESCE({col}, (SELECT {operation}({col}) FROM {previousToolName}_{previousToolId})) AS {col}" for col in
            input_field_list]
        cte_query = f"""{toolName}_{toolId} AS (
                            SELECT {', \n'.join(coalesce_exprs)} 
                            FROM {previousToolName}_{previousToolId})"""

    elif incomingReplaceFlag == 'True' and userSpecifiedReplaceFlag == 'True':
        coalesce_exprs = [f"COALESCE(NULLIF({col}, {incomingReplaceValue}), {userSpecifiedReplaceValue}) AS {col}" for
                          col in input_field_list]
        cte_query = f"""{toolName}_{toolId} AS (
                            SELECT {', \n'.join(coalesce_exprs)}
                            FROM {previousToolName}_{previousToolId})"""

    elif incomingReplaceFlag == 'True' and (meanFlag == "True" or medianFlag == "True" or modeFlag == "True"):
        operation = "AVG" if meanFlag == "True" else "MEDIAN" if medianFlag == "True" else "MODE" if modeFlag == "True" else ""
        coalesce_exprs = [
            f"COALESCE(NULLIF({col}, {incomingReplaceValue}), (SELECT {operation}({col}) FROM {previousToolName}_{previousToolId})) AS {col}"
            for col in input_field_list]
        cte_query = f"""{toolName}_{toolId} AS (
                            SELECT {', \n'.join(coalesce_exprs)} 
                            FROM {previousToolName}_{previousToolId})"""

    return current_tool_fields, cte_query


def generate_cte_for_Sample(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    mode = root.find(".//Mode").text
    n = root.find(".//N").text

    groupByFields = root.find('.//Configuration/GroupFields')

    group_by_fields = []

    for field in groupByFields.findall('Field'):
        field_name = field.get('name')
        group_by_fields.append(f'"{field_name}"')

    if mode == 'First':
        if not group_by_fields:
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT {', '.join([f'"{col}"' for col in prev_tool_fields])}
                FROM {previousToolName}_{previousToolId}
                LIMIT {n}
            )
            """
        else:
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT {', '.join([f'"{col}"' for col in prev_tool_fields])}
                FROM {previousToolName}_{previousToolId}
                QUALIFY ROW_NUMBER() OVER(PARTITION BY {', '.join(group_by_fields)}   ORDER BY {', '.join(group_by_fields)}) <= {n}
            )"""



    elif mode == 'Sample':
        if not group_by_fields:
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT {', '.join([f'"{col}"' for col in prev_tool_fields])}
                FROM {previousToolName}_{previousToolId}
                QUALIFY ROW_NUMBER() OVER(ORDER BY NULL) % {n} = 1
            )
            """
        else:
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT {', '.join([f'"{col}"' for col in prev_tool_fields])}
                FROM {previousToolName}_{previousToolId}
                QUALIFY ROW_NUMBER() OVER(PARTITION BY {', '.join(group_by_fields)}   ORDER BY {', '.join(group_by_fields)})  % {n} = 1
            )"""

    elif mode == 'Last':
        if not group_by_fields:
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT {', '.join([f'"{col}"' for col in prev_tool_fields])}
                FROM {previousToolName}_{previousToolId}
                QUALIFY ROW_NUMBER() OVER(ORDER BY NULL) > (SELECT COUNT(*) - {n} FROM {previousToolName}_{previousToolId})
            )
            """
        else:
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT {', '.join([f'"{col}"' for col in prev_tool_fields])}
                FROM {previousToolName}_{previousToolId}
                QUALIFY ROW_NUMBER() OVER(PARTITION BY {', '.join(group_by_fields)}   ORDER BY {', '.join(group_by_fields)}) >
                (COUNT(*) OVER(PARTITION BY {', '.join(group_by_fields)}) - {n})
            )"""

    elif mode == 'Skip':
        if not group_by_fields:
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT {', '.join([f'"{col}"' for col in prev_tool_fields])}
                FROM {previousToolName}_{previousToolId}
                QUALIFY ROW_NUMBER() OVER(ORDER BY NULL) > {n}
            )
            """
        else:
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT {', '.join([f'"{col}"' for col in prev_tool_fields])}
                FROM {previousToolName}_{previousToolId}
                QUALIFY ROW_NUMBER() OVER(PARTITION BY {', '.join(group_by_fields)}   ORDER BY {', '.join(group_by_fields)}) > {n}
            )"""

    elif mode == 'NPercent':
        if not group_by_fields:
            cte_query = f"""
            {toolName}_{toolId} AS (
                SELECT {', '.join([f'"{col}"' for col in prev_tool_fields])}
                FROM {previousToolName}_{previousToolId}
                LIMIT (SELECT FLOOR(COUNT(*) * {n} / 100) FROM {previousToolName}_{previousToolId})
            )
            """
        else:
            cte_query = f"""
                {toolName}_{toolId} AS (
                        SELECT {', '.join([f'"{col}"' for col in prev_tool_fields])}
                        FROM {previousToolName}_{previousToolId} e
                        QUALIFY ROW_NUMBER() OVER (PARTITION BY {', '.join(group_by_fields)}  ORDER BY {', '.join(group_by_fields)} ) AS row_num
                            <= (SELECT COUNT(*) * {n} / 100 FROM {previousToolName}_{previousToolId} WHERE {' AND '.join([f'{col} = e.{col}' for col in group_by_fields])})
                        )
                        """

    else:
        cte_query = ''

    return prev_tool_fields, cte_query


def generate_cte_for_DBFileInput(xml_data, toolId):
    root = ET.fromstring(xml_data)
    AllFields = root.find('.//MetaInfo/RecordInfo')

    fieldInfo = {}
    fieldList = []

    for field in AllFields.findall('Field'):
        field_name = field.get('name')
        field_type = field.get('type')
        fieldInfo[field_name] = field_type
        fieldList.append(field_name)

    return fieldList


def generate_cte_for_DbFileOutput(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    if (len(prev_tool_fields) > 0):
        cte_query = f"""
            SELECT 
            {', '.join([f'\"{col}\"' for col in prev_tool_fields])}
            FROM {previousToolName}_{previousToolId}
        """
    else:
        cte_query = f"""
            SELECT
                *
            FROM {previousToolName}_{previousToolId}
        """

    return prev_tool_fields, cte_query


def generate_cte_for_LockInInput(xml_data, toolId):
    root = ET.fromstring(xml_data)
    query = root.find(".//Query").text
    fieldList = []

    cte_query = f"""
                    LockInInput_{toolId} AS (
                            {query} )
                            """

    return fieldList, cte_query


def generate_cte_for_TextInput(xml_data, toolId):
    root = ET.fromstring(xml_data)

    fields = root.find('.//Fields')
    fieldList = []

    for field in fields.findall('Field'):
        field_name = field.get('name')
        fieldList.append(f'"{field_name}"')

    # Extract row data dynamically from the <Data> section
    rows = []
    data = root.find('.//Data')  # Find the Data element
    for r in data.findall('r'):  # For each <r> (row)
        row = [c.text for c in r.findall('c')]  # Extract each <c> (column) value for the row
        rows.append(row)

    # Add UNION SELECT for each row dynamically
    union_queries = []
    for row in rows:
        # Create SELECT statement with field names as aliases
        union_queries.append(
            f"SELECT {', '.join([f'{repr(value)} AS {field}' for value, field in zip(row, fieldList)])}")

    # Combine all parts into one final query
    query = "\n UNION \n".join(union_queries)

    cte_query = f"""
                    TextInput_{toolId} AS (
                            {query} )
                            """

    return fieldList, cte_query


def generate_cte_for_Regex(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)
    method = root.find(".//Method").text
    regexColumn = root.find(".//Configuration/Field").text
    caseInsensitveFlag = root.find('.//CaseInsensitve').attrib['value']
    regex_value = root.find('.//RegExExpression').attrib['value']
    matchField = root.find(".//Match/Field").text
    replaceExpression = root.find('.//Replace').attrib['expression']
    SplitToRows = root.find(".//ParseSimple/SplitToRows").get("value")

    current_tool_fields = []
    prev_tool_fields = prev_tool_fields.copy()

    fields = root.find('.//ParseComplex')
    fieldList = []

    for fieldss in fields.findall('Field'):
        field_name = fieldss.get('field')
        fieldList.append(field_name)

    # Replace every single backslash with double backslashes
    regex_value = re.sub(r'\\', r'\\\\', regex_value)

    # Replace every dollar sign ($) with double backslashes (\\)
    replaceExpression = re.sub(r'\$', r'\\\\', replaceExpression)

    if method == 'Match' and caseInsensitveFlag == 'True':
        cte_query = f"""
                        {toolName}_{toolId} AS (
                            SELECT {', '.join(prev_tool_fields)},
                            REGEXP_LIKE({regexColumn}, '{regex_value}', 'i') AS {matchField}
                            FROM {previousToolName}_{previousToolId}
                            )
                            """
        current_tool_fields.extend(prev_tool_fields)
        current_tool_fields.append(matchField)
    elif method == 'Match' and caseInsensitveFlag == 'False':
        cte_query = f"""
                        {toolName}_{toolId} AS (
                            SELECT {', '.join(prev_tool_fields)},
                            REGEXP_LIKE({regexColumn}, '{regex_value}', 'c') AS {matchField}
                            FROM {previousToolName}_{previousToolId}
                            )
                            """
        current_tool_fields.extend(prev_tool_fields)
        current_tool_fields.append(matchField)
    elif method == 'Replace' and caseInsensitveFlag == 'True':
        prev_tool_fields.remove(regexColumn)
        cte_query = f"""
                        {toolName}_{toolId} AS (
                            SELECT {', '.join(prev_tool_fields)},
                            REGEXP_REPLACE({regexColumn}, '{regex_value}', '{replaceExpression}', 1, 0, 'i') AS {regexColumn}
                            FROM {previousToolName}_{previousToolId}
                            )
                            """
        current_tool_fields.extend(prev_tool_fields)
        current_tool_fields.append(regexColumn)
    elif method == 'Replace' and caseInsensitveFlag == 'False':
        prev_tool_fields.remove(regexColumn)
        cte_query = f"""
                        {toolName}_{toolId} AS (
                            SELECT {', '.join(prev_tool_fields)},
                            REGEXP_REPLACE({regexColumn}, '{regex_value}', '{replaceExpression}', 1, 0, 'c') AS {regexColumn}
                            FROM {previousToolName}_{previousToolId}
                            )
                            """
        current_tool_fields.extend(prev_tool_fields)
        current_tool_fields.append(regexColumn)

    elif method == 'ParseComplex' and caseInsensitveFlag == 'True':

        groups = re.findall(r'([^\(\)]*\([^\)]*\))', regex_value)

        # Start building the SQL query
        select_clause = ''

        # Loop through the groups and column names to build the REGEXP_SUBSTR parts
        for i, (group, col_name) in enumerate(zip(groups, fieldList)):
            # Add the REGEXP_SUBSTR statement for each group with the corresponding column name
            select_clause += f"\n    REGEXP_SUBSTR({regexColumn}, '{group}', 1, 1,'i') AS {col_name},"

        # Remove the last comma
        select_clause = select_clause.rstrip(',')

        cte_query = f"""
                        {toolName}_{toolId} AS (
                            SELECT {', '.join(prev_tool_fields)},
                            {select_clause}
                            FROM {previousToolName}_{previousToolId}
                            )
                            """
        current_tool_fields.extend(prev_tool_fields)
        current_tool_fields.extend(fieldList)

    elif method == 'ParseComplex' and caseInsensitveFlag == 'False':

        groups = re.findall(r'([^\(\)]*\([^\)]*\))', regex_value)

        # Start building the SQL query
        select_clause = ''

        # Loop through the groups and column names to build the REGEXP_SUBSTR parts
        for i, (group, col_name) in enumerate(zip(groups, fieldList)):
            # Add the REGEXP_SUBSTR statement for each group with the corresponding column name
            select_clause += f"\n    REGEXP_SUBSTR({regexColumn}, '{group}', 1, 1,'c') AS {col_name},"

        # Remove the last comma
        select_clause = select_clause.rstrip(',')

        cte_query = f"""
                        {toolName}_{toolId} AS (
                            SELECT {', '.join(prev_tool_fields)},
                            {select_clause}
                            FROM {previousToolName}_{previousToolId}
                            )
                            """
        current_tool_fields.extend(prev_tool_fields)
        current_tool_fields.extend(fieldList)


    elif method == 'ParseSimple' and caseInsensitveFlag == 'True' and SplitToRows == 'False':
        NumFields = root.find(".//ParseSimple/NumFields").get("value")
        RootName = root.find(".//ParseSimple/RootName").text
        splitColumnList = []
        # Start building the SQL query
        sql_query = ''

        # Create dynamic REGEXP_SUBSTR expressions for each part of the address
        for i in range(1, int(NumFields) + 1):
            sql_query += f"REGEXP_SUBSTR({regexColumn}, '{regex_value}',1 ,{i} ,'i') AS {RootName}{i},\n"
            splitColumnList.append(f'{RootName}{i}')

        # Remove the trailing comma on the last line
        sql_query = sql_query.rstrip(',')

        cte_query = f"""
                        {toolName}_{toolId} AS (
                            SELECT {', '.join(prev_tool_fields)},
                            {sql_query}
                            FROM {previousToolName}_{previousToolId}
                            )
                            """
        current_tool_fields.extend(prev_tool_fields)
        current_tool_fields.extend(splitColumnList)


    elif method == 'ParseSimple' and caseInsensitveFlag == 'False' and SplitToRows == 'False':
        NumFields = root.find(".//ParseSimple/NumFields").get("value")
        RootName = root.find(".//ParseSimple/RootName").text
        splitColumnList = []
        # Start building the SQL query

        sql_query = ''
        # Create dynamic REGEXP_SUBSTR expressions for each part of the address
        for i in range(1, int(NumFields) + 1):
            sql_query += f"REGEXP_SUBSTR({regexColumn}, '{regex_value}',1 ,{i} ,'c') AS {RootName}{i},\n"
            splitColumnList.append(f'{RootName}{i}')

        # Remove the trailing comma on the last line
        sql_query = sql_query.rstrip(',')

        cte_query = f"""
                        {toolName}_{toolId} AS (
                            SELECT {', '.join(prev_tool_fields)},
                            {sql_query}
                            FROM {previousToolName}_{previousToolId}
                            )
                            """

        current_tool_fields.extend(prev_tool_fields)
        current_tool_fields.extend(splitColumnList)


    elif method == 'ParseSimple' and caseInsensitveFlag == 'True' and SplitToRows == 'True':
        prev_tool_fields.remove(regexColumn)

        cte_query = f"""
                        {toolName}_{toolId} AS (
                                -- Base case: get the first title
                            SELECT 
                                {', '.join(prev_tool_fields)}, 
                                TRIM(REGEXP_SUBSTR({regexColumn}, '{regex_value}', 1, 1,'i')) AS {regexColumn},
                                1 AS idx,
                                {regexColumn} AS original_col  -- Keep the original column for recursion
                            FROM {previousToolName}_{previousToolId}
                            WHERE {regexColumn} IS NOT NULL

                            UNION ALL

                            -- Recursive case: get the next title by incrementing idx
                            SELECT 
                                {', '.join(prev_tool_fields)},
                                TRIM(REGEXP_SUBSTR(original_col, '{regex_value}', 1, idx + 1)),
                                idx + 1,
                                original_col
                            FROM {toolName}_{toolId}
                            WHERE REGEXP_SUBSTR(original_col, '{regex_value}', 1, idx + 1) IS NOT NULL
                            )
                            """

        current_tool_fields.extend(prev_tool_fields)
        current_tool_fields.append(regexColumn)


    elif method == 'ParseSimple' and caseInsensitveFlag == 'False' and SplitToRows == 'True':
        prev_tool_fields.remove(regexColumn)

        cte_query = f"""
                        {toolName}_{toolId} AS (
                                -- Base case: get the first title
                            SELECT 
                                {', '.join(prev_tool_fields)}, 
                                TRIM(REGEXP_SUBSTR({regexColumn}, '{regex_value}', 1, 1,'c')) AS {regexColumn},
                                1 AS idx,
                                {regexColumn} AS original_col  -- Keep the original column for recursion
                            FROM {previousToolName}_{previousToolId}
                            WHERE {regexColumn} IS NOT NULL

                            UNION ALL

                            -- Recursive case: get the next title by incrementing idx
                            SELECT 
                                {', '.join(prev_tool_fields)},
                                TRIM(REGEXP_SUBSTR(original_col, '{regex_value}', 1, idx + 1)),
                                idx + 1,
                                original_col
                            FROM {toolName}_{toolId}
                            WHERE REGEXP_SUBSTR(original_col, '{regex_value}', 1, idx + 1) IS NOT NULL
                            )
                            """

        current_tool_fields.extend(prev_tool_fields)
        current_tool_fields.append(regexColumn)

    return current_tool_fields, cte_query


def removing_comment(expression):
    expression_list = expression.split('\n')
    expression = []
    for i in expression_list:
        if ('//' not in i):
            expression.append(i)
        else:
            ind = i.index('//')
            if (ind != 0):
                expression.append(i[:ind])
    expression = '\n'.join(expression)
    return expression


## functionfor cleaning expression paramteres
def sanitize_expression_for_filter_formula_dynamic_rename(expression, field_name=None):
    """
    Converts Alteryx-style conditional expressions into SQL-compliant CASE statements.
    Handles:
    - IF-THEN-ELSE-ENDIF to CASE-WHEN-THEN-ELSE-END.
    - NULL() to NULL.
    - [_CurrentField_] replacement for Multi-Field Formula.
    - Row-based references ([Row-1:Field]) to LAG/LEAD for Multi-Row Formula.
    """

    if not expression:
        return ""
    
    # Remove square brackets [] from field names
    expression = re.sub(r"\[(.*?)\]", r'"\1"', expression)

    # Ensure CONTAINS is uppercase
    expression = re.sub(r"\b(Contains|contains)\s*\(", "CONTAINS(", expression, flags=re.IGNORECASE)

    # Replace [_CurrentField_] with actual field name if provided
    if field_name:
        expression = expression.replace("[_CurrentField_]", f"\"{field_name}\"")

    # **Fix ToNumber → TO_NUMBER while keeping already correct TO_NUMBER unchanged**
    def fix_to_number(match):
        function_name = match.group(1).strip()  # ToNumber or TO_NUMBER
        first_param = match.group(2).strip()
        optional_format = match.group(3).strip() if match.group(3) else ""

        # ✅ **Ensure we do NOT modify expressions inside RIGHT, LEFT, etc.**
        if first_param.startswith("RIGHT(") or first_param.startswith("LEFT(") or first_param.startswith("SUBSTRING("):
            return f"TO_NUMBER({first_param}{optional_format})"

        # ✅ **Convert only `ToNumber` → `TO_NUMBER` but leave `TO_NUMBER()` unchanged**
        if function_name.lower() == "tonumber":
            return f"TO_NUMBER({first_param}{optional_format})"
        return match.group(0)  # Keep already correct TO_NUMBER as is

    expression = re.sub(r"\b(ToNumber|TO_NUMBER)\s*\(\s*([^,]+)(,\s*[^)]+)?\s*\)", fix_to_number, expression, flags=re.IGNORECASE)


    # Ensure CONTAINS function has the field name as the first argument
    expression = re.sub(r"CONTAINS\(\s*['\"]([^'\"]+)['\"]\s*\)", rf"CONTAINS(\"{field_name}\", '\1')", expression,
                        flags=re.IGNORECASE)

    # Adding this regex to ensure mathematical expressions keep their structure. This ensures that A * (B / C) remains correctly formatted.
    expression = re.sub(r"(\S+)\s*\*\s*\(([^)]+)\)", r"\1 * (\2)", expression)

    # Ensure all field names are quoted:
    # expression = re.sub(r"\b(\w+\s+\w+)\b", r'"\1"', expression)

    # Ensure LENGTH() is formatted correctly
    def fix_length(match):
        first_arg = match.group(1).strip()
        rest_of_expression = match.group(2).strip()  # This could be `-1` or `+2` etc.

        # Convert single quotes to double quotes
        if first_arg.startswith("'") and first_arg.endswith("'"):
            first_arg = f'"{first_arg[1:-1]}"'

        # If no quotes, wrap in double quotes
        elif not (first_arg.startswith('"') and first_arg.endswith('"')):
            first_arg = f'"{first_arg}"'

        return f"LENGTH({first_arg}){rest_of_expression}"  # Keep `-1` or `+2` untouched

    expression = re.sub(r"\bLENGTH\s*\(\s*([^,]+?)\s*\)([^\)]*)", fix_length, expression, flags=re.IGNORECASE)


    # Ensure first parameter inside functions like LEFT, RIGHT, LENGTH, ABS, etc., is in double quotes
    def fix_function_argument(match):
        function_name = match.group(1).upper()  # Convert function name to uppercase
        first_arg = match.group(2).strip()
        rest_of_expression = match.group(3)  # Remaining arguments

        # Convert single quotes to double quotes
        if first_arg.startswith("'") and first_arg.endswith("'"):
            first_arg = f'"{first_arg[1:-1]}"'

        # If no quotes, wrap in double quotes
        elif not (first_arg.startswith('"') and first_arg.endswith('"')):
            first_arg = f'"{first_arg}"'

        return f"{function_name}({first_arg}{rest_of_expression})"

    expression = re.sub(r"\b(LEFT|RIGHT|ABS|UPPER|LOWER|SUBSTRING)\s*\(\s*([^,]+)(.*?)\)", fix_function_argument,
                        expression, flags=re.IGNORECASE)

    # Ensure SPLIT_PART follows Snowflake syntax with correct first parameter quoting
    def fix_split_part(match):
        first_param = match.group(1).strip()
        delimiter = match.group(2).strip()
        part_number = match.group(3).strip()

        # Convert single quotes to double quotes
        if first_param.startswith("'") and first_param.endswith("'"):
            first_param = f'"{first_param[1:-1]}"'

        # If no quotes, wrap in double quotes
        elif not (first_param.startswith('"') and first_param.endswith('"')):
            first_param = f'"{first_param}"'

        return f"SPLIT_PART({first_param}, {delimiter}, {part_number})"

    expression = re.sub(r"\bSPLIT_PART\s*\(([^,]+),\s*([^,]+),\s*([^,]+)\)", fix_split_part, expression,
                        flags=re.IGNORECASE)
  
    # Ensure TO_CHAR() and TO_DATE() fields are properly enclosed in correct quotes
    def fix_to_char_to_date(match):
        function_name = match.group(1).upper()  # Convert function name to uppercase
        field = match.group(2).strip()
        format_string = match.group(3).strip()

        # If field is in single quotes, convert it to double quotes
        if field.startswith("'") and field.endswith("'"):
            field = f'"{field[1:-1]}"'  # Convert 'Field' → "Field"

        # If field is already in double quotes, keep as double quotes (No Change)
        elif field.startswith('"') and field.endswith('"'):
            field = field

            # If field has no quotes, wrap it in double quotes
        else:
            field = f'"{field}"'

        return f"{function_name}({field}, {format_string})"

    # Apply the transformation in the expression
    expression = re.sub(r"\b(TO_CHAR|TO_DATE)\s*\(\s*(\"[^\"]+\"|'[^']+'|[\w\s]+)\s*,\s*([^,]+)\s*\)",
                        fix_to_char_to_date, expression, flags=re.IGNORECASE)
    
    
    # Ensure DateTimeYear() and DateTimeTrim() are properly converted
    def fix_datetime_functions(match):
        function_name = match.group(1).strip().upper()  # Extract function name
        first_param = match.group(2).strip()  # Extract first parameter (column)
        second_param = match.group(3).strip() if match.group(3) else None  # Extract optional second parameter

        # Ensure first parameter is enclosed in double quotes (column name)
        if first_param.startswith("'") and first_param.endswith("'"):
            first_param = f'"{first_param[1:-1]}"'
        elif not (first_param.startswith('"') and first_param.endswith('"')):
            first_param = f'"{first_param}"'

        # Convert DateTimeYear() → YEAR()
        if function_name == "DATETIMEYEAR":
            return f"YEAR({first_param})"

        # Convert DateTimeTrim("eventdate", "month") → MONTH("eventdate")
        if function_name == "DATETIMETRIM" and second_param:
            if second_param.lower() in ["'month'", '"month"']:  # Ensure "month" parameter is matched correctly
                return f"MONTH({first_param})"

        return match.group(0)  # Return original if no transformation is needed

    # Apply regex transformation for DateTimeYear() and DateTimeTrim()
    expression = re.sub(r"\b(DateTimeYear|DateTimeTrim)\s*\(\s*([^,]+)(?:,\s*([^,]+))?\s*\)", fix_datetime_functions, expression, flags=re.IGNORECASE)
    
    # Fix THEN/ELSE Statements
    def fix_case_statement(match):
        """
        Ensures correct formatting for CASE WHEN statements:
        - Columns in double quotes.
        - String literals in single quotes.
        - NULL formatted correctly.
        """
        condition = match.group(1).strip()
        then_value = match.group(2).strip()
        else_value = match.group(3).strip()

        # Function to format THEN/ELSE values
        def format_value(val):
            if val.upper() == "NULL" or val.upper() == "NULL)":
                return "NULL"  # Ensure NULL is not quoted

            # If the value is numeric, leave as is
            if val.replace("-", "").isdigit():
                return val

            # If the value is in double quotes, it's likely a column name (leave it)
            if val.startswith('"') and val.endswith('"'):
                return val

            # Otherwise, it's a string literal, ensure it's in single quotes
            return f"'{val.strip('\"')}'"

        then_value = format_value(then_value)
        else_value = format_value(else_value)

        return f"CASE WHEN {condition} THEN {then_value} ELSE {else_value} END"

    # Convert Alteryx-style string concatenation (`+`) to Snowflake `CONCAT()`
    def replace_concat(match):
        """Correctly replaces `+` with either:
        - `CONCAT()` (if it's a string operation)
        - Keeps `+` (if it's an arithmetic operation)
        - Ensures `END + CASE WHEN` remains unchanged
        """
        first_param = match.group(1).strip()
        second_param = match.group(2).strip()

        # Preserve END + CASE WHEN
        if first_param.upper() == "END" and second_param.upper() == "CASE WHEN":
            return "END + CASE WHEN"

        # Preserve `+` for numeric operations
        if first_param.isdigit() or second_param.isdigit():
            return f"{first_param} + {second_param}"

        # Ensure first parameter (column names) is in double quotes
        def process_first_param(param):
            """Ensure first parameter (column name) is in double quotes."""
            if param.upper() == "END":  # Skip processing for END
                return param

            if param.startswith("'") and param.endswith("'"):
                return f'"{param[1:-1]}"'  # Convert single to double quotes
            
            elif not (param.startswith('"') and param.endswith('"')):
                return f'"{param}"'  # Wrap in double quotes if no quotes
            
            return param  # Keep as is if already in double quotes

        def process_second_param(param):
            """Ensure second parameter (string literal) is in single quotes."""
            if param.upper() == "CASE WHEN":  # Skip processing for CASE WHEN
                return param

            if param.startswith('"') and param.endswith('"'):
                return f"'{param[1:-1]}'"  # Convert double to single quotes
            elif not (param.startswith("'") and param.endswith("'")):
                return f"'{param}'"  # Wrap in single quotes if no quotes
            return param  # Keep as is if already in single quotes

        # Apply transformations only when needed
        first_param = process_first_param(first_param)
        second_param = process_second_param(second_param)

        return f"CONCAT({first_param}, {second_param})"

    # Apply transformation
    # expression = re.sub(r"(\S+)\s*\+\s*(\S+)", replace_concat, expression)
    expression = re.sub(r"(END)\s*\+\s*(CASE WHEN)", replace_concat, expression)


    # Apply the regex transformation for CASE WHEN statements
    expression = re.sub(r"CASE\s+WHEN\s+(.*?)\s+THEN\s+(.*?)\s+ELSE\s+(.*?)\s+END",fix_case_statement,expression,flags=re.IGNORECASE)

    # Convert Alteryx-style IF-THEN-ELSE-ENDIF into SQL CASE WHEN
    expression = re.sub(r"\bif\s+(.+?)\s+then\s+(.+?)\s+ELSE\s+(.+?)\s+END",r"CASE WHEN \1 THEN \2 ELSE \3 END",expression,flags=re.IGNORECASE)
    expression = re.sub(r"\bif\s+(.*?)\s+then\s+(.*?)\s+else\s+(.*?)\s+endif", r"CASE WHEN \1 THEN \2 ELSE \3 END", expression, flags=re.IGNORECASE)

    # Ensure proper transformation for single-line IF statements
    expression = re.sub(r"\bif\s+(.+?)\s+then\s+(.+?)\s+ELSE\s+(.+?)\b",r"CASE WHEN \1 THEN \2 ELSE \3 END",expression,flags=re.IGNORECASE)

    # Ensure ELSE and END are correctly formatted
    expression = re.sub(r"\belseif\s+(.*?)\s+then", r"WHEN \1 THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\belse\b", r"ELSE", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bendif\b", r"END", expression, flags=re.IGNORECASE)

    # Handle NULL() conversion
    expression = re.sub(r"(?i)NULL\(\)", "NULL", expression)

    # Ensure string literals in comparisons (`=`, `<>`, `IN`, `LIKE`) use single quotes
    expression = re.sub(r'=\s*"([^"]+)"', r"= '\1'", expression)
    expression = re.sub(r'<>\s*"([^"]+)"', r"<> '\1'", expression)
    expression = re.sub(r'IN\s*\(\s*"([^"]+)"\s*\)', r"IN ('\1')", expression, flags=re.IGNORECASE)
    expression = re.sub(r'LIKE\s*"([^"]+)"', r"LIKE '\1'", expression, flags=re.IGNORECASE)

    # Ensure string literals in `THEN` clause are enclosed in single quotes
    # expression = re.sub(r"THEN\s+\"([^\"']+)\"", r"THEN '\1'", expression, flags=re.IGNORECASE)
    # expression = re.sub(r"ELSE\s+\"([^\"']+)\"", r"ELSE '\1'", expression, flags=re.IGNORECASE)

    # Standardize logical operators
    expression = expression.replace("=", " = ").replace("<>", " != ").replace(" And ", " AND ").replace(" Or ", " OR ")

    # Remove extra double quotes inside function calls (Fix for `''Treaty''`)
    expression = re.sub(r"''([^']+)''", r"'\1'", expression)

    # Handle line breaks and extra spaces
    expression = expression.replace("\n", " ").replace("\r", " ").strip()

    # Handle [_CurrentField_] replacement dynamically
    expression = expression.replace("[_CurrentField_]", '"_CurrentField_"')

    # Convert Row-based references (Multi-Row Formula)
    expression = re.sub(r"\[Row-([0-9]+):(.+?)\]", r"LAG(\2, \1) OVER ()", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\[Row\+([0-9]+):(.+?)\]", r"LEAD(\2, \1) OVER ()", expression, flags=re.IGNORECASE)

    return expression.strip()

# Function to Convert Alteryx DateTime Formats to Snowflake-Compatible Formats
def sanitize_datetime_format(alteryx_format, is_input=True):
    """
    Converts Alteryx DateTime format specifiers into Snowflake-compatible format.
    Handles DateTimeToString and StringToDateTime conversions.
    - On input: Standardizes equivalent separators.
    - On output: Keeps separators exactly as they are.
    - Handles 2-digit year (`yy`) mapping to correct range.
    """

    # Standardize separators (ONLY for input formats)
    if is_input:
        # Replace '-' with '/', as both are equivalent
        alteryx_format = re.sub(r"[-]", "/", alteryx_format)

        # Remove unnecessary white spaces
        alteryx_format = re.sub(r"\s+", " ", alteryx_format.strip())

    # Mapping of Alteryx format specifiers to Snowflake format specifiers
    format_mappings = {
        # Days
        "d": "D", "dd": "DD", "day": "Day", "dy": "DY", "EEEE": "Day",

        # Months
        "M": "M", "MM": "MM", "MMM": "Mon", "MMMM": "MMMM", "Mon": "Mon", "Month": "Mon",

        # Years
        "yy": "YY",  # 2-digit year (Handled separately)
        "yyyy": "YYYY",

        # Hours (12-hour & 24-hour)
        "H": "HH24", "HH": "HH24", "hh": "HH24", "ahh": "AM",

        # Minutes & Seconds
        "mm": "MI", "ss": "SS",

        # Subseconds / Precision
        "ffff": "FF"
    }

    # Replace Alteryx format specifiers with Snowflake equivalents
    for alteryx_fmt, sql_fmt in format_mappings.items():
        alteryx_format = alteryx_format.replace(alteryx_fmt, sql_fmt)

    # Handle Custom Wildcard Case (*)
    alteryx_format = alteryx_format.replace("*", "")

    return alteryx_format


def generate_cte_for_DateTime(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    """
    Parses the Alteryx DateTime Tool XML configuration and generates an equivalent SQL CTE.
    Handles:
      - DateTime to String conversion (TO_CHAR)
      - String to DateTime conversion (TO_DATE)
      - Custom DateTime formats
      - Language-based formatting
      - Ensures column names are enclosed in double quotes
    """
    root = ET.fromstring(xml_data)

    # Extract attributes in the required order
    config_node = root.find(".//Configuration")
    if config_node is None:
        raise ValueError("Missing 'Configuration' element in XML configuration.")

    isFrom = config_node.find(".//IsFrom")
    isFrom = isFrom.get("value").strip().lower() == "true" if isFrom is not None else False  # Default: False

    input_field_node = config_node.find(".//InputFieldName")
    input_field = input_field_node.text.strip() if input_field_node is not None else None

    language_node = config_node.find(".//Language")
    language = language_node.text.strip() if language_node is not None else None  # Not used for Snowflake

    format_node = config_node.find(".//Format")
    datetime_format = format_node.text.strip() if format_node is not None else None

    output_field_node = config_node.find(".//OutputFieldName")
    output_field = output_field_node.text.strip() if output_field_node is not None else "DateTime_Out"

    # Validation Checks
    if not input_field or not datetime_format:
        raise ValueError("Missing required fields: 'InputFieldName' or 'Format'.")

    # Convert Alteryx datetime format to Snowflake format
    sql_datetime_format = sanitize_datetime_format(datetime_format)

    #  Ensure the first parameter inside TO_CHAR/TO_DATE is enclosed in double quotes
    input_field = f'"{input_field}"' if not (input_field.startswith('"') and input_field.endswith('"')) else input_field

    #  Generate SQL Expression with Correct Quoting for TO_CHAR & TO_DATE
    function_name = "TO_CHAR" if isFrom else "TO_DATE"
    sql_expression = f"{function_name}({input_field}, '{sql_datetime_format}') AS \"{output_field}\""

    #  Apply sanitize function for additional formatting
    sql_expression = sanitize_expression_for_filter_formula_dynamic_rename(sql_expression)

    #  Ensure all column names in SELECT are enclosed in double quotes
    prev_fields_str = ", ".join(
        f'"{field}"' if not (field.startswith('"') and field.endswith('"')) else field for field in prev_tool_fields)

    #  Construct the SQL CTE
    cte_query = f"""
    {toolName}_{toolId} AS (
        SELECT {prev_fields_str},
               {sql_expression}
        FROM {previousToolName}_{previousToolId}
    )
    """

    return prev_tool_fields + [output_field], cte_query


## Tile Tool in Alteryx
def generate_cte_for_Tile(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
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

    config = root.find(".//Configuration")
    if config is None:
        raise ValueError("Missing 'Configuration' section in XML.")

    tile_method = config.find("Method").text.strip() if config.find("Method") is not None else None
    group_fields_node = config.find("GroupFields")

    # Extract grouping fields and order change flag
    group_fields = [field.get("name") for field in
                    group_fields_node.findall("Field")] if group_fields_node is not None else []
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
        name_field = config.find(".//SmartTile/NameField").text.strip() if config.find(
            ".//SmartTile/NameField") is not None else "None"

        # Mapping name field behavior
        name_field_case = {
            "None": "",
            "Output": f", \"{tile_column}_Name\"",
            "Verbose": f", \"{tile_column}_Verbose\""
        }
        sql_expression = f"NTILE(7) OVER (ORDER BY STDDEV(\"{smart_field}\") DESC) AS \"{tile_column}\"{name_field_case.get(name_field, '')}"

    elif tile_method == "UniqueValue":
        unique_fields = [field.get("field") for field in config.findall(".//UniqueValue/UniqueFields/Field")]
        dont_sort = config.find(".//UniqueValue/DontSort").get("value") if config.find(
            ".//UniqueValue/DontSort") is not None else "False"
        order_by_clause = "" if dont_sort == "True" else f"ORDER BY {', '.join(unique_fields)}"
        sql_expression = f"DENSE_RANK() OVER ({order_by_clause}) AS \"{tile_column}\""

    elif tile_method == "Manual":
        manual_field = config.find(".//Manual/Field").text.strip()
        cutoffs_text = config.find(".//Manual/Cutoffs").text.strip()
        cutoffs = [c.strip() for c in cutoffs_text.split("\n") if c.strip()]
        case_conditions = " ".join(
            [f"WHEN \"{manual_field}\" <= {cutoff} THEN {i + 1}" for i, cutoff in enumerate(cutoffs)])
        sql_expression = f"CASE {case_conditions} ELSE {len(cutoffs) + 1} END AS \"{tile_column}\""

    else:
        raise ValueError(f"Unsupported Tile Method: {tile_method}")

    # Sanitize the SQL Expression
    sql_expression = sanitize_expression_for_filter_formula_dynamic_rename(sql_expression)

    # Construct final SQL query
    prev_fields_str = ", ".join(f'"{field}"' for field in prev_tool_fields)

    cte_query = f"""
    {toolName}_{toolId} AS (
        SELECT {prev_fields_str}, 
               {sql_expression}
        FROM {previousToolName}_{previousToolId}
    )
    """

    new_fields = prev_tool_fields + [tile_column]
    return new_fields, cte_query

# Convert Alteryx-style ISNULL and NOT (!) into Snowflake IS NULL and IS NOT NULL
def fix_isnull_not_operator(expression):
    """
    Converts `ISNULL("column")` and `!ISNULL("column")` into Snowflake-compliant syntax.
    
    - `ISNULL("column")` → `"column" IS NULL`
    - `!ISNULL("column")` → `"column" IS NOT NULL`
    - `NOT ISNULL("column")` → `"column" IS NOT NULL`
    - Ensures `CASE WHEN` conditions remain intact.
    """

    # Standardize all variations of `isnull` (e.g., `isnull`, `IsNull`, `ISNULL`) to uppercase `ISNULL`
    expression = re.sub(r"\b(isnull|IsNull|ISNULL)\b", "ISNULL", expression, flags=re.IGNORECASE)

    # Standardize all variations of `not` (e.g., `not`, `Not`, `NOT`) to uppercase `NOT`
    expression = re.sub(r"\b(not|Not|NOT)\b", "NOT", expression, flags=re.IGNORECASE)

    # Convert `!ISNULL("column_name")` → `"column_name" IS NOT NULL`
    expression = re.sub(r"!\s*ISNULL\s*\(\s*([\"'][^\"']+[\"'])\s*\)", r"\1 IS NOT NULL", expression, flags=re.IGNORECASE)

    # Convert `NOT ISNULL("column_name")` → `"column_name" IS NOT NULL`
    expression = re.sub(r"\bNOT\s+ISNULL\s*\(\s*([\"'][^\"']+[\"'])\s*\)", r"\1 IS NOT NULL", expression, flags=re.IGNORECASE)

    # Convert `ISNULL("column_name")` → `"column_name" IS NULL`
    expression = re.sub(r"\bISNULL\s*\(\s*([\"'][^\"']+[\"'])\s*\)", r"\1 IS NULL", expression, flags=re.IGNORECASE)
    expression = re.sub(r"ISNULL\s*\(\s*\[([^\]]+)\]\s*\)", r'"\1" IS NULL', expression)

    return expression


# Convert Alteryx-style if into Snowflake CASE WHEN Stmts
def fix_if_to_case(expression):
    """
    Fixes Alteryx-style `IF-THEN-ELSE` statements into Snowflake-compliant `CASE WHEN`.
    Also ensures `ENDIF` is replaced correctly without breaking syntax.
    """
    #  Standardize IF, ELSE, and ENDIF
    expression = re.sub(r"\bif\b", "CASE WHEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bthen\b", "THEN", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\belse\b", "ELSE", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bendif\b", "END", expression, flags=re.IGNORECASE)
    
    # Fix `IF-THEN-ELSE-ENDIF` into proper `CASE WHEN`
    expression = re.sub(r"\bif\s+(.*?)\s+then\s+(.*?)\s+else\s+(.*?)\s+endif", r"CASE WHEN \1 THEN \2 ELSE \3 END", expression, flags=re.IGNORECASE)

    # Fix `IF-THEN-ELSE-ENDIF` into proper `CASE WHEN`
    expression = re.sub(r"CASE WHEN\s+(.*?)\s+THEN\s+(.*?)\s+ELSE\s+(.*?)\s+END",r"CASE WHEN \1 THEN \2 ELSE \3 END", expression, flags=re.IGNORECASE)


    # **Ensure `END` is properly concatenated with the next `CASE WHEN` using `+`**
    expression = re.sub(r"END\s+(CASE WHEN)", r"END + \1", expression, flags=re.IGNORECASE)

    return expression

# Function to parse the XML and generate SQL CTE for Filter
def generate_cte_for_Filter(xml_data, previousToolId, toolId, filterType, prev_tool_fields, toolName, previousToolName):
    """
    Generates SQL CTE for filter expressions found in the configuration.
    Sanitizes filter expressions for SQL compliance.
    """
    root = ET.fromstring(xml_data)

    # Locate the Filter Configuration node
    expression_node = root.find('.//Configuration/Expression')

    if expression_node is None:
        return [], f"-- No filter configuration found for ToolID CTE_{toolId}"

    current_tool_fields = prev_tool_fields.copy()

    # Sanitize and clean the filter expression
    filter_expression = expression_node.text.strip() if expression_node.text else "1=1"
    filter_expression = sanitize_expression_for_filter_formula_dynamic_rename(filter_expression)

    # Apply fix for ISNULL and NOT (!) operators
    filter_expression = fix_isnull_not_operator(filter_expression)

    if filterType == 'True':
        cte_query = f"""
                {toolName}_{toolId} AS (
                SELECT  {', '.join([f'\"{col}\"' for col in current_tool_fields])}
                FROM {previousToolName}_{previousToolId}
                WHERE {filter_expression}
            )
            """
    elif filterType == 'False':
        cte_query = f"""
            {toolName}_{toolId} AS (
            SELECT  {', '.join([f'\"{col}\"' for col in current_tool_fields])}
            FROM {previousToolName}_{previousToolId}
            WHERE NOT ({filter_expression})
        )
        """
    return current_tool_fields, cte_query


# Function to parse the XML and generate SQL CTE for Formula
def generate_cte_for_Formula(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    # Extract SummarizeFields
    formula_fields = root.find('.//Configuration/FormulaFields')

    if formula_fields is  None:
        return [], f"-- No formula configuration found for ToolID CTE_{toolId}"

    formula_expr = []
    current_tool_fields = []
    formula_field_names = []
    prev_tool_fields_except_formula_fields = []

    # Function to ensure mathematical expressions use double quotes
    def quote_columns_for_math(expression):
        # Split the expression by math operators but keep them
        tokens = re.split(r'(\+|\-|\*|/|\(|\)|\s+)', expression)

        updated_tokens = []
        for token in tokens:
            stripped_token = token.strip()

            # If token is a column and NOT inside a function, wrap in double quotes
            if stripped_token in prev_tool_fields and not re.search(
                    r'(LEFT|RIGHT|CONCAT|ABS|LENGTH|CASE|WHEN|THEN|ELSE|NULL)', stripped_token, re.IGNORECASE):
                updated_tokens.append(f'"{stripped_token}"')
            else:
                updated_tokens.append(token)

        return ''.join(updated_tokens)

    # Extract each formula field and generate SQL expressions
    for field in formula_fields.findall('FormulaField'):
        expr_name = field.get('expression')
        field_name = field.get('field')

        if '//' in expr_name:
            expr_name = removing_comment(expr_name)

        # Apply quoting for mathematical expressions
        processed_expr = quote_columns_for_math(expr_name)
        sql_expression = sanitize_expression_for_filter_formula_dynamic_rename(processed_expr)

        # Convert any remaining `if ... then ...` to `CASE WHEN ... THEN ...`
        format_ifs = fix_if_to_case(sql_expression)

        # Apply fix for ISNULL and NOT (!) operators
        format_nulls = fix_isnull_not_operator(format_ifs)

        formula_expr.append(f"{format_nulls} AS \"{field_name}\"")
        formula_field_names.append(field_name)

    # Remove formula fields from previous tool fields to avoid duplication
    for i in prev_tool_fields:
        if i not in formula_field_names:
            prev_tool_fields_except_formula_fields.append(i)

    current_tool_fields = prev_tool_fields_except_formula_fields + formula_field_names

    # Generate the SQL CTE query string
    cte_query = f"""
        {toolName}_{toolId} AS  (
        SELECT 
           {', '.join([f'\"{col}\"' for col in prev_tool_fields_except_formula_fields])}
           {',' if prev_tool_fields_except_formula_fields and formula_expr else ''}
           {', '.join(formula_expr)}
        FROM {previousToolName}_{previousToolId}
    )
    """

    return current_tool_fields, cte_query


def generate_cte_for_AppendFields(xml_data, sourceToolID, targetToolID, toolId, sourceToolColList, TargetToolColList,
                                  sourceToolName, targetToolName):
    """
    Generates SQL CTE for appending fields based on SelectField attributes.
    Only includes fields with selected="True".
    """

    # Parse the XML data
    root = ET.fromstring(xml_data)

    select_fields_node = root.find('.//Configuration/SelectFields')

    if select_fields_node is None:
        return [], f"-- No append fields configuration found for ToolID CTE_{toolId}"

    source_fields = []
    target_fields = []

    Selected_source_true_fields = {}
    Selected_target_true_fields = {}

    Selected_source_false_fields = []
    Selected_target_false_fields = []

    current_tool_fields = []

    for field in select_fields_node.findall('SelectField'):
        field_name = field.get('field')
        selected = field.get('selected')
        selected_rename = field.get('rename')
        selected_input = field.get('input')

        if (selected == 'True' and field_name.upper() != '*UNKNOWN'):
            if (selected_rename is not None and selected_input == 'Source_'):
                Selected_source_true_fields[field_name[7:]] = selected_rename
            elif (selected_rename is None and selected_input == 'Source_'):
                Selected_source_true_fields[field_name[7:]] = field_name[5:]
            elif (selected_rename is not None and selected_input == 'Target_'):
                Selected_target_true_fields[field_name[7:]] = selected_rename
            elif (selected_rename is None and selected_input == 'Target_'):
                Selected_target_true_fields[field_name[7:]] = field_name[6:]
        elif selected == 'False' and field_name.upper() != '*UNKNOWN':
            if (selected_input == 'Source_'):
                Selected_source_false_fields.append(field_name[7:])
            elif (selected_input == 'Target_'):
                Selected_target_false_fields.append(field_name[7:])
        elif (selected == "True" and field_name.upper() == '*UNKNOWN'):
            for field in sourceToolColList:
                if (field not in Selected_source_false_fields and field not in Selected_source_true_fields.keys()):
                    source_fields.append(f'SourceTable."{field}"')
                    current_tool_fields.append(field)
                elif (field not in Selected_source_false_fields and field in Selected_source_true_fields.keys()):
                    if (Selected_source_true_fields[field] == field):
                        source_fields.append(f'SourceTable."{field}"')
                    else:
                        source_fields.append(f'SourceTable."{field}" AS "{Selected_source_true_fields[field]}"')
                    current_tool_fields.append(Selected_source_true_fields[field])
            for field in TargetToolColList:
                if (field not in Selected_target_false_fields and field not in Selected_target_true_fields.keys()):
                    target_fields.append(f'TargetTable."{field}"')
                    current_tool_fields.append(field)
                elif (field not in Selected_target_false_fields and field in Selected_target_true_fields.keys()):
                    if (Selected_target_true_fields[field] == field):
                        target_fields.append(f'TargetTable."{field}"')
                    else:
                        target_fields.append(f'TargetTable."{field}" AS "{Selected_target_true_fields[field]}"')
                    current_tool_fields.append(Selected_target_true_fields[field])
        elif (selected == "False" and field_name.upper() == '*UNKNOWN'):
            for k, v in Selected_source_true_fields.items():
                current_tool_fields.append(v)
                if (k == v):
                    source_fields.append(f'SourceTable."{k}"')
                else:
                    source_fields.append(f'SourceTable."{k}" AS "{v}"')
            for k, v in Selected_target_true_fields.items():
                current_tool_fields.append(v)
                if (k == v):
                    target_fields.append(f'TargetTable."{k}"')
                else:
                    target_fields.append(f'TargetTable."{k}" AS "{v}"')

    #     # Only include fields marked as selected
    #     if selected == "True":
    #         selected_fields.append(field_name)

    final_fields = target_fields + source_fields

    # Generate CTE query
    cte_query = f"""
    AppendFields_{toolId} AS (
        SELECT 
            {', '.join(final_fields)}
        FROM {targetToolName}_{targetToolID} TargetTable
        CROSS JOIN {sourceToolName}_{sourceToolID} SourceTable
    )
    """
    return current_tool_fields, cte_query


def generate_cte_for_CrossTab(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
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

    current_tool_fields = prev_tool_fields.copy()
    current_tool_fields.extend(group_by_fields)
    current_tool_fields.extend(unique_values)

    # Generate SQL CTE dynamically
    cte_query = f"""
    {toolName}_{toolId} AS (
        SELECT 
            {', '.join([f'\"{col}\"' for col in current_tool_fields])}, 
            {', '.join(case_statements)}
        FROM {previousToolName}_{previousToolId}
        GROUP BY {', '.join([f'\"{field}\"' for field in group_by_fields])}
        {f'ORDER BY {order_by_clause}' if order_by_clause else ''}
    )
    """

    return current_tool_fields, cte_query


def generate_cte_for_DynamicRename(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
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

    current_tool_fields = prev_tool_fields.copy()

    rename_mappings = []

    # Extract additional attributes based on Rename Mode
    expression = root.find(".//Expression").text if root.find(".//Expression") is not None else ""
    prefix_suffix_type = root.find(".//AddPrefixSuffix/Type")
    prefix_suffix_text = root.find(".//AddPrefixSuffix/Text")
    remove_suffix_text = root.find(".//RemovePrefixSuffix/Text")
    right_input_name = root.find(".//NamesFromMetadata/NewName")

    # Handle FirstRow rename mode
    if rename_mode == "FirstRow":
        rename_mappings = [f"\"{input_fields[i]}\" AS \"{output_fields[i]}\"" for i in range(min_length)]
        current_tool_fields.extend(output_fields)

    # Handle Formula rename mode with sanitized expressions
    elif rename_mode == "Formula":
        rename_mappings = [f"{sanitize_expression_for_filter_formula_dynamic_rename(expression, field)} AS \"{field}\""
                           for field in input_fields]
        current_tool_fields.extend(input_fields)

    # Handle Add Prefix/Suffix rename mode
    elif rename_mode == "Add":
        if prefix_suffix_type is not None and prefix_suffix_text is not None:
            if prefix_suffix_type.text == "Prefix":
                rename_mappings = [f"'{prefix_suffix_text.text}' || \"{field}\" AS \"{field}\"" for field in
                                   input_fields]
            else:
                rename_mappings = [f"\"{field}\" || '{prefix_suffix_text.text}' AS \"{field}\"" for field in
                                   input_fields]
            current_tool_fields.extend(input_fields)

    # Handle Remove Prefix/Suffix rename mode
    elif rename_mode == "Remove":
        if remove_suffix_text is not None:
            rename_mappings = [
                f"REPLACE(\"{field}\", '{remove_suffix_text.text}', '') AS \"{field}\"" for field in input_fields
            ]
            current_tool_fields.extend(input_fields)

    # Handle RightInputMetadata rename mode
    elif rename_mode == "RightInputMetadata":
        if right_input_name is not None:
            rename_mappings = [
                f"\"{right_input_name.text}\" AS \"{field}\"" for field in input_fields
            ]
            current_tool_fields.extend(input_fields)

    # Handle RightInputRows rename mode
    elif rename_mode == "RightInputRows":
        rename_mappings = [
            f"\"{field}\" AS \"{field}\"" for field in input_fields
        ]
        current_tool_fields.extend(input_fields)

    # Default case (if rename mode is unknown or not supported)
    if not rename_mappings:
        rename_mappings = [f"\"{field}\" AS \"{field}\"" for field in input_fields]
        current_tool_fields.extend(input_fields)

    # Generate SQL CTE dynamically
    cte_query = f"""
    {toolName}_{toolId} AS (
        SELECT 
            {', '.join(rename_mappings)}
        FROM {previousToolName}_{previousToolId}
    )
    """

    # {', '.join([f'\"{col}\"' for col in current_tool_fields])},

    return current_tool_fields, cte_query


def generate_cte_for_DataCleansing(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    """
    Parses the Alteryx Data Cleansing node from XML, extracts cleansing operations only if they are active (True),
    and generates an equivalent SQL CTE using ToolID.

    - Extracts selected fields only if transformations are enabled.
    - Handles cleansing operations like replacing nulls, trimming spaces, case conversion, etc.
    """

    root = ET.fromstring(xml_data)

    # Extract selected fields for cleansing (only if enabled)
    fields_element = root.find(".//Value[@name='List Box (11)']")
    # selected_fields = [f.strip('"') for f in
    #                    fields_element.text.split(",")] if fields_element is not None and fields_element.text else []

    selected_fields = []
    if (fields_element is not None and fields_element.text.strip()):
        selected_fields = []
    else:
        for f in fields_element.text.split(","):
            selected_fields.append(f.strip('"'))

    # Extract checkboxes only if their value is "True"
    replace_with_blank = root.find(".//Value[@name='Check Box (84)']")
    replace_with_zero = root.find(".//Value[@name='Check Box (117)']")
    trim_whitespace = root.find(".//Value[@name='Check Box (15)']")
    remove_letters = root.find(".//Value[@name='Check Box (53)']")
    remove_numbers = root.find(".//Value[@name='Check Box (58)']")
    remove_punctuation = root.find(".//Value[@name='Check Box (70)']")
    modify_case = root.find(".//Value[@name='Check Box (77)']")
    case_type = root.find(".//Value[@name='Drop Down (81)']")

    # Extracting current_tool_fields
    current_tool_fields = prev_tool_fields.copy()

    # SQL transformation rules
    sql_transformations = []
    transformations = []

    for field in selected_fields:
        if field not in current_tool_fields:
            current_tool_fields.append(field)

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
        {toolName}_{toolId} AS (
            SELECT {', '.join([f'\"{col}\"' for col in current_tool_fields])},
                   {', '.join(sql_transformations)}
            FROM {previousToolName}_{previousToolId}
        )
        """
    else:
        cte_query = f"""
        -- No active data cleansing transformations for ToolID {toolId}
        {toolName}_{toolId} AS (
             SELECT {', '.join([f'\"{col}\"' for col in current_tool_fields])}
            FROM {previousToolName}_{previousToolId}
        )
        """

    return current_tool_fields, cte_query


def generate_cte_for_Text_To_Columns(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    """
    Parses the Alteryx Text To Columns tool XML configuration and generates an equivalent SQL CTE.
    Handles splitting columns based on delimiters, methods (split to columns or rows), and advanced options.
    Uses UNNEST(STRING_TO_ARRAY) for splitting.
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
    extra_chars_option = extra_chars_option_node.get(
        "value") if extra_chars_option_node is not None else "Leave extra in last column"

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
        new_columns = [f'{output_root_name}_{i + 1}' for i in range(num_columns)]

        split_part_expressions = [
            sanitize_expression_for_filter_formula_dynamic_rename(
                f'SPLIT_PART("{column_to_split}", \'{delimiters}\', {i + 1}) AS "{col}"'
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
        {toolName}_{toolId} AS (
            SELECT {prev_fields_str},
                   {', '.join(split_part_expressions)}
            FROM {previousToolName}_{previousToolId}
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
        {toolName}_{toolId} AS (
            SELECT {prev_fields_str},
                   {unnest_expression}
            FROM {previousToolName}_{previousToolId}
        )
        """

    new_fields = prev_tool_fields + new_columns if split_method == "Split to columns" else prev_tool_fields + [
        output_root_name]
    return new_fields, cte_query


def generate_cte_for_Message(xml_data, previousToolId, toolId, prev_tool_fields):
    """
    Parses the Alteryx Message tool XML configuration and generates an equivalent SQL CTE.
    Handles all Message tool use-cases based on the provided XML file.
    """
    root = ET.fromstring(xml_data)

    message_time = root.find(".//When").text
    message_type = root.find(".//Type").text
    message_expression = root.find(".//MessageExpression").text

    # Map message types to SQL output
    message_type_sql = {
        "Message": "Standard Message",
        "Warning": "Warning Message",
        "Field Conversion Error": "Conversion Error",
        "Error": "Error Message",
        "Error - And Stop Passing Records": "Fatal Error",
        "File Input": "Input File Message",
        "File Output": "Output File Message"
    }.get(message_type, "Unknown Message Type")

    fields = ', '.join([f'"{field}"' for field in prev_tool_fields])

    if message_time == "First":
        cte_query = f"""
        CTE_{toolId} AS (SELECT {fields}, '{message_type_sql}' AS MessageType, '{message_time}' AS MessageTime, '{message_expression}' AS MessageText FROM CTE_{previousToolId})
        """
    elif message_time == "Filter":
        filter_condition = root.find(".//Filter").text
        cte_query = f"""
        CTE_{toolId} AS (SELECT {fields}, '{message_type_sql}' AS MessageType, '{message_time}' AS MessageTime, '{message_expression}' AS MessageText FROM CTE_{previousToolId} WHERE {filter_condition})
        """
    elif message_time == "Last":
        cte_query = f"""
        CTE_{toolId} AS (SELECT {fields}, '{message_type_sql}' AS MessageType, '{message_time}' AS MessageTime, '{message_expression}' AS MessageText FROM CTE_{previousToolId})
        """
    elif message_time == "All":
        cte_query = f"""
        CTE_{toolId} AS (SELECT {fields}, '{message_type_sql}' AS MessageType, '{message_time}' AS MessageTime, '{message_expression}' AS MessageText FROM CTE_{previousToolId})
        """
    else:
        cte_query = f"-- Unsupported message time for ToolID {toolId}"

    new_fields = prev_tool_fields + ["MessageType", "MessageTime", "MessageText"]
    return new_fields, cte_query


def generate_cte_for_MultiFieldFormula(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    """
    Parses Alteryx Multi-Field Formula node from XML, extracts formula transformations dynamically,
    and generates an equivalent SQL CTE.

    - Extracts selected fields from XML.
    - Replaces [_CurrentField_] with actual field names.
    - Applies prefix/suffix if enabled.
    - Includes previousToolId for chaining transformations.
    """

    root = ET.fromstring(xml_data)

    # Extract selected fields
    fields = [field.get("name") for field in root.findall(".//Fields/Field") if field.get("name") != "*Unknown"]

    # Extract expression and transform it
    expression_node = root.find(".//Expression")
    expression = expression_node.text if expression_node is not None else ""
    sanitized_expression = sanitize_expression_for_filter_formula_dynamic_rename(expression)

    # Extract prefix/suffix settings
    new_field_prefix = root.find(".//NewFieldAddOn")
    new_field_prefix = new_field_prefix.text if new_field_prefix is not None else ""

    new_field_position = root.find(".//NewFieldAddOnPos")
    new_field_position = new_field_position.text if new_field_position is not None else "Suffix"

    # Determine if original fields should be kept
    copy_output = root.find(".//CopyOutput")
    copy_output = copy_output is not None and copy_output.get("value") == "True"

    # Generate transformed field names
    if new_field_position == "Prefix":
        transformed_fields = [f'{new_field_prefix}{field}' for field in fields]
    else:
        transformed_fields = [f'{field}{new_field_prefix}' for field in fields]

    # Apply formula to each selected field
    transformations = [
        f"{sanitized_expression.replace('[_CurrentField_]', f'\"{field}\"')} AS \"{new_field}\""
        for field, new_field in zip(fields, transformed_fields)
    ]

    # Determine final field selection
    if copy_output:
        all_fields = prev_tool_fields + transformed_fields
    else:
        all_fields = transformed_fields

    fields_selection = ', '.join([f'"{field}"' for field in all_fields])

    # Generate SQL CTE
    cte_query = f"""
    -- Multi-Field Formula transformations applied
    {toolName}_{toolId} AS (
        SELECT {fields_selection}
        FROM {previousToolName}_{previousToolId}
    )
    """

    return all_fields, cte_query


def generate_cte_for_MultiRowFormula(xml_data, previousToolId, toolId, prev_tool_fields, toolName, previousToolName):
    root = ET.fromstring(xml_data)

    # Extracting values from XML
    update_existing = root.find(".//UpdateField").get("value") == "True"
    existing_field = root.find(".//UpdateField_Name").text if update_existing else None
    new_field = root.find(".//CreateField_Name").text if not update_existing else None
    expression = root.find(".//Expression").text.strip()
    num_rows = root.find(".//NumRows").get("value")
    group_by_fields = [field.get("field") for field in root.findall(".//GroupByFields/Field")]

    # Cleaning up the expression
    sanitized_expression = sanitize_expression_for_filter_formula_dynamic_rename(expression)

    # Generating SQL logic
    partition_clause = f"PARTITION BY {', '.join([f'\"{field}\"' for field in group_by_fields])}" if group_by_fields else ""
    lag_lead_function = sanitized_expression.replace("[Row-1:", "LAG(").replace("[Row+1:", "LEAD(").replace("]",
                                                                                                            f", {num_rows}) OVER ({partition_clause} ORDER BY ROW_NUMBER() OVER())")

    # Determining selected fields
    if update_existing:
        transformations = f"{lag_lead_function} AS \"{existing_field}\""
        all_fields = prev_tool_fields  # Keeps original field structure
    else:
        transformations = f"{lag_lead_function} AS \"{new_field}\""
        all_fields = prev_tool_fields + [new_field]

    fields_selection = ', '.join([f'"{field}"' for field in all_fields])

    # Generating CTE query
    cte_query = f"""
    {toolName}_{toolId} AS (
        SELECT {fields_selection}
        FROM {previousToolName}_{previousToolId}
    )
    """

    return all_fields, cte_query


def connectionDetails(file, dfWithTool):
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

    dfWithTool = dfWithTool[['ToolID', 'Plugin']]
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
                    df_with_tool_name.at[
                        match_row.name, 'Origin_ToolID'] = f"{match_row['Origin_ToolID']}_{match_row['Origin_Connection']}"

    for index, row in df_with_tool_name[
        df_with_tool_name['Plugin'] == 'AlteryxBasePluginsGui.Unique.Unique'].iterrows():
        destination = row['Destination_ToolID']

        # Find the rows where the destination matches origin
        matching_rows = df_with_tool_name[df_with_tool_name['Origin_ToolID'] == destination]

        # Check if there are multiple matching rows with different originConnections
        if len(matching_rows) > 1 and len(matching_rows['Origin_Connection'].unique()) > 1:
            # Modify the origin column by appending originConnection if needed
            for _, match_row in matching_rows.iterrows():
                # Only modify the origin if originConnection is different
                if match_row['Origin_Connection'] != row['Origin_Connection']:
                    df_with_tool_name.at[
                        match_row.name, 'Origin_ToolID'] = f"{match_row['Origin_ToolID']}_{match_row['Origin_Connection']}"

    for index, row in df_with_tool_name[
        df_with_tool_name['Plugin'] == 'AlteryxBasePluginsGui.Filter.Filter'].iterrows():
        destination = row['Destination_ToolID']

        # Find the rows where the destination matches origin
        matching_rows = df_with_tool_name[df_with_tool_name['Origin_ToolID'] == destination]

        # Check if there are multiple matching rows with different originConnections
        if len(matching_rows) > 1 and len(matching_rows['Origin_Connection'].unique()) > 1:
            # Modify the origin column by appending originConnection if needed
            for _, match_row in matching_rows.iterrows():
                # Only modify the origin if originConnection is different
                if match_row['Origin_Connection'] != row['Origin_Connection']:
                    df_with_tool_name.at[
                        match_row.name, 'Origin_ToolID'] = f"{match_row['Origin_ToolID']}_{match_row['Origin_Connection']}"

    for index, row in df_with_tool_name[
        df_with_tool_name['Plugin'] == 'LockInGui.LockInFilter.LockInFilter'].iterrows():
        destination = row['Destination_ToolID']

        # Find the rows where the destination matches origin
        matching_rows = df_with_tool_name[df_with_tool_name['Origin_ToolID'] == destination]

        # Check if there are multiple matching rows with different originConnections
        if len(matching_rows) > 1 and len(matching_rows['Origin_Connection'].unique()) > 1:
            # Modify the origin column by appending originConnection if needed
            for _, match_row in matching_rows.iterrows():
                # Only modify the origin if originConnection is different
                if match_row['Origin_Connection'] != row['Origin_Connection']:
                    df_with_tool_name.at[
                        match_row.name, 'Origin_ToolID'] = f"{match_row['Origin_ToolID']}_{match_row['Origin_Connection']}"

    return df, df_with_tool_name


def CTEGneration(df, path, inputNodes):
    cte_list = []
    plugin_name = ""
    output_cte = ""
    for i in path:
        if (i not in inputNodes):
            cte = df.loc[df['ToolID'] == i, 'CTE'].values[0]
            plugin_name = df.loc[df['ToolID'] == i, 'Plugin'].values[0]
            if (plugin_name in ['AlteryxBasePluginsGui.DbFileOutput.DbFileOutput']):
                output_cte = str(cte)
            else:
                cte = str(cte)
                cte_list.append(cte.strip())
    result = "\n\n\n\nWith " + ',\n'.join(cte_list) + output_cte
    if (len(plugin_name) > 0):
        plugin_name = plugin_name.split('.')[-1]
    return result, plugin_name


def finalCTEGeneration(df, executionOrder, inputNodes, outputNodes):
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

    return result, results_dict


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


def find_dependent_nodes(graph, start_node):
    visited = set()
    stack = [start_node]

    while stack:
        node = stack.pop()
        if node not in visited:
            visited.add(node)
            stack.extend(graph.predecessors(node))  # Traverse predecessors to collect dependent nodes

    return visited


def top_sort(df_connetion, outputNodes):
    g1 = nx.DiGraph()
    edges = []

    for _, row in df_connetion.iterrows():
        edges.append((row["Origin_ToolID"], row["Destination_ToolID"]))

    g1.add_edges_from(edges)
    all_dependent_nodes = {}

    for target in outputNodes:
        dependent_nodes = find_dependent_nodes(g1, target)
        all_dependent_nodes[target] = dependent_nodes

    topo_sort = {}
    for target, nodes in all_dependent_nodes.items():
        subgraph = g1.subgraph(nodes)
        try:
            topo_sort[target] = list(nx.topological_sort(subgraph))
        except nx.NetworkXUnfeasible:
            print(f"The graph contains a cycle and therefore a topological sort is not possible for {target}.")

    path_lists = list(topo_sort.values())
    return path_lists


def configuartionDBT(df, toolID):
    properties = df.loc[df['ToolID'] == toolID, 'Properties'].values[0]

    root = ET.fromstring(properties)
    fileFormat = root.find(".//File").get('FileFormat')

    if fileFormat == '25':  # excel output
        outputOption = root.find(".//OutputOption").text

        if outputOption in ('Create', 'Overwrite', 'RemoveFile'):
            config = f"""{{{{
                config(
                    schema='Add your schema here',
                    materialized = 'table'
                    )
            }}}}"""

        elif outputOption == 'Append':
            config = f"""{{{{
                config(
                    schema='Add your schema here',
                    materialized = 'incremental',
                    incremental_strategy = 'append'
                    )
            }}}}"""

    elif fileFormat == '0':  # csv output
        delimeter = root.find(".//Delimeter").text

        config = f"""{{{{
            config(
                schema='Add your schema here',
                materialized = 'table'
                -- Please use this delimiter while unloading " {delimeter} "
                )
        }}}}"""

    elif fileFormat == '23':  # odbc output
        outputOption = root.find(".//OutputOption").text

        if outputOption in ('Create', 'Overwrite', 'RemoveFile'):
            config = f"""{{{{
                config(
                    schema='Add your schema here',
                    materialized = 'table'
                    )
            }}}}"""

        elif outputOption == 'Append':
            config = f"""{{{{
                config(
                    schema='Add your schema here',
                    materialized = 'incremental',
                    incremental_strategy = 'append'
                    )
            }}}}"""

    return config


if __name__ == "__main__":
    st.title('Alteryx Converter')
    fileNameList = st.file_uploader('Upload XML files', type=['yxmd', 'xml'], accept_multiple_files=True)

    cteDictionaries = []  # This will store the cteDictionary for each file

    if fileNameList:
        for file in fileNameList:

            # st.write(getToolData(file))

            plugin_functions = {
                'AlteryxBasePluginsGui.AlteryxSelect.AlteryxSelect': generate_cte_for_AlteryxSelect,
                'LockInGui.LockInSelect.LockInSelect': generate_cte_for_AlteryxSelect,
                'AlteryxSpatialPluginsGui.Summarize.Summarize': generate_cte_for_Summarize,
                'AlteryxBasePluginsGui.Formula.Formula': generate_cte_for_Formula,
                'AlteryxBasePluginsGui.Sort.Sort': generate_cte_for_Sort,
                'AlteryxBasePluginsGui.Sample.Sample': generate_cte_for_Sample,
                'AlteryxBasePluginsGui.RunningTotal.RunningTotal': generate_cte_for_RunningTotal,
                'AlteryxBasePluginsGui.RecordID.RecordID': generate_cte_for_RecordID,
                'AlteryxBasePluginsGui.RegEx.RegEx': generate_cte_for_Regex,
                'Imputation_v3': generate_cte_for_Imputation,
                'WeightedAvg': generate_cte_for_WeightedAvg,
                'AlteryxBasePluginsGui.CrossTab.CrossTab': generate_cte_for_CrossTab,
                'Cleanse': generate_cte_for_DataCleansing,
                'AlteryxBasePluginsGui.DynamicRename.DynamicRename': generate_cte_for_DynamicRename,
                'AlteryxBasePluginsGui.TextToColumns.TextToColumns': generate_cte_for_Text_To_Columns,
                'AlteryxBasePluginsGui.Message.Message': generate_cte_for_Message,
                'AlteryxBasePluginsGui.MultiFieldFormula.MultiFieldFormula': generate_cte_for_MultiFieldFormula,
                'AlteryxBasePluginsGui.MultiRowFormula.MultiRowFormula': generate_cte_for_MultiRowFormula,
                'CountRecords': generate_cte_for_CountRecords,
                'AlteryxBasePluginsGui.DbFileOutput.DbFileOutput': generate_cte_for_DbFileOutput,
                'LockInGui.LockInStreamOut.LockInStreamOut': generate_cte_for_LockInStreamOut,
                'SelectRecords': generate_cte_for_SelectRecords,
                'AlteryxBasePluginsGui.Transpose.Transpose': generate_cte_for_Transpose,
                'AlteryxBasePluginsGui.Rank.Rank': generate_cte_for_Rank,
                'MultiFieldBinning_v2': generate_cte_for_MultiFieldBinning,
                'AlteryxBasePluginsGui.DateTime.DateTime': generate_cte_for_DateTime,
                'AlteryxBasePluginsGui.Tile.Tile': generate_cte_for_Tile,
                'RandomRecords': generate_cte_for_RandomRecords
            }

            df = getToolData(file)

            functionCallList, parentMap = connectionDetails(file, df)

            executionOrder, inputNodes, outputNodes, df_connetion = executionOrders(parentMap)

            path_lists = top_sort(df_connetion, outputNodes)

            functionCallList, _, _, _ = executionOrders(functionCallList)

            df = generate_ctes_for_plugin(df, parentMap, functionCallList)

            # cte, cteDictionary = finalCTEGeneration(df, executionOrder, inputNodes, outputNodes)
            cte_dict = {}
            for path in path_lists:

                final_cte, plugin_name = CTEGneration(df, path, inputNodes)
                if plugin_name in ('DbFileOutput'):
                    config = configuartionDBT(df, path[-1])
                    cte_dict[plugin_name + '_' + path[-1]] = config + final_cte

            cteDictionaries.append(cte_dict)
            st.write(df)
            st.write(df[['toolPluginName', 'ColumnsList']])
            # st.write(parentMap)
            # st.write(executionOrder)
            # st.write(inputNodes)
            # st.write(outputNodes)
            # st.write(cte)
            # st.write(cteDictionary)

        zip_file_path = create_zip_of_folders(fileNameList, cteDictionaries)

        # Provide the zip file for download
        with open(zip_file_path, "rb") as f:
            st.download_button("Download All SQL Files", f, file_name=zip_file_path)
