from database import engine
from sqlalchemy import text

def update_db():
    tables = [
        "students_cse", "students_ece", "students_eee", 
        "students_mech", "students_civil", "students_bio", "students_aids"
    ]
    
    with engine.connect() as conn:
        for table in tables:
            try:
                conn.execute(text(f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS overall_study_strategy TEXT"))
                print(f"Updated {table}")
            except Exception as e:
                print(f"Error updating {table}: {e}")
        conn.commit()

if __name__ == "__main__":
    update_db()
