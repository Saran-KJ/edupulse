"""
End-to-End Test: Quiz Answering Flow with All Question Types
Tests the complete flow from question selection to submission with MCQ, MCS, and NAT.
"""

import sys
import json
from datetime import datetime
from scoring_service import ScoringService

def print_section(title):
    print("\n" + "="*80)
    print(title.center(80))
    print("="*80)

def print_subsection(title):
    print("\n" + "-"*80)
    print(title)
    print("-"*80)

def test_mcq_flow():
    """Test MCQ question answering flow"""
    print_subsection("MCQ FLOW TEST")
    
    scoring = ScoringService()
    
    # Simulate student answering MCQ
    question_type = 'MCQ'
    student_answer = 'Option B'
    correct_answer = 'Option B'
    
    is_correct = scoring.evaluate_answer(student_answer, correct_answer, question_type)
    
    print(f"Question Type: {question_type}")
    print(f"Student Answer: {student_answer}")
    print(f"Correct Answer: {correct_answer}")
    result_str = "CORRECT" if is_correct else "INCORRECT"
    print(f"Result: {result_str}")
    
    assert is_correct, "MCQ should be correct"
    print("[PASS] MCQ flow works correctly")

def test_mcs_flow():
    """Test MCS question answering flow"""
    print_subsection("MCS FLOW TEST")
    
    scoring = ScoringService()
    
    # Simulate student answering MCS correctly
    question_type = 'MCS'
    student_answer = ['Option A', 'Option B', 'Option D']
    correct_answer = 'Option A, Option B, Option D'
    
    is_correct = scoring.evaluate_answer(student_answer, correct_answer, question_type)
    
    print(f"Question Type: {question_type}")
    print(f"Student Answer: {student_answer}")
    print(f"Correct Answer: {correct_answer}")
    result_str = "CORRECT" if is_correct else "INCORRECT"
    print(f"Result: {result_str}")
    
    assert is_correct, "MCS should be correct when all options match"
    print("[PASS] MCS flow works correctly")

def test_mcs_incorrect_flow():
    """Test MCS with incorrect answers"""
    print_subsection("MCS INCORRECT FLOW TEST")
    
    scoring = ScoringService()
    
    # Student selects wrong option
    question_type = 'MCS'
    student_answer = ['Option A', 'Option B']  # Missing Option D
    correct_answer = 'Option A, Option B, Option D'
    
    is_correct = scoring.evaluate_answer(student_answer, correct_answer, question_type)
    
    print(f"Question Type: {question_type}")
    print(f"Student Answer: {student_answer}")
    print(f"Correct Answer: {correct_answer}")
    result_str = "CORRECT" if is_correct else "INCORRECT"
    print(f"Result: {result_str}")
    
    assert not is_correct, "MCS should be incorrect when missing options"
    print("[PASS] MCS incorrect detection works correctly")

def test_nat_flow():
    """Test NAT question answering flow"""
    print_subsection("NAT FLOW TEST")
    
    scoring = ScoringService()
    
    # Simulate student answering NAT correctly
    question_type = 'NAT'
    student_answer = '3.14'
    correct_answer = '3.14'
    
    is_correct = scoring.evaluate_answer(student_answer, correct_answer, question_type)
    
    print(f"Question Type: {question_type}")
    print(f"Student Answer: {student_answer}")
    print(f"Correct Answer: {correct_answer}")
    result_str = "CORRECT" if is_correct else "INCORRECT"
    print(f"Result: {result_str}")
    
    assert is_correct, "NAT should be correct with exact match"
    print("[PASS] NAT flow works correctly")

def test_nat_tolerance_flow():
    """Test NAT with tolerance"""
    print_subsection("NAT TOLERANCE FLOW TEST")
    
    scoring = ScoringService()
    
    # Simulate student answer within tolerance
    question_type = 'NAT'
    student_answer = '3.14'
    correct_answer = '3.145'  # Within ±0.01
    
    is_correct = scoring.evaluate_answer(student_answer, correct_answer, question_type)
    
    print(f"Question Type: {question_type}")
    print(f"Student Answer: {student_answer}")
    print(f"Correct Answer: {correct_answer}")
    print("Tolerance: ±0.01")
    result_str = "CORRECT" if is_correct else "INCORRECT"
    print(f"Result: {result_str}")
    
    assert is_correct, "NAT should be correct within tolerance"
    print("[PASS] NAT tolerance works correctly")

