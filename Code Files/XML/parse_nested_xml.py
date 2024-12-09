#!/usr/bin/env python
# coding: utf-8
# importing libraries
import xml.etree.ElementTree as ET
import pandas as pd

# Parse the XML
tree = ET.parse('Expected_Ceded_Claims_by_Treaty093024.xml')  # Replace with your XML file path
root = tree.getroot()

# Initialize a list to store
data = []

# Iterate through all <Node> elements in the XML
for node in root.findall('.//Node'):
    node_data = {}
    
    # Extract ToolID
    tool_id = node.get('ToolID')
    if tool_id:
        node_data['ToolID'] = tool_id
    
    # Extract Plugin (inside GuiSettings)
    plugin = node.find('.//GuiSettings').get('Plugin') if node.find('.//GuiSettings') is not None else None
    if plugin:
        node_data['Plugin'] = plugin
    
    # Extract Position (x and y)
    position = node.find('.//GuiSettings/Position')
    if position is not None:
        node_data['Position X'] = position.get('x')
        node_data['Position Y'] = position.get('y')
    
    # Extract Query (inside Configuration)
    query = node.find('.//Properties/Configuration/Query')
    if query is not None:
        node_data['Query'] = query.text
    
    # Extract Formula or other data if present
    formula_fields = node.findall('.//Properties/Configuration/FormulaFields/FormulaField')
    if formula_fields:
        formula_data = []
        for formula in formula_fields:
            expression = formula.get('expression')
            field = formula.get('field')
            formula_data.append(f"{field}: {expression}")
        node_data['FormulaFields'] = "; ".join(formula_data)
    
    # Append the node data to the list
    data.append(node_data)

# Create a pandas DataFrame from the extracted data
df = pd.DataFrame(data)
df

# Save the DataFrame to an Excel file
df.to_excel('output_xml.xlsx', index=False)
