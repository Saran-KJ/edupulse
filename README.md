# EduPulse – AI-Powered Student 360° Performance & Activity Management System

<div align="center">

![EduPulse](https://img.shields.io/badge/EduPulse-v2.0.0-blue)
![Python](https://img.shields.io/badge/Python-3.9+-green)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104-teal)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-12+-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

**A comprehensive college management system with AI-powered risk prediction for student academic performance**

[Features](#-features) • [Tech Stack](#-tech-stack) • [Installation](#-installation) • [Usage](#-usage) • [API Documentation](#-api-documentation)

</div>

---

## 📋 Overview

EduPulse is a production-ready, full-stack student management system designed for colleges to track and analyze student performance comprehensively. It combines traditional management features with AI/ML capabilities to predict academic risk and provide actionable insights.

### Key Highlights

- **360° Student View**: Complete profile with marks, attendance, activities, and AI insights
- **AI Risk Prediction**: Machine learning models predict student academic risk
- **Multi-Platform**: Flutter mobile app (Android/iOS) + Web dashboard from single codebase
- **Multi-Role Access**: Admin, Faculty, Class Advisor, HOD, Principal, Vice Principal, Student, and Parent roles
- **Department-Specific Data**: Separate student tables per department (CSE, ECE, EEE, MECH, CIVIL, BIO, AIDS)
- **Real-Time Analytics**: Interactive charts and dashboards
- **RESTful API**: FastAPI backend with comprehensive endpoints
- **Timetable Management**: Create and publish class timetables
- **Reports & Export**: PDF and Excel report generation

---

## ✨ Features

### Core Features

1. **Multi-Role Authentication**
   - JWT token-based secure authentication
   - **8 User Roles**:
     - **Admin**: Full system access, user management, approvals
     - **Faculty**: Mark entry, attendance management
     - **Class Advisor**: Class-specific analytics and student management
     - **HOD**: Department-level oversight
     - **Vice Principal**: Institution-level access
     - **Principal**: Institution-level access
     - **Student**: View own marks, attendance, timetable
     - **Parent**: View child's academic performance
   - User registration with approval workflow
   - Secret PIN-based password recovery

2. **Student Information Management**
   - Department-specific student tables (CSE, ECE, EEE, MECH, CIVIL, BIO, AIDS)
   - Complete student profiles (reg_no, personal info, department, year, section, contact)
   - Search and filter capabilities
   - CRUD operations with validation

3. **Academic Performance Tracking**
   - **Internal Marks Components**:
     - 5 Assignments (out of 10 each)
     - 4 Slip Tests (out of 10 each)
     - 2 CIA exams (Continuous Internal Assessment)
     - Model exam
   - University result grade tracking
   - Subject-wise marks management
   - Semester-wise performance tracking

4. **Attendance Management**
   - Daily attendance entry by class (dept, year, section)
   - Status types: Present, Absent, OD (On Duty) with reason
   - View attendance history with filtering
   - Attendance percentage calculation

5. **Activity Tracking**
   - Activity Types: Sports, Hackathon, Workshop, Symposium, Seminar, Competition, Other
   - Activity levels: College, State, National, International
   - Participation records with roles and achievements
   - Student participation history

6. **AI/ML Risk Prediction**
   - Predicts academic risk (Low/Medium/High)
   - Features: attendance %, internal marks, GPA, activities, backlogs
   - Multiple models compared (Logistic Regression, Random Forest, XGBoost)
   - Detailed risk reasons and recommendations
   - At-risk students identification

7. **Timetable Management**
   - Create class timetables by department, year, section
   - Period-wise schedule (6 periods per day)
   - Day-wise entries (Monday to Saturday)
   - Publish/unpublish functionality
   - Students view their class timetable

8. **Analytics & Dashboards**
   - **Admin Dashboard**: System-wide statistics, pending approvals
   - **Class Advisor Dashboard**: Class-specific analytics
   - **Student Dashboard**: Personal marks, attendance, timetable
   - **Parent Dashboard**: Child's academic overview
   - Interactive charts and visualizations

9. **Reports & Export**
   - PDF report generation
   - Excel data export
   - Marks reports by class
   - Attendance reports

---

## 🛠 Tech Stack

### Backend
- **Framework**: FastAPI (Python 3.9+)
- **Database**: PostgreSQL 12+
- **ORM**: SQLAlchemy
- **Authentication**: JWT (python-jose)
- **Password Hashing**: bcrypt (passlib)
- **Validation**: Pydantic schemas

### Machine Learning
- **Framework**: scikit-learn
- **Models**: Logistic Regression, Random Forest, XGBoost
- **Model Persistence**: joblib
- **Data Processing**: pandas, numpy

### Mobile & Web
- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **HTTP Client**: dio, http
- **Charts**: fl_chart
- **Storage**: shared_preferences
- **PDF Generation**: pdf, printing packages
- **Excel Export**: excel packages

---

## 📦 Installation

### Prerequisites

- Python 3.9+
- PostgreSQL 12+
- Flutter 3.0+
- Android Studio (for mobile development)
- Git

### Backend Setup

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
copy .env.example .env

# Update .env with your database credentials
# DATABASE_URL=postgresql://username:password@localhost:5432/edupulse
# SECRET_KEY=your-secret-key-here

# Initialize database (creates tables and seed data)
python init_db.py

# Run the server
python main.py
```

The API will be available at `http://localhost:8000`

### ML Model Training

```bash
# Navigate to ml_models directory
cd ml_models

# Install dependencies
pip install -r requirements.txt

# Generate sample training data
python generate_sample_data.py

# Train models and save the best one
python train_model.py
```

This will create `best_model.pkl` and `feature_scaler.pkl` files.

### Mobile App Setup

```bash
# Navigate to mobile directory
cd mobile

# Install Flutter dependencies
flutter pub get

# Update API base URL in lib/config/app_config.dart
# Change baseUrl to your backend URL
# For Android emulator: http://10.0.2.2:8000
# For physical device: http://your-ip:8000

# Run on Android
flutter run

# Build APK
flutter build apk --release
```

### Web Dashboard Setup

```bash
# Same Flutter project supports web
cd mobile

# Enable web support (if not already enabled)
flutter config --enable-web

# Run web version
flutter run -d chrome

# Build for production
flutter build web --release
```

---

## 🚀 Usage

### 1. Start the Backend

```bash
cd backend
python main.py
```

### 2. Create Initial Admin User

Use the API documentation at `http://localhost:8000/docs` to register an admin user:

```json
POST /api/auth/register
{
  "name": "Admin User",
  "email": "admin@edupulse.com",
  "password": "admin123",
  "role": "admin",
  "secret_pin": "1234"
}
```

### 3. Login and Access Features

- Open the mobile app or web dashboard
- Login with your credentials
- Based on role, you'll see the appropriate dashboard:
  - **Admin**: User management, approvals, system settings
  - **Faculty**: Mark entry, attendance entry
  - **Class Advisor**: Class analytics, student performance
  - **Student**: View marks, attendance, timetable
  - **Parent**: View child's academic data

---

## 📚 API Documentation

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | User login (returns JWT token) |
| POST | `/api/auth/register` | Register new user |
| GET | `/api/auth/me` | Get current user info |
| POST | `/api/auth/reset-password` | Reset password with secret PIN |

### Admin Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/pending-users` | List pending approval users |
| POST | `/api/admin/approve-user/{id}` | Approve user registration |
| POST | `/api/admin/reject-user/{id}` | Reject user registration |
| GET | `/api/admin/users` | List all users |
| POST | `/api/admin/create-user` | Create user (admin only) |
| DELETE | `/api/admin/users/{id}` | Delete user |
| GET | `/api/admin/login-logs` | View login audit logs |

### Student Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/students` | List students (with dept filter) |
| POST | `/api/students` | Create new student |
| GET | `/api/students/{id}` | Get student by ID |
| GET | `/api/students/{id}/profile` | Get 360° student profile |
| PUT | `/api/students/{id}` | Update student |
| DELETE | `/api/students/{id}` | Delete student |
| GET | `/api/students/class/{dept}/{year}/{section}` | Get students by class |

### Marks Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/marks` | Add/update marks entry |
| POST | `/api/marks/bulk` | Bulk mark entry for class |
| GET | `/api/marks/student/{reg_no}` | Get student marks by reg_no |
| GET | `/api/marks/class/{dept}/{year}/{section}` | Get class marks |
| DELETE | `/api/marks/{id}` | Delete mark entry |

### Attendance Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/attendance/bulk` | Submit bulk attendance for class |
| GET | `/api/attendance/class/{dept}/{year}/{section}` | Get class attendance |
| GET | `/api/attendance/student/{reg_no}` | Get student attendance |
| DELETE | `/api/attendance/{id}` | Delete attendance record |

### Activity Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/activities` | Create activity |
| GET | `/api/activities` | List activities |
| GET | `/api/activities/{id}` | Get activity details |
| PUT | `/api/activities/{id}` | Update activity |
| DELETE | `/api/activities/{id}` | Delete activity |
| POST | `/api/activities/participation` | Record student participation |
| GET | `/api/activities/participation/student/{reg_no}` | Get student participations |
| GET | `/api/activities/class/{dept}/{year}/{section}` | Get class activities |

### Timetable Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/timetable` | Create timetable entry |
| GET | `/api/timetable/{dept}/{year}/{section}` | Get class timetable |
| PUT | `/api/timetable/{id}` | Update timetable entry |
| DELETE | `/api/timetable/{id}` | Delete timetable entry |
| POST | `/api/timetable/publish/{dept}/{year}/{section}` | Publish timetable |
| GET | `/api/timetable/status/{dept}/{year}/{section}` | Get publish status |

### Analytics Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/analytics/dashboard` | Dashboard statistics |
| GET | `/api/analytics/department/{dept}` | Department analytics |

### Report Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/reports/marks/pdf` | Download marks PDF report |
| GET | `/api/reports/marks/excel` | Download marks Excel report |

### ML Prediction Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/predict/risk` | Predict student risk |
| GET | `/api/predict/at-risk-students` | List at-risk students |
| GET | `/api/predict/history/{reg_no}` | Prediction history |

**Interactive API Documentation**: Visit `http://localhost:8000/docs` for Swagger UI

---

## 🤖 Machine Learning

### Features Used for Prediction

1. **Attendance Percentage** (0-100%)
2. **Internal Marks Average** (0-100)
3. **External GPA** (0-10 scale)
4. **Activity Count** (number of activities participated)
5. **Backlog Count** (number of failed subjects)

### Models Compared

- **Logistic Regression**: Baseline linear model
- **Random Forest**: Ensemble tree-based model
- **XGBoost**: Gradient boosting model

### Risk Levels

- **Low Risk**: Score 0-29 (Good performance)
- **Medium Risk**: Score 30-59 (Needs attention)
- **High Risk**: Score 60-100 (Immediate intervention required)

### Model Performance

The training script evaluates models using:
- Accuracy
- F1 Score (weighted)
- Confusion Matrix
- Cross-validation (5-fold)

---

## 📱 Mobile App Screens

### Authentication
- **Login Screen**: Secure authentication with role selection
- **Register Screen**: User registration with role-specific fields
- **Forgot Password**: Password reset with secret PIN

### Admin
- **Admin Dashboard**: Pending approvals, user management, system stats

### Faculty/Class Advisor
- **Class Advisor Dashboard**: Class analytics, student list
- **Mark Entry Screen**: Enter marks for students by subject
- **Attendance Entry Screen**: Mark daily attendance
- **View Marks Screen**: View class marks
- **View Attendance Screen**: View attendance history
- **Activity Management**: Create activities, record participation
- **Timetable Screen**: Create and manage class timetable

### Student
- **Student Dashboard**: Personal overview, quick stats
- **Student Marks Screen**: View all subject marks
- **Student Attendance Screen**: View attendance history
- **Student Profile Screen**: View/edit profile
- **Timetable View**: View class timetable

### Parent
- **Parent Dashboard**: Child's academic overview

---

## 🌐 Database Schema

### Core Tables

| Table | Description |
|-------|-------------|
| `users` | User authentication, roles, and profile |
| `departments` | Department master data (CSE, ECE, etc.) |
| `students_cse`, `students_ece`, etc. | Department-specific student tables |
| `subjects` | Subject master data |
| `marks` | Academic marks records |
| `attendance` | Attendance tracking |
| `activities` | Activity master data |
| `activity_participation` | Student participation records |
| `risk_predictions` | AI prediction results |
| `timetables` | Class timetable entries |
| `timetable_status` | Timetable publish status |
| `login_logs` | Authentication audit logs |

---

## 🔒 Security

- JWT token-based authentication
- Password hashing with bcrypt
- Role-based access control (RBAC)
- CORS middleware for API security
- Input validation with Pydantic schemas
- Query parameter token support for report downloads
- Login audit logging

---

## 📁 Project Structure

```
edupulse/
├── backend/
│   ├── routes/
│   │   ├── auth_routes.py      # Authentication
│   │   ├── admin_routes.py     # Admin operations
│   │   ├── student_routes.py   # Student CRUD
│   │   ├── mark_routes.py      # Marks management
│   │   ├── attendance_routes.py # Attendance
│   │   ├── activity_routes.py  # Activities
│   │   ├── timetable_routes.py # Timetable
│   │   ├── analytics_routes.py # Analytics
│   │   ├── prediction_routes.py # ML predictions
│   │   └── report_routes.py    # PDF/Excel reports
│   ├── models.py               # SQLAlchemy models
│   ├── schemas.py              # Pydantic schemas
│   ├── auth.py                 # JWT authentication
│   ├── database.py             # Database connection
│   ├── config.py               # Configuration
│   ├── ml_service.py           # ML model service
│   ├── main.py                 # FastAPI app
│   └── requirements.txt
├── mobile/
│   └── lib/
│       ├── screens/            # All app screens
│       ├── services/           # API service
│       ├── models/             # Data models
│       ├── config/             # App configuration
│       └── main.dart           # App entry point
├── ml_models/
│   ├── train_model.py          # Model training
│   └── generate_sample_data.py # Sample data generation
└── README.md
```

---

## 🎯 Implemented Features

- [x] Multi-role authentication (8 roles)
- [x] User registration with approval workflow
- [x] Password reset with secret PIN
- [x] Department-specific student management
- [x] Mark entry (Assignments, Slip Tests, CIA, Model, University)
- [x] Attendance management with OD reason support
- [x] Activity and participation tracking
- [x] Timetable management
- [x] AI risk prediction
- [x] PDF/Excel report generation
- [x] Role-based dashboards
- [x] Class Advisor analytics
- [x] Parent portal
- [x] Login audit logging

---

## 📄 License

This project is licensed under the MIT License.

---

## 👥 Contributors

- **Saran KJ** - Final Year Project

---

## 📞 Support

For support, open an issue in the repository.

---

## 🙏 Acknowledgments

- FastAPI for the excellent web framework
- Flutter team for the cross-platform framework
- scikit-learn for ML capabilities
- All open-source contributors

---

<div align="center">

**Made with ❤️ for better education management**

⭐ Star this repo if you find it helpful!

</div>
