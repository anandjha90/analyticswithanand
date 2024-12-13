import xml.etree.ElementTree as ET
import pandas as pd

def getToolData(filePath):
    # Parse the XML
    tree = ET.parse(filePath)
    root = tree.getroot()

    data=[]

    # Iterate through all <Node> elements in the XML
    for node in root.findall('.//Node'):

        node_data = {}

        # Extract ToolID
        tool_id = node.get('ToolID')
        if tool_id:
            node_data['ToolID']=tool_id

        # Extract Plugin (inside GuiSettings)
        gui_settings = node.find('.//GuiSettings')
        if gui_settings is not None:
            node_data['Plugin'] = gui_settings.get('Plugin', '')

        data.append(node_data)
    df=pd.DataFrame(data)
    res = df.groupby('Plugin')['ToolID'].apply(lambda x: ','.join(map(str, x))).reset_index()
    res.columns = ['Plugin', "ToolID's"]
    res['Tool Name'] = res['Plugin'].apply(lambda x: x.split('.')[-1])
    res['Tool Count'] = res["ToolID's"].apply(lambda x: len(x.split(',')))
    return res

filePath=['Expected_Ceded_Claims_by_Treaty093024.xml','Unpk_to_bsum.xml']
output_path = 'ToolAnalyzerV2.xlsx'    ## give the complete path for another location like C:\\Work\\Alteryx Accelerator\\ToolAnalyzer.xlsx
toolNames=['AlteryxSelect','AppendFields','BrowseV2','DbFileInput','DbFileOutput','DynamicRename','Filter','Formula','Join','Sample','Union','Summarize','TextBox','DateTime','Charting','Container','Multi-Field Formula','Sort','Transpose','Random ampling','CrossTab','FindReplace','Macro','Container','Charting','Connectors','DataStreamOut']

finalDF=pd.DataFrame()
for file in filePath:
    res=getToolData(file)

    pivotData= {}
    for tool in toolNames:
        toolIds = res[res['Tool Name']==tool]['Tool Count'].tolist()
        if toolIds:
            pivotData[tool]=toolIds
        else:
            pivotData[tool]=[0]
    eachRow=pd.DataFrame.from_dict(pivotData,orient='columns')
    eachRow['Alteryx Workflow Name']=file.split("\\")[-1]
    eachRow=eachRow[['Alteryx Workflow Name']+[col for col in eachRow.columns if col!='Alteryx Workflow Name']]
    finalDF=pd.concat([finalDF,eachRow],ignore_index=True)
finalDF.to_excel(output_path, index=False)
