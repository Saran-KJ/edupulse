from database import engine
from sqlalchemy import text

def run_migration():
    with engine.connect() as conn:
        print("Attempting to add 'period' column...")
        try:
            conn.execute(text("ALTER TABLE attendance ADD COLUMN period INTEGER NOT NULL DEFAULT 1"))
            conn.commit()
            print("Successfully added 'period' column.")
        except Exception as e:
            conn.rollback()
            print(f"Skipped adding 'period' (might already exist): {e}")
            
        print("Attempting to add 'subject_code' column...")
        try:
            conn.execute(text("ALTER TABLE attendance ADD COLUMN subject_code VARCHAR(20)"))
            conn.commit()
            print("Successfully added 'subject_code' column.")
        except Exception as e:
            conn.rollback()
            print(f"Skipped adding 'subject_code' (might already exist): {e}")

if __name__ == "__main__":
    run_migration()
