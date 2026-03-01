"""
Seed Assessment-Unit Mappings into the database.
Maps each assessment format to the units it covers.
"""
import sys
from sqlalchemy.orm import Session
from database import SessionLocal, engine, Base
from models import AssessmentUnitMapping
import models

# Map to populate AssessmentUnitMapping table
ASSESSMENT_UNIT_MAP_SEED = [
    {"assessment_name": "slip_test_1", "units": "1"},
    {"assessment_name": "slip_test_2", "units": "2"},
    {"assessment_name": "slip_test_3", "units": "3"},
    {"assessment_name": "slip_test_4", "units": "4"},
    {"assessment_name": "cia_1", "units": "1,2"},
    {"assessment_name": "cia_2", "units": "3,4"},
    {"assessment_name": "model", "units": "1,2,3,4,5"},
    {"assessment_name": "university_exam", "units": "1,2,3,4,5"},
]

def seed_assessment_mappings():
    print("Seeding Assessment Unit Mappings...")
    db: Session = SessionLocal()
    try:
        # Create table if it doesn't exist
        Base.metadata.create_all(bind=engine)
        print("✓ Database tables verified")

        for mapping in ASSESSMENT_UNIT_MAP_SEED:
            existing = db.query(AssessmentUnitMapping).filter(
                AssessmentUnitMapping.assessment_name == mapping["assessment_name"]
            ).first()

            if existing:
                if existing.units != mapping["units"]:
                    existing.units = mapping["units"]
                    print(f"  Updated mapping: {mapping['assessment_name']} -> Units {mapping['units']}")
                else:
                    print(f"  Skipped (already exists): {mapping['assessment_name']}")
            else:
                new_mapping = AssessmentUnitMapping(**mapping)
                db.add(new_mapping)
                print(f"✓ Added mapping: {mapping['assessment_name']} -> Units {mapping['units']}")

        db.commit()
        print("\n✅ Assessment Unit Mappings seeding completed successfully!")

    except Exception as e:
        print(f"❌ Error during seeding: {e}")
        db.rollback()
        sys.exit(1)
    finally:
        db.close()

if __name__ == "__main__":
    seed_assessment_mappings()
