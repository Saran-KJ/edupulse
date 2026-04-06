from sqlalchemy import create_engine, text
from config import get_settings

def update_schema():
    settings = get_settings()
    engine = create_engine(settings.database_url)
    
    with engine.connect() as conn:
        print("Checking for 'time' column in 'attendance' table...")
        try:
            # PostgreSQL syntax to add column if not exists
            conn.execute(text("ALTER TABLE attendance ADD COLUMN IF NOT EXISTS time VARCHAR(20)"))
            conn.commit()
            print("Successfully added 'time' column to 'attendance' table.")
        except Exception as e:
            print(f"Error updating schema: {e}")

if __name__ == "__main__":
    update_schema()
