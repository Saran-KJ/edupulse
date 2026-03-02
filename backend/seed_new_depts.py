"""
Seeding script for new departments: EEE, Bio.Tech, Civil, AIDS
"""
from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
from auth import get_password_hash
from datetime import date

def get_student_model(dept: str):
    if dept == 'EEE': return models.StudentEEE
    if dept == 'Bio.Tech': return models.StudentBIO
    if dept == 'Civil': return models.StudentCIVIL
    if dept == 'AIDS': return models.StudentAIDS
    return None

def seed_new_departments():
    db = SessionLocal()
    try:
        print("Seeding new departments...")
        
        # 1. Define new departments
        new_depts_data = [
            {"code": "EEE", "name": "Electrical and Electronics Engineering"},
            {"code": "Bio.Tech", "name": "Biotechnology"},
            {"code": "Civil", "name": "Civil Engineering"},
            {"code": "AIDS", "name": "Artificial Intelligence and Data Science"},
        ]
        
        for d in new_depts_data:
            existing = db.query(models.Department).filter(models.Department.dept_code == d["code"]).first()
            if not existing:
                new_dept = models.Department(dept_code=d["code"], dept_name=d["name"])
                db.add(new_dept)
                db.commit()
                db.refresh(new_dept)
                print(f"Created department: {d['code']}")
            else:
                print(f"Department already exists: {d['code']}")
                
        # 2. Create Class Advisors for these departments
        advisors_data = [
            {"name": "Prof. EEE Advisor", "email": "advisor.eee@edupulse.com", "dept": "EEE"},
            {"name": "Prof. BioTech Advisor", "email": "advisor.biotech@edupulse.com", "dept": "Bio.Tech"},
            {"name": "Prof. Civil Advisor", "email": "advisor.civil@edupulse.com", "dept": "Civil"},
            {"name": "Prof. AIDS Advisor", "email": "advisor.aids@edupulse.com", "dept": "AIDS"},
        ]
        
        for a in advisors_data:
            existing = db.query(models.User).filter(models.User.email == a["email"]).first()
            if not existing:
                advisor = models.User(
                    name=a["name"],
                    email=a["email"],
                    password=get_password_hash("advisor123"),
                    role=models.RoleEnum.CLASS_ADVISOR,
                    is_approved=1,
                    is_active=1,
                    dept=a["dept"],
                    year="2",
                    section="A"
                )
                db.add(advisor)
                print(f"Created advisor: {a['email']}")
            else:
                print(f"Advisor already exists: {a['email']}")
        db.commit()

        # 3. Create Sample Students for these departments
        # We'll create 2 students for each new department
        
        students_data = [
            # EEE
            {"reg": "2021EEE001", "name": "EEE Student 1", "dept": "EEE"},
            {"reg": "2021EEE002", "name": "EEE Student 2", "dept": "EEE"},
            # Bio.Tech
            {"reg": "2021BIO001", "name": "BioTech Student 1", "dept": "Bio.Tech"},
            {"reg": "2021BIO002", "name": "BioTech Student 2", "dept": "Bio.Tech"},
            # Civil
            {"reg": "2021CIV001", "name": "Civil Student 1", "dept": "Civil"},
            {"reg": "2021CIV002", "name": "Civil Student 2", "dept": "Civil"},
            # AIDS
            {"reg": "2021AIDS001", "name": "AIDS Student 1", "dept": "AIDS"},
            {"reg": "2021AIDS002", "name": "AIDS Student 2", "dept": "AIDS"},
        ]
        
        for s in students_data:
            model = get_student_model(s["dept"])
            if not model:
                print(f"Unknown department model for {s['dept']}")
                continue

            existing = db.query(model).filter(model.reg_no == s["reg"]).first()
            if not existing:
                student = model(
                    reg_no=s["reg"],
                    name=s["name"],
                    email=f"{s['reg'].lower()}@student.edu",
                    dept=s["dept"], # Changed from dept_id
                    year=2,
                    semester=4,
                    section="A",
                    dob=date(2003, 1, 1),
                    address="Hostel"
                )
                db.add(student)
                print(f"Created student: {s['name']}")
            else:
                print(f"Student already exists: {s['reg']}")
                
        db.commit()
        print("Seeding completed successfully!")

    except Exception as e:
        print(f"Error seeding data: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_new_departments()
