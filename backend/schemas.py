from pydantic import BaseModel, EmailStr
from typing import Optional, List, Dict, Any
from datetime import date, datetime
from models import RoleEnum, RiskLevelEnum, ActivityTypeEnum

# User Schemas
class UserBase(BaseModel):
    name: str
    email: EmailStr
    role: RoleEnum

class UserCreate(UserBase):
    password: str
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
    dept: Optional[str] = None
    year: Optional[str] = None
    section: Optional[str] = None

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetVerify(BaseModel):
    email: EmailStr
    otp: str

class PasswordResetConfirm(BaseModel):
    email: EmailStr
    otp: str
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
    blood_group: Optional[str] = None
    religion: Optional[str] = None
    caste: Optional[str] = None
    abc_id: Optional[str] = None
    aadhar_no: Optional[str] = None
    father_name: Optional[str] = None
    father_occupation: Optional[str] = None
    father_phone: Optional[str] = None
    mother_name: Optional[str] = None
    mother_occupation: Optional[str] = None
    mother_phone: Optional[str] = None
    guardian_name: Optional[str] = None
    guardian_occupation: Optional[str] = None
    guardian_phone: Optional[str] = None

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
    dob: Optional[date] = None
    blood_group: Optional[str] = None
    religion: Optional[str] = None
    caste: Optional[str] = None
    abc_id: Optional[str] = None
    aadhar_no: Optional[str] = None
    father_name: Optional[str] = None
    father_occupation: Optional[str] = None
    father_phone: Optional[str] = None
    mother_name: Optional[str] = None
    mother_occupation: Optional[str] = None
    mother_phone: Optional[str] = None
    guardian_name: Optional[str] = None
    guardian_occupation: Optional[str] = None
    guardian_phone: Optional[str] = None

class StudentResponse(StudentBase):
    student_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Subject Schemas
class SubjectBase(BaseModel):
    semester: str
    subject_code: str
    subject_title: str
    category: Optional[str] = None  # CORE, LAB, PEC, OEC, EEC
    credits: float = 0

class SubjectCreate(SubjectBase):
    pass

class SubjectResponse(SubjectBase):
    id: int
    
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
    assignment_1: Optional[int] = None
    assignment_2: Optional[int] = None
    assignment_3: Optional[int] = None
    assignment_4: Optional[int] = None
    assignment_5: Optional[int] = None
    slip_test_1: Optional[int] = None
    slip_test_2: Optional[int] = None
    slip_test_3: Optional[int] = None
    slip_test_4: Optional[int] = None
    cia_1: Optional[int] = None
    cia_2: Optional[int] = None
    model: Optional[int] = None
    university_result_grade: Optional[str] = None

class MarkCreate(MarkBase):
    pass

class MarkUpdate(BaseModel):
    assignment_1: Optional[int] = None
    assignment_2: Optional[int] = None
    assignment_3: Optional[int] = None
    assignment_4: Optional[int] = None
    assignment_5: Optional[int] = None
    slip_test_1: Optional[int] = None
    slip_test_2: Optional[int] = None
    slip_test_3: Optional[int] = None
    slip_test_4: Optional[int] = None
    cia_1: Optional[int] = None
    cia_2: Optional[int] = None
    model: Optional[int] = None
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
    period: int = 1
    subject_code: Optional[str] = None
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
    period: int = 1
    subject_code: Optional[str] = None
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

class EarlyRiskQuizRequest(BaseModel):
    reg_no: str
    subject_code: str
    unit_number: int = 1

class EarlyRiskResponse(BaseModel):
    reg_no: str
    subject_code: str
    risk_level: str
    probability: float
    probability_percentage: float
    features: Dict[str, Any]
    recommendations: List[str]
    interpretation: str

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
    learning_path_preference: Optional[str] = None
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

# HOD Subject Selection Schemas
class SubjectSelectionBase(BaseModel):
    dept: str
    year: int
    section: str
    semester: str
    subject_code: str
    subject_title: str
    category: str

class SubjectSelectionCreate(SubjectSelectionBase):
    pass

