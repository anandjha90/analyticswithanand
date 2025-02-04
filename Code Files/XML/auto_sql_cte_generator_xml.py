import streamlit as st
import xml.etree.ElementTree as ET
import pandas as pd
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

def connectionDetails(filePath):
    tree = ET.parse(filePath)
    root = tree.getroot()
    # Create a dictionary to map ToolID to its CTE name
    tool_to_cte_map = {}
    connections = {}

    # Populate the map with connections data
    connectionRoot = root.find('Connections')
    for conn in connectionRoot.findall('.//Connection'):
        origin_tool_id = conn.find('Origin').get('ToolID')
        destination_tool_id = conn.find('Destination').get('ToolID')

        # Assign a CTE name to each ToolID (use a set to avoid duplication)
        tool_to_cte_map[origin_tool_id] = f"CTE_{origin_tool_id}"
        tool_to_cte_map[destination_tool_id] = f"CTE_{destination_tool_id}"

        # Store the connection from origin to destination (handle multiple destinations per origin)
        if origin_tool_id not in connections:
            connections[origin_tool_id] = []
        connections[origin_tool_id].append(destination_tool_id)
    return tool_to_cte_map,connections


# Function to iterate over each row and generate the correct CTE based on Plugin Name
def generate_ctes_for_plugin(df):
    # Iterate through each row in the DataFrame
    for index, row in df.iterrows():
        # Depending on Plugin Name, generate the appropriate CTE
        if row['Plugin'] == 'AlteryxBasePluginsGui.AlteryxSelect.AlteryxSelect':
            # Generate CTE for AlteryxSelect
            df.loc[index, 'CTE'] = generate_cte_for_AlteryxSelect(row['Properties'])
        elif row['Plugin'] == 'AlteryxSpatialPluginsGui.Summarize.Summarize':
            # Generate CTE for Summarize
            df.loc[index, 'CTE'] = generate_cte_for_Summarize(row['Properties'])
        else:
            df.loc[index, 'CTE'] = None  # If no logic for other Plugin Names

    return df

def generate_cte_for_AlteryxSelect(xml_data):
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
        SelectedFields AS (
            SELECT
                {', '.join(selected_columns)}
            FROM YourTableName  
        )
        """

    return cte_query


# Function to parse the XML and generate SQL CTE for GroupBy and Aggregation
def generate_cte_for_Summarize(xml_data):
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
    SummarizedData AS (
        SELECT
            {', '.join(group_by_fields)},  -- Group By Fields
            {', '.join(aggregate_fields)}  -- Aggregated Fields
        FROM table_reference -- Use the previous CTE or current tool's CTE as the table
        GROUP BY
            {', '.join(group_by_fields_before_rename)}  -- Group By Fields Before Rename
    )
    """

    return cte_query



if __name__ == "__main__":
    st.title('Alteryx Converter')
    fileNameList = st.file_uploader('Upload XML files', type=['yxmd','xml'], accept_multiple_files=True)

    if fileNameList:
        for file in fileNameList:
            st.write(getToolData(file))

            file.seek(0)
            tool_to_cte_map,connections = connectionDetails(file)

            file.seek(0)
            df= getToolData(file)
            df['Source file'] = file.name

            df = generate_ctes_for_plugin(df)

            st.write(df)
            st.write(tool_to_cte_map)
            st.write(connections)
