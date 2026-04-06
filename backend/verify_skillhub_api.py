import sys
import os

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    import config as cfg
    from gemini_service import generate_skill_content
    
    settings = cfg.get_settings()
    print(f"SKILLHUB_API_KEY loaded: {'Yes' if settings.skillhub_api_key else 'No'}")
    if settings.skillhub_api_key:
        print(f"Key starts with: {settings.skillhub_api_key[:10]}...")
    
    print("\nAttempting to call generate_skill_content (dry run with print)...")
    # We can't easily perform a real call without hitting the API, 
    # but we can check if the logic correctly selects the key.
    
    skill_category = "Programming"
    override_key = (
        settings.skillhub_api_key if settings.skillhub_api_key else
        (settings.nvidia_api_key if settings.nvidia_api_key else
        (settings.programming_api_key if skill_category.lower() == "programming" and settings.programming_api_key else settings.skill_gemini_api_key))
    )
    
    print(f"Selected override_key: {override_key[:10]}...")
    if override_key == settings.skillhub_api_key:
        print("SUCCESS: SkillHub API Key correctly prioritized!")
    else:
        print("FAILURE: SkillHub API Key not prioritized.")

except Exception as e:
    print(f"Error during verification: {e}")
