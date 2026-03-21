import psycopg2
import os

def check_db():
    conn_str = "postgresql://postgres:sk%4065@localhost:5432/edupulse"
    try:
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        print("Connected to DB")
        
        cur.execute("SELECT id, subject_title, subject_code, is_active FROM scheduled_quizzes")
        rows = cur.fetchall()
        print(f"Total scheduled quizzes: {len(rows)}")
        for row in rows:
            print(row)
        
        cur.close()
        conn.close()
        print("Done")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_db()
