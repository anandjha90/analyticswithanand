import os
import json
import requests
import time
from dotenv import load_dotenv

# Load variables from .env into environment
load_dotenv()
# Access the variable
api_key = os.getenv("GEMINI_API_KEY")

def read_file_content(file_path):
    """
    Reads the raw content of a file.

    Args:
        file_path (str): The path to the file.

    Returns:
        str or None: The content of the file as a string, or None if an error occurs.
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            return file.read()
    except Exception as e:
        print(f"Error reading file '{file_path}': {e}")
        return None


def write_to_file(file_path, content):
    """
    Writes the given content to a file.

    Args:
        file_path (str): The path to the file.
        content (str): The content to write to the file.

    Returns:
        bool: True if the operation was successful, False otherwise.
    """
    try:
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(content)
        return True
    except Exception as e:
        print(f"Error writing to file '{file_path}': {e}")
        return False


def call_gemini_api(payload, api_key):
    """
    Makes a POST request to the Gemini API and returns the extracted text.
    Includes retry logic for rate limiting errors.

    Args:
        payload (dict): The payload to send to the API.
        api_key (str): Your Gemini API key.

    Returns:
        str: The extracted text content from the API response, or None on failure.
    """
    if not api_key:
        print("Error: GEMINI_API_KEY not found. Please ensure it is set in your .env file.")
        return None

    api_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
    
    max_retries = 5
    backoff_factor = 2  # Initial wait time in seconds

    for attempt in range(max_retries):
        try:
            response = requests.post(
                api_url,
                headers={'Content-Type': 'application/json'},
                data=json.dumps(payload)
            )
            response.raise_for_status()  # This will raise an HTTPError for bad responses (4xx or 5xx)
            
            result = response.json()

            # Extract and clean the text from the response
            text_content = result["candidates"][0]["content"]["parts"][0]["text"]
            text_content = text_content.strip()
            if text_content.startswith("```markdown"):
                text_content = text_content[len("```markdown"):].strip()
            elif text_content.startswith("```"):
                text_content = text_content[3:].strip()

            if text_content.endswith("```"):
                text_content = text_content[:-3].strip()

            return text_content # Success, exit the loop and return content

        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 429:
                wait_time = backoff_factor * (2 ** attempt)
                print(f"Warning: Rate limit exceeded (429). Retrying in {wait_time} seconds... (Attempt {attempt + 1}/{max_retries})")
                time.sleep(wait_time)
            else:
                # For other HTTP errors, don't retry, just fail
                print(f"Error calling Gemini API (HTTP {e.response.status_code}): {e}")
                return None
        except requests.exceptions.RequestException as e:
            print(f"Error calling Gemini API: {e}")
            return None # For connection errors etc., don't retry
        except (json.JSONDecodeError, KeyError, IndexError, AttributeError) as e:
            print(f"Error processing response from Gemini API: {e}")
            if 'response' in locals():
                print(f"Received Response: {response.text}")
            return None # Malformed response, don't retry

    print(f"Error: Failed to call Gemini API after {max_retries} attempts due to rate limiting.")
    return None


def generate_adf_lineage_summary(arm_template_path, output_folder):
    """
    Generates an ADF lineage summary from an ARM template using the Gemini API.

    Args:
        arm_template_path (str): The path to the ADF ARM template JSON file.
        output_folder (str): The path to the main output folder.
    """
    print(f"Starting ADF lineage summary generation for: {arm_template_path}")
    arm_template_content = read_file_content(arm_template_path)
    if not arm_template_content:
        return

    prompt = f"""You are an expert ADF lineage analyzer. Given this ARM template JSON from '{arm_template_path}'. Extract STTM for all activities: list source dataset/table/columns, target dataset/table/columns, transformations, and business rules. Output as Markdown table: |Source Table|Source Columns|Transformation|Target Table|Target Columns|Confidence|.

ARM Template Content:
```json
{arm_template_content}
```
"""

    payload = {"contents": [{"role": "user", "parts": [{"text": prompt}]}]}

    content = call_gemini_api(payload, api_key)

    if content:
        # Ensure the output directory exists
        os.makedirs(output_folder, exist_ok=True)
        
        output_file_path = os.path.join(output_folder, "gemini_summary_latest.md")
        
        if write_to_file(output_file_path, content):
            print(f"Successfully generated ADF lineage summary at: '{output_file_path}'")
        else:
            print(f"Failed to write ADF lineage summary for '{arm_template_path}'")
    else:
        print(f"Failed to generate content from Gemini API for '{arm_template_path}'")
