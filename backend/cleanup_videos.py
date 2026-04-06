import sqlalchemy
from sqlalchemy import create_engine, text
import config as cfg

settings = cfg.get_settings()
engine = create_engine(settings.database_url)

irrelevant_keywords = [
    "hindi", "telugu", "malayalam", "kannada", "marathi", "bengali",
    "punjabi", "gujarati", "urdu", "script"
]

print(f"Cleaning up YouTube recommendation cache in PostgreSQL...")

deleted_total = 0
try:
    with engine.connect() as conn:
        for kw in irrelevant_keywords:
            # Check title and language fields
            result = conn.execute(
                text("DELETE FROM youtube_recommendations WHERE LOWER(title) LIKE :kw OR LOWER(language) LIKE :kw"),
                {"kw": f"%{kw}%"}
            )
            deleted_total += result.rowcount
        conn.commit()
    print(f"Cleanup complete. Removed {deleted_total} irrelevant regional language recommendations.")
except Exception as e:
    print(f"Error during cleanup: {e}")
