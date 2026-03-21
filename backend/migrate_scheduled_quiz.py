import psycopg2
import os

def update_db():
    conn_str = "postgresql://postgres:sk%4065@localhost:5432/edupulse"
    try:
        conn = psycopg2.connect(conn_str)
        conn.autocommit = True
        cur = conn.cursor()
        print("Connected to DB")
        
        # Add column
        cur.execute("ALTER TABLE student_quiz_attempts ADD COLUMN IF NOT EXISTS scheduled_quiz_id INTEGER REFERENCES scheduled_quizzes(id)")
        print("Column 'scheduled_quiz_id' ensured.")
        
        cur.close()
        conn.close()
        print("Done")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    update_db()
