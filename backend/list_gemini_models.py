import google.generativeai as genai
import config as cfg

def list_models():
    settings = cfg.get_settings()
    keys = [settings.skill_gemini_api_key, settings.gemini_api_key]
    
    for i, key in enumerate(keys):
        if not key: continue
        print(f"\n--- Testing Key {i+1} ---")
        try:
            genai.configure(api_key=key)
            for m in genai.list_models():
                if 'generateContent' in m.supported_generation_methods:
                    print(f"Model: {m.name}")
        except Exception as e:
            print(f"Error listing models with key {i+1}: {e}")

if __name__ == "__main__":
    list_models()
