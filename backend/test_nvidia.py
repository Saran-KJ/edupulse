import os
import sys
import json
import requests

# Add backend to path to import config and gemini_service
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import config as cfg
import gemini_service

def test_nvidia_connectivity():
    print("=" * 60)
    print("NVIDIA API Connectivity Test")
    print("=" * 60)
    
    settings = cfg.get_settings()
    api_key = settings.nvidia_api_key
    
    if not api_key:
        print("[ERROR] NVIDIA_API_KEY not found in settings!")
        return
    
    print(f"[INFO] NVIDIA API Key found: {api_key[:10]}...")
    
    # Test 1: Direct Call
    print("\n--- Test 1: Direct NVIDIA API Call ---")
    url = "https://integrate.api.nvidia.com/v1/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }
    payload = {
        "model": "meta/llama-3.1-70b-instruct",
        "messages": [{"role": "user", "content": "Say 'NVIDIA Connected'"}],
        "max_tokens": 50
    }
    
    try:
        resp = requests.post(url, headers=headers, json=payload, timeout=20)
        resp.raise_for_status()
        data = resp.json()
        content = data['choices'][0]['message']['content'].strip()
        print(f"[SUCCESS] Direct Response: {content}")
    except Exception as e:
        print(f"[FAIL] Direct Call Failed: {e}")
        if hasattr(e, 'response') and e.response is not None:
             print(f"   Response Body: {e.response.text}")
             
    # Test 2: Via gemini_service._call_ai_service
    print("\n--- Test 2: Via gemini_service._call_ai_service (JSON) ---")
    prompt = "Return a JSON object with a key 'status' and value 'connected'."
    try:
        data = gemini_service._call_ai_service(prompt, is_json=True)
        if data and isinstance(data, dict) and data.get('status') == 'connected':
            print(f"[SUCCESS] Service Layer (JSON) Response: {data}")
        elif data:
            print(f"[SUCCESS] Service Layer responded but format differs: {data}")
        else:
            print(f"[FAIL] Service Layer (JSON) returned no data")
    except Exception as e:
        print(f"[FAIL] Service Layer (JSON) Error: {e}")

    # Test 3: Via generate_quiz_questions
    print("\n--- Test 3: Via generate_quiz_questions ---")
    try:
        questions = gemini_service.generate_quiz_questions("Python Programming", 1, "LOW")
        if questions and len(questions) > 0:
            print(f"[SUCCESS] Quiz Generation Success: Generated {len(questions)} questions")
            print(f"  Sample Question: {questions[0].get('question')}")
        else:
            print("[FAIL] Quiz Generation returned no questions")
    except Exception as e:
        print(f"❌ Quiz Generation Error: {e}")

    print("\n" + "=" * 60)
    print("TESTS COMPLETE")
    print("=" * 60)

if __name__ == "__main__":
    test_nvidia_connectivity()
