from database import engine
from sqlalchemy import text

def add_child_reg_no_column():
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN child_reg_no VARCHAR(50)"))
            conn.commit()
            print("Successfully added child_reg_no column to users table.")
        except Exception as e:
            print(f"Error adding column (might already exist): {e}")

if __name__ == "__main__":
    add_child_reg_no_column()
