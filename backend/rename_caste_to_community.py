import psycopg2
from config import get_settings

def migrate():
    settings = get_settings()
    db_url = settings.database_url
    
    print(f"Connecting to database: {db_url}")
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()
    
    tables = [
        "students_cse", "students_ece", "students_eee", 
        "students_mech", "students_civil", "students_bio", 
        "students_aids"
    ]
    
    try:
        for table in tables:
            print(f"Renaming 'caste' to 'community' in table: {table}")
            cur.execute(f"ALTER TABLE {table} RENAME COLUMN caste TO community;")
        
        conn.commit()
        print("Migration completed successfully!")
    except Exception as e:
        conn.rollback()
        print(f"Migration failed: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    migrate()
