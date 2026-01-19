"""
Script to delete all marks from the database
"""
from database import SessionLocal
import models

def delete_all_marks():
    db = SessionLocal()
    try:
        count = db.query(models.Mark).count()
        db.query(models.Mark).delete()
        db.commit()
        print(f"✓ Deleted {count} marks from database")
    except Exception as e:
        print(f"✗ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("Deleting all marks from database...")
    delete_all_marks()
