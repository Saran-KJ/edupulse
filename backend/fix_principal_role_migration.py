import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), 'edupulse.db')

def normalize_roles():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    # Update any role values that are not lowercase but match known roles
    cur.execute("""
        UPDATE users
        SET role = LOWER(role)
        WHERE role != LOWER(role)
    """)
    conn.commit()
    # Verify changes
    cur.execute("SELECT user_id, role FROM users WHERE role != LOWER(role)")
    remaining = cur.fetchall()
    if remaining:
        print('Some roles still not normalized:', remaining)
    else:
        print('All role values normalized to lowercase.')
    conn.close()

if __name__ == '__main__':
    normalize_roles()
