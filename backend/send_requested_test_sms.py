import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sms_service import sms_service
from database import SessionLocal

def send_test_sms():
    print("--- [EDUPULSE TEST SMS TO SPECIFIC NUMBER] ---")
    
    phone = "+91 9566384882" # Using the exact string from the user
    
    en = "EduPulse: This is a test alert for your final year project. Connectivity with SMSMobileAPI confirmed."
    ta = "எடியுபல்ஸ்: இது உங்கள் இறுதி ஆண்டு திட்டத்திற்கான சோதனை எச்சரிக்கை. SMSMobileAPI உடனான இணைப்பு உறுதிப்படுத்தப்பட்டது."
    
    print(f"DEBUG: Attempting to send SMS to {phone}...")
    success = sms_service.send_bilingual_sms(phone, en, ta)
    
    if success:
        print("\n[OK] SMS notification sent successfully!")
    else:
        print("\n[FAIL] SMS notification failed. Check terminal for error details.")
    
    print("\n--- [TEST COMPLETE] ---")

if __name__ == "__main__":
    send_test_sms()
