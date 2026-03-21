import sqlite3
import os

def migrate_db():
    # Attempt to locate edupulse.db
    db_path = "edupulse.db"
    if not os.path.exists(db_path):
        print(f"Database {db_path} not found. Please run this from the backend directory.")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # Check if period column exists
        cursor.execute("PRAGMA table_info(attendance)")
        columns = [info[1] for info in cursor.fetchall()]
        
        if "period" not in columns:
            print("Adding 'period' column to attendance table...")
            cursor.execute("ALTER TABLE attendance ADD COLUMN period INTEGER NOT NULL DEFAULT 1")
        else:
            print("'period' column already exists.")

        if "subject_code" not in columns:
            print("Adding 'subject_code' column to attendance table...")
            cursor.execute("ALTER TABLE attendance ADD COLUMN subject_code VARCHAR(20)")
        else:
            print("'subject_code' column already exists.")

        conn.commit()
        print("Migration completed successfully.")

    except Exception as e:
        print(f"Error during migration: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    migrate_db()
