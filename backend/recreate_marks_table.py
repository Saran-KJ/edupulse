"""
Script to recreate marks table with new structure
"""
from database import engine
from models import Base, Mark

def recreate_marks_table():
    try:
        # Drop the marks table
        Mark.__table__.drop(engine, checkfirst=True)
        print("✓ Dropped old marks table")
        
        # Create the new marks table
        Mark.__table__.create(engine)
        print("✓ Created new marks table with updated structure")
        
        print("\nNew marks table structure:")
        print("- id (primary key)")
        print("- reg_no, student_name, year, semester")
        print("- subject_code, subject_title")
        print("- assignment_1 to assignment_5")
        print("- slip_test_1 to slip_test_4")
        print("- cia_1, cia_2")
        print("- model")
        print("- university_result_grade")
        
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    print("Recreating marks table...")
    print("="*60)
    recreate_marks_table()
    print("="*60)
