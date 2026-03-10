import sys
import os
sys.path.insert(0, os.path.abspath('.'))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from config import get_settings
import models

def clear_bad_recs():
    settings = get_settings()
    engine = create_engine(settings.database_url)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    try:
        # Delete recommendations for the subject that had issues
        # Or delete all Recommendations to force a fresh fetch with new logic
        count = db.query(models.YouTubeRecommendation).delete()
        db.commit()
        print(f"✓ Cleared {count} cached YouTube recommendations.")

    finally:
        db.close()

if __name__ == "__main__":
    clear_bad_recs()
