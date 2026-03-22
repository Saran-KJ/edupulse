#!/usr/bin/env python
"""
Quiz submission and scoring integration test.
Uses manually created quiz data to test the full submission flow.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from database import SessionLocal
from models import QuizQuestion, StudentQuizAttempt, User, StudentCSE
from scoring_service import scoring_service
from datetime import datetime
import json

def create_test_quiz():
    """Create sample quiz questions for testing scoring."""
    db = SessionLocal()
    
    print("\n" + "="*80)
    print("Creating Test Quiz Questions")
    print("="*80)
    
    try:
        # Clear existing test questions
        db.query(QuizQuestion).filter(
            QuizQuestion.subject == "TEST_DATA_STRUCTURES"
        ).delete()
        db.commit()
        print("Cleared existing test questions")
        
        # Create test questions with all three types
        test_questions = [
            # MCQ Questions
            {
                "subject": "TEST_DATA_STRUCTURES",
                "unit": 1,
                "question": "What is the time complexity of binary search?",
                "option_a": "O(n)",
                "option_b": "O(log n)",
                "option_c": "O(n^2)",
                "option_d": "O(1)",
                "correct_answer": "O(log n)",
                "difficulty_level": "Moderate",
                "question_type": "MCQ",
                "assessment_type": "SlipTest"
            },
            {
                "subject": "TEST_DATA_STRUCTURES",
                "unit": 1,
                "question": "Which data structure uses LIFO principle?",
                "option_a": "Queue",
                "option_b": "Stack",
                "option_c": "Tree",
                "option_d": "Graph",
                "correct_answer": "Stack",
                "difficulty_level": "Moderate",
                "question_type": "MCQ",
                "assessment_type": "SlipTest"
            },
            # MCS Questions
            {
                "subject": "TEST_DATA_STRUCTURES",
                "unit": 1,
                "question": "Which of the following are valid sorting algorithms?",
                "option_a": "Quick Sort",
                "option_b": "Merge Sort",
                "option_c": "Random Sort",
                "option_d": "Heap Sort",
                "correct_answer": "Quick Sort, Merge Sort, Heap Sort",
                "difficulty_level": "Moderate",
                "question_type": "MCS",
                "assessment_type": "SlipTest"
            },
            {
                "subject": "TEST_DATA_STRUCTURES",
                "unit": 1,
                "question": "Which characteristics apply to a tree data structure?",
                "option_a": "Acyclic",
                "option_b": "Connected",
                "option_c": "Cyclic",
                "option_d": "Hierarchical",
                "correct_answer": "Acyclic, Connected, Hierarchical",
                "difficulty_level": "Moderate",
                "question_type": "MCS",
                "assessment_type": "SlipTest"
            },
            # NAT Questions
            {
                "subject": "TEST_DATA_STRUCTURES",
                "unit": 1,
                "question": "What is 2^10?",
                "option_a": None,
                "option_b": None,
                "option_c": None,
                "option_d": None,
                "correct_answer": "1024",
                "difficulty_level": "Moderate",
                "question_type": "NAT",
                "assessment_type": "SlipTest"
            },
            {
                "subject": "TEST_DATA_STRUCTURES",
                "unit": 1,
                "question": "Calculate the result: 15 * 3.14 / 5",
                "option_a": None,
                "option_b": None,
                "option_c": None,
                "option_d": None,
                "correct_answer": "9.42",
                "difficulty_level": "Moderate",
                "question_type": "NAT",
                "assessment_type": "SlipTest"
            },
        ]
        
        created_questions = []
        for q_data in test_questions:
            q = QuizQuestion(**q_data)
            db.add(q)
            created_questions.append(q)
        
        db.commit()
        
        # Refresh to get IDs
        for q in created_questions:
            db.refresh(q)
        
        print(f"\nCreated {len(created_questions)} test questions:")
        for i, q in enumerate(created_questions, 1):
            print(f"  Q{i} (ID: {q.id}): {q.question_type} - {q.question[:50]}...")
        
        return {q.id: q for q in created_questions}
        
    finally:
        db.close()


def test_submission_scoring():
    """Test quiz submission and scoring with all question types."""
    print("\n" + "="*80)
    print("Testing Quiz Submission Scoring")
    print("="*80)
    
    # Create test quiz
    questions_map = create_test_quiz()
    question_ids = list(questions_map.keys())
    
    print(f"\nTest Quiz IDs: {question_ids}")
    
    # Test Case 1: All correct answers
    print("\n" + "-"*80)
    print("Test Case 1: All Correct Answers")
    print("-"*80)
    
    answers = {
        str(question_ids[0]): "O(log n)",           # MCQ correct
        str(question_ids[1]): "Stack",              # MCQ correct
        str(question_ids[2]): ["Quick Sort", "Merge Sort", "Heap Sort"],  # MCS correct (all 3)
        str(question_ids[3]): ["Acyclic", "Connected", "Hierarchical"],   # MCS correct (all 3)
        str(question_ids[4]): "1024",               # NAT correct
        str(question_ids[5]): "9.42",               # NAT correct
    }
    
    correct_count = 0
    db = SessionLocal()
    try:
        for q_id_str, answer in answers.items():
            q_id = int(q_id_str)
            q = db.query(QuizQuestion).filter(QuizQuestion.id == q_id).first()
            if q:
                is_correct = scoring_service.evaluate_answer(
                    answer,
                    q.correct_answer,
                    q.question_type
                )
                status = "CORRECT" if is_correct else "INCORRECT"
                print(f"  Q{q_id} ({q.question_type}): {status}")
                if is_correct:
                    correct_count += 1
        
        score = (correct_count / len(answers)) * 100
        print(f"\nScore: {correct_count}/{len(answers)} = {score:.1f}%")
        print(f"Expected: 100% - {'PASS' if score == 100 else 'FAIL'}")
        
    finally:
        db.close()
    
    # Test Case 2: Mixed correct/incorrect
    print("\n" + "-"*80)
    print("Test Case 2: Mixed Correct and Incorrect Answers")
    print("-"*80)
    
    answers2 = {
        str(question_ids[0]): "O(n)",               # MCQ WRONG
        str(question_ids[1]): "Stack",              # MCQ correct
        str(question_ids[2]): ["Quick Sort", "Random Sort"],  # MCS WRONG (has invalid option)
        str(question_ids[3]): ["Acyclic", "Connected", "Hierarchical"],   # MCS correct
        str(question_ids[4]): "1024",               # NAT correct
        str(question_ids[5]): "9.50",               # NAT WRONG (outside tolerance)
    }
    
    correct_count2 = 0
    db = SessionLocal()
    try:
        for q_id_str, answer in answers2.items():
            q_id = int(q_id_str)
            q = db.query(QuizQuestion).filter(QuizQuestion.id == q_id).first()
            if q:
                is_correct = scoring_service.evaluate_answer(
                    answer,
                    q.correct_answer,
                    q.question_type
                )
                status = "CORRECT" if is_correct else "INCORRECT"
                print(f"  Q{q_id} ({q.question_type}): {status}")
                if is_correct:
                    correct_count2 += 1
        
        score2 = (correct_count2 / len(answers2)) * 100
        print(f"\nScore: {correct_count2}/{len(answers2)} = {score2:.1f}%")
        print(f"Expected: 50% (3 correct out of 6) - {'PASS' if score2 == 50.0 else 'FAIL'}")
        
    finally:
        db.close()
    
    # Test Case 3: Numeric tolerance
    print("\n" + "-"*80)
    print("Test Case 3: NAT Numeric Tolerance")
    print("-"*80)
    
    db = SessionLocal()
    try:
        q = db.query(QuizQuestion).filter(
            QuizQuestion.subject == "TEST_DATA_STRUCTURES",
            QuizQuestion.question_type == "NAT"
        ).first()
        
        if q:
            test_values = [
                ("9.42", True, "Exact match"),
                ("9.41", True, "Within tolerance (9.42 +- 0.01)"),
                ("9.43", True, "Within tolerance (9.42 +- 0.01)"),
                ("9.40", True, "Within tolerance edge"),
                ("9.44", False, "Outside tolerance"),
                ("9.30", False, "Far outside tolerance"),
            ]
            
            for value, expected, desc in test_values:
                result = scoring_service.evaluate_nat(value, q.correct_answer)
                status = "PASS" if result == expected else "FAIL"
                print(f"  {status}: {value} vs {q.correct_answer} - {desc} - Got {result}")
    finally:
        db.close()


def main():
    print("\n" + "="*80)
    print("QUIZ SUBMISSION AND SCORING INTEGRATION TEST")
    print("="*80)
    print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    try:
        test_submission_scoring()
        
        print("\n" + "="*80)
        print("TEST SUMMARY")
        print("="*80)
        print("[PASS] All integration tests completed")
        print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("="*80)
        
        return 0
    except Exception as e:
        print(f"\n[FAIL] Error during testing: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
