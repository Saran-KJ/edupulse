#!/usr/bin/env python
"""
Simple scoring service test - no AI required.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from scoring_service import scoring_service

def test_scoring():
    """Test the scoring service for all question types."""
    print("\n" + "="*80)
    print("Testing Scoring Service")
    print("="*80)
    
    tests = [
        # MCQ tests - case insensitive
        ("MCQ", "Option A", "Option A", True, "Single exact match"),
        ("MCQ", "option a", "Option A", True, "Case insensitive"),
        ("MCQ", "Option A", "Option B", False, "Wrong answer"),
        
        # MCS tests - set comparison
        ("MCS", ["A", "B"], "A, B", True, "Multiple selection exact match"),
        ("MCS", ["a", "b"], "A, B", True, "Case insensitive MCS"),
        ("MCS", ["A", "B", "D"], "A, B", False, "Extra selection"),
        ("MCS", ["A"], "A, B", False, "Missing selection"),
        ("MCS", "A, B", "A, B", True, "Comma-separated string format"),
        
        # NAT tests - numeric with tolerance
        ("NAT", 3.14, "3.14", True, "Exact numeric match"),
        ("NAT", 3.14159, "3.14", True, "Within tolerance (3.14159 vs 3.14)"),
        ("NAT", "3.14", "3.14", True, "String numeric match"),
        ("NAT", 5.0, "3.14", False, "Outside tolerance (diff > 0.01)"),
        ("NAT", " 3.14 ", "3.14", True, "With whitespace"),
    ]
    
    passed = 0
    failed = 0
    
    print("\nTest Results:")
    print("-" * 80)
    
    for q_type, student_ans, correct_ans, expected, desc in tests:
        result = scoring_service.evaluate_answer(student_ans, correct_ans, q_type)
        status = "[PASS]" if result == expected else "[FAIL]"
        if result == expected:
            passed += 1
        else:
            failed += 1
        match_str = "matches" if result else "doesn't match"
        print(f"{status} {q_type:3} | {desc:40} | {match_str}")
    
    print("-" * 80)
    print(f"\nScoring Tests: {passed} passed, {failed} failed")
    print("="*80)
    
    return failed == 0


if __name__ == "__main__":
    success = test_scoring()
    sys.exit(0 if success else 1)
