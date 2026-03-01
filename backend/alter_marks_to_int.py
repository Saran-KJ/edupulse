from database import SessionLocal
from sqlalchemy import text

def alter_marks_table():
    db = SessionLocal()
    try:
        columns = [
            'assignment_1', 'assignment_2', 'assignment_3', 'assignment_4', 'assignment_5',
            'slip_test_1', 'slip_test_2', 'slip_test_3', 'slip_test_4',
            'cia_1', 'cia_2', 'model'
        ]
        
        for col in columns:
            query = f"ALTER TABLE marks ALTER COLUMN {col} TYPE INTEGER USING {col}::integer;"
            db.execute(text(query))
            print(f"Altered {col} to Integer")
            
        db.commit()
        print("Successfully updated database schema to INTEGER for marks.")
    except Exception as e:
        db.rollback()
        print(f"Error occurred: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    alter_marks_table()
