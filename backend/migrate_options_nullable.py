#!/usr/bin/env python
"""
Migration: Make option columns nullable in quiz_questions table for NAT questions
"""

import sys
sys.path.insert(0, '.')

from database import SessionLocal, engine
from sqlalchemy import text

def migrate():
    """Make option fields nullable"""
    db = SessionLocal()
    
    try:
        print("Migrating quiz_questions table...")
        print("Making option_a, option_b, option_c, option_d nullable...")
        
        # PostgreSQL syntax to alter column nullability
        migrations = [
            "ALTER TABLE quiz_questions ALTER COLUMN option_a DROP NOT NULL;",
            "ALTER TABLE quiz_questions ALTER COLUMN option_b DROP NOT NULL;",
            "ALTER TABLE quiz_questions ALTER COLUMN option_c DROP NOT NULL;",
            "ALTER TABLE quiz_questions ALTER COLUMN option_d DROP NOT NULL;",
        ]
        
        for migration in migrations:
            try:
                db.execute(text(migration))
                print(f"  [OK] {migration.strip()}")
            except Exception as e:
                print(f"  [INFO] {migration.strip()} - {str(e)[:100]}")
        
        db.commit()
        print("\nMigration completed successfully!")
        return True
        
    except Exception as e:
        print(f"Error during migration: {e}")
        db.rollback()
        return False
    finally:
        db.close()


if __name__ == "__main__":
    success = migrate()
    sys.exit(0 if success else 1)
