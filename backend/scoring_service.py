"""
Scoring service for different question types (MCQ, MCS, NAT).
Handles answer evaluation and scoring logic.
"""

from typing import Any, Union, List
import re


class ScoringService:
    """Service for evaluating quiz answers based on question type."""
    
    # Tolerance for numeric answers (±0.01)
    NAT_TOLERANCE = 0.01
    
    @staticmethod
    def evaluate_mcq(student_answer: str, correct_answer: str) -> bool:
        """
        Evaluate MCQ (Multiple Choice Question) answer.
        Single correct answer from 4 options.
        
        Args:
            student_answer: Student's selected option
            correct_answer: Correct answer from database
            
        Returns:
            True if answer is correct, False otherwise
        """
        if not student_answer or not correct_answer:
            return False
        
        # Normalize: strip whitespace and convert to lowercase
        student = student_answer.strip().lower()
        correct = correct_answer.strip().lower()
        
        return student == correct
    
    @staticmethod
    def evaluate_mcs(student_answers: Union[List[str], str], correct_answers: str) -> bool:
        """
        Evaluate MCS (Multiple Choice Selection) answer.
        Multiple correct answers - student must select ALL correct options and NO incorrect options.
        
        Args:
            student_answers: List of student's selected options or comma-separated string
            correct_answers: Comma-separated correct answers from database (e.g., "A, B, D")
            
        Returns:
            True if answer is completely correct, False otherwise
        """
        if not student_answers or not correct_answers:
            return False
        
        # Normalize student answers
        if isinstance(student_answers, str):
            # If comma-separated string, split it
            if ',' in student_answers:
                student_set = set(opt.strip().lower() for opt in student_answers.split(','))
            else:
                # Single answer in string format - might be a list representation
                student_set = set(opt.strip().lower() for opt in student_answers.split())
        elif isinstance(student_answers, list):
            student_set = set(opt.strip().lower() for opt in student_answers)
        else:
            return False
        
        # Normalize correct answers
        correct_set = set(opt.strip().lower() for opt in correct_answers.split(','))
        
        # Exact match required: student must have selected ALL correct options and NO extras
        is_correct = student_set == correct_set
        
        if not is_correct:
            print(f"DEBUG MCS: Student {student_set} != Correct {correct_set}")
        
        return is_correct
    
    @staticmethod
    def evaluate_nat(student_answer: Union[str, int, float], correct_answer: str) -> bool:
        """
        Evaluate NAT (Numerical Answer Type) answer.
        Student enters a numeric value with tolerance.
        
        Args:
            student_answer: Student's numeric answer
            correct_answer: Correct answer from database (numeric value as string)
            
        Returns:
            True if answer is within tolerance, False otherwise
        """
        if not student_answer or not correct_answer:
            return False
        
        try:
            # Convert student answer to float
            if isinstance(student_answer, str):
                # Remove any whitespace and special characters (except decimal point)
                student_val = float(re.sub(r'[^\d.-]', '', student_answer))
            else:
                student_val = float(student_answer)
            
            # Convert correct answer to float
            correct_val = float(correct_answer.strip())
            
            # Check if within tolerance
            difference = abs(student_val - correct_val)
            is_correct = difference <= ScoringService.NAT_TOLERANCE
            
            if not is_correct:
                print(f"DEBUG NAT: Student {student_val} (diff: {difference}) vs Correct {correct_val}")
            
            return is_correct
            
        except (ValueError, AttributeError) as e:
            print(f"ERROR NAT: Failed to parse numeric answer - {e}")
            return False
    
    @staticmethod
    def evaluate_answer(student_answer: Any, correct_answer: str, question_type: str = "MCQ") -> bool:
        """
        Unified answer evaluation based on question type.
        
        Args:
            student_answer: Student's answer (format depends on question_type)
            correct_answer: Correct answer from database
            question_type: Type of question (MCQ, MCS, or NAT)
            
        Returns:
            True if answer is correct, False otherwise
        """
        question_type = question_type.upper()
        
        if question_type == "MCQ":
            return ScoringService.evaluate_mcq(student_answer, correct_answer)
        elif question_type == "MCS":
            return ScoringService.evaluate_mcs(student_answer, correct_answer)
        elif question_type == "NAT":
            return ScoringService.evaluate_nat(student_answer, correct_answer)
        else:
            # Default to MCQ for unknown types
            print(f"WARNING: Unknown question type '{question_type}', defaulting to MCQ")
            return ScoringService.evaluate_mcq(student_answer, correct_answer)


# Create singleton instance
scoring_service = ScoringService()
