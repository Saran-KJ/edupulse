from database import SessionLocal
from models import User, FacultyAllocation

def remove_allocation():
    db = SessionLocal()
    try:
        # 1. Find user Keerthi
        keerthi = db.query(User).filter(User.name.ilike('%keerthi%')).first()
        if not keerthi:
            print("Keerthi user not found.")
            return

        print(f"Found user: {keerthi.name} (ID: {keerthi.user_id})")

        # 2. Find the problematic allocation
        # Subject: OMG353, Year: 1, Section: A
        allocation = db.query(FacultyAllocation).filter(
            FacultyAllocation.faculty_id == keerthi.user_id,
            FacultyAllocation.subject_code == 'OMG353',
            FacultyAllocation.year == 1,
            FacultyAllocation.section == 'A'
        ).first()

        if not allocation:
            print("Problematic allocation (OMG353, Year 1, Section A) for Keerthi not found.")
            # Let's list all her allocations just in case the data is slightly different
            all_allocations = db.query(FacultyAllocation).filter(
                FacultyAllocation.faculty_id == keerthi.user_id
            ).all()
            print("Keerthi's current allocations:")
            for a in all_allocations:
                print(f"ID: {a.id}, Sub: {a.subject_code}, Year: {a.year}, Section: {a.section}")
            return

        # 3. Delete the allocation
        print(f"Deleting allocation ID: {allocation.id} ({allocation.subject_code}, {allocation.year}{allocation.section})")
        db.delete(allocation)
        db.commit()
        print("Successfully removed the allocation.")

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    remove_allocation()