class SubjectSelectionResponse(SubjectSelectionBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Personalized Learning Plan Schemas
class PersonalizedLearningPlanResponse(BaseModel):
    id: int
    reg_no: str
    subject_code: str
    risk_level: str
    focus_type: str
    units: Optional[str] = None
    skill_category: Optional[str] = None
    resource_level: Optional[str] = None
    latest_assessment: Optional[str] = None
    is_active: int = 1
    created_at: datetime
    pending_choice: bool = False  # True if LOW risk and no choice made yet
    
    class Config:
        from_attributes = True

class LowRiskChoiceRequest(BaseModel):
    subject_code: str
    choice: str  # "academic_enhancement" or "skill_development"

class SkillSelectionRequest(BaseModel):
    subject_code: str
    skill: str  # "Communication", "Programming", "Aptitude", etc.

class GlobalPathPreferenceRequest(BaseModel):
    choice: str  # "Academic Enhancement" or "Skill Development"
    sub_choice: Optional[str] = None

class LearningPlanResourceResponse(BaseModel):
    resource_id: int
    title: str
    description: Optional[str] = None
    url: str
    type: str
    tags: Optional[str] = None
    unit: Optional[str] = None
    resource_level: Optional[str] = None
    skill_category: Optional[str] = None
    is_completed: bool = False
    
    class Config:
        from_attributes = True

class PreferredLearningTypeRequest(BaseModel):
    learning_type: str  # "video_tamil", "pdf", "visual", "text"

class SubjectLearningStatus(BaseModel):
    subject_code: str
    subject_title: str
    risk_level: str
    focus_type: str
    progress_percentage: float = 0.0
    practice_schedule: Optional[str] = None
    weekly_goals: Optional[str] = None

class OverallLearningViewResponse(BaseModel):
    overall_risk: str
    priority_subjects: List[SubjectLearningStatus]
    study_strategy: dict
    total_progress: float
    preferred_learning_type: str

class StudentLearningStatusResponse(BaseModel):
    reg_no: str
    student_name: str
    overall_risk: str
    high_risk_count: int
    medium_risk_count: int
    low_risk_count: int
    overall_progress: float
    subjects: List[SubjectLearningStatus]

class HighRiskAlertResponse(BaseModel):
    reg_no: str
    student_name: str
    dept: str
    year: int
    section: str
    high_risk_subjects: List[str]
    alert_severity: str  # "critical", "warning"
    recommended_actions: List[str]

# Assessment Unit Mapping Schemas
class AssessmentUnitMappingBase(BaseModel):
    assessment_name: str
    units: str

class AssessmentUnitMappingCreate(AssessmentUnitMappingBase):
    pass

class AssessmentUnitMappingResponse(AssessmentUnitMappingBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class YouTubeVideoResponse(BaseModel):
    video_id: str
    title: str
    thumbnail: str
    video_url: str

class LearningResourcesResponse(BaseModel):
    subject: str
    risk_level: str
    focus_type: str
    weak_unit: str
    recommended_videos: List[YouTubeVideoResponse]

    class Config:
        from_attributes = True

# Quiz Schemas
class QuizQuestionBase(BaseModel):
    question: str
    option_a: Optional[str] = None  # Can be None for NAT
    option_b: Optional[str] = None
    option_c: Optional[str] = None
    option_d: Optional[str] = None
    correct_answer: str

class QuizQuestionResponse(QuizQuestionBase):
    id: int
    subject: str
    unit: int
    difficulty_level: str
    question_type: str = "MCQ"  # MCQ, MCS, NAT
    assessment_type: Optional[str] = None  # SlipTest, CIA, ModelExam
    
    class Config:
        from_attributes = True

class QuizGenerationResponse(BaseModel):
    subject: str
    unit: int
    risk_level: str
    total_questions: int
    quiz: List[QuizQuestionResponse]

class QuizAttemptSubmission(BaseModel):
    subject: str
    unit: int
    answers: Dict[int, str] # question_id -> selected_option
    risk_level: str
    scheduled_quiz_id: Optional[int] = None

class QuizAttemptResponse(BaseModel):
    total_questions: int
    correct_answers: int
    wrong_answers: int
    score: float
    status: str # "success"

# Project Coordinator Schemas
class ProjectCoordinatorBase(BaseModel):
    faculty_id: int
    dept: str
    year: int

class ProjectCoordinatorCreate(ProjectCoordinatorBase):
    pass

class ProjectCoordinatorResponse(ProjectCoordinatorBase):
    id: int
    faculty_name: str
    created_at: datetime
    
    class Config:
        from_attributes = True

# Project Review Schemas

class ProjectReviewBase(BaseModel):
    batch_id: int
    review_number: int
    marks: float
    feedback: Optional[str] = None

class ProjectReviewCreate(ProjectReviewBase):
    pass

class ProjectReviewResponse(ProjectReviewBase):
    id: int
    reviewer_id: Optional[int] = None
    reviewer_name: Optional[str] = None
    reviewed_at: datetime
    
    class Config:
        from_attributes = True

# Project Task Schemas

class ProjectTaskBase(BaseModel):
    batch_id: int
    phase: str
    task_name: str
    is_completed: int

class ProjectTaskCreate(ProjectTaskBase):
    pass

class ProjectTaskUpdate(BaseModel):
    is_completed: int

class ProjectTaskResponse(ProjectTaskBase):
    id: int
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Project Batch Allocation Schemas
class ProjectBatchCreate(BaseModel):
    guide_id: int
    dept: Optional[str] = None
    year: Optional[int] = None
    section: Optional[str] = None
    student_reg_nos: List[str]

class ProjectBatchStudentResponse(BaseModel):
    student_id: int
    name: str
    reg_no: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    
class ProjectBatchResponse(BaseModel):
    id: int
    guide_id: int
    guide_name: str
    reviewer_id: Optional[int] = None
    reviewer_name: Optional[str] = None
    dept: Optional[str] = None
    year: Optional[int] = None
    section: Optional[str] = None
    students: List[ProjectBatchStudentResponse]
    reviews: List[ProjectReviewResponse] = []
    tasks: List[ProjectTaskResponse] = []
    created_at: datetime
    
    class Config:
        from_attributes = True

class ProjectBatchReviewerUpdate(BaseModel):
    reviewer_id: int

# Learning Content Generation Schemas
class ContentSection(BaseModel):
    title: str
    content: str
    key_points: List[str]
    examples: Optional[List[str]] = None

class ContentGenerationRequest(BaseModel):
    subject_name: str
    unit_number: int
    topic: str
    learning_preference: Optional[str] = "text"  # text, visual, mixed

class ContentGenerationResponse(BaseModel):
    subject: str
    unit: int
    topic: str
    title: str
    introduction: str
    sections: List[ContentSection]
    summary: str
    learning_objectives: List[str]
    difficulty_level: str
    estimated_read_time: str

class QuizWithContentResponse(BaseModel):
    content: ContentGenerationResponse
    quiz: QuizGenerationResponse


