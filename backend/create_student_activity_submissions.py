"""
Migration script to create the student_activity_submissions table.
Run this once to add the table to the database.
"""
from database import engine
from models import Base, StudentActivitySubmission

# Create only the new table
StudentActivitySubmission.__table__.create(bind=engine, checkfirst=True)
print("✅ student_activity_submissions table created successfully!")
