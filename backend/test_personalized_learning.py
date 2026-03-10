"""
Internal test script bypassing HTTP auth
"""
import sys
from sqlalchemy.orm import Session
from database import SessionLocal
from models import User, Mark
from routes.learning_routes import generate_plan_for_subject, get_plan_resources

def test_internal():
    db: Session = SessionLocal()
    try:
        # Find any student that has marks
        mark = db.query(Mark).first()
        if not mark:
            print("No marks found in DB. Cannot test.")
            return

        reg_no = mark.reg_no
        subject_code = mark.subject_code

        print(f"Testing for Student: {reg_no}, Subject: {subject_code}")

        # MANUALLY SET MARKS to isolate Slip Test 1
        # Clear other assessments to ensure detection picks slip_test_1
        mark.university_result_grade = None
        mark.model = 0
        mark.cia_2 = 0
        mark.slip_test_4 = 0
        mark.assignment_4 = 0
        mark.slip_test_3 = 0
        mark.assignment_3 = 0
        mark.cia_1 = 0
        mark.slip_test_2 = 0
        mark.assignment_2 = 0
        mark.assignment_1 = 0
        
        mark.slip_test_1 = 8  # Only Slip Test 1 is set
        db.commit()

        # Get actual student to bypass _get_student check
        import models
        student_model = getattr(models, f"Student{mark.dept}", None)
        if not student_model:
            print(f"Unknown department model {mark.dept}")
            return
            
        student = db.query(student_model).filter(student_model.reg_no == reg_no).first()
        if not student:
            print("Student not found in department table.")
            return

        class DummyUser:
            role = "student"
            dept = mark.dept
            email = student.email
        user = DummyUser()

        # 1. Generate plan
        print("\nStep 1: Generating plan...")
        plan = generate_plan_for_subject(db, reg_no, subject_code)
        if not plan:
            print("Failed to generate plan.")
            return
            
        print("✓ Plan generated successfully")
        print(f"  Detected Assessment: {plan.latest_assessment}")
        print(f"  Risk Level: {plan.risk_level}")
        print(f"  Units: {plan.units}")

        if plan.latest_assessment != "slip_test_1":
            print(f"❌ FAILED: Expected latest assessment 'slip_test_1', got '{plan.latest_assessment}'")
        if plan.units != "1":
            print(f"❌ FAILED: Expected units '1', got '{plan.units}'")

        # 2. Get Resources Endpoint logic
        print("\nStep 2: Retrieving resources...")
        res_data = get_plan_resources(subject_code=subject_code, language="English", db=db, current_user=user)
        
        plan_obj = res_data.get("plan", {})
        print("\n--- Final Output Format ---")
        print(f"Risk Level: {plan_obj.get('Risk Level')}")
        print(f"Focus Type: {plan_obj.get('Focus Type')}")
        print(f"Unit(s) or Skill: {plan_obj.get('Unit(s) or Skill')}")
        
        resources = plan_obj.get('Assigned Learning Resource(s)', [])
        print(f"Assigned Learning Resource(s): Found {len(resources)} resources.")
        
        # Check if any resource NOT in Unit 1 is present
        failed_units = []
        for r in resources:
            u = r.get('unit')
            if u and "1" not in u.split(","):
                failed_units.append(f"{r.get('title')} (Unit {u})")
            print(f"  - [{r.get('type')}] {r.get('title')} (Unit: {r.get('unit')})")

        if failed_units:
            print(f"\n❌ FAILED: Found resources from wrong units: {', '.join(failed_units)}")
        else:
            print("\n✅ SUCCESS: Only Unit 1 resources (or general resources) were returned!")
            
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    test_internal()
