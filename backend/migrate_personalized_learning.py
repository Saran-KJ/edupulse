"""
Migration script to add new columns to learning_resources table
and create personalized_learning_plans table.
"""
from database import engine, SessionLocal, Base
from sqlalchemy import text
import models  # Import to register all models

def migrate():
    db = SessionLocal()
    try:
        # Create new tables (PersonalizedLearningPlan)
        Base.metadata.create_all(bind=engine)
        print("✓ Created new tables (personalized_learning_plans)")

        # Add new columns to learning_resources if they don't exist
        conn = engine.connect()

        columns_to_add = [
            ("unit", "VARCHAR(20)"),
            ("resource_level", "VARCHAR(20)"),
            ("skill_category", "VARCHAR(50)"),
        ]

        for col_name, col_type in columns_to_add:
            try:
                conn.execute(text(f"ALTER TABLE learning_resources ADD COLUMN {col_name} {col_type}"))
                conn.commit()
                print(f"✓ Added column '{col_name}' to learning_resources")
            except Exception as e:
                conn.rollback()
                if "already exists" in str(e).lower() or "duplicate column" in str(e).lower():
                    print(f"  Column '{col_name}' already exists, skipping")
                else:
                    print(f"  Warning adding '{col_name}': {e}")

        conn.close()
        print("\n✓ Migration complete!")

    except Exception as e:
        print(f"Migration error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    migrate()
