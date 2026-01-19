"""
Add parent-specific columns to the users table (PostgreSQL).
Run this script after updating models.py with the new columns.
"""
from database import engine
from sqlalchemy import text

def add_parent_columns():
    with engine.connect() as conn:
        # Add new columns if they don't exist
        columns = [
            ("child_name", "VARCHAR(100)"),
            ("child_phone", "VARCHAR(20)"),
            ("occupation", "VARCHAR(100)")
        ]
        
        for col_name, col_type in columns:
            try:
                conn.execute(text(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}"))
                conn.commit()
                print(f"✓ Added column: {col_name}")
            except Exception as e:
                conn.rollback()
                if "already exists" in str(e).lower() or "duplicate column" in str(e).lower():
                    print(f"✓ Column {col_name} already exists")
                else:
                    print(f"⚠ Error adding {col_name}: {e}")
        
        print("\n✓ Parent columns migration complete!")

if __name__ == "__main__":
    add_parent_columns()
