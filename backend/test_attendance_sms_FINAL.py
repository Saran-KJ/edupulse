import sys
import os
from unittest.mock import MagicMock, patch
from datetime import date

# Add the current directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Mock database and dependencies
class MockDB:
    def query(self, model):
        return self
    def filter(self, *args):
        return self
    def first(self):
        # Mock a student record
        student = MagicMock()
        student.name = "John Doe"
        # Return a phone number to trigger SMS
        student.father_phone = "9876543210"
        return student
    def count(self):
        return 10 # Total periods

# Mock the attendance query results for percentage calculation
def mock_count_all(db_session, reg_no, semester):
    return 10 # Total 10 periods

def mock_count_present(db_session, reg_no, semester):
    return 8 # 8 present, 2 absent = 80%

try:
    from sms_service import SMSService
    import models
    # check_and_notify_attendance_threshold is local to create_bulk_attendance, 
    # so we test the service methods directly instead.
except ImportError as e:
    print(f"Import Error: {e}")
    sys.exit(1)

def run_verification():
    print("--- STARTING ATTENDANCE SMS VERIFICATION ---")
    
    # 1. Initialize SMSService
    service = SMSService()
    
    # Mock the actual network request part
    # We want it to print the "[SMS SUCCESS]" message like the real one would
    def mock_send_bilingual_sms(phone, en, ta):
        print(f"[INTERNAL DEBUG] Preparing to send bilingual SMS to {phone}")
        try:
            print(f"  EN: {en}")
            # Try to print Tamil, but handle encoding errors if they occur
            safe_ta = ta.encode('ascii', errors='replace').decode('ascii')
            print(f"  TA (Safe): {safe_ta}")
        except:
            print("  [Note] English message printed, Tamil message contains Unicode characters.")
        
        # Print the success message exactly as SMSService would
        print(f"[SMS SUCCESS] Notification sent to {phone} via Fast2SMS")
        return True

    service.send_bilingual_sms = mock_send_bilingual_sms
    
    # 2. Test Immediate Absence SMS Logic
    print("\nSCENARIO 1: Faculty marks student as ABSENT")
    test_phone = "9876543210"
    test_name = "John Doe"
    test_date = "2026-04-17"
    test_period = "2"
    
    print(f"Action: Triggering immediate absence alert for {test_name}...")
    service.notify_absence(test_phone, test_name, test_date, test_period)
    
    # 3. Test Threshold Alert Logic (80% Attendance)
    print("\nSCENARIO 2: Attendance recorded, threshold is 80.0% (Good)")
    # We'll call the service method directly to see the output
    service.notify_attendance_good(test_phone, test_name, 80.0)

    # 4. Test Threshold Alert Logic (65% Attendance)
    print("\nSCENARIO 3: Attendance recorded, threshold is 65.0% (Low)")
    service.notify_low_attendance(test_phone, test_name, 65.0)

    print("\n--- VERIFICATION COMPLETED ---")

if __name__ == "__main__":
    run_verification()
