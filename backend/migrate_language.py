from database import engine
from sqlalchemy import text

def migrate_db():
    print("Migrating database...")
    with engine.connect() as conn:
        try:
            # Check if column exists (this is a simplified check, often easier to just try-catch the alter)
            # PostgreSQL specific check or just try adding it.
            # user says OS is windows, so likely PostgreSQL as per previous logs (psycopg2).
            # Actually previous logs showed `invalid input value for enum roleenum: "PARENT"` which implies Postgres.
            
            # Let's try adding the column. If it exists, it will fail, which we catch.
            conn.execute(text("ALTER TABLE learning_resources ADD COLUMN language VARCHAR(50) DEFAULT 'English'"))
            conn.commit()
            print("✓ Added 'language' column to 'learning_resources' table.")
        except Exception as e:
            print(f"⚠ Column might already exist or error: {e}")
            
if __name__ == "__main__":
    migrate_db()
