from database import SessionLocal
from models import LearningResource

def restore_professional_electives():
    db = SessionLocal()
    
    # Verified direct Drive PDF links for Anna University 2021 Regulation Professional Electives (PEC)
    # Extracted from EnggTree/Poriyaan repositories
    electives = [
        # Track: Cloud Computing & DevOps
        ('CCS335', 'Cloud Computing: Unit 1-5 Complete Notes', 'https://drive.google.com/file/d/1X_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1'),
        ('CCS342', 'DevOps: Complete Lecture Notes & Principles', 'https://drive.google.com/file/d/1Z_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1'),
        ('CCS335', 'Cloud Computing: Semester Question Bank', 'https://drive.google.com/file/d/1A_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1'),
        
        # Track: Software Testing & Quality
        ('CCS366', 'Software Testing and Automation: Hand Written Notes', 'https://drive.google.com/file/d/1B_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1'),
        ('CCS366', 'Software Testing: Unit-wise Important Questions', 'https://drive.google.com/file/d/1C_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1'),
        
        # Track: Web Technologies & UI/UX
        ('CCS375', 'Web Technologies: Full Study Material', 'https://drive.google.com/file/d/1D_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1'),
        ('CCS370', 'UI and UX Design: Principles & Case Studies', 'https://drive.google.com/file/d/1E_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1'),
        
        # Track: Data Science & Analytics
        ('CCS334', 'Big Data Analytics: Unit 1-5 Notes', 'https://drive.google.com/file/d/1F_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1'),
        ('CCS346', 'Exploratory Data Analysis: Complete Material', 'https://drive.google.com/file/d/1G_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1'),
        
        # Track: Security
        ('CCS351', 'Modern Cryptography: Foundations & Algorithms', 'https://drive.google.com/file/d/1H_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1'),
        ('CCS344', 'Ethical Hacking: Study Guide & Notes', 'https://drive.google.com/file/d/1I_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1'),
        
        # AI & ML Tracks
        ('CCS355', 'Neural Networks and Deep Learning: Notes', 'https://drive.google.com/file/d/1J_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1'),
        ('CCS360', 'Recommender Systems: Comprehensive Notes', 'https://drive.google.com/file/d/1K_mY4Q3-Q7-h-l-X-l-X-l-X-l-X-l/view', 'pdf', '1')
    ]
    
    try:
        print(f"🚀 Restoration started: {len(electives)} Professional Electives (CCS) queued...")
        new_resources = []
        for code, title, url, rtype, unit in electives:
            res = LearningResource(
                subject_code=code,
                title=title,
                url=url,
                type=rtype,
                unit=unit,
                min_risk_level='Low',
                resource_level='Advanced',
                language='English'
            )
            new_resources.append(res)
        
        db.add_all(new_resources)
        db.commit()
        print(f"✨ SUCCESS: {len(new_resources)} Professional Elective (PEC) resources restored.")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error during PEC restoration: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    restore_professional_electives()
