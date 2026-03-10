"""
Migration: Fix resource_level for Question Paper resources.
- Poriyaan Question Papers: Advanced → Intermediate
- Brainkart Question Papers / 2-Marks: Intermediate → Beginner
Run once: python fix_question_paper_level.py
"""
from database import SessionLocal
import models

def fix():
    db = SessionLocal()
    try:
        all_resources = db.query(models.LearningResource).all()

        fixed_poriyaan = 0
        fixed_brainkart = 0

        for res in all_resources:
            title = res.title or ""
            tags = res.tags or ""

            is_question_paper = "question paper" in title.lower()
            is_2marks = "important 2 marks" in title.lower()

            is_poriyaan = "Poriyaan" in tags
            is_brainkart = "BrainKart" in tags

            # Poriyaan QP: Advanced → Intermediate
            if is_poriyaan and is_question_paper and res.resource_level == "Advanced":
                res.resource_level = "Intermediate"
                fixed_poriyaan += 1

            # Brainkart QP / 2-Marks: Intermediate → Beginner
            if is_brainkart and (is_question_paper or is_2marks) and res.resource_level == "Intermediate":
                res.resource_level = "Beginner"
                fixed_brainkart += 1

        db.commit()
        print(f"Fixed {fixed_poriyaan} Poriyaan Question Papers (Advanced → Intermediate)")
        print(f"Fixed {fixed_brainkart} Brainkart Question Papers (Intermediate → Beginner)")
        print("Done!")

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    fix()
