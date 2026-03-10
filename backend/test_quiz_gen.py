import sys
import os
sys.path.insert(0, os.path.abspath('.'))

from gemini_service import generate_quiz_questions

def test_quiz_generation():
    print("Testing Gemini Quiz Generation for EduPulse...")
    subject = "DBMS"
    unit = 1
    risk = "HIGH"
    
    print(f"Requesting {risk} risk quiz for {subject} Unit {unit}...")
    questions = generate_quiz_questions(subject, unit, risk)
    
    if questions:
        print(f"✓ Successfully generated {len(questions)} questions.")
        for i, q in enumerate(questions[:2]): # Show first 2
            print(f"\nQ{i+1}: {q['question']}")
            print(f"  A) {q['option_a']}")
            print(f"  B) {q['option_b']}")
            print(f"  C) {q['option_c']}")
            print(f"  D) {q['option_d']}")
            print(f"  Correct: {q['correct_answer']}")
    else:
        print("✗ Failed to generate questions or received empty response.")

if __name__ == "__main__":
    test_quiz_generation()
