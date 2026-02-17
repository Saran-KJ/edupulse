from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import date, datetime
from models import RoleEnum, RiskLevelEnum, ActivityTypeEnum

# User Schemas
class UserBase(BaseModel):
    name: str
    email: EmailStr
    role: RoleEnum

class UserCreate(UserBase):
    password: str
    secret_pin: Optional[str] = None
    reg_no: Optional[str] = None
    phone: Optional[str] = None
    dept: Optional[str] = None
    year: Optional[str] = None
    section: Optional[str] = None
    # Parent-specific fields
    child_name: Optional[str] = None
    child_phone: Optional[str] = None
    child_reg_no: Optional[str] = None
    occupation: Optional[str] = None

class UserResponse(UserBase):
    user_id: int
    is_approved: int
    is_active: int
    reg_no: Optional[str] = None
    phone: Optional[str] = None
    dept: Optional[str] = None
    year: Optional[str] = None
    section: Optional[str] = None
    # Parent-specific fields
    child_name: Optional[str] = None
    child_phone: Optional[str] = None
    child_reg_no: Optional[str] = None
    occupation: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    role: Optional[RoleEnum] = None
    is_active: Optional[int] = None

class AdminUserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: RoleEnum
    secret_pin: Optional[str] = None
    dept: Optional[str] = None
    year: Optional[str] = None
    section: Optional[str] = None

class PasswordReset(BaseModel):
    email: EmailStr
    secret_pin: str
    new_password: str

class PendingUserResponse(BaseModel):
    user_id: int
    name: str
    email: EmailStr
    role: RoleEnum
    created_at: datetime
    
    class Config:
        from_attributes = True

class LoginLogResponse(BaseModel):
    log_id: int
    user_id: Optional[int]
    email: str
    success: int
    ip_address: Optional[str]
    user_agent: Optional[str]
    failure_reason: Optional[str]
    timestamp: datetime
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

# Department Schemas
class DepartmentBase(BaseModel):
    dept_code: str
    dept_name: str

class DepartmentCreate(DepartmentBase):
    pass

class DepartmentResponse(DepartmentBase):
    dept_id: int
    
    class Config:
        from_attributes = True

# Student Schemas
class StudentBase(BaseModel):
    reg_no: str
    name: str
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    dept: str # Changed from dept_id
    year: int
    semester: int
    section: Optional[str] = None
    dob: Optional[date] = None
    address: Optional[str] = None

class StudentCreate(StudentBase):
    pass

class StudentUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    year: Optional[int] = None
    semester: Optional[int] = None
    section: Optional[str] = None
    address: Optional[str] = None

class StudentResponse(StudentBase):
    student_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Subject Schemas
class SubjectBase(BaseModel):
    subject_code: str
    subject_name: str
    dept_id: int
    semester: int
    credits: int = 3

class SubjectCreate(SubjectBase):
    pass

class SubjectResponse(SubjectBase):
    subject_id: int
    
    class Config:
        from_attributes = True

# Mark Schemas
class MarkBase(BaseModel):
    reg_no: str
    student_name: str
    dept: str # Added dept
    year: int
    section: str
    semester: int
    subject_code: str
    subject_title: str
    assignment_1: float = 0.0
    assignment_2: float = 0.0
    assignment_3: float = 0.0
    assignment_4: float = 0.0
    assignment_5: float = 0.0
    slip_test_1: float = 0.0
    slip_test_2: float = 0.0
    slip_test_3: float = 0.0
    slip_test_4: float = 0.0
    cia_1: float = 0.0
    cia_2: float = 0.0
    model: float = 0.0
    university_result_grade: Optional[str] = None

class MarkCreate(MarkBase):
    pass

class MarkUpdate(BaseModel):
    assignment_1: Optional[float] = None
    assignment_2: Optional[float] = None
    assignment_3: Optional[float] = None
    assignment_4: Optional[float] = None
    assignment_5: Optional[float] = None
    slip_test_1: Optional[float] = None
    slip_test_2: Optional[float] = None
    slip_test_3: Optional[float] = None
    slip_test_4: Optional[float] = None
    cia_1: Optional[float] = None
    cia_2: Optional[float] = None
    model: Optional[float] = None
    university_result_grade: Optional[str] = None

