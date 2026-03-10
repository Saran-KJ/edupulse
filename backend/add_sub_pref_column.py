from sqlalchemy import create_engine, text
from database import engine

def add_column():
    tables = [
        "students_cse", "students_ece", "students_eee", 
        "students_mech", "students_civil", "students_bio", "students_aids"
    ]
    
    with engine.connect() as conn:
        for table in tables:
            try:
                # Check if column exists first
                result = conn.execute(text(f"""
                    SELECT column_name 
                    FROM information_schema.columns 
                    WHERE table_name='{table}' AND column_name='learning_sub_preference'
                """))
                if not result.fetchone():
                    print(f"Adding learning_sub_preference to {table}...")
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN learning_sub_preference VARCHAR(50)"))
                    conn.commit()
                    print(f"✓ Added to {table}")
                else:
                    print(f"⚠ Column already exists in {table}")
            except Exception as e:
                print(f"✗ Error updating {table}: {e}")

if __name__ == "__main__":
    add_column()
