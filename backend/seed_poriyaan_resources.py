import json
import re
from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models

def extract_subject_code(content, title):
    # Try to find something like CS3351, PH3151, GE3151, CCS356 in the content
    # Usually it's in the first few lines: "CS3351 3rd Semester CSE Dept | 2021 Regulation"
    match = re.search(r'\b([A-Z]{2,3}\d{3,4})\b', content)
    if match:
        return match.group(1)
    
    # Alternatively try matching from title by just stripping common words?
    # Poriyaan subject code extraction might fail if not present.
    return None

def seed_learning_resources():
    db = SessionLocal()
    
    try:
        # Load the scraped data
        with open('poriyaan_content.json', 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        print(f"Loaded {len(data)} subjects from poriyaan_content.json")
        
        # Mapping of subject code to subject for validation
        db_subjects = {s.subject_code: s for s in db.query(models.Subject).all()}
        
        resources_added = 0
        resources_skipped = 0
        
        for item in data:
            title = item.get('title', '')
            content = item.get('content', '')
            pdf_links = item.get('pdf_links', [])
            
            subject_code = extract_subject_code(content, title)
            
            if not subject_code or subject_code not in db_subjects:
                # Try finding by title
                matched_subject = None
                for code, sub in db_subjects.items():
                    if sub.subject_title.lower() in title.lower() or title.lower() in sub.subject_title.lower():
                        matched_subject = sub
                        subject_code = code
                        break
                    
                if not matched_subject:
                    print(f"Skipping {title}: Could not match subject code {subject_code} in DB")
                    continue
                    
            print(f"Processing {title} ({subject_code})...")
            
            # Add PDF links as Learning Resources
            for link in pdf_links:
                link_text = link.get('text', '')
                url = link.get('url', '')
                
                if not url:
                    continue
                    
                # Check if it already exists
                existing = db.query(models.LearningResource).filter_by(url=url).first()
                if existing:
                    resources_skipped += 1
                    continue
                
                # Determine Resource Type and Unit based on text
                r_type = "pdf"
                r_unit = None
                r_level = "Intermediate"
                
                if "Question Paper" in link_text:
                    r_type = "article"
                    r_level = "Intermediate"  # Question papers are practice for all students, not just advanced
                elif "Notes" in link_text or "Important Questions" in link_text:
                    r_type = "pdf"
                    
                # Look for "Unit X" in link text
                unit_match = re.search(r'Unit\s*(\d)', link_text, re.IGNORECASE)
                if unit_match:
                    r_unit = unit_match.group(1)
                
                resource = models.LearningResource(
                    title=link_text[:190], # Truncate if too long
                    description=f"Study material for {db_subjects[subject_code].subject_title} ({subject_code})",
                    url=url,
                    type=r_type,
                    tags="Poriyaan, AU2021, StudyMaterial",
                    language="English",
                    dept="CSE",
                    subject_code=subject_code,
                    unit=r_unit,
                    resource_level=r_level,
                    min_risk_level=None
                )
                db.add(resource)
                resources_added += 1
                
        db.commit()
        print(f"Successfully added {resources_added} learning resources. Skipped {resources_skipped} already existing.")
        
    except Exception as e:
        print(f"Error seeding learning resources: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_learning_resources()
