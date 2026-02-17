from database import engine
from sqlalchemy import text

def drop_table():
    with engine.connect() as conn:
        try:
            conn.execute(text("DROP TABLE IF EXISTS timetables"))
            conn.commit()
            print("✓ Dropped timetables table")
        except Exception as e:
            print(f"Error dropping table: {e}")

if __name__ == "__main__":
    drop_table()
