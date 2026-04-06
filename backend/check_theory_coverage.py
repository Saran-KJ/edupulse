from database import SessionLocal
from models import Subject, LearningResource

def check_theory_coverage():
    db = SessionLocal()
    try:
        # Filter: Exclude titles containing Laboratory, Lab, Practical, or Workshop
        subjects = db.query(Subject).all()
        theory_subjects = [s for s in subjects if not any(word in s.subject_title.lower() for word in ['laboratory', 'lab', 'practical', 'workshop'])]
        
        total_theory = len(theory_subjects)
        covered = 0
        missing = []
        
        for s in theory_subjects:
            count = db.query(LearningResource).filter(
                LearningResource.subject_code == s.subject_code,
                LearningResource.url.ilike('%drive.google.com%')
            ).count()
            
            if count > 0:
                covered += 1
            else:
                missing.append(f"{s.subject_code} ({s.subject_title})")
        
        print(f"📊 THEORY RESOURCE COVERAGE REPORT")
        print(f"---------------------------------")
        print(f"Total Theory Subjects: {total_theory}")
        print(f"Subjects Covered: {covered}")
        print(f"Subjects Missing Drive Links: {len(missing)}")
        
        if missing:
            print(f"\n❌ MISSING THEORY SUBJECTS:")
            for m in missing:
                print(f" - {m}")
        else:
            print(f"\n✅ SUCCESS: All {total_theory} theory subjects have at least one direct Drive link!")
            
    finally:
        db.close()

if __name__ == "__main__":
    check_theory_coverage()
