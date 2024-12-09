#!/usr/bin/env python
# coding: utf-8
import xml.etree.ElementTree as ET
import pandas as pd

# Parse the XML
tree = ET.parse('Expected_Ceded_Claims_by_Treaty093024.xml')  # Replace with your XML file path
root = tree.getroot()

# Initialize a list to store the extracted data
data = []

# Iterate through all <Node> elements in the XML
for node in root.findall('.//Node'):
    node_data = {}

    # Extract ToolID
    tool_id = node.get('ToolID')
    if tool_id:
        node_data['ToolID'] = tool_id

    # Extract Plugin (inside GuiSettings)
    gui_settings = node.find('.//GuiSettings')
    if gui_settings is not None:
        node_data['Plugin'] = gui_settings.get('Plugin', '')

    # Extract Position (x and y)
    position = gui_settings.find('./Position') if gui_settings is not None else None
    if position is not None:
        node_data['Position X'] = position.get('x', '')
        node_data['Position Y'] = position.get('y', '')

    # Extract OutputFileName
    output_file = node.find('.//Properties/Configuration/File')
    if output_file is not None:
        output_file_name = output_file.get('OutputFileName', '')
        node_data['OutputFileName'] = output_file_name

    # Extract Query (inside Configuration)
    query = node.find('.//Properties/Configuration/Query')
    if query is not None:
        node_data['Query'] = query.text

    # Extract Formula fields
    formula_fields = node.findall('.//Properties/Configuration/FormulaFields/FormulaField')
    if formula_fields:
        formula_data = []
        for formula in formula_fields:
            expression = formula.get('expression', '')
            field = formula.get('field', '')
            formula_data.append(f"{field}: {expression}")
        node_data['FormulaFields'] = "; ".join(formula_data)

    # Extract Fields and their attributes
    fields = node.findall('.//Field')
    if fields:
        field_data = []
        for field in fields:
            field_name = field.get('name', '')
            field_type = field.get('type', '')
            field_size = field.get('size', '')
            field_source = field.get('source', '')
            field_data.append(f"{field_name} (Type: {field_type}, Size: {field_size}, Source: {field_source})")
        node_data['Fields'] = "; ".join(field_data)

    # Extract Summarize fields
    summarize_fields = node.findall('.//SummarizeField')
    if summarize_fields:
        summarize_data = []
        for summarize in summarize_fields:
            field = summarize.get('field', '')
            action = summarize.get('action', '')
            rename = summarize.get('rename', '')
            summarize_data.append(f"{field} (Action: {action}, Rename: {rename})")
        node_data['SummarizeFields'] = "; ".join(summarize_data)

    # Extract Select fields
    select_fields = node.findall('.//SelectField')
    if select_fields:
        select_data = []
        for select in select_fields:
            field = select.get('field', '')
            selected = select.get('selected', '')
            rename = select.get('rename', '')
            select_data.append(f"{field} (Selected: {selected}, Rename: {rename})")
        node_data['SelectFields'] = "; ".join(select_data)

    # Extract Join fields
    join_fields = node.findall('.//JoinInfo')
    if join_fields:
        join_data = []
        for join in join_fields:
            connection = join.get('connection', '')
            field = join.find('.//Field').get('field', '') if join.find('.//Field') is not None else ''
            join_data.append(f"Connection: {connection}, Field: {field}")
        node_data['JoinFields'] = "; ".join(join_data)

    
    # Extract connection parameters from <Connections>
    connections = root.find('.//Connections')
    if connections is not None:
        connection_data = []
        for connection in connections.findall('.//Connection'):
            origin = connection.find('.//Origin')
            destination = connection.find('.//Destination')
            connection_info = {
                "Origin ToolID": origin.get('ToolID', '') if origin is not None else '',
                "Origin Connection": origin.get('Connection', '') if origin is not None else '',
                "Destination ToolID": destination.get('ToolID', '') if destination is not None else '',
                "Destination Connection": destination.get('Connection', '') if destination is not None else '',
                "Wireless": connection.get('Wireless', 'False'),
                "Name": connection.get('name', '')
            }
            connection_data.append(
                f"Origin ToolID: {connection_info['Origin ToolID']}, "
                f"Origin Connection: {connection_info['Origin Connection']}, "
                f"Destination ToolID: {connection_info['Destination ToolID']}, "
                f"Destination Connection: {connection_info['Destination Connection']}, "
                f"Wireless: {connection_info['Wireless']}, Name: {connection_info['Name']}"
            )
        node_data['Connection'] = "; ".join(connection_data)     
        
    # Append the node data to the list
    data.append(node_data)

# Create a pandas DataFrame from the extracted data
df = pd.DataFrame(data)

# Save the DataFrame to an Excel file
output_path = 'detailed_output_xml.xlsx'  # Replace with your desired output path
df.to_excel(output_path, index=False)

print(f"XML data has been extracted and saved to {output_path}")
