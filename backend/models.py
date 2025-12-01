from sqlalchemy import Column, Integer, String, Float, Date, ForeignKey, DateTime, Enum, Text
from sqlalchemy.orm import relationship
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
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Department(Base):
    __tablename__ = "departments"
    
    dept_id = Column(Integer, primary_key=True, index=True)
    dept_code = Column(String(20), unique=True, nullable=False)
    dept_name = Column(String(100), nullable=False)
    
    students = relationship("Student", back_populates="department")
    subjects = relationship("Subject", back_populates="department")

class Student(Base):
    __tablename__ = "students"
    
    student_id = Column(Integer, primary_key=True, index=True)
    reg_no = Column(String(50), unique=True, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True)
    phone = Column(String(20))
    dept_id = Column(Integer, ForeignKey("departments.dept_id"))
    year = Column(Integer, nullable=False)
    semester = Column(Integer, nullable=False)
    dob = Column(Date)
    address = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    department = relationship("Department", back_populates="students")
    marks = relationship("Mark", back_populates="student", cascade="all, delete-orphan")
    attendance = relationship("Attendance", back_populates="student", cascade="all, delete-orphan")
    activity_participations = relationship("ActivityParticipation", back_populates="student", cascade="all, delete-orphan")
    risk_predictions = relationship("RiskPrediction", back_populates="student", cascade="all, delete-orphan")

class Subject(Base):
    __tablename__ = "subjects"
    
    subject_id = Column(Integer, primary_key=True, index=True)
    subject_code = Column(String(20), unique=True, nullable=False)
    subject_name = Column(String(100), nullable=False)
    dept_id = Column(Integer, ForeignKey("departments.dept_id"))
    semester = Column(Integer, nullable=False)
    credits = Column(Integer, default=3)
    
    department = relationship("Department", back_populates="subjects")
    marks = relationship("Mark", back_populates="subject")
    attendance = relationship("Attendance", back_populates="subject")

class Mark(Base):
    __tablename__ = "marks"
    
    mark_id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.student_id"))
    subject_id = Column(Integer, ForeignKey("subjects.subject_id"))
    semester = Column(Integer, nullable=False)
    internal_marks = Column(Float, nullable=False)
    external_marks = Column(Float)
    total_marks = Column(Float)
    grade = Column(String(5))
    exam_date = Column(Date)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    student = relationship("Student", back_populates="marks")
    subject = relationship("Subject", back_populates="marks")

class Attendance(Base):
    __tablename__ = "attendance"
    
    attendance_id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.student_id"))
    subject_id = Column(Integer, ForeignKey("subjects.subject_id"))
    month = Column(String(20), nullable=False)
    year = Column(Integer, nullable=False)
    total_classes = Column(Integer, nullable=False)
    attended_classes = Column(Integer, nullable=False)
    attendance_percentage = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    student = relationship("Student", back_populates="attendance")
    subject = relationship("Subject", back_populates="attendance")

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
    student_id = Column(Integer, ForeignKey("students.student_id"))
    role = Column(String(100))  # Participant, Winner, Organizer, etc.
    achievement = Column(String(200))  # 1st Place, 2nd Place, etc.
    created_at = Column(DateTime, default=datetime.utcnow)
    
    activity = relationship("Activity", back_populates="participations")
    student = relationship("Student", back_populates="activity_participations")

class RiskPrediction(Base):
    __tablename__ = "risk_predictions"
    
    prediction_id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.student_id"))
    risk_level = Column(Enum(RiskLevelEnum), nullable=False)
    risk_score = Column(Float, nullable=False)
    attendance_percentage = Column(Float)
    internal_avg = Column(Float)
    external_gpa = Column(Float)
    activity_count = Column(Integer)
    backlog_count = Column(Integer)
    reasons = Column(Text)
    prediction_date = Column(DateTime, default=datetime.utcnow)
    
    student = relationship("Student", back_populates="risk_predictions")

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
