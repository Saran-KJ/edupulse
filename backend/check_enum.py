"""Check and fix roleenum values."""
from database import engine
from sqlalchemy import text

def check_and_fix_enum():
    with engine.connect() as conn:
        # Check current enum values
        result = conn.execute(text("""
            SELECT enumlabel FROM pg_enum 
            WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'roleenum')
            ORDER BY enumsortorder
        """))
        labels = [r[0] for r in result.fetchall()]
        print(f"Current roleenum values: {labels}")
        
        # Check if 'parent' exists (case-sensitive)
        if 'parent' in labels:
            print("✓ 'parent' already exists in roleenum")
        else:
            print("Adding 'parent' to roleenum...")
            try:
                conn.execute(text("ALTER TYPE roleenum ADD VALUE 'parent'"))
                conn.commit()
                print("✓ Added 'parent' to roleenum")
            except Exception as e:
                print(f"Error: {e}")

if __name__ == "__main__":
    check_and_fix_enum()
