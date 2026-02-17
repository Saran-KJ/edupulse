from database import engine, Base
from models import FacultyAllocation

print("Creating faculty_allocations table...")
FacultyAllocation.__table__.create(bind=engine)
print("Done!")
