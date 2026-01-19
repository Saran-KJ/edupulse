"""
Database initialization script
Creates sample data for testing the EduPulse system with new role-based system
"""

from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
from auth import get_password_hash
from datetime import date, datetime

def create_sample_data():
    """Create sample data for testing"""
    db = SessionLocal()
    
    try:
        # Create tables
        models.Base.metadata.create_all(bind=engine)
        print("✓ Database tables created")
        
        # Check if data already exists
        if db.query(models.User).first():
            print("⚠ Sample data already exists. Skipping...")
            return
        
        # Create admin user with specified credentials
        admin = models.User(
            name="System Administrator",
            email="admin65@gmail.com",
            password=get_password_hash("1234678@"),
            role=models.RoleEnum.ADMIN,
            secret_pin="1234",
            is_approved=1,
            is_active=1
        )
        
        # Create sample high-privilege users
        hod = models.User(
            name="Dr. John Smith",
            email="hod.cse@edupulse.com",
            password=get_password_hash("hod123"),
            role=models.RoleEnum.HOD,
            secret_pin="5678",
            is_approved=1,
            is_active=1
        )
        
        faculty = models.User(
            name="Prof. Sarah Johnson",
            email="faculty@edupulse.com",
            password=get_password_hash("faculty123"),
            role=models.RoleEnum.FACULTY,
            secret_pin="9012",
            is_approved=1,
            is_active=1
        )
        
        # Create pending student user (for testing approval workflow)
        pending_student = models.User(
            name="Pending Student",
            email="pending@student.edu",
            password=get_password_hash("student123"),
            role=models.RoleEnum.STUDENT,
            secret_pin="3456",
            is_approved=0,  # Pending approval
            is_active=1
        )
        
        db.add_all([admin, hod, faculty, pending_student])
        db.commit()
        print("✓ Created users with new role system")
        
        # Create departments
        dept_cse = models.Department(dept_code="CSE", dept_name="Computer Science Engineering")
        dept_ece = models.Department(dept_code="ECE", dept_name="Electronics and Communication")
        dept_mech = models.Department(dept_code="MECH", dept_name="Mechanical Engineering")
        
        db.add_all([dept_cse, dept_ece, dept_mech])
        db.commit()
        print("✓ Created departments")
        
        # Create subjects
        subjects = [
            models.Subject(subject_code="CS101", subject_name="Data Structures", dept_id=dept_cse.dept_id, semester=3),
            models.Subject(subject_code="CS102", subject_name="Algorithms", dept_id=dept_cse.dept_id, semester=3),
            models.Subject(subject_code="CS103", subject_name="Database Systems", dept_id=dept_cse.dept_id, semester=4),
            models.Subject(subject_code="CS104", subject_name="Operating Systems", dept_id=dept_cse.dept_id, semester=4),
        ]
        
        db.add_all(subjects)
        db.commit()
        print("✓ Created subjects")
        
        # Create sample students
        # CSE Students
        students_cse = [
            models.StudentCSE(
                reg_no="2021CSE001",
                name="Rahul Kumar",
                email="rahul@student.edu",
                phone="9876543210",
                dept="CSE",
                year=2,
                semester=4,
                dob=date(2003, 5, 15),
                address="123 Main St, City",
                section="A"
            ),
            models.StudentCSE(
                reg_no="2021CSE002",
                name="Priya Sharma",
                email="priya@student.edu",
                phone="9876543211",
                dept="CSE",
                year=2,
                semester=4,
                dob=date(2003, 8, 22),
                address="456 Park Ave, City",
                section="A"
            ),
            models.StudentCSE(
                reg_no="2021CSE003",
                name="Amit Patel",
                email="amit@student.edu",
                phone="9876543212",
                dept="CSE",
                year=2,
                semester=4,
                dob=date(2003, 3, 10),
                address="789 Lake Rd, City",
                section="A"
            ),
        ]
        db.add_all(students_cse)
        
        # ECE Students
        students_ece = [
             models.StudentECE(
                reg_no="2021ECE001",
                name="ECE Student 1",
                email="ece1@student.edu",
                dept="ECE",
                year=2,
                semester=4,
                section="A"
            )
        ]
        db.add_all(students_ece)

        # MECH Students
        students_mech = [
             models.StudentMECH(
                reg_no="2021MECH001",
                name="MECH Student 1",
                email="mech1@student.edu",
                dept="MECH",
                year=2,
                semester=4,
                section="A"
            )
        ]
        db.add_all(students_mech)
        
        db.commit()
        print("✓ Created sample students in separate tables")
        
        
        # Create attendance records
        for student in students_cse:
            for subject in subjects[:2]:
                attendance = models.Attendance(
                    reg_no=student.reg_no,
                    student_name=student.name,
                    date=date(2024, 1, 15), # Dummy date
                    status="Present",
                    year=2,
                    section="A",
                    dept="CSE"
                )
                db.add(attendance)
        
        db.commit()
        print("✓ Created attendance records")
        
        # Create activities
        activities = [
            models.Activity(
                activity_name="Annual Hackathon 2024",
                activity_type=models.ActivityTypeEnum.HACKATHON,
                level="College",
                activity_date=date(2024, 3, 15),
                description="24-hour coding competition"
            ),
            models.Activity(
                activity_name="Tech Symposium",
                activity_type=models.ActivityTypeEnum.SYMPOSIUM,
                level="State",
                activity_date=date(2024, 2, 20),
                description="State-level technical symposium"
            ),
        ]
        
        db.add_all(activities)
        db.commit()
        print("✓ Created activities")
        
        # Create activity participations
        for student in students_cse[:2]:  # First 2 students
            participation = models.ActivityParticipation(
                activity_id=activities[0].activity_id,
                reg_no=student.reg_no,
                role="Participant",
                achievement="Winner" if student.reg_no == "2021CSE001" else "Participant"
            )
            db.add(participation)
        
        db.commit()
        print("✓ Created activity participations")
        
        print("\n" + "="*60)
        print("✓ Sample data created successfully!")
        print("="*60)
        print("\nLogin Credentials:")
        print("  Admin: admin65@gmail.com / 1234678@ (PIN: 1234)")
        print("  HOD: hod.cse@edupulse.com / hod123 (PIN: 5678)")
        print("  Faculty: faculty@edupulse.com / faculty123 (PIN: 9012)")
        print("\nPending Approval:")
        print("  Student: pending@student.edu / student123 (PIN: 3456)")
        print("\nSample Students:")
        print("  - Rahul Kumar (2021CSE001)")
        print("  - Priya Sharma (2021CSE002)")
        print("  - Amit Patel (2021CSE003)")
        print("="*60)
        
    except Exception as e:
        print(f"✗ Error creating sample data: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("EduPulse - Database Initialization")
    print("="*60)
    create_sample_data()
