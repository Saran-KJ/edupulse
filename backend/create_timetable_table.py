from database import engine
from models import Base, Timetable

def create_timetable_table():
    print("Creating timetables table...")
    Timetable.__table__.create(bind=engine, checkfirst=True)
    print("✅ Timetables table created successfully.")

if __name__ == "__main__":
    create_timetable_table()
