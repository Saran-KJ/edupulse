import requests
from config import get_settings
import models
from sqlalchemy.orm import Session

class SMSService:
    def __init__(self):
        settings = get_settings()
        self.api_key = settings.fast2sms_api_key
        self.url = "https://www.fast2sms.com/dev/bulkV2"
        self.driver = settings.notification_driver or "fast2sms"
        self.student_map = {
            'CSE': models.StudentCSE, 'ECE': models.StudentECE, 'EEE': models.StudentEEE,
            'MECH': models.StudentMECH, 'CIVIL': models.StudentCIVIL, 'BIO': models.StudentBIO, 'AIDS': models.StudentAIDS,
        }

    def get_parent_phone(self, db: Session, reg_no: str, dept: str = None) -> tuple[str, str]:
        """
        Fetches parent phone number and student name.
        1. Checks for a parent User account linked via child_reg_no.
        2. Falls back to department student tables.
        """
        # 1. Check parent User
        parent_user = db.query(models.User).filter(
            models.User.role == models.RoleEnum.PARENT,
            models.User.child_reg_no == reg_no,
            models.User.phone != None
        ).first()

        if parent_user:
            return parent_user.phone, parent_user.child_name or "Student"

        # 2. Check Student tables
        if not dept:
            # If dept not provided, we have to search or assume from reg_no prefix? 
            # Better to find student first.
            return None, "Student"

        student_model = self.student_map.get(dept)
        if student_model:
            student = db.query(student_model).filter(student_model.reg_no == reg_no).first()
            if student:
                phone = student.father_phone or student.mother_phone or student.guardian_phone
                return phone, student.name

        return None, "Student"

    def send_bilingual_sms(self, phone_number: str, english_text: str, tamil_text: str):
        """
        Sends a bilingual (English + Tamil) SMS via the selected driver.
        Ensures India country code (+91) if not present.
        """
        if not phone_number:
            print("WARNING: No phone number provided. Skipping SMS.")
            return False

        # Clean phone number (removing spaces, dashes, etc.)
        num_str = str(phone_number).strip().replace(" ", "").replace("-", "")
        clean_number = "".join(c for c in num_str if c.isdigit() or c == "+")
        
        # If it's 10 digits, prepend +91
        if len(clean_number) == 10:
            clean_number = f"+91{clean_number}"
        elif len(clean_number) == 12 and clean_number.startswith("91"):
            clean_number = f"+{clean_number}"
        
        full_message = f"{english_text}\n\n{tamil_text}"

        # 1. SMSMobileAPI Driver
        if self.driver == "smsmobileapi":
            from sms_mobile_driver import sms_mobile_driver
            return sms_mobile_driver.send_sms(clean_number, full_message)

        # 2. Email Driver (Optional addition later)
        # elif self.driver == "email":
        #     # Use email_service here...
        #     pass

        # 3. Default: Fast2SMS
        if not self.api_key:
            print("WARNING: Fast2SMS API Key not configured. Skipping SMS.")
            return False

        if not phone_number:
            print("WARNING: No phone number provided. Skipping SMS.")
            return False

        headers = {
            'authorization': self.api_key,
            'Content-Type': "application/json"
        }

        payload = {
            "route": "q", # Quick route
            "message": full_message,
            "language": "english", # Fast2SMS handles unicode within english route usually, 
                                   # but we will use 'v3' or ensure it works. 
                                   # Actually 'q' is most reliable for custom messages.
            "flash": 0,
            "numbers": phone_number
        }

        try:
            response = requests.post(self.url, json=payload, headers=headers)
            res_data = response.json()
            if res_data.get("return"):
                print(f"[SMS SUCCESS] Notification sent to {phone_number} via Fast2SMS")
                return True
            else:
                print(f"[SMS ERROR] Fast2SMS Error: {res_data.get('message')}")
                return False
        except Exception as e:
            print(f"[SMS ERROR] Failed to send SMS to {phone_number}: {e}")
            return False

    def notify_mark_update(self, phone_number: str, student_name: str, subject: str, marks_dict: dict):
        """
        Alerts parent when marks are updated.
        Strictly includes ONLY non-zero, non-null numerical marks.
        """
        active_marks = []
        for key, label in [
            ('st1', 'ST1'), ('st2', 'ST2'), ('st3', 'ST3'), ('st4', 'ST4'),
            ('a1', 'A1'), ('a2', 'A2'), ('a3', 'A3'), ('a4', 'A4'), ('a5', 'A5'),
            ('cia_1', 'CIA1'), ('cia_2', 'CIA2'), ('model', 'Model')
        ]:
            val = marks_dict.get(key)
            try:
                # Only include if it's a positive number (ignoring 0/None/empty)
                if val is not None and float(val) > 0:
                    active_marks.append(f"{label}:{val}")
            except (ValueError, TypeError):
                continue
        
        if not active_marks:
            # If nothing is entered yet, don't send a confusing SMS
            return True
            
        marks_str = ", ".join(active_marks)
        en = f"EduPulse: {student_name}'s {subject} marks updated. {marks_str}."
        ta = f"மதிப்பெண்: {student_name}-ன் {subject} மதிப்பெண்கள்: {marks_str}."
        
        return self.send_bilingual_sms(phone_number, en, ta)

    def notify_quiz_score(self, phone_number: str, student_name: str, subject: str, unit: int, score: float):
        """
        Alerts parent of early risk quiz score.
        """
        en = f"EduPulse: {student_name} scored {score}% in {subject} Unit {unit} early risk quiz. Guidance recommended."
        ta = f"எடியுபல்ஸ்: {student_name} {subject} பாடம் யூனிட் {unit} ஆரம்பகட்ட வினாடி வினாவில் {score}% மதிபெண் பெற்றுள்ளார்."

        return self.send_bilingual_sms(phone_number, en, ta)

    def notify_low_attendance(self, phone_number: str, student_name: str, percentage: float):
        """
        Alerts parent when student's attendance falls below 75%.
        """
        en = f"EduPulse: {student_name}'s attendance is {percentage:.1f}%, which is below the threshold (75%). Please ensure consistency."
        ta = f"எடியுபல்ஸ் தகவல்: {student_name}-ன் வருகைப்பதிவு {percentage:.1f}% ஆக உள்ளது (75% க்கும் குறைவு). மாணவர் தொடர்ந்து கல்லூரிக்கு வருவதை உறுதி செய்யவும்."

        return self.send_bilingual_sms(phone_number, en, ta)

    def notify_risk_alert(self, phone_number: str, student_name: str, risk_level: str, score: float):
        """
        Alerts parent when student is flagged as Medium or High Risk.
        """
        en = f"EduPulse: {student_name} is flagged as {risk_level} Risk. Performance score: {score:.1f}%. Check app for recovery plan."
        ta = f"எடியுபல்ஸ்: {student_name} {risk_level} அபாய நிலையில் (Risk) உள்ளார். செயல்திறன் மதிப்பெண்: {score:.1f}%. மீண்டெழும் திட்டத்தை செயலியில் பார்க்கவும்."

        return self.send_bilingual_sms(phone_number, en, ta)

sms_service = SMSService()
