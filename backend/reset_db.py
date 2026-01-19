"""
Reset Database Script
Drops all tables in the database using reflection.
"""
from database import engine
from sqlalchemy import MetaData

def reset_database():
    print("Dropping all tables...")
    try:
        metadata = MetaData()
        metadata.reflect(bind=engine)
        metadata.drop_all(bind=engine)
        print("✓ All tables dropped successfully.")
    except Exception as e:
        print(f"✗ Error dropping tables: {e}")

if __name__ == "__main__":
    reset_database()
