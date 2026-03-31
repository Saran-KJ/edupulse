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
    def evaluate_mcq(student_answer: str, correct_answer: str, question_obj: Any = None) -> bool:
        """
        Evaluate MCQ. Supports matching both the label (Option A) and the actual value.
        """
        if not student_answer or not correct_answer:
            return False
        
        student = student_answer.strip().lower()
        # The correct_answer in DB is usually "Option A" or just "A" 
        # but could also be the text itself from AI generation
        correct = correct_answer.strip().lower()

        if student == correct:
            return True

        # Fallback: Resolve Option Label to Value
        if question_obj:
            val = ScoringService.get_option_value(question_obj, student)
            if val and val.strip().lower() == correct:
                return True
            
            # Or if student provided "smtp" and correct is "Option A" (which is "smtp")
            c_val = ScoringService.get_option_value(question_obj, correct)
            if c_val and c_val.strip().lower() == student:
                return True
                
        return False

    @staticmethod
    def evaluate_mcs(student_answers: Union[List[str], str], correct_answers: str, question_obj: Any = None) -> bool:
        """
        Evaluate MCS. Cross-references labels and values.
        """
        if not student_answers or not correct_answers:
            return False
            
        def normalize_set(vals):
            if isinstance(vals, str):
                if ',' in vals: return set(v.strip().lower() for v in vals.split(','))
                return set(v.strip().lower() for v in vals.split())
            return set(v.strip().lower() for v in vals)

        student_set = normalize_set(student_answers)
        correct_set = normalize_set(correct_answers)

        if student_set == correct_set:
            return True

        if not question_obj:
            return False

        # Deep Value Resolution for MCS
        resolved_student = set()
        for s in student_set:
            val = ScoringService.get_option_value(question_obj, s)
            resolved_student.add(val.strip().lower() if val else s)

        resolved_correct = set()
        for c in correct_set:
            val = ScoringService.get_option_value(question_obj, c)
            resolved_correct.add(val.strip().lower() if val else c)

        return resolved_student == resolved_correct

    @staticmethod
    def get_option_value(q: Any, label: str) -> str:
        """Helper to get text content from a label like 'Option A' or 'A'"""
        l = label.strip().lower()
        if 'option a' in l or l == 'a': return getattr(q, 'option_a', None)
        if 'option b' in l or l == 'b': return getattr(q, 'option_b', None)
        if 'option c' in l or l == 'c': return getattr(q, 'option_c', None)
        if 'option d' in l or l == 'd': return getattr(q, 'option_d', None)
        return None

    @staticmethod
    def evaluate_nat(student_answer: Union[str, int, float], correct_answer: str) -> bool:
        if student_answer is None or student_answer == "" or str(student_answer).strip() == "":
            return False
            
        try:
            # Clean student input: " 80.0 " -> 80.0
            s_str = str(student_answer).strip()
            student_val = float(re.sub(r'[^\d.-]', '', s_str))
            correct_val = float(str(correct_answer).strip())
            
            difference = abs(student_val - correct_val)
            return difference <= ScoringService.NAT_TOLERANCE
        except Exception:
            return False

    @staticmethod
    def evaluate_answer(student_answer: Any, question: Any) -> bool:
        """Unified evaluator using the question object for context."""
        q_type = (question.question_type or "MCQ").upper()
        
        if q_type == "MCQ":
            return ScoringService.evaluate_mcq(student_answer, question.correct_answer, question)
        elif q_type == "MCS":
            return ScoringService.evaluate_mcs(student_answer, question.correct_answer, question)
        elif q_type == "NAT":
            return ScoringService.evaluate_nat(student_answer, question.correct_answer)
        return False


# Create singleton instance
scoring_service = ScoringService()
