from database import SessionLocal
import models
from sms_service import sms_service

def debug_parent_lookup(reg_no):
    db = SessionLocal()
    try:
        print(f"DEBUG: Looking for parent of {reg_no}...")
        
        # Manually replicate logic from sms_service
        parent_user = db.query(models.User).filter(
            models.User.role == models.RoleEnum.PARENT,
            models.User.child_reg_no == reg_no
        ).first()
        
        if parent_user:
            print(f"SUCCESS: Found parent User: {parent_user.name}")
            print(f"Parent Email: {parent_user.email}")
            print(f"Parent Phone: {parent_user.phone}")
            print(f"Parent Child Reg No: {parent_user.child_reg_no}")
        else:
            print(f"FAILED: No parent User found for child_reg_no={reg_no}")
            
        phone, name = sms_service.get_parent_phone(db, reg_no, "CSE")
        print(f"sms_service.get_parent_phone returned: phone={phone}, name={name}")
        
    finally:
        db.close()

if __name__ == "__main__":
    debug_parent_lookup("2024CSE001")
