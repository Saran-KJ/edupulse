"""Add PARENT uppercase to roleenum."""
from database import engine
from sqlalchemy import text

with engine.connect() as conn:
    try:
        conn.execute(text("ALTER TYPE roleenum ADD VALUE 'PARENT'"))
        conn.commit()
        print("✓ Added 'PARENT' to roleenum")
    except Exception as e:
        if "already exists" in str(e).lower():
            print("✓ 'PARENT' already exists")
        else:
            print(f"Error: {e}")
