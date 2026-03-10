from database import SessionLocal
import models
from ml_service import ml_service

def debug_risk(reg_no, subject_code):
    db = SessionLocal()
    try:
        # 1. Check PersonalPlan
        plan = db.query(models.PersonalizedLearningPlan).filter(
            models.PersonalizedLearningPlan.reg_no == reg_no,
            models.PersonalizedLearningPlan.subject_code == subject_code,
            models.PersonalizedLearningPlan.is_active == 1
        ).first()
        if plan:
            print(f"PLAN: ID={plan.id}, Risk={plan.risk_level}, Focus={plan.focus_type}")
        else:
            print("PLAN: None found")

        # 2. Check Marks
        mark = db.query(models.Mark).filter(
            models.Mark.reg_no == reg_no,
            models.Mark.subject_code == subject_code
        ).first()
        if mark:
            print(f"MARKS: ST1={mark.slip_test_1}, ST2={mark.slip_test_2}, CIA1={mark.cia_1}")
            print(f"       ST3={mark.slip_test_3}, ST4={mark.slip_test_4}, CIA2={mark.cia_2}, MODEL={mark.model}")
            
            # 3. Calculate Risk
            risk_result = ml_service.calculate_subject_risk(db, reg_no, subject_code)
            print(f"CALCULATED RISK: {risk_result}")
        else:
            print("MARKS: None found for subject")

    finally:
        db.close()

if __name__ == "__main__":
    debug_risk("813522104065", "GE3791")
