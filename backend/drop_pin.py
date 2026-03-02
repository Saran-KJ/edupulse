from sqlalchemy import text
from database import engine

def drop_secret_pin():
    try:
        with engine.connect() as conn:
            conn.execute(text("ALTER TABLE users DROP COLUMN IF EXISTS secret_pin;"))
            conn.commit()
            print("Successfully dropped secret_pin column from users table.")
    except Exception as e:
        print(f"Error dropping column: {e}")

if __name__ == '__main__':
    drop_secret_pin()
