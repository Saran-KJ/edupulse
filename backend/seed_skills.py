from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models

def seed_skills():
    db = SessionLocal()
    try:
        # We'll use a special semester "SKILL" to identify these
        skills_data = [
            ("SKILL", "SKILL_APT", "Aptitude Training", "EEC", 3),
            ("SKILL", "SKILL_PROG", "Programming Essentials", "EEC", 3),
            ("SKILL", "SKILL_COMM", "Business Communication", "EEC", 3),
            ("SKILL", "SKILL_SOFT", "Soft Skills", "EEC", 2),
        ]
        
        for sem, code, title, cat, credits in skills_data:
            # Check if exists
            existing = db.query(models.Subject).filter(models.Subject.subject_code == code).first()
            if not existing:
                print(f"Adding skill: {title}...")
                new_skill = models.Subject(
                    semester=sem,
                    subject_code=code,
                    subject_title=title,
                    category=cat,
                    credits=float(credits)
                )
                db.add(new_skill)
            else:
                print(f"⚠ Skill {title} already exists")
        
        db.commit()
        print("✓ Skill subjects seeded successfully")
    except Exception as e:
        print(f"✗ Error seeding skills: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_skills()
