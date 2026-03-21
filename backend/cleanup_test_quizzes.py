import psycopg2
import os

def cleanup_db():
    conn_str = "postgresql://postgres:sk%4065@localhost:5432/edupulse"
    try:
        conn = psycopg2.connect(conn_str)
        conn.autocommit = True
        cur = conn.cursor()
        print("Connected to DB")
        
        # Delete first from attempts then from quizzes
        cur.execute("DELETE FROM student_quiz_attempts WHERE scheduled_quiz_id IN (SELECT id FROM scheduled_quizzes WHERE subject_title = 'Fix Verification')")
        cur.execute("DELETE FROM scheduled_quizzes WHERE subject_title = 'Fix Verification'")
        print("Test quizzes with subject_title 'Fix Verification' deleted.")
        
        cur.close()
        conn.close()
        print("Done")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    cleanup_db()
