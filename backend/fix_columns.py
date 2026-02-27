from sqlalchemy import text
from database import engine

def add_missing_columns():
    try:
        with engine.connect() as conn:
            conn.execute(text("""
                ALTER TABLE learning_resources 
                ADD COLUMN IF NOT EXISTS unit VARCHAR(20),
                ADD COLUMN IF NOT EXISTS resource_level VARCHAR(20),
                ADD COLUMN IF NOT EXISTS skill_category VARCHAR(50)
            """))
            conn.commit()
            print("Successfully added missing columns to learning_resources table")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    add_missing_columns()
