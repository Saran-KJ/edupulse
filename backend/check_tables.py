import sqlite3

def list_tables():
    db_path = 'e:/final-year-project-demo/backend/edupulse.db'
    print(f"Connecting to: {db_path}")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        
        if not tables:
            print("No tables found in the database.")
        else:
            print("Tables found:")
            for table in tables:
                print(f"- {table[0]}")
                
                # If marks table exists, count rows
                if table[0] == 'marks':
                    cursor.execute("SELECT COUNT(*) FROM marks")
                    count = cursor.fetchone()[0]
                    print(f"  (Rows: {count})")
            
    except Exception as e:
        print(f"Error querying database: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    list_tables()
