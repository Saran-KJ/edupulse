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

class UserResponse(UserBase):
    user_id: int
    is_approved: int
    is_active: int
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
    dept_id: int
    year: int
    semester: int
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
    student_id: int
    subject_id: int
    semester: int
    internal_marks: float
    external_marks: Optional[float] = None
    total_marks: Optional[float] = None
    grade: Optional[str] = None
    exam_date: Optional[date] = None

class MarkCreate(MarkBase):
    pass

class MarkResponse(MarkBase):
    mark_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Attendance Schemas
class AttendanceBase(BaseModel):
    student_id: int
    subject_id: int
    month: str
    year: int
    total_classes: int
    attended_classes: int

class AttendanceCreate(AttendanceBase):
    pass

class AttendanceResponse(AttendanceBase):
    attendance_id: int
    attendance_percentage: Optional[float] = None
    created_at: datetime
    
    class Config:
        from_attributes = True

# Activity Schemas
class ActivityBase(BaseModel):
    activity_name: str
    activity_type: ActivityTypeEnum
    level: Optional[str] = None
    activity_date: date
    description: Optional[str] = None

class ActivityCreate(ActivityBase):
    pass

class ActivityResponse(ActivityBase):
    activity_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Activity Participation Schemas
class ActivityParticipationBase(BaseModel):
    activity_id: int
    student_id: int
    role: Optional[str] = None
    achievement: Optional[str] = None

class ActivityParticipationCreate(ActivityParticipationBase):
    pass

class ActivityParticipationResponse(ActivityParticipationBase):
    participation_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Risk Prediction Schemas
class RiskPredictionRequest(BaseModel):
    student_id: int

class RiskPredictionResponse(BaseModel):
    prediction_id: int
    student_id: int
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
