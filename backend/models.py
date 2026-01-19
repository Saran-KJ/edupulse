from sqlalchemy import Column, Integer, String, Float, Date, ForeignKey, DateTime, Enum, Text
from sqlalchemy.orm import relationship, declarative_base
from datetime import datetime
import enum
from database import Base

class RoleEnum(str, enum.Enum):
    ADMIN = "admin"
    STUDENT = "student"
    CLASS_ADVISOR = "class_advisor"
    FACULTY = "faculty"
    HOD = "hod"
    VICE_PRINCIPAL = "vice_principal"
    PRINCIPAL = "principal"
    PARENT = "parent"

class RiskLevelEnum(str, enum.Enum):
    LOW = "Low"
    MEDIUM = "Medium"
    HIGH = "High"

class ActivityTypeEnum(str, enum.Enum):
    SPORTS = "Sports"
    HACKATHON = "Hackathon"
    WORKSHOP = "Workshop"
    SYMPOSIUM = "Symposium"
    SEMINAR = "Seminar"
    COMPETITION = "Competition"
    OTHER = "Other"

class User(Base):
    __tablename__ = "users"
    
    user_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    password = Column(String(255), nullable=False)
    role = Column(Enum(RoleEnum), nullable=False)
    is_approved = Column(Integer, default=0)  # 0 = pending, 1 = approved
    is_active = Column(Integer, default=1)    # 0 = disabled, 1 = active
    secret_pin = Column(String(10), nullable=True)
    reg_no = Column(String(50), nullable=True)
    phone = Column(String(20), nullable=True)
    dept = Column(String(50), nullable=True)
    year = Column(String(10), nullable=True)
    section = Column(String(10), nullable=True)
    # Parent-specific fields
    child_name = Column(String(100), nullable=True)
    child_phone = Column(String(20), nullable=True)
    occupation = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Department(Base):
    __tablename__ = "departments"
    
    dept_id = Column(Integer, primary_key=True, index=True)
    dept_code = Column(String(20), unique=True, nullable=False)
    dept_name = Column(String(100), nullable=False)
    
    subjects = relationship("Subject", back_populates="department")

# Abstract Base Class for Students
class StudentBase(Base):
    __abstract__ = True
    
    student_id = Column(Integer, primary_key=True, index=True)
    reg_no = Column(String(50), unique=True, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True)
    phone = Column(String(20))
    dept = Column(String(10), nullable=False) # Stored as string now
    year = Column(Integer, nullable=False)
    semester = Column(Integer, nullable=False)
    section = Column(String(10), nullable=True)
    dob = Column(Date)
    address = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

# Department-specific Student Tables
class StudentCSE(StudentBase):
    __tablename__ = "students_cse"

class StudentECE(StudentBase):
    __tablename__ = "students_ece"

class StudentEEE(StudentBase):
    __tablename__ = "students_eee"

class StudentMECH(StudentBase):
    __tablename__ = "students_mech"

class StudentCIVIL(StudentBase):
    __tablename__ = "students_civil"

class StudentBIO(StudentBase):
    __tablename__ = "students_bio"

class StudentAIDS(StudentBase):
    __tablename__ = "students_aids"

class Subject(Base):
    __tablename__ = "subjects"
    
    subject_id = Column(Integer, primary_key=True, index=True)
    subject_code = Column(String(20), unique=True, nullable=False)
    subject_name = Column(String(100), nullable=False)
    dept_id = Column(Integer, ForeignKey("departments.dept_id"))
    semester = Column(Integer, nullable=False)
    credits = Column(Integer, default=3)
    
    department = relationship("Department", back_populates="subjects")

