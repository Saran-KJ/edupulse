from sqlalchemy import Column, Integer, String, Float, Date, ForeignKey, DateTime, Enum, Text, BigInteger
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
    reg_no = Column(String(50), nullable=True)
    phone = Column(String(20), nullable=True)
    dept = Column(String(50), nullable=True)
    year = Column(String(10), nullable=True)
    section = Column(String(10), nullable=True)
    # Parent-specific fields
    child_name = Column(String(100), nullable=True)
    child_phone = Column(String(20), nullable=True)
    child_reg_no = Column(String(50), nullable=True)
    occupation = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Department(Base):
    __tablename__ = "departments"
    
    dept_id = Column(Integer, primary_key=True, index=True)
    dept_code = Column(String(20), unique=True, nullable=False)
    dept_name = Column(String(100), nullable=False)

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
    blood_group = Column(String(20), nullable=True)
    religion = Column(String(50), nullable=True)
    caste = Column(String(50), nullable=True)
    abc_id = Column(String(50), nullable=True)
    aadhar_no = Column(String(50), nullable=True)
    father_name = Column(String(100), nullable=True)
    father_occupation = Column(String(100), nullable=True)
    father_phone = Column(String(20), nullable=True)
    mother_name = Column(String(100), nullable=True)
    mother_occupation = Column(String(100), nullable=True)
    mother_phone = Column(String(20), nullable=True)
    guardian_name = Column(String(100), nullable=True)
    guardian_occupation = Column(String(100), nullable=True)
    guardian_phone = Column(String(20), nullable=True)
    preferred_learning_type = Column(String(50), default="text")  # video_tamil, pdf, visual, text
    learning_path_preference = Column(String(50), nullable=True)   # Academic Enhancement / Skill Development
    learning_sub_preference = Column(String(50), nullable=True)    # Aptitude, Programming, etc.
    overall_study_strategy = Column(Text, nullable=True)         # JSON cache of AI-generated strategy
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
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    semester = Column(String(10), nullable=False)
    subject_code = Column(String(15), nullable=False)
    subject_title = Column(String(200), nullable=False)
    category = Column(String(10), nullable=True)  # CORE, LAB, PEC, OEC, EEC
    credits = Column(Float, default=0)

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
    assignment_1 = Column(Integer, default=0)
    assignment_2 = Column(Integer, default=0)
    assignment_3 = Column(Integer, default=0)
    assignment_4 = Column(Integer, default=0)
    assignment_5 = Column(Integer, default=0)
    
    # Slip Tests (out of 10 each)
    slip_test_1 = Column(Integer, default=0)
    slip_test_2 = Column(Integer, default=0)
    slip_test_3 = Column(Integer, default=0)
    slip_test_4 = Column(Integer, default=0)
    
    # CIA (Continuous Internal Assessment)
    cia_1 = Column(Integer, default=0)
    cia_2 = Column(Integer, default=0)
    
    # Model exam
    model = Column(Integer, default=0)
    
    # University result
    university_result_grade = Column(String(5), nullable=True)
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Attendance(Base):
    __tablename__ = "attendance"
    
    id = Column(Integer, primary_key=True, index=True)
    reg_no = Column(String(20), nullable=False, index=True)
    student_name = Column(String(100), nullable=False)
    date = Column(Date, nullable=False)
    period = Column(Integer, nullable=False, server_default='1')
    subject_code = Column(String(20), nullable=True)
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
    reg_no = Column(String(50), nullable=False, index=True) # Changed from student_id
    role = Column(String(100))  # Participant, Winner, Organizer, etc.
    achievement = Column(String(200))  # 1st Place, 2nd Place, etc.
    created_at = Column(DateTime, default=datetime.utcnow)
    
    activity = relationship("Activity", back_populates="participations")
    # Removed direct student relationship

