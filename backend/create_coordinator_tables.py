import sqlite3
import os

# Path to the database
db_path = os.path.join(os.path.dirname(__file__), "edupulse.db")

def migrate():
    if not os.path.exists(db_path):
        print(f"Database not found at {db_path}")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # 1. Create project_coordinators table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS project_coordinators (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                faculty_id INTEGER NOT NULL,
                dept TEXT NOT NULL,
                year INTEGER NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (faculty_id) REFERENCES users (user_id)
            )
        """)
        print("OK: Created project_coordinators table")

        # 2. Add reviewer_id to batches table
        try:
            cursor.execute("ALTER TABLE batches ADD COLUMN reviewer_id INTEGER REFERENCES users (user_id)")
            print("OK: Added reviewer_id to batches table")
        except sqlite3.OperationalError:
            print("INFO: reviewer_id already exists in batches table")

        # 3. Add reviewer_id to project_reviews table
        try:
            cursor.execute("ALTER TABLE project_reviews ADD COLUMN reviewer_id INTEGER REFERENCES users (user_id)")
            print("OK: Added reviewer_id to project_reviews table")
        except sqlite3.OperationalError:
            print("INFO: reviewer_id already exists in project_reviews table")

        conn.commit()
    except Exception as e:
        print(f"ERROR: Migration failed: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()


if __name__ == "__main__":
    migrate()