class Mark(Base):
    __tablename__ = "marks"
    
    # Primary identification
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    reg_no = Column(String(50), nullable=False, index=True)
    student_name = Column(String(100), nullable=False)
    dept = Column(String(10), nullable=False) # Added dept
    year = Column(Integer, nullable=False)
    section = Column(String(10), nullable=False)
    semester = Column(Integer, nullable=False)
    
    # Subject details
    subject_code = Column(String(20), nullable=False)
    subject_title = Column(String(100), nullable=False)
    
    # Assignments (out of 10 each)
    assignment_1 = Column(Float, default=0.0)
    assignment_2 = Column(Float, default=0.0)
    assignment_3 = Column(Float, default=0.0)
    assignment_4 = Column(Float, default=0.0)
    assignment_5 = Column(Float, default=0.0)
    
    # Slip Tests (out of 10 each)
    slip_test_1 = Column(Float, default=0.0)
    slip_test_2 = Column(Float, default=0.0)
    slip_test_3 = Column(Float, default=0.0)
    slip_test_4 = Column(Float, default=0.0)
    
    # CIA (Continuous Internal Assessment)
    cia_1 = Column(Float, default=0.0)
    cia_2 = Column(Float, default=0.0)
    
    # Model exam
    model = Column(Float, default=0.0)
    
    # University result
    university_result_grade = Column(String(5), nullable=True)
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Attendance(Base):
    __tablename__ = "attendance"
    
    id = Column(Integer, primary_key=True, index=True)
    reg_no = Column(String(20), nullable=False)
    student_name = Column(String(100), nullable=False)
    date = Column(Date, nullable=False)
    status = Column(String(10), nullable=False) # 'Present', 'Absent'
    
    # Class details for easier querying
    dept = Column(String(10), nullable=False) # Changed from dept_id to dept (CSE, ECE, etc.)
    year = Column(Integer, nullable=False)
    section = Column(String(5), nullable=False)
    reason = Column(String(200), nullable=True) # Added reason for OD/Leave
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Activity(Base):
    __tablename__ = "activities"
    
    activity_id = Column(Integer, primary_key=True, index=True)
    activity_name = Column(String(200), nullable=False)
    activity_type = Column(Enum(ActivityTypeEnum), nullable=False)
    level = Column(String(50))  # College, State, National, International
    activity_date = Column(Date, nullable=False)
    description = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    participations = relationship("ActivityParticipation", back_populates="activity")

class ActivityParticipation(Base):
    __tablename__ = "activity_participation"
    
    participation_id = Column(Integer, primary_key=True, index=True)
    activity_id = Column(Integer, ForeignKey("activities.activity_id"))
    reg_no = Column(String(50), nullable=False) # Changed from student_id
    role = Column(String(100))  # Participant, Winner, Organizer, etc.
    achievement = Column(String(200))  # 1st Place, 2nd Place, etc.
    created_at = Column(DateTime, default=datetime.utcnow)
    
    activity = relationship("Activity", back_populates="participations")
    # Removed direct student relationship

class RiskPrediction(Base):
    __tablename__ = "risk_predictions"
    
    prediction_id = Column(Integer, primary_key=True, index=True)
    reg_no = Column(String(50), nullable=False) # Changed from student_id
    risk_level = Column(Enum(RiskLevelEnum), nullable=False)
    risk_score = Column(Float, nullable=False)
    attendance_percentage = Column(Float)
    internal_avg = Column(Float)
    external_gpa = Column(Float)
    activity_count = Column(Integer)
    backlog_count = Column(Integer)
    reasons = Column(Text)
    prediction_date = Column(DateTime, default=datetime.utcnow)
    
    # Removed direct student relationship

class LoginLog(Base):
    __tablename__ = "login_logs"
    
    log_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    email = Column(String(100), nullable=False)
    success = Column(Integer, nullable=False)  # 0 = failed, 1 = success
    ip_address = Column(String(50), nullable=True)
    user_agent = Column(String(255), nullable=True)
    failure_reason = Column(String(255), nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)

class Timetable(Base):
    __tablename__ = "timetables"

    timetable_id = Column(Integer, primary_key=True, index=True)
    dept = Column(String(10), nullable=False)
    year = Column(Integer, nullable=False)
    section = Column(String(5), nullable=False)
    day = Column(String(10), nullable=False) # Monday, Tuesday, etc.
    period = Column(Integer, nullable=False) # 1, 2, 3, 4, 5, 6
    subject_code = Column(String(20), nullable=False)
    subject_title = Column(String(100), nullable=False)
    duration = Column(Integer, default=1) # Duration in hours/periods
    

    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class TimetableStatus(Base):
    """
    Tracks whether the timetable for a specific class has been published.
    """
    __tablename__ = "timetable_status"
    
    status_id = Column(Integer, primary_key=True, index=True)
    dept = Column(String(10), nullable=False)
    year = Column(Integer, nullable=False)
    section = Column(String(5), nullable=False)
    is_published = Column(Integer, default=0) # 0 = Draft, 1 = Published
    
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
