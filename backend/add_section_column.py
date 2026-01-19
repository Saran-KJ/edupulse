from sqlalchemy import text
from database import engine

def add_section_column():
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE students ADD COLUMN section VARCHAR(10)"))
            conn.commit()
            print("Successfully added 'section' column to 'students' table.")
        except Exception as e:
            print(f"Error adding column: {e}")

if __name__ == "__main__":
    add_section_column()
