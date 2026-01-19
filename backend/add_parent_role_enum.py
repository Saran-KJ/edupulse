"""
Add 'parent' value to the roleenum enum type in PostgreSQL.
"""
from database import engine
from sqlalchemy import text

def add_parent_to_role_enum():
    with engine.connect() as conn:
        try:
            # Add 'parent' to the roleenum enum type
            conn.execute(text("ALTER TYPE roleenum ADD VALUE IF NOT EXISTS 'parent'"))
            conn.commit()
            print("✓ Added 'parent' to roleenum enum type")
        except Exception as e:
            conn.rollback()
            if "already exists" in str(e).lower():
                print("✓ 'parent' already exists in roleenum")
            else:
                print(f"⚠ Error: {e}")
        
        print("\n✓ Role enum migration complete!")

if __name__ == "__main__":
    add_parent_to_role_enum()