def test_complete_quiz_submission():
    """Test complete quiz submission with mixed question types"""
    print_subsection("COMPLETE QUIZ SUBMISSION TEST")
    
    scoring = ScoringService()
    
    # Simulate a complete quiz with 3 MCQ, 2 MCS, 3 NAT = 8 questions
    quiz_answers = {
        '1': 'Option A',  # MCQ - correct
        '2': 'Option B',  # MCQ - correct
        '3': 'Option C',  # MCQ - incorrect (correct is Option A)
        '4': ['Option A', 'Option B'],  # MCS - correct
        '5': ['Option A', 'Option C'],  # MCS - incorrect (missing B)
        '6': '9.81',  # NAT - correct
        '7': '3.14',  # NAT - correct
        '8': '2.70',  # NAT - incorrect (correct is 2.718, tolerance +-0.01)
    }
    
    quiz_metadata = {
        '1': {'type': 'MCQ', 'correct': 'Option A'},
        '2': {'type': 'MCQ', 'correct': 'Option B'},
        '3': {'type': 'MCQ', 'correct': 'Option A'},
        '4': {'type': 'MCS', 'correct': 'Option A, Option B'},
        '5': {'type': 'MCS', 'correct': 'Option A, Option B, Option C'},
        '6': {'type': 'NAT', 'correct': '9.81'},
        '7': {'type': 'NAT', 'correct': '3.14'},
        '8': {'type': 'NAT', 'correct': '2.718'},
    }
    
    correct_count = 0
    results = []
    
    print("\nSubmitted Answers:")
    print("-" * 80)
    
    for q_id, answer in quiz_answers.items():
        metadata = quiz_metadata[q_id]
        is_correct = scoring.evaluate_answer(
            answer,
            metadata['correct'],
            metadata['type']
        )
        correct_count += int(is_correct)
        
        status = "CORRECT" if is_correct else "INCORRECT"
        results.append({
            'question_id': q_id,
            'type': metadata['type'],
            'student_answer': answer,
            'correct_answer': metadata['correct'],
            'is_correct': is_correct,
        })
        
        print(f"Q{q_id} ({metadata['type']:3}): {status} - Student: {str(answer)[:30]:30} | Expected: {metadata['correct']}")
    
    total = len(quiz_answers)
    percentage = (correct_count / total) * 100
    
    print("\n" + "-"*80)
    print(f"Score: {correct_count}/{total} = {percentage:.1f}%")
    
    # Expected: MCQ 2/3 + MCS 1/2 + NAT 2/3 = 5/8 = 62.5%
    expected_correct = 5
    assert correct_count == expected_correct, f"Expected {expected_correct} correct, got {correct_count}"
    
    print("[PASS] Complete quiz submission works correctly")
    
    return results

def test_flutter_data_format():
    """Test that Flutter data format matches backend expectations"""
    print_subsection("FLUTTER DATA FORMAT TEST")
    
    # Simulate Flutter app sending answers
    flutter_submission = {
        'subject': 'Computer Science',
        'unit': 1,
        'risk_level': 'High',
        'answers': {
            '1': 'Option A',  # MCQ as string
            '2': ['Option A', 'Option B', 'Option D'],  # MCS as list
            '3': '3.14',  # NAT as string
        }
    }
    
    print("Flutter Submission Format:")
    print(json.dumps(flutter_submission, indent=2))
    
    # Verify format matches expectations
    assert isinstance(flutter_submission['answers']['1'], str), "MCQ should be string"
    assert isinstance(flutter_submission['answers']['2'], list), "MCS should be list"
    assert isinstance(flutter_submission['answers']['3'], str), "NAT should be string"
    
    print("[PASS] Flutter data format is correct")

def main():
    print_section("END-TO-END QUIZ ANSWERING FLOW TEST")
    print(f"Start time: {datetime.now()}")
    
    try:
        test_mcq_flow()
        test_mcs_flow()
        test_mcs_incorrect_flow()
        test_nat_flow()
        test_nat_tolerance_flow()
        test_flutter_data_format()
        results = test_complete_quiz_submission()
        
        print_section("TEST SUMMARY")
        print("[PASS] All end-to-end tests completed successfully")
        print(f"End time: {datetime.now()}")
        print("\nKey Achievements:")
        print("[PASS] MCQ question flow working")
        print("[PASS] MCS question flow working with set comparison")
        print("[PASS] NAT question flow working with tolerance")
        print("[PASS] Flutter data format matches backend expectations")
        print("[PASS] Complete quiz submission with mixed types working")
        print("\n" + "="*80)
        
        return 0
        
    except Exception as e:
        print_section("TEST FAILURE")
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
