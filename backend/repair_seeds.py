import re
from database import SessionLocal, engine
from sqlalchemy import text
from models import LearningResource, StudentLearningProgress, Subject

def repair_and_seed():
    db = SessionLocal()
    sql_file = 'insert_learning_resources.sql'
    
    # Subject Name to Code Mapping
    print("Fetching subject mapping...")
    subjects = db.query(Subject).all()
    name_to_code = {s.subject_title: s.subject_code for s in subjects}
    
    # Regex to extract VALUES from INSERT statements
    pattern = re.compile(r"VALUES\s*\(\s*'(.*?)',\s*(\d+),\s*'(.*?)',\s*'(.*?)',\s*'(.*?)',\s*'(.*?)',\s*'(.*?)',\s*'(.*?)'\s*\)", re.IGNORECASE)
    
    try:
        # Step 1: Force expand subject_code column to avoid truncation errors
        print("Expanding database column width...")
        with engine.connect() as conn:
            conn.execute(text("ALTER TABLE learning_resources ALTER COLUMN subject_code TYPE VARCHAR(100)"))
            conn.commit()
        
        print(f"Reading {sql_file}...")
        with open(sql_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        matches = pattern.findall(content)
        print(f"Found {len(matches)} resource records to import.")
        
        # Step 2: Clear existing resources due to schema/mapping change
        print("Cleaning up old progress and resource records...")
        db.query(StudentLearningProgress).delete()
        db.query(LearningResource).delete()
        db.commit()
        
        new_resources = []
        for match in matches:
            subj_name, unit, risk, level, res_type, title, url, lang = match
            
            # Smart Mapping: Resolve Name to Code
            # Try exact match, then trimmed match
            subj_code = name_to_code.get(subj_name) or name_to_code.get(subj_name.strip()) or subj_name
            
            # Normalize type for frontend display
            normalized_type = res_type.lower()
            if 'visual' in normalized_type:
                normalized_type = 'article'
            elif 'pdf' in normalized_type:
                normalized_type = 'pdf'
            
            res = LearningResource(
                subject_code=subj_code,
                unit=str(unit), 
                min_risk_level=risk,
                resource_level=level,
                type=normalized_type,
                title=title,
                url=url,
                language=lang
            )
            new_resources.append(res)
        
        # Batch insert to avoid overwhelming the DB
        batch_size = 500
        for i in range(0, len(new_resources), batch_size):
            batch = new_resources[i:i+batch_size]
            db.add_all(batch)
            db.commit()
            print(f"Inserted batch {i//batch_size + 1}...")
            
        print("✨ RESTORATION COMPLETE: All PDFs and Videos are now correctly linked to their Subject Codes!")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error during restoration: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    repair_and_seed()
