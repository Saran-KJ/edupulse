import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sms_service import sms_service
from database import SessionLocal

def test_real_sms():
    print("--- [EDUPULSE REAL SMS CONNECTIVITY TEST] ---")
    
    # We will use the parent's phone number seeded for Rajesh
    phone = "9123456789" # In real use, this should be a valid number if you want to see the result
    
    en = "EduPulse: This is a real connectivity test for bilingual SMS alerts."
    ta = "எடியுபல்ஸ்: இது இருமொழி எஸ்எம்எஸ் விழிப்பூட்டல்களுக்கான உண்மையான இணைப்பு சோதனையாகும்."
    
    print(f"DEBUG: Attempting to send SMS to {phone}...")
    success = sms_service.send_bilingual_sms(phone, en, ta)
    
    if success:
        print("\n[OK] SMS logic triggered successfully. Check Fast2SMS dashboard/phone.")
    else:
        print("\n[FAIL] SMS logic failed. Check Fast2SMS error logs in terminal.")
    
    print("\n--- [TEST COMPLETE] ---")

if __name__ == "__main__":
    test_real_sms()
