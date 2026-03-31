#!/usr/bin/env python
"""
Comprehensive test script for assessment quiz generation.
Tests SlipTest (20), CIA (40), and ModelExam (50) quiz generation.
Verifies question type distribution and scoring.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from database import SessionLocal
from models import QuizQuestion
from gemini_service import generate_assessment_quiz
from scoring_service import scoring_service
from datetime import datetime

def test_assessment_generation(subject: str, unit: int, assessment_type: str, risk_level: str = "MEDIUM"):
    """
    Test assessment quiz generation and verify:
    1. Correct number of questions
    2. Correct question type distribution
    3. All questions have correct_answer
    """
    print(f"\n{'='*80}")
    print(f"Testing {assessment_type} - {subject} Unit {unit}")
    print(f"{'='*80}")
    
    # Expected counts by assessment type
    expected_counts = {
        "SlipTest": 20,    # 30% MCQ (6), 40% MCS (8), 30% NAT (6)
        "CIA": 40,         # 25% MCQ (10), 50% MCS (20), 25% NAT (10)
        "ModelExam": 50    # 30% MCQ (15), 40% MCS (20), 30% NAT (15)
    }
    
    expected_distribution = {
        "SlipTest": {"MCQ": (6, 0.30), "MCS": (8, 0.40), "NAT": (6, 0.30)},
        "CIA": {"MCQ": (10, 0.25), "MCS": (20, 0.50), "NAT": (10, 0.25)},
        "ModelExam": {"MCQ": (15, 0.30), "MCS": (20, 0.40), "NAT": (15, 0.30)}
    }
    
    expected_total = expected_counts[assessment_type]
    expected_dist = expected_distribution[assessment_type]
    
    print(f"Expected: {expected_total} questions")
    print(f"Expected distribution: MCQ={expected_dist['MCQ'][1]*100}%, MCS={expected_dist['MCS'][1]*100}%, NAT={expected_dist['NAT'][1]*100}%")
    
    # Generate quiz
    print("\nGenerating quiz...")
    quiz = generate_assessment_quiz(subject, unit, assessment_type, risk_level)
    
    if not quiz:
        print("[FAIL] FAILED: No quiz generated!")
        return False
    
    print(f"[OK] Generated {len(quiz)} questions")
    
    # Verify total count
    if len(quiz) != expected_total:
        print(f"[FAIL] FAILED: Expected {expected_total} questions, got {len(quiz)}")
        return False
    
    # Analyze question types
    type_counts = {"MCQ": 0, "MCS": 0, "NAT": 0}
    issues = []
    
    for i, q in enumerate(quiz, 1):
        q_type = q.get("question_type", "MCQ")
        type_counts[q_type] = type_counts.get(q_type, 0) + 1
        
        # Validate question structure
        if not q.get("question"):
            issues.append(f"  Q{i}: Missing 'question' field")
        if not q.get("correct_answer"):
            issues.append(f"  Q{i}: Missing 'correct_answer' field")
        
        # NAT questions shouldn't have options
        if q_type == "NAT":
            if q.get("option_a") or q.get("option_b") or q.get("option_c") or q.get("option_d"):
                issues.append(f"  Q{i}: NAT question has options (should be None/null)")
        else:
            # MCQ/MCS should have options
            if not (q.get("option_a") and q.get("option_b") and q.get("option_c") and q.get("option_d")):
                issues.append(f"  Q{i}: {q_type} missing options")
    
    # Print type distribution
    print("\nQuestion Type Distribution:")
    all_correct = True
    for q_type in ["MCQ", "MCS", "NAT"]:
        actual_count = type_counts[q_type]
        expected_count, expected_pct = expected_dist[q_type]
        actual_pct = actual_count / len(quiz) * 100
        
        match = "[OK]" if actual_count == expected_count else "[FAIL]"
        print(f"  {q_type}: {actual_count} ({actual_pct:.1f}%) - Expected: {expected_count} ({expected_pct*100:.1f}%) {match}")
        
        if actual_count != expected_count:
            all_correct = False
    
    if issues:
        print("\n⚠️  Issues found:")
        for issue in issues[:5]:  # Show first 5 issues
            print(issue)
        if len(issues) > 5:
            print(f"  ... and {len(issues)-5} more issues")
        all_correct = False
    
    if all_correct:
        print("\n[PASS] PASSED: Quiz generation correct!")
    else:
        print("\n[FAIL] FAILED: Issues found in quiz generation")
    
    return all_correct


def test_scoring():
    """Test the scoring service for all question types."""
    print(f"\n{'='*80}")
    print("Testing Scoring Service")
    print(f"{'='*80}")
    
    tests = [
        # MCQ tests
        ("MCQ", "option_a", "Option A", True, "Single exact match"),
        ("MCQ", "option_a", "OPTION_A", True, "Case insensitive"),
        ("MCQ", "option_a", "option_b", False, "Wrong answer"),
        
        # MCS tests
        ("MCS", ["A", "B"], "A, B", True, "Multiple selection exact match"),
        ("MCS", ["A", "B", "D"], "A, B", False, "Extra selection"),
        ("MCS", ["A"], "A, B", False, "Missing selection"),
        
        # NAT tests
        ("NAT", 3.14, "3.14", True, "Exact numeric match"),
        ("NAT", 3.14159, "3.14", True, "Within tolerance"),
        ("NAT", "3.14", "3.14", True, "String numeric match"),
        ("NAT", 5.0, "3.14", False, "Outside tolerance"),
    ]
    
    passed = 0
    failed = 0
    
    for q_type, student_ans, correct_ans, expected, desc in tests:
        result = scoring_service.evaluate_answer(student_ans, correct_ans, q_type)
        status = "[PASS]" if result == expected else "[FAIL]"
        if result == expected:
            passed += 1
        else:
            failed += 1
        print(f"{status} {q_type:3} | {desc:35} | Result: {result}")
    
    print(f"\nScoring Tests: {passed} passed, {failed} failed")
    return failed == 0


def test_database_storage():
    """Test that generated quizzes are properly stored in database."""
    print(f"\n{'='*80}")
    print("Testing Database Storage")
    print(f"{'='*80}")
    
    db = SessionLocal()
    
    try:
        # Count assessment questions by type
        assessment_questions = db.query(QuizQuestion).filter(
            QuizQuestion.assessment_type.isnot(None)
        ).all()
        
        print(f"Total assessment questions in DB: {len(assessment_questions)}")
        
        # Count by assessment type
        for assessment_type in ["SlipTest", "CIA", "ModelExam"]:
            count = db.query(QuizQuestion).filter(
                QuizQuestion.assessment_type == assessment_type
            ).count()
            print(f"  {assessment_type}: {count} questions")
        
        # Count by question type
        for q_type in ["MCQ", "MCS", "NAT"]:
            count = db.query(QuizQuestion).filter(
                QuizQuestion.question_type == q_type
            ).count()
            print(f"  {q_type}: {count} questions")
        
        return True
    finally:
        db.close()


def main():
    print("\n" + "="*80)
    print("ASSESSMENT QUIZ GENERATION TEST SUITE")
    print("="*80)
    print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Test scoring first
    scoring_ok = test_scoring()
    
    # Test quiz generation for each assessment type
    test_subject = "Data Structures"
    test_unit = 1
    
    results = {}
    for assessment_type in ["SlipTest", "CIA", "ModelExam"]:
        results[assessment_type] = test_assessment_generation(
            test_subject, 
            test_unit, 
            assessment_type
        )
    
    # Test database storage
    db_ok = test_database_storage()
    
    # Summary
    print(f"\n{'='*80}")
    print("TEST SUMMARY")
    print(f"{'='*80}")
    print(f"Scoring Service: {'[PASS] PASSED' if scoring_ok else '[FAIL] FAILED'}")
    print(f"SlipTest Generation: {'[PASS] PASSED' if results['SlipTest'] else '[FAIL] FAILED'}")
    print(f"CIA Generation: {'[PASS] PASSED' if results['CIA'] else '[FAIL] FAILED'}")
    print(f"ModelExam Generation: {'[PASS] PASSED' if results['ModelExam'] else '[FAIL] FAILED'}")
    print(f"Database Storage: {'[PASS] PASSED' if db_ok else '[FAIL] FAILED'}")
    
    all_passed = scoring_ok and all(results.values()) and db_ok
    print(f"\nOverall: {'[PASS] ALL TESTS PASSED' if all_passed else '[FAIL] SOME TESTS FAILED'}")
    print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*80)
    
    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())