class MarkResponse(MarkBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Bulk Mark Entry Schemas
class SubjectInput(BaseModel):
    subject_code: str
    subject_title: str

class BulkMarkEntry(BaseModel):
    """Schema for bulk mark entry - list of mark records"""
    marks: List[MarkCreate]


# Attendance Schemas
class AttendanceBase(BaseModel):
    reg_no: str
    student_name: str
    date: date
    status: str
    year: int
    section: str
    dept: str
    reason: Optional[str] = None

class AttendanceCreate(AttendanceBase):
    pass

class AttendanceResponse(AttendanceBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class StudentAttendanceInput(BaseModel):
    reg_no: str
    student_name: str
    status: str
    reason: Optional[str] = None

class BulkAttendanceCreate(BaseModel):
    date: date
    year: int
    section: str
    dept: str
    attendance_list: List[StudentAttendanceInput]

# Activity Schemas
class ActivityBase(BaseModel):
    activity_name: str
    activity_type: ActivityTypeEnum
    level: Optional[str] = None
    activity_date: date
    description: Optional[str] = None

class ActivityCreate(ActivityBase):
    pass

class ActivityUpdate(BaseModel):
    activity_name: Optional[str] = None
    activity_type: Optional[ActivityTypeEnum] = None
    level: Optional[str] = None
    activity_date: Optional[date] = None
    description: Optional[str] = None

class ActivityResponse(ActivityBase):
    activity_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Activity Participation Schemas
class ActivityParticipationBase(BaseModel):
    activity_id: int
    reg_no: str # Changed from student_id
    role: Optional[str] = None
    achievement: Optional[str] = None

class ActivityParticipationCreate(ActivityParticipationBase):
    pass

class ActivityParticipationUpdate(BaseModel):
    role: Optional[str] = None
    achievement: Optional[str] = None

class ActivityParticipationResponse(ActivityParticipationBase):
    participation_id: int
    created_at: datetime
    activity: Optional[ActivityResponse] = None
    
    class Config:
        from_attributes = True

# Student Activity Submission Schemas
class StudentActivitySubmissionCreate(BaseModel):
    activity_name: str
    activity_type: ActivityTypeEnum
    level: Optional[str] = None
    activity_date: date
    description: Optional[str] = None
    role: Optional[str] = None
    achievement: Optional[str] = None

class StudentActivitySubmissionResponse(BaseModel):
    id: int
    reg_no: str
    activity_name: str
    activity_type: ActivityTypeEnum
    level: Optional[str] = None
    activity_date: date
    description: Optional[str] = None
    role: Optional[str] = None
    achievement: Optional[str] = None
    dept: str
    year: int
    section: str
    status: str
    review_comment: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class StudentActivitySubmissionReview(BaseModel):
    status: str  # "approved" or "rejected"
    review_comment: Optional[str] = None


class RiskPredictionRequest(BaseModel):
    reg_no: str # Changed from student_id

class RiskPredictionResponse(BaseModel):
    prediction_id: int
    reg_no: str # Changed from student_id
    risk_level: RiskLevelEnum
    risk_score: float
    attendance_percentage: Optional[float] = None
    internal_avg: Optional[float] = None
    external_gpa: Optional[float] = None
    activity_count: Optional[int] = None
    backlog_count: Optional[int] = None
    reasons: Optional[str] = None
    prediction_date: datetime
    
    class Config:
        from_attributes = True

# Dashboard Analytics
class DashboardStats(BaseModel):
    total_students: int
    total_activities: int
    avg_attendance: float
    at_risk_count: int
    high_performers: int

class StudentProfile360(BaseModel):
    student: StudentResponse
    marks: List[MarkResponse]
    attendance: List[AttendanceResponse]
    activities: List[ActivityParticipationResponse]
    latest_risk_prediction: Optional[RiskPredictionResponse] = None

class StudentWithActivities(BaseModel):
    student: StudentResponse
    activities: List[ActivityParticipationResponse]
    
    class Config:
        from_attributes = True

# Faculty Schemas
class FacultyClassInfo(BaseModel):
    """Represents a unique class taught by a faculty member"""
    dept: str
    year: int
    section: str
    subject_code: str
    subject_title: str
    
class FacultyDashboardStats(BaseModel):
    """Statistics for faculty dashboard"""
    total_classes: int
    total_students: int
    subjects_taught: int

# Faculty Allocation Schemas
class FacultyAllocationBase(BaseModel):
    dept: str
    year: int
    section: str
    subject_code: str
    subject_title: str
    faculty_id: int
    faculty_name: str

class FacultyAllocationCreate(FacultyAllocationBase):
    pass

class FacultyAllocationResponse(FacultyAllocationBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

