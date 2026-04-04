import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sms_service import sms_service
from config import get_settings

def test_sms_mobile_integration():
    print("--- [SMSMOBILEAPI.COM INTEGRATION TEST] ---")
    settings = get_settings()
    
    # 1. Check Configuration
    print(f"Driver Path: {settings.notification_driver}")
    print(f"API Key Present: {'Yes' if settings.sms_mobile_api_key else 'No'}")
    
    if settings.notification_driver != "smsmobileapi":
        print("\n[WARNING] config.py is NOT set to 'smsmobileapi'.")
        print("Please update .env to: NOTIFICATION_DRIVER=smsmobileapi")
        return

    if not settings.sms_mobile_api_key:
        print("\n[ERROR] SMS_MOBILE_API_KEY is missing in .env.")
        print("Please add your key from the SMSMobileAPI App.")
        return

    # 2. Test Trigger
    phone = "9123456789" # Use a real number here to see the result
    student = "Rajesh"
    subject = "AI Ethics"
    score = 88.5
    
    print(f"\nAttempting to trigger Bilingual Alert to {phone}...")
    
    # This will now use the SMSMobileAPI driver automatically
    success = sms_service.notify_quiz_score(phone, student, subject, 1, score)
    
    if success:
        print("\n[SUCCESS] The request was sent to the SMSMobileAPI Cloud.")
        print("Check your phone app to see it being sent via your SIM.")
    else:
        print("\n[FAILURE] The request failed. check the console logs for exceptions.")

    print("\n--- [TEST COMPLETE] ---")

if __name__ == "__main__":
    test_sms_mobile_integration()
