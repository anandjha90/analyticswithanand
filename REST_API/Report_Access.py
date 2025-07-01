import requests
import msal

# Replace with your Azure app details
client_id = '2e6c312c-343d-423d-bef8-5bf1dc43795e'
client_secret = 'IZO8Q~oJL9kWmL6s4RReZGaZYB1F4qO09aYImaG2'
tenant_id = '373ef1a3-001e-47cc-9486-82a7f4c6221d'

# Authority and scope
authority_url = f"https://login.microsoftonline.com/{tenant_id}"
scope = ["https://analysis.windows.net/powerbi/api/.default"]

# Initialize MSAL client
app = msal.ConfidentialClientApplication(
    client_id,
    authority=authority_url,
    client_credential=client_secret
)

# Acquire token
result = app.acquire_token_for_client(scopes=scope)
# Workspace ID
groupId = 'b8c8eaa4-f32b-478e-9601-c14b1c59d8fe'

if "access_token" in result:
    access_token = result["access_token"]
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    }

    # Call Power BI REST API to get list of reports
    endpoint = f"https://api.powerbi.com/v1.0/myorg/groups/{groupId}/reports"
    response = requests.get(endpoint, headers=headers)
    if response.status_code == 200:
        reports = response.json().get("value", [])
        for report in reports:
            print(f"Report Name: {report['name']}")
            print(f"Report ID: {report['id']}")
            print(f"Web URL: {report['webUrl']}")
            print('-' * 40)
    else:
        print(f"Failed to get reports: {response.status_code} - {response.text}")
else:
    print(f"Authentication failed: {result.get('error_description')}")
