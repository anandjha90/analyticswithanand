import requests
import msal

# Replace with your registered app credentials
client_id = '2e6c312c-343d-423d-bef8-5bf1dc43795e'
client_secret = 'IZO8Q~oJL9kWmL6s4RReZGaZYB1F4qO09aYImaG2'
tenant_id = '373ef1a3-001e-47cc-9486-82a7f4c6221d'

def request_access_token():
    authority_url = f'https://login.microsoftonline.com/{tenant_id}'
    scope = ['https://analysis.windows.net/powerbi/api/.default']

    app = msal.ConfidentialClientApplication(
        client_id,
        authority=authority_url,
        client_credential=client_secret
    )

    token_response = app.acquire_token_for_client(scopes=scope)
    if 'access_token' not in token_response:
        raise Exception(token_response.get('error_description', 'Unknown error'))

    return token_response['access_token']

access_token = request_access_token()

dataset_id = 'aa74484a-cb61-4836-841b-a168fc30a656'
WorkspaceId = 'b8c8eaa4-f32b-478e-9601-c14b1c59d8fe'
endpoint = f'https://api.powerbi.com/v1.0/myorg/groups/{WorkspaceId}/datasets/{dataset_id}/refreshes'
headers = {
    'Authorization': f'Bearer {access_token}'
}

response = requests.post(endpoint, headers=headers)
if response.status_code == 202:
    print('✅ Dataset refresh initiated.')
else:
    print('❌ Failed to refresh dataset.')
    print(response.status_code, response.reason)
    print(response.json())
