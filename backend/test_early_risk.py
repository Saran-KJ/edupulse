"""Quick test to verify predict_early_risk works correctly."""
import sys
import traceback
from database import SessionLocal
from ml_service import ml_service
import models

db = SessionLocal()

try:
    # 1. Pick a real student from the DB
    student = db.query(models.StudentCSE).first()
    if not student:
        print("ERROR: No CSE students in database to test with")
        sys.exit(1)

    reg_no = student.reg_no
    print(f"Testing with student: {student.name} ({reg_no})")

    # 2. Pick a subject the student has marks for (if any)
    mark = db.query(models.Mark).filter(models.Mark.reg_no == reg_no).first()
    subject = mark.subject_code if mark else "CS3351"
    print(f"Using subject: {subject}")

    # 3. Run the early risk prediction
    result = ml_service.predict_early_risk(db, reg_no, subject)
    print(f"\n--- Early Risk Prediction Result ---")
    print(f"  Risk Level   : {result['risk_level']}")
    print(f"  Probability  : {result['probability']:.4f}")
    print(f"  Features     : {result.get('features', 'N/A')}")
    print(f"------------------------------------")

    # 4. Verify thresholds
    prob = result['probability']
    level = result['risk_level']
    if prob < 0.4:
        assert level == "Low", f"Expected Low but got {level}"
    elif prob < 0.7:
        assert level == "Medium", f"Expected Medium but got {level}"
    else:
        assert level == "High", f"Expected High but got {level}"
    print("Threshold classification: PASS")

    # 5. Check if any AcademicAlerts exist
    alerts = db.query(models.AcademicAlert).filter(models.AcademicAlert.reg_no == reg_no).all()
    print(f"Academic Alerts for {reg_no}: {len(alerts)}")
    for a in alerts:
        print(f"  - [{a.risk_level}] {a.subject}: {a.message[:60]}...")

    print("\nAll checks passed!")

except Exception as e:
    print(f"ERROR: {e}")
    traceback.print_exc()
finally:
    db.close()
