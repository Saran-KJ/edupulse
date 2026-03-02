import os
from sqlalchemy import text
from database import engine

def add_columns(connection, table_name, columns):
    for col_name, col_type in columns.items():
        try:
            # PostgreSQL syntax: ALTER TABLE table_name ADD COLUMN column_name data_type
            connection.execute(text(f"ALTER TABLE {table_name} ADD COLUMN IF NOT EXISTS {col_name} {col_type}"))
            print(f"Added/Ensured {col_name} in {table_name}")
        except Exception as e:
            print(f"Error adding {col_name} to {table_name}: {e}")

def main():
    tables = [
        "students_cse", "students_ece", "students_eee", 
        "students_mech", "students_civil", "students_bio", "students_aids"
    ]

    new_columns = {
        "blood_group": "VARCHAR(20)",
        "religion": "VARCHAR(50)",
        "caste": "VARCHAR(50)",
        "abc_id": "VARCHAR(50)",
        "aadhar_no": "VARCHAR(50)",
        "father_name": "VARCHAR(100)",
        "father_occupation": "VARCHAR(100)",
        "father_phone": "VARCHAR(20)",
        "mother_name": "VARCHAR(100)",
        "mother_occupation": "VARCHAR(100)",
        "mother_phone": "VARCHAR(20)",
        "guardian_name": "VARCHAR(100)",
        "guardian_occupation": "VARCHAR(100)",
        "guardian_phone": "VARCHAR(20)"
    }

    try:
        with engine.connect() as connection:
            for table in tables:
                print(f"\nUpdating table: {table}")
                add_columns(connection, table, new_columns)
            
            connection.commit()
            print("\nDatabase migration complete.")
            
    except Exception as e:
        print(f"Failed to connect or migrate: {e}")

if __name__ == "__main__":
    main()
