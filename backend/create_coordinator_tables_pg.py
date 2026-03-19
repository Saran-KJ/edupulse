import psycopg2
import os
from urllib.parse import urlparse

# DATABASE_URL = "postgresql://postgres:sk%4065@localhost:5432/edupulse"
db_url = "postgresql://postgres:sk%4065@localhost:5432/edupulse"

def migrate():
    try:
        conn = psycopg2.connect(db_url)
        cursor = conn.cursor()
        
        # 1. Create project_coordinators table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS project_coordinators (
                id SERIAL PRIMARY KEY,
                faculty_id INTEGER NOT NULL REFERENCES users (user_id),
                dept VARCHAR(50) NOT NULL,
                year INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        print("OK: Created project_coordinators table")

        # 2. Add reviewer_id to batches table
        try:
            cursor.execute("ALTER TABLE batches ADD COLUMN reviewer_id INTEGER REFERENCES users (user_id)")
            print("OK: Added reviewer_id to batches table")
        except psycopg2.errors.DuplicateColumn:
            conn.rollback() # Rollback the sub-transaction
            print("INFO: reviewer_id already exists in batches table")
        except Exception as e:
            conn.rollback()
            print(f"INFO: Could not add reviewer_id to batches (likely exists): {e}")

        # 3. Add reviewer_id to project_reviews table
        try:
            cursor.execute("ALTER TABLE project_reviews ADD COLUMN reviewer_id INTEGER REFERENCES users (user_id)")
            print("OK: Added reviewer_id to project_reviews table")
        except psycopg2.errors.DuplicateColumn:
            conn.rollback()
            print("INFO: reviewer_id already exists in project_reviews table")
        except Exception as e:
            conn.rollback()
            print(f"INFO: Could not add reviewer_id to project_reviews (likely exists): {e}")

        conn.commit()
    except Exception as e:
        print(f"ERROR: Migration failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if 'conn' in locals() and conn:
            conn.close()

if __name__ == "__main__":
    migrate()
