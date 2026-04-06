from database import engine
from sqlalchemy import text, inspect

def sync_schema():
    inspector = inspect(engine)
    
    student_tables = [
        'students_cse', 'students_ece', 'students_eee', 
        'students_mech', 'students_civil', 'students_bio', 'students_aids'
    ]
    
    # Missing columns to add
    # Format: (column_name, data_type, default_value)
    missing_columns = [
        ('placement_readiness_score', 'FLOAT', '0.0'),
        ('skill_streak', 'INTEGER', '0'),
        ('last_skill_activity', 'TIMESTAMP', 'NULL'),
    ]
    
    with engine.connect() as conn:
        for table in student_tables:
            if table not in inspector.get_table_names():
                print(f"Skipping {table} as it doesn't exist.")
                continue
                
            existing_columns = [c['name'] for c in inspector.get_columns(table)]
            
            for col_name, col_type, default_val in missing_columns:
                if col_name not in existing_columns:
                    print(f"Adding column {col_name} ({col_type}) to {table}...")
                    try:
                        sql = f"ALTER TABLE {table} ADD COLUMN {col_name} {col_type} DEFAULT {default_val}"
                        conn.execute(text(sql))
                        conn.commit()
                        print(f"Successfully added {col_name} to {table}.")
                    except Exception as e:
                        print(f"Error adding {col_name} to {table}: {e}")
                        conn.rollback()

if __name__ == "__main__":
    sync_schema()
