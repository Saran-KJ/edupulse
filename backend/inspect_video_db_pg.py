import sys
import os
sys.path.insert(0, os.path.abspath('.'))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from config import get_settings
import models

def inspect_db():
    settings = get_settings()
    engine = create_engine(settings.database_url)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    try:
        print("--- Subjects ---")
        subjects = db.query(models.Subject).limit(10).all()
        for s in subjects:
            print(f"Code: {s.subject_code}, Title: {s.subject_title}, Sem: {s.semester}")
        
        print("\n--- YouTube Recommendations ---")
        recs = db.query(models.YouTubeRecommendation).limit(10).all()
        for r in recs:
            print(f"Reg: {r.reg_no}, Sub: {r.subject_code}, Unit: {r.unit}, Title: {r.title}")
            
        print("\n--- Active Personalized Plans ---")
        plans = db.query(models.PersonalizedLearningPlan).filter(models.PersonalizedLearningPlan.is_active == 1).limit(10).all()
        for p in plans:
            print(f"Reg: {p.reg_no}, Sub: {p.subject_code}, Risk: {p.risk_level}, Focus: {p.focus_type}, Units: {p.units}")

        print("\n--- Assessment Unit Mapping ---")
        mappings = db.query(models.AssessmentUnitMapping).all()
        for m in mappings:
            print(f"Assessment: {m.assessment_name}, Units: {m.units}")

    finally:
        db.close()

if __name__ == "__main__":
    inspect_db()
