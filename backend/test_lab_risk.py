"""
Script to verify lab subject risk parsing
"""
import sys
from sqlalchemy.orm import Session
from database import SessionLocal
import models
from ml_service import ml_service

def verify_labs():
    db: Session = SessionLocal()
    try:
        # Find a lab subject
        lab_subject = db.query(models.Subject).filter(models.Subject.category == 'LAB').first()
        if not lab_subject:
            print("No LAB subject found to test.")
            return

        print(f"Testing Lab Subject: {lab_subject.subject_code} - {lab_subject.subject_title}")
        
        # Find a student who has marks for this lab
        mark = db.query(models.Mark).filter(models.Mark.subject_code == lab_subject.subject_code).first()
        if not mark:
            print("No marks found for this lab subject.")
            return
            
        reg_no = mark.reg_no
        print(f"Testing for student: {reg_no}")

        # 1. Test subject-level risk explicitly
        print("\n--- Testing calculate_subject_risk ---")
        risk_data = ml_service.calculate_subject_risk(db, reg_no, lab_subject.subject_code)
        print(f"Risk Level: {risk_data.get('risk_level')}")
        print(f"Score: {risk_data.get('score')}")
        print(f"Basis: {risk_data.get('basis')}")

        if risk_data.get('risk_level') == 'Low':
            print("✓ SUCCESS: Lab paper was successfully classified as Low risk automatically.")
        else:
            print("X FAILED: Lab paper was not Low risk.")
            
        # 2. Test predict_risk to see if it causes issues
        print("\n--- Testing overall predict_risk ---")
        overall_risk = ml_service.predict_risk(db, reg_no)
        print(f"Overall internal_avg: {overall_risk.get('internal_avg')}%")
        print("✓ SUCCESS: predict_risk ran without errors.")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    verify_labs()
