from smsmobileapi import SMSSender
from config import get_settings

class SMSMobileDriver:
    """
    Driver for smsmobileapi.com - turns an Android phone into a wireless SMS gateway.
    """
    def __init__(self):
        settings = get_settings()
        self.api_key = settings.sms_mobile_api_key
        self.client = None
        if self.api_key:
            try:
                self.client = SMSSender(api_key=self.api_key)
            except Exception as e:
                print(f"ERROR: SMSMobileAPI initialization failed: {e}")

    def send_sms(self, phone_number: str, message: str):
        """
        Sends an SMS via the SMSMobileAPI wireless gateway.
        """
        if not self.client:
            print("WARNING: SMSMobileAPI Client not initialized. Check your API key.")
            return False

        if not phone_number:
            print("WARNING: No phone number provided.")
            return False

        try:
            # The library typically uses 'to' and 'message'
            # We assume it supports Unicode for Tamil characters
            print(f"DEBUG: Calling SMSMobileAPI for {phone_number}...")
            response = self.client.send_message(to=phone_number, message=message)
            
            # Check response - depends on the library's return format
            # Usually it returns a dict or success object
            if response:
                print(f"[SMSMobileAPI SUCCESS] Message sent to {phone_number}")
                return True
            else:
                print(f"[SMSMobileAPI ERROR] Failed to send message to {phone_number}")
                return False
        except Exception as e:
            print(f"[SMSMobileAPI EXCEPTION] {e}")
            return False

# Export instance
sms_mobile_driver = SMSMobileDriver()
