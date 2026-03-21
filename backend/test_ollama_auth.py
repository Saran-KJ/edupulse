import os

url = "http://localhost:11434/api/chat"
model = "gpt-oss:120b-cloud"
# Use environment variables for sensitive information
key = os.getenv("GOOGLE_API_KEY", "your-google-api-key-here")
openai_key = os.getenv("OPENAI_API_KEY", "your-openai-api-key-here")
payload = {
    "model": model,
    "messages": [{"role": "user", "content": "hi"}],
    "stream": False
}

headers_to_test = [
    {"Authorization": f"Bearer {key}"},
    {"Authorization": f"Bearer {openai_key}"},
    {"api-key": openai_key},
    {} # No header
]

for headers in headers_to_test:
    print(f"\nTesting headers: {headers}")
    try:
        r = requests.post(url, json=payload, headers=headers, timeout=30)
        print(f"Status: {r.status_code}")
        print(f"Response: {r.text[:200]}")
    except Exception as e:
        print(f"Error: {e}")
