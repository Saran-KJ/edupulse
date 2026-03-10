"""Migration: Add content column to learning_resources table."""
from sqlalchemy import text
from database import engine

def migrate():
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE learning_resources ADD COLUMN content TEXT"))
            conn.commit()
            print("✅ Added 'content' column to learning_resources table.")
        except Exception as e:
            if "duplicate column" in str(e).lower() or "already exists" in str(e).lower():
                print("ℹ️  Column 'content' already exists — skipping.")
            else:
                raise

if __name__ == "__main__":
    migrate()
