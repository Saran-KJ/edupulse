from sqlalchemy import text
from database import SessionLocal
import models

def clear_skill_content():
    db = SessionLocal()
    try:
        # Clear the content column for all skill-related resources
        result = db.execute(text("UPDATE learning_resources SET content = NULL WHERE skill_category IS NOT NULL"))
        db.commit()
        print(f"Successfully cleared content for {result.rowcount} skill resources.")
    except Exception as e:
        db.rollback()
        print(f"Error clearing skill content: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    clear_skill_content()
