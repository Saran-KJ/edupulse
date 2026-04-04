import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sms_service import sms_service
from database import SessionLocal
import models

def test_sms_logic():
    print("--- [EDUPULSE SMS BILINGUAL TEST] ---")
    from config import get_settings
    print(f"LOADING DB: {get_settings().database_url}")
    db = SessionLocal()
    
    # Test Student Details
    reg_no = "21CS001" # Assuming this exists in one of the tables
    dept = "CSE"
    
    # 1. Test Parent Lookup Logic
    print(f"Step 1: Testing Parent Lookup for {reg_no}...")
    phone, name = sms_service.get_parent_phone(db, reg_no, dept)
    print(f"Result: Phone={phone}, Name={name}")
    
    # 2. Test Message Formatting
    print("\nStep 2: Testing Message Formatting (Mark Update)...")
    marks = {"cia_1": 85, "cia_2": 90, "model": 88}
    subject = "Distributed Systems"
    
    # Since we don't want to consume real credits in a generic test,
    # let's just print what the bilingual message WOULD look like.
    en = f"EduPulse: {name}'s marks updated for {subject}. CIA1: {marks['cia_1']}, CIA2: {marks['cia_2']}, Model: {marks['model']}. Check app for details."
    ta = f"எடியுபல்ஸ் தகவல்: {name}-ன் {subject} மதிப்பெண்கள் புதுப்பிக்கப்பட்டுள்ளன. CIA1: {marks['cia_1']}, CIA2: {marks['cia_2']}, Model: {marks['model']}. கூடுதல் விவரங்களுக்கு செயலியைப் பார்க்கவும்."
    
    print(f"\n[BILINGUAL PREVIEW - ENGLISH]\n{en}")
    print(f"\n[BILINGUAL PREVIEW - TAMIL]\n{ta}")
    
    # 3. Quiz Score Preview
    print("\nStep 3: Testing Message Formatting (Quiz Score)...")
    score = 92.5
    en_q = f"EduPulse: {name} scored {score}% in {subject} Unit 1 early risk quiz. Guidance recommended."
    ta_q = f"எடியுபல்ஸ்: {name} {subject} பாடம் யூனிட் 1 ஆரம்பகட்ட வினாடி வினாவில் {score}% மதிப்பெண் பெற்றுள்ளார்."
    
    print(f"\n[BILINGUAL PREVIEW - ENGLISH]\n{en_q}")
    print(f"\n[BILINGUAL PREVIEW - TAMIL]\n{ta_q}")
    
    db.close()
    print("\n--- [TEST COMPLETE] ---")

if __name__ == "__main__":
    test_sms_logic()
