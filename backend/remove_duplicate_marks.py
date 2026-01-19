from database import SessionLocal
from models import Mark
from sqlalchemy import func

def remove_duplicates():
    db = SessionLocal()
    try:
        # Find duplicates
        # We want to group by reg_no, subject_code, semester and find count > 1
        duplicates = db.query(
            Mark.reg_no, Mark.subject_code, Mark.semester, func.count(Mark.id)
        ).group_by(
            Mark.reg_no, Mark.subject_code, Mark.semester
        ).having(func.count(Mark.id) > 1).all()
        
        if not duplicates:
            print("No duplicates found.")
            return

        print(f"Found {len(duplicates)} sets of duplicates.")
        
        total_deleted = 0
        for dup in duplicates:
            reg_no, subject_code, semester, count = dup
            print(f"Processing duplicate: {reg_no} - {subject_code} (Sem {semester}) - Count: {count}")
            
            # Get all records for this combination
            records = db.query(Mark).filter(
                Mark.reg_no == reg_no,
                Mark.subject_code == subject_code,
                Mark.semester == semester
            ).order_by(Mark.id.desc()).all()
            
            # Keep the first one (highest ID, presumably latest), delete others
            to_keep = records[0]
            to_delete = records[1:]
            
            print(f"  Keeping ID: {to_keep.id}")
            for record in to_delete:
                print(f"  Deleting ID: {record.id}")
                db.delete(record)
                total_deleted += 1
                
        db.commit()
        print(f"Successfully deleted {total_deleted} duplicate records.")
        
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    remove_duplicates()
