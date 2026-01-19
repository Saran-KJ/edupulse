from database import engine, Base
from sqlalchemy import text
import models

def add_column():
    with engine.connect() as conn:
        conn.execute(text("ALTER TABLE timetables ADD COLUMN faculty_name VARCHAR(100)"))
        conn.commit()
    print("Added faculty_name column to timetables")

if __name__ == "__main__":
    try:
        add_column()
    except Exception as e:
        print(f"Error (might already exist): {e}")
