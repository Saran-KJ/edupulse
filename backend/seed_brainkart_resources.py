import json
import re
from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models

def extract_subject_code(content, title):
    # Brainkart URL often has the code like computer-networks---cs3591-2060
    # Let's search the URL inside content
    match = re.search(r'-([a-z]{2,3}\d{3,4})-', content.lower())
    if match:
        return match.group(1).upper()
        
    match2 = re.search(r'\b([A-Z]{2,3}\d{3,4})\b', content)
    if match2:
        return match2.group(1)
        
    return None

def seed_learning_resources():
    db = SessionLocal()
    
    try:
        # Load the scraped data
        with open('brainkart_content.json', 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        print(f"Loaded {len(data)} subjects from brainkart_content.json")
        
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
                r_type = "pdf" # default
                r_unit = None
                r_level = "Beginner" # Brainkart materials are usually beginner/intermediate
                
                if "Question Paper" in link_text or "Important 2 Marks" in link_text:
                    r_type = "article"
                    r_level = "Beginner"  # Question papers accessible to all, including high-risk students
                elif "Notes" in link_text or "Important Questions" in link_text:
                    r_type = "pdf"
                    
                if "Lab Manual" in link_text or "Practical Manual" in link_text:
                    r_type = "pdf"
                    r_level = "Beginner"
                    
                # Look for "Unit 1", "Unit 2", etc.
                unit_match = re.search(r'Unit\s*(\d)', link_text, re.IGNORECASE)
                if unit_match:
                    r_unit = unit_match.group(1)
                elif "Question Paper" in link_text:
                    r_unit = "1,2,3,4,5" # Covers all units usually
                
                resource = models.LearningResource(
                    title=link_text[:190], # Truncate if too long
                    description=f"Study material from BrainKart for {db_subjects[subject_code].subject_title} ({subject_code})",
                    url=url,
                    type=r_type,
                    tags="BrainKart, AU2021, StudyMaterial, CSE",
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
