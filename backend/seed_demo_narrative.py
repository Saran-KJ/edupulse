import sys
import os
from datetime import datetime, timedelta

# Add the current directory to the path so we can import internal modules
sys.path.append(os.getcwd())

from database import SessionLocal
import models
import auth

def seed_demo_narrative():
    db = SessionLocal()
    try:
        # --- 1. PERSONA: RAJESH (HIGH RISK - THE STORY OF RECOVERY) ---
        print("Seeding Rajesh (High Risk)...")
        rajesh_email = "rajesh.high@edupulse.com"
        rajesh_reg = "2024CSE001"
        
        user_rajesh = db.query(models.User).filter(models.User.email == rajesh_email).first()
        if not user_rajesh:
            user_rajesh = models.User(
                name="Rajesh Kumar",
                email=rajesh_email,
                password=auth.get_password_hash("rajesh123"),
                role=models.RoleEnum.STUDENT,
                phone="9876543210",
                is_approved=1,
                is_active=1,
                reg_no=rajesh_reg,
                dept="CSE",
                year="4",
                section="A"
            )
            db.add(user_rajesh)
            db.flush()

        # Profile
        profile_rajesh = db.query(models.StudentCSE).filter(models.StudentCSE.reg_no == rajesh_reg).first()
        if not profile_rajesh:
            profile_rajesh = models.StudentCSE(
                reg_no=rajesh_reg,
                name="Rajesh Kumar",
                email=rajesh_email,
                dept="CSE",
                year=4,
                semester=8,
                section="A"
            )
            db.add(profile_rajesh)

        # Marks (Low)
        subjects = [
            ("CS8001", "Distributed Systems"),
            ("CS8002", "Mobile Computing"),
            ("CS8003", "Network Security")
        ]
        for scode, stitle in subjects:
            mark = db.query(models.Mark).filter(models.Mark.reg_no == rajesh_reg, models.Mark.subject_code == scode).first()
            if not mark:
                db.add(models.Mark(
                    reg_no=rajesh_reg,
                    student_name="Rajesh Kumar",
                    dept="CSE",
                    year=4,
                    section="A",
                    semester=8,
                    subject_code=scode,
                    subject_title=stitle,
                    cia_1=12, 
                    cia_2=14, 
                    model=35
                ))
        
        # Attendance (Low)
        for i in range(10):
            db.add(models.Attendance(
                reg_no=rajesh_reg,
                student_name="Rajesh Kumar",
                date=datetime.now() - timedelta(days=i),
                period=1,
                subject_code="CS8001",
                status="Present" if i < 6 else "Absent", # 60% attendance
                dept="CSE",
                year=4,
                section="A"
            ))

        # Alert
        db.add(models.AcademicAlert(
            reg_no=rajesh_reg,
            subject="Critical Attendance Warning",
            message="Your attendance in CS8001 is below 75%. Please review your personalized learning plan to catch up on missed units.",
            is_read=0
        ))

        # --- 2. PERSONA: PRIYA (MEDIUM RISK - THE JOURNEY OF IMPROVEMENT) ---
        print("Seeding Priya (Medium Risk)...")
        priya_email = "priya.med@edupulse.com"
        priya_reg = "2024CSE002"
        
        user_priya = db.query(models.User).filter(models.User.email == priya_email).first()
        if not user_priya:
            user_priya = models.User(
                name="Priya Sharma",
                email=priya_email,
                password=auth.get_password_hash("priya123"),
                role=models.RoleEnum.STUDENT,
                phone="9876543211",
                is_approved=1,
                is_active=1,
                reg_no=priya_reg,
                dept="CSE",
                year="4",
                section="A"
            )
            db.add(user_priya)
            db.flush()

        profile_priya = db.query(models.StudentCSE).filter(models.StudentCSE.reg_no == priya_reg).first()
        if not profile_priya:
            profile_priya = models.StudentCSE(
                reg_no=priya_reg,
                name="Priya Sharma",
                email=priya_email,
                dept="CSE",
                year=4,
                semester=8,
                section="A"
            )
            db.add(profile_priya)

        # Marks (Improving)
        for scode, stitle in subjects:
            mark = db.query(models.Mark).filter(models.Mark.reg_no == priya_reg, models.Mark.subject_code == scode).first()
            if not mark:
                db.add(models.Mark(
                    reg_no=priya_reg,
                    student_name="Priya Sharma",
                    dept="CSE",
                    year=4,
                    section="A",
                    semester=8,
                    subject_code=scode,
                    subject_title=stitle,
                    cia_1=16, 
                    cia_2=18,
                    model=65
                ))

        # Attendance (Medium)
        for i in range(10):
            db.add(models.Attendance(
                reg_no=priya_reg,
                student_name="Priya Sharma",
                date=datetime.now() - timedelta(days=i),
                period=1,
                subject_code="CS8001",
                status="Present" if i < 8 else "Absent", # 80% attendance
                dept="CSE",
                year=4,
                section="A"
            ))

        # --- 3. PERSONA: ANKIT (LOW RISK - THE ALL-ROUNDER) ---
        print("Seeding Ankit (Low Risk)...")
        ankit_email = "ankit.low@edupulse.com"
        ankit_reg = "2024CSE003"
        
        user_ankit = db.query(models.User).filter(models.User.email == ankit_email).first()
        if not user_ankit:
            user_ankit = models.User(
                name="Ankit Verma",
                email=ankit_email,
                password=auth.get_password_hash("ankit123"),
                role=models.RoleEnum.STUDENT,
                phone="9876543212",
                is_approved=1,
                is_active=1,
                reg_no=ankit_reg,
                dept="CSE",
                year="4",
                section="A"
            )
            db.add(user_ankit)
            db.flush()

        profile_ankit = db.query(models.StudentCSE).filter(models.StudentCSE.reg_no == ankit_reg).first()
        if not profile_ankit:
            profile_ankit = models.StudentCSE(
                reg_no=ankit_reg,
                name="Ankit Verma",
                email=ankit_email,
                dept="CSE",
                year=4,
                semester=8,
                section="A"
            )
            db.add(profile_ankit)

        # Marks (High)
        for scode, stitle in subjects:
            mark = db.query(models.Mark).filter(models.Mark.reg_no == ankit_reg, models.Mark.subject_code == scode).first()
            if not mark:
                db.add(models.Mark(
                    reg_no=ankit_reg,
                    student_name="Ankit Verma",
                    dept="CSE",
                    year=4,
                    section="A",
                    semester=8,
                    subject_code=scode,
                    subject_title=stitle,
                    cia_1=22, 
                    cia_2=24,
                    model=88
                ))

        # Attendance (High)
        for i in range(10):
            db.add(models.Attendance(
                reg_no=ankit_reg,
                student_name="Ankit Verma",
                date=datetime.now() - timedelta(days=i),
                period=1,
                subject_code="CS8001",
                status="Present" if i < 10 else "Absent", # 100% attendance
                dept="CSE",
                year=4,
                section="A"
            ))

        # Activity
        db.add(models.Activity(
            activity_name="IEEE Tech Expo 2024",
            description="Presentation on AI-driven Education Systems.",
            activity_date=datetime.now(),
            activity_type=models.ActivityTypeEnum.COMPETITION,
            level="National"
        ))
        db.flush()
        
        expo = db.query(models.Activity).filter(models.Activity.activity_name == "IEEE Tech Expo 2024").first()
        if expo:
            db.add(models.ActivityParticipation(
                activity_id=expo.activity_id,
                reg_no=ankit_reg,
                role="Winner",
                achievement="1st Place"
            ))

        # --- 4. FACULTY PERSONA: PROF. SARAN (THE MENTOR) ---
        print("Seeding Prof. Saran (Faculty)...")
        saran_email = "saran@edupulse.com"
        user_saran = db.query(models.User).filter(models.User.email == saran_email).first()
        if not user_saran:
            user_saran = models.User(
                name="Prof. Saran K J",
                email=saran_email,
                password=auth.get_password_hash("faculty123"),
                role=models.RoleEnum.FACULTY,
                is_approved=1,
                is_active=1
            )
            db.add(user_saran)
            db.flush()

        # Allocation
        allocations = [
            ("CSE", 4, "A", "CS8001", "Distributed Systems"),
            ("CSE", 4, "A", "CS8002", "Mobile Computing"),
            ("CSE", 4, "A", "CS8003", "Network Security")
        ]
        for dept, year, sec, scode, stitle in allocations:
            alloc = db.query(models.FacultyAllocation).filter(
                models.FacultyAllocation.faculty_id == user_saran.user_id,
                models.FacultyAllocation.subject_code == scode
            ).first()
            if not alloc:
                db.add(models.FacultyAllocation(
                    faculty_id=user_saran.user_id,
                    faculty_name=user_saran.name,
                    dept=dept,
                    year=year,
                    section=sec,
                    subject_code=scode,
                    subject_title=stitle
                ))

        # --- 5. SCHEDULED QUIZ ---
        quiz = db.query(models.ScheduledQuiz).first()
        if not quiz:
            db.add(models.ScheduledQuiz(
                faculty_id=user_saran.user_id,
                subject_code="CS8001",
                subject_title="Distributed Systems",
                unit_number=1,
                assessment_type="Slip Test",
                target_year=4,
                target_section="A",
                target_dept="CSE",
                deadline=(datetime.now() + timedelta(days=2))
            ))

        # --- 6. PARENT PERSONA: MR. KUMAR (THE CONCERNED PARENT) ---
        print("Seeding Mr. Kumar (Rajesh's Parent)...")
        parent_email = "kumar.parent@edupulse.com"
        user_parent = db.query(models.User).filter(models.User.email == parent_email).first()
        if not user_parent:
            user_parent = models.User(
                name="Mr. Kumar",
                email=parent_email,
                password=auth.get_password_hash("parent123"),
                role=models.RoleEnum.PARENT,
                phone="9123456789", # Main target for SMS alerts
                child_reg_no=rajesh_reg,
                is_approved=1,
                is_active=1
            )
            db.add(user_parent)

        db.commit()
        print("\nSuccessfully seeded High/Med/Low risk personas for the final demo!")
        print("-" * 50)
        print("Logins:")
        print(f"1. High Risk: {rajesh_email} / rajesh123")
        print(f"2. Med Risk:  {priya_email} / priya123")
        print(f"3. Low Risk:  {ankit_email} / ankit123")
        print(f"4. Faculty:   {saran_email} / faculty123")
        print(f"5. Parent:    {parent_email} / parent123 (Linked to Rajesh)")
        print("-" * 50)

    except Exception as e:
        print(f"Error seeding demo narrative: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_demo_narrative()
