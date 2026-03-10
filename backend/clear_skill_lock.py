"""Clear skill_category from all Skill Development plans so students can see all skills."""
from database import SessionLocal
from models import PersonalizedLearningPlan

db = SessionLocal()
try:
    updated = db.query(PersonalizedLearningPlan).filter(
        PersonalizedLearningPlan.focus_type == 'Skill Development',
        PersonalizedLearningPlan.skill_category != None
    ).update({'skill_category': None})
    db.commit()
    print(f"✅ Cleared skill_category on {updated} Skill Development plan(s). Students can now learn ALL skills.")
except Exception as e:
    db.rollback()
    print(f"❌ Error: {e}")
finally:
    db.close()