class RiskPrediction(Base):
    __tablename__ = "risk_predictions"
    
    prediction_id = Column(Integer, primary_key=True, index=True)
    reg_no = Column(String(50), nullable=False, index=True) # Changed from student_id
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

class StudentActivitySubmission(Base):
    """Student-submitted activities pending class advisor approval"""
    __tablename__ = "student_activity_submissions"
    
    id = Column(Integer, primary_key=True, index=True)
    reg_no = Column(String(50), nullable=False, index=True)
    activity_name = Column(String(200), nullable=False)
    activity_type = Column(Enum(ActivityTypeEnum), nullable=False)
    level = Column(String(50))  # College, State, National, International
    activity_date = Column(Date, nullable=False)
    description = Column(Text)
    role = Column(String(100))  # Participant, Winner, Organizer
    achievement = Column(String(200))  # 1st Place, etc.
    dept = Column(String(10), nullable=False)
    year = Column(Integer, nullable=False)
    section = Column(String(10), nullable=False)
    status = Column(String(20), default="pending")  # pending / approved / rejected
    reviewer_id = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    review_comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class FacultyAllocation(Base):
    __tablename__ = "faculty_allocations"
    
    id = Column(Integer, primary_key=True, index=True)
    dept = Column(String(10), nullable=False)
    year = Column(Integer, nullable=False)
    section = Column(String(10), nullable=False)
    subject_code = Column(String(20), nullable=False)
    subject_title = Column(String(100), nullable=False)
    faculty_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    faculty_name = Column(String(100), nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class SubjectSelection(Base):
    """Stores elective subjects (PEC, OEC, EEC) selected by HOD for a specific class."""
    __tablename__ = "subject_selections"
    
    id = Column(Integer, primary_key=True, index=True)
    dept = Column(String(10), nullable=False)
    year = Column(Integer, nullable=False)
    section = Column(String(10), nullable=False)
    semester = Column(String(10), nullable=False)
    subject_code = Column(String(20), nullable=False)
    subject_title = Column(String(200), nullable=False)
    category = Column(String(10), nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)

class LearningResource(Base):
    __tablename__ = "learning_resources"
    
    resource_id = Column(BigInteger, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    url = Column(String(500), nullable=False)
    type = Column(String(50), nullable=False) # video, article, course, quiz
    tags = Column(String(200), nullable=True) # comma-separated tags
    language = Column(String(50), default="English") # Added for multilingual support
    dept = Column(String(10), nullable=True)  # specific to dept or null for all
    subject_code = Column(String(20), nullable=True)  # subject-specific resource (null = general)
    min_risk_level = Column(String(20), nullable=True) # Show only if risk level is at least this (Low, Medium, High)
    unit = Column(String(20), nullable=True) # e.g. "1", "1,2", "1,2,3,4,5" or null for skill resources
    resource_level = Column(String(20), nullable=True) # Basic, Intermediate, Advanced
    skill_category = Column(String(50), nullable=True) # Communication, Programming, Aptitude, etc.
    content = Column(Text, nullable=True)  # Self-written in-app content (JSON string with sections + quiz)
    created_at = Column(DateTime, default=datetime.utcnow)

class StudentLearningProgress(Base):
    __tablename__ = "student_learning_progress"
    
    id = Column(BigInteger, primary_key=True, index=True)
    reg_no = Column(String(50), nullable=False)
    resource_id = Column(BigInteger, ForeignKey("learning_resources.resource_id"), nullable=False)
    completed = Column(Integer, default=0) # 0 = false, 1 = true
    completed_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationship
    resource = relationship("LearningResource")

class PersonalizedLearningPlan(Base):
    __tablename__ = "personalized_learning_plans"
    
    id = Column(Integer, primary_key=True, index=True)
    reg_no = Column(String(50), nullable=False, index=True)
    subject_code = Column(String(20), nullable=False)
    risk_level = Column(String(20), nullable=False)        # High, Medium, Low
    focus_type = Column(String(50), nullable=False)         # Academic Recovery / Improvement / Enhancement, Skill Development
    units = Column(String(50), nullable=True)               # e.g. "1,2" or null for skills
    skill_category = Column(String(50), nullable=True)      # e.g. "Programming" (only for Skill Dev)
    resource_level = Column(String(20), nullable=True)      # Basic / Intermediate / Advanced
    latest_assessment = Column(String(50), nullable=True)   # e.g. "slip_test_1", "cia_1"
    practice_schedule = Column(Text, nullable=True)          # JSON: daily plan for High, weekly for Medium
    weekly_goals = Column(Text, nullable=True)               # JSON: target goals per week
    is_active = Column(Integer, default=1)                  # 1=active, 0=superseded
    created_at = Column(DateTime, default=datetime.utcnow)

class AssessmentUnitMapping(Base):
    """Maps an assessment name to the syllabus units it covers."""
    __tablename__ = "assessment_unit_mapping"
    
    id = Column(Integer, primary_key=True, index=True)
    assessment_name = Column(String(50), nullable=False, unique=True, index=True)
    units = Column(String(50), nullable=False) # e.g. "1,2"
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class PasswordReset(Base):
    __tablename__ = "password_resets"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(100), index=True, nullable=False)
    otp = Column(String(6), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class YouTubeRecommendation(Base):
    __tablename__ = "youtube_recommendations"
    
    id = Column(BigInteger, primary_key=True, index=True)
    reg_no = Column(String(50), nullable=False, index=True)
    subject_code = Column(String(20), nullable=False)
    unit = Column(String(50), nullable=True)
    video_id = Column(String(100), nullable=False)
    title = Column(String(255), nullable=False)
    thumbnail = Column(String(500), nullable=True)
    video_url = Column(String(500), nullable=False)
    risk_level = Column(String(20), nullable=True)
    language = Column(String(50), nullable=True)  # Added to cache per language
    created_at = Column(DateTime, default=datetime.utcnow)

class QuizQuestion(Base):
    __tablename__ = "quiz_questions"
    
    id = Column(BigInteger, primary_key=True, index=True)
    subject = Column(String(100), nullable=False)
    unit = Column(Integer, nullable=False)
    question = Column(Text, nullable=False)
    option_a = Column(String(500), nullable=False)
    option_b = Column(String(500), nullable=False)
    option_c = Column(String(500), nullable=False)
    option_d = Column(String(500), nullable=False)
    correct_answer = Column(String(500), nullable=False)
    difficulty_level = Column(String(50), nullable=False)
    is_early_risk_quiz = Column(Integer, default=0)  # 1 if part of early risk assessment
    created_at = Column(DateTime, default=datetime.utcnow)

class StudentQuizAttempt(Base):
    __tablename__ = "student_quiz_attempts"
    
    id = Column(BigInteger, primary_key=True, index=True)
    reg_no = Column(String(50), nullable=False, index=True)
    subject = Column(String(100), nullable=False)
    unit = Column(Integer, nullable=False)
    total_questions = Column(Integer, nullable=False)
    correct_answers = Column(Integer, nullable=False)
    wrong_answers = Column(Integer, nullable=False)
    score = Column(Float, nullable=False) # (Correct / Total) * 100
    risk_level = Column(String(20), nullable=False)
    attempted_at = Column(DateTime, default=datetime.utcnow)
    scheduled_quiz_id = Column(Integer, ForeignKey("scheduled_quizzes.id"), nullable=True)

class AcademicAlert(Base):
    __tablename__ = "academic_alerts"
    
    id = Column(Integer, primary_key=True, index=True)
    reg_no = Column(String(50), nullable=False, index=True)
    subject = Column(String(100), nullable=True)
    message = Column(Text, nullable=False)
    risk_level = Column(String(20), nullable=True) # Low, Medium, High
    probability = Column(Float, nullable=True)    # The Logistic Regression output
    is_read = Column(Integer, default=0)         # 0 = unread, 1 = read
    created_at = Column(DateTime, default=datetime.utcnow)

class ScheduledQuiz(Base):
    """Faculty-scheduled quiz before a formal assessment."""
    __tablename__ = "scheduled_quizzes"
    
    id = Column(Integer, primary_key=True, index=True)
    faculty_id = Column(Integer, nullable=False)
    dept = Column(String(50), nullable=False)
    year = Column(Integer, nullable=False)
    section = Column(String(10), nullable=False)
    subject_code = Column(String(20), nullable=False)
    subject_title = Column(String(200), nullable=False)
    unit_number = Column(Integer, nullable=False)
    assessment_type = Column(String(50), nullable=False)  # Slip Test, CIA, Model Exam
    start_time = Column(DateTime, nullable=True) # Nullable for older records
    deadline = Column(DateTime, nullable=False)
    is_active = Column(Integer, default=1)  # 1=active, 0=closed
    created_at = Column(DateTime, default=datetime.utcnow)

class ProjectCoordinator(Base):
    """Faculty assigned as project coordinator for a department/year."""
    __tablename__ = "project_coordinators"
    
    id = Column(Integer, primary_key=True, index=True)
    faculty_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    dept = Column(String(50), nullable=False)
    year = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    faculty = relationship("User")


class ProjectBatch(Base):
    """Represents a final year/semester project batch guided by a faculty member."""
    __tablename__ = "batches"
    
    id = Column(Integer, primary_key=True, index=True)
    guide_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    reviewer_id = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    dept = Column(String(50), nullable=True) # E.g., CSE, ECE
    year = Column(Integer, nullable=True)     # E.g., 4
    section = Column(String(10), nullable=True) # E.g., A
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    guide = relationship("User", foreign_keys=[guide_id])
    reviewer = relationship("User", foreign_keys=[reviewer_id])
    creator = relationship("User", foreign_keys=[created_by])
    students = relationship("ProjectBatchStudent", back_populates="batch", cascade="all, delete-orphan")
    reviews = relationship("ProjectReview", back_populates="batch", cascade="all, delete-orphan")
    tasks = relationship("ProjectTask", back_populates="batch", cascade="all, delete-orphan")


class ProjectBatchStudent(Base):
    """Maps a student to a specific project batch."""
    __tablename__ = "batch_students"
    
    id = Column(Integer, primary_key=True, index=True)
    batch_id = Column(Integer, ForeignKey("batches.id"), nullable=False)
    student_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    
    batch = relationship("ProjectBatch", back_populates="students")
    student = relationship("User", foreign_keys=[student_id])

class ProjectReview(Base):
    """Stores assessment data for Reviews 1, 2, and 3."""
    __tablename__ = "project_reviews"
    
    id = Column(Integer, primary_key=True, index=True)
    batch_id = Column(Integer, ForeignKey("batches.id"), nullable=False)
    reviewer_id = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    review_number = Column(Integer, nullable=False) # 1, 2, or 3
    marks = Column(Float, default=0.0)
    feedback = Column(Text, nullable=True)
    reviewed_at = Column(DateTime, default=datetime.utcnow)
    
    batch = relationship("ProjectBatch", back_populates="reviews")
    reviewer = relationship("User", foreign_keys=[reviewer_id])


class ProjectTask(Base):
    """Tracking individual tasks for project phases."""
    __tablename__ = "project_tasks"
    
    id = Column(Integer, primary_key=True, index=True)
    batch_id = Column(Integer, ForeignKey("batches.id"), nullable=False)
    phase = Column(String(50), nullable=False) # Phase 1, Phase 2, Phase 3
    task_name = Column(String(200), nullable=False)
    is_completed = Column(Integer, default=0) # 0=Pending, 1=Completed
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    batch = relationship("ProjectBatch", back_populates="tasks")
