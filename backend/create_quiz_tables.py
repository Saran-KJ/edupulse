import sys
import os
sys.path.insert(0, os.path.abspath('.'))

from database import engine
import models

def migrate_quiz_tables():
    print("Connecting to database and creating quiz tables...")
    try:
        # checkfirst=True prevents error if they already exist
        models.QuizQuestion.__table__.create(bind=engine, checkfirst=True)
        models.StudentQuizAttempt.__table__.create(bind=engine, checkfirst=True)
        print("✓ Quiz tables created successfully.")
    except Exception as e:
        print(f"✗ Error creating quiz tables: {e}")

if __name__ == "__main__":
    migrate_quiz_tables()
