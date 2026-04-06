from database import SessionLocal
from models import Subject, LearningResource

def check_coverage():
    db = SessionLocal()
    try:
        subjects = db.query(Subject).all()
        total_subjects = len(subjects)
        covered = 0
        missing = []
        
        for s in subjects:
            count = db.query(LearningResource).filter(
                LearningResource.subject_code == s.subject_code,
                LearningResource.url.ilike('%drive.google.com%')
            ).count()
            
            if count > 0:
                covered += 1
            else:
                missing.append(f"{s.subject_code} ({s.subject_title})")
        
        print(f"📊 DRIVE LINK COVERAGE REPORT")
        print(f"-----------------------------")
        print(f"Total Subjects: {total_subjects}")
        print(f"Subjects Covered: {covered}")
        print(f"Subjects Missing Drive Links: {len(missing)}")
        
        if missing:
            print(f"\n❌ MISSING SUBJECTS (Top 20):")
            for m in missing[:20]:
                print(f" - {m}")
        else:
            print(f"\n✅ SUCCESS: All {total_subjects} subjects have at least one Drive link!")
            
    finally:
        db.close()

if __name__ == "__main__":
    check_coverage()
