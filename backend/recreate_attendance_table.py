from database import engine, Base
import models

def recreate_attendance_table():
    print("Dropping attendance table...")
    try:
        models.Attendance.__table__.drop(engine)
        print("Attendance table dropped.")
    except Exception as e:
        print(f"Error dropping table (might not exist): {e}")

    print("Creating attendance table...")
    models.Attendance.__table__.create(engine)
    print("Attendance table created successfully.")

if __name__ == "__main__":
    recreate_attendance_table()
