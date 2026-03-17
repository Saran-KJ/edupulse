import os
import sys

# Add backend to sys.path to allow imports
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import AssessmentUnitMapping

def verify():
    db_url = os.environ.get("DATABASE_URL", "sqlite:///e:/final-year-project-demo/backend/edupulse.db")
    print(f"Connecting to: {db_url}")
    engine = create_engine(db_url)
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    try:
        mappings = db.query(AssessmentUnitMapping).order_by(AssessmentUnitMapping.id).all()
        print(f"Found {len(mappings)} mappings:")
        for m in mappings:
            print(f"  - {m.assessment_name}: {m.units}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    verify()
