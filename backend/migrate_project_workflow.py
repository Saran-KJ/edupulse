from database import engine, SessionLocal
import models
from sqlalchemy import text

def migrate():
    # 1. Create new tables
    models.Base.metadata.create_all(bind=engine)
    print("New tables created (if they didn't exist).")

    # 2. Add new columns to existing 'batches' table manually (since create_all doesn't add columns to existing tables)
    db = SessionLocal()
    try:
        columns_to_add = [
            ("reviewer_2_id", "INTEGER"),
            ("project_title", "VARCHAR(255)"),
            ("description", "TEXT"),
            ("zeroth_review_status", "VARCHAR(20) DEFAULT 'Pending'"),
            ("coordinator_remarks", "TEXT"),
            ("start_date", "DATE"),
            ("completion_status", "VARCHAR(20) DEFAULT 'In Progress'"),
            ("final_demo_url", "VARCHAR(500)"),
            ("final_report_url", "VARCHAR(500)")
        ]
        
        for col_name, col_type in columns_to_add:
            try:
                db.execute(text(f"ALTER TABLE batches ADD COLUMN {col_name} {col_type}"))
                print(f"Added column {col_name} to batches table.")
            except Exception as e:
                if "duplicate column name" in str(e).lower() or "already exists" in str(e).lower():
                    print(f"Column {col_name} already exists in batches table.")
                else:
                    print(f"Error adding column {col_name}: {e}")
        
        # Also project_reviews lost the 'marks' column conceptually, but we can keep it in DB for backward compat or drop it
        # Actually, let's just make sure the new tables are there.
        
        db.commit()
    except Exception as e:
        print(f"Migration error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    migrate()
