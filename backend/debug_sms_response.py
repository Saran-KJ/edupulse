import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sms_mobile_driver import SMSMobileDriver
from config import get_settings

def debug_sms():
    settings = get_settings()
    num = "+91 9566384882"
    msg = "EduPulse Debug: Testing response format."
    
    print(f"--- [SMSMobileAPI DEBUG] ---")
    print(f"Driver API Key: {settings.sms_mobile_api_key[:10]}...")
    
    driver = SMSMobileDriver()
    if not driver.client:
        print("ERROR: Client failed to initialize.")
        return

    print(f"Calling send_message to {num}...")
    try:
        # Clean number like the service does now
        num_clean = "".join(c for c in num if c.isdigit() or c == "+")
        if len(num_clean) == 10: num_clean = f"+91{num_clean}"
        
        response = driver.client.send_message(to=num_clean, message=msg)
        print("\n--- RAW API RESPONSE ---")
        print(f"Type: {type(response)}")
        print(f"Content: {response}")
        print("------------------------")
        
        if response:
            print("\nResult: Logic treated this as SUCCESS.")
        else:
            print("\nResult: Logic treated this as FAILURE.")
            
    except Exception as e:
        print(f"EXCEPTION: {e}")

if __name__ == "__main__":
    debug_sms()
