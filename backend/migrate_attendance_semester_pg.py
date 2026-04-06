from database import engine
from sqlalchemy import text

def run_migration():
    with engine.connect() as conn:
        print("Attempting to add 'semester' column to attendance table...")
        try:
            # Add integer column with default 1
            conn.execute(text("ALTER TABLE attendance ADD COLUMN semester INTEGER NOT NULL DEFAULT 1"))
            conn.commit()
            print("Successfully added 'semester' column.")
        except Exception as e:
            conn.rollback()
            print(f"Skipped adding 'semester' or error: {e}")

if __name__ == "__main__":
    run_migration()
