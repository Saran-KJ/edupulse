import sys
import os

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from config import get_settings
    from sms_service import SMSService
    
    settings = get_settings()
    service = SMSService()
    
    print(f"NOTIFICATION_DRIVER: {settings.notification_driver}")
    print(f"Service Driver: {service.driver}")
    print(f"Fast2SMS API Key: {service.api_key[:10]}..." if service.api_key else "Fast2SMS API Key: NOT SET")
    
    if service.driver == "fast2sms" and service.api_key:
        print("\nSUCCESS: SMSService is configured to use Fast2SMS correctly!")
    elif service.driver == "smsmobileapi" and settings.sms_mobile_api_key:
        print(f"\nSUCCESS: SMSService is configured to use SMSMobileAPI correctly!")
        print(f"Mobile API Key: {settings.sms_mobile_api_key[:10]}...")
    else:
        print("\nFAILURE: Check configuration (Driver or API Key mismatch).")

except Exception as e:
    print(f"Error during verification: {e}")
