"""
Script to add existing approved students to their department tables
Run this to fix students who were approved before the auto-creation fix
"""

from database import get_db
from models import User, StudentCSE, StudentECE, StudentEEE, StudentMECH, StudentCIVIL, StudentBIO, StudentAIDS, RoleEnum

def add_existing_students():
    db = next(get_db())
    
    # Department model mapping
    dept_model_map = {
        "CSE": StudentCSE,
        "ECE": StudentECE,
        "EEE": StudentEEE,
        "MECH": StudentMECH,
        "CIVIL": StudentCIVIL,
        "BIO": StudentBIO,
        "AIDS": StudentAIDS
    }
    
    # Find all approved students
    approved_students = db.query(User).filter(
        User.role == RoleEnum.STUDENT,
        User.is_approved == 1,
        User.reg_no.isnot(None),
        User.dept.isnot(None)
    ).all()
    
    print(f"Found {len(approved_students)} approved student users")
    
    added_count = 0
    already_exists_count = 0
    
    for user in approved_students:
        student_model = dept_model_map.get(user.dept)
        if not student_model:
            print(f"⚠️  Unknown department '{user.dept}' for {user.name}")
            continue
        
        # Check if student record already exists
        existing = db.query(student_model).filter(
            student_model.reg_no == user.reg_no
        ).first()
        
        if existing:
            print(f"✓ Student record already exists: {user.name} ({user.reg_no})")
            already_exists_count += 1
        else:
            # Create student record
            new_student = student_model(
                reg_no=user.reg_no,
                name=user.name,
                email=user.email,
                phone=user.phone,
                dept=user.dept,
                year=int(user.year) if user.year else 1,
                semester=int(user.year) * 2 if user.year else 1,
                section=user.section if user.section else "A"
            )
            db.add(new_student)
            print(f"✓ Added student record: {user.name} ({user.reg_no}) - {user.dept} Year {user.year}")
            added_count += 1
    
    db.commit()
    print(f"\n✅ Summary:")
    print(f"   - Added: {added_count} student records")
    print(f"   - Already existed: {already_exists_count} student records")
    print(f"   - Total processed: {len(approved_students)} students")

if __name__ == "__main__":
    add_existing_students()
