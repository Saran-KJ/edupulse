import os
import sys

# Add the backend directory to sys.path so we can import services
sys.path.append(os.getcwd())

import gemini_service

def test_variety():
    levels = ["Beginner", "Intermediate", "Advanced"]
    results = {}
    
    print("Testing content variety for Programming (JavaScript)...")
    for level in levels:
        content = gemini_service.generate_skill_content("Programming", "JavaScript", level)
        summary = content.get("summary", "")
        results[level] = summary
        print(f"\n[{level}] Summary: {summary}")
        
    # Simple check: are they different?
    if results["Beginner"] != results["Intermediate"] and results["Intermediate"] != results["Advanced"]:
        print("\nSUCCESS: Content varies across levels.")
    else:
        print("\nWARNING: Content might still be similar across levels.")

if __name__ == "__main__":
    test_variety()
