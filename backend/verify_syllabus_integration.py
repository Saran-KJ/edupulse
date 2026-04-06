import sys
import os

# Add the current directory to sys.path to import gemini_service
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from gemini_service import _get_syllabus_context

def test_context_retrieval():
    print("Testing Syllabus Context Retrieval...")
    
    # Test cases
    test_subjects = [
        ("CS3491", 1),
        ("CS3491", 3),
        ("MA3151", 1),
        ("GE3151", 1),
        ("CS3391", 2)
    ]
    
    for code, unit in test_subjects:
        ctx = _get_syllabus_context(code, unit)
        if ctx:
            print(f"\n[SUCCESS] Found {code} Unit {unit}:")
            print(f"Title: {ctx['title']}")
            print(f"Topics: {ctx['topics'][:100]}...")
        else:
            print(f"\n[FAILURE] Could not find {code} Unit {unit}")

if __name__ == "__main__":
    test_context_retrieval()
