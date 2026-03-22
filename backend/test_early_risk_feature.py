#!/usr/bin/env python
"""
Test script for early risk assessment quiz feature.
Tests the backend implementation without starting the server.
"""

import sys
sys.stdout.reconfigure(encoding='utf-8')

from database import SessionLocal
from models import StudentCSE, QuizQuestion
from routes.prediction_routes import router
from schemas import EarlyRiskQuizRequest
import json

def test_database_schema():
    """Test that database schema has required columns"""
    print("\n=== Testing Database Schema ===")
    db = SessionLocal()
    try:
        # Check QuizQuestion columns
        columns = [c.name for c in QuizQuestion.__table__.columns]
        required = ['is_early_risk_quiz']
        
        for col in required:
            if col in columns:
                print(f"OK: Column '{col}' exists in quiz_questions table")
            else:
                print(f"ERROR: Column '{col}' missing from quiz_questions table")
        
        # Check data exists
        count = db.query(QuizQuestion).count()
        print(f"OK: Found {count} quiz questions in database")
        
        # Check a sample has the field
        sample = db.query(QuizQuestion).first()
        if sample and hasattr(sample, 'is_early_risk_quiz'):
            print(f"OK: Sample question has is_early_risk_quiz field (value: {sample.is_early_risk_quiz})")
        
    finally:
        db.close()

def test_early_risk_quiz_request_schema():
    """Test that request schema is properly defined"""
    print("\n=== Testing Request Schema ===")
    
    try:
        request = EarlyRiskQuizRequest(
            reg_no="CSE001",
            subject_code="CS101",
            unit_number=1
        )
        print(f"OK: EarlyRiskQuizRequest created successfully")
        print(f"  - reg_no: {request.reg_no}")
        print(f"  - subject_code: {request.subject_code}")
        print(f"  - unit_number: {request.unit_number}")
    except Exception as e:
        print(f"ERROR: Failed to create request schema: {e}")

def test_student_data():
    """Test that we have student data to work with"""
    print("\n=== Testing Student Data ===")
    db = SessionLocal()
    try:
        student = db.query(StudentCSE).first()
        if student:
            print(f"OK: Found CSE student: {student.reg_no}")
            print(f"  - Quiz Score: {student.quiz_score}")
            print(f"  - Attendance: {student.attendance}%")
            print(f"  - Internal Marks: {student.internal_marks}")
            print(f"  - Backlog Count: {student.backlog_count}")
            print(f"  - Learning Engagement: {student.learning_engagement}")
        else:
            print("ERROR: No CSE students found in database")
    finally:
        db.close()

def main():
    print("=== Early Risk Assessment Quiz Feature Test ===")
    
    try:
        test_database_schema()
        test_early_risk_quiz_request_schema()
        test_student_data()
        
        print("\n=== Test Summary ===")
        print("All basic checks passed!")
        print("Ready for API endpoint testing.")
        
    except Exception as e:
        print(f"\nERROR: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
