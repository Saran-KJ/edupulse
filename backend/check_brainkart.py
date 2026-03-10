import sys
sys.path.insert(0, '.')
from config import get_settings
from sqlalchemy import create_engine, text

settings = get_settings()
print("DB URL:", settings.database_url)

try:
    engine = create_engine(settings.database_url)
    with engine.connect() as conn:
        result = conn.execute(text("SELECT COUNT(*) FROM learning_resources WHERE tags LIKE '%BrainKart%'"))
        count = result.scalar()
        print(f"\nBrainKart resources in DB: {count}")

        result2 = conn.execute(text("SELECT title, subject_code FROM learning_resources WHERE tags LIKE '%BrainKart%' LIMIT 5"))
        rows = result2.fetchall()
        print("\nSample rows:")
        for row in rows:
            print(f"  - {row[1]} | {row[0]}")
except Exception as e:
    print("Error:", e)
