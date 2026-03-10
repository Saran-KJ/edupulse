import sys
import os
sys.path.insert(0, os.path.abspath('.'))
import google.generativeai as genai
from config import get_settings

def list_models():
    settings = get_settings()
    genai.configure(api_key=settings.gemini_api_key)
    print("Listing available Gemini models:")
    try:
        for m in genai.list_models():
            if 'generateContent' in m.supported_generation_methods:
                print(f"- {m.name}")
    except Exception as e:
        print(f"Error listing models: {e}")

if __name__ == "__main__":
    list_models()
