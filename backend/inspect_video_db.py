import sqlite3
import pandas as pd

def inspect_db():
    conn = sqlite3.connect('e:/final-year-project-demo/backend/edupulse.db')
    
    print("--- Subjects ---")
    subjects = pd.read_sql_query("SELECT subject_code, subject_title, semester FROM subjects LIMIT 20", conn)
    print(subjects)
    
    print("\n--- YouTube Recommendations ---")
    recs = pd.read_sql_query("SELECT reg_no, subject_code, unit, title, risk_level, language FROM youtube_recommendations LIMIT 20", conn)
    print(recs)
    
    print("\n--- Active Personalized Plans ---")
    plans = pd.read_sql_query("SELECT reg_no, subject_code, risk_level, focus_type, units FROM personalized_learning_plans WHERE is_active = 1 LIMIT 20", conn)
    print(plans)
    
    conn.close()

if __name__ == "__main__":
    inspect_db()
