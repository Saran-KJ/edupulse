import sqlite3
import os

db_path = 'edupulse.db'
if not os.path.exists(db_path):
    print(f"Database not found at {db_path}")
    exit(1)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    cursor.execute("SELECT id, faculty_id, subject_title FROM scheduled_quizzes")
    rows = cursor.fetchall()
    print("Scheduled Quizzes:")
    for row in rows:
        print(f"ID: {row[0]}, Faculty ID: {row[1]}, Subject: {row[2]}")
except Exception as e:
    print(f"Error: {e}")

conn.close()
