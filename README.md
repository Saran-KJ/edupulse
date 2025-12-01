# EduPulse – AI-Powered Student 360° Performance & Activity Management System

<div align="center">

![EduPulse](https://img.shields.io/badge/EduPulse-v1.0.0-blue)
![Python](https://img.shields.io/badge/Python-3.9+-green)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104-teal)
![License](https://img.shields.io/badge/License-MIT-yellow)

**A comprehensive college management system with AI-powered risk prediction for student academic performance**

[Features](#features) • [Tech Stack](#tech-stack) • [Installation](#installation) • [Usage](#usage) • [API Documentation](#api-documentation)

</div>

---

## 📋 Overview

EduPulse is a production-ready, full-stack student management system designed for colleges to track and analyze student performance comprehensively. It combines traditional management features with AI/ML capabilities to predict academic risk and provide actionable insights.

### Key Highlights

- **360° Student View**: Complete profile with marks, attendance, activities, and AI insights
- **AI Risk Prediction**: Machine learning models predict student academic risk
- **Multi-Platform**: Flutter mobile app (Android/iOS) + Web dashboard from single codebase
- **Role-Based Access**: Admin, Staff, and Student roles with appropriate permissions
- **Real-Time Analytics**: Interactive charts and dashboards
- **RESTful API**: FastAPI backend with comprehensive endpoints

---

## ✨ Features

### Core Features

1. **Role-Based Authentication**
   - JWT token-based secure authentication
   - Admin, Staff/Mentor, and Student roles
   - Persistent login sessions

2. **Student Information Management**
   - Complete student profiles (personal info, department, year, contact)
   - Search and filter capabilities
   - CRUD operations with validation

3. **Academic Performance Tracking**
   - Internal and external marks management
   - Automatic grade calculation
   - Semester-wise performance tracking
   - GPA trend analysis

4. **Attendance Management**
   - Subject-wise attendance tracking
   - Monthly attendance records
   - Automatic percentage calculation
   - Attendance trend visualization

5. **Activity Tracking**
   - Sports, hackathons, workshops, symposiums
   - Participation records with achievements
   - Activity level tracking (College, State, National, International)

6. **AI/ML Risk Prediction**
   - Predicts academic risk (Low/Medium/High)
   - Features: attendance %, internal marks, GPA, activities, backlogs
   - Multiple models compared (Logistic Regression, Random Forest, XGBoost)
   - Detailed risk reasons and recommendations

7. **Analytics & Dashboards**
   - Real-time statistics
   - Interactive charts (attendance trends, marks distribution)
   - At-risk students identification
   - Department-level analytics

8. **Reports & Export**
   - PDF report generation
   - Excel data export
   - Student performance summaries

---

## 🛠 Tech Stack

### Backend
- **Framework**: FastAPI (Python)
- **Database**: PostgreSQL
- **ORM**: SQLAlchemy
- **Authentication**: JWT (python-jose)
- **Password Hashing**: bcrypt

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
- **PDF/Excel**: pdf, printing, excel packages

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
# Change baseUrl to your backend URL (e.g., http://10.0.2.2:8000 for Android emulator)

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
  "role": "admin"
}
```

### 3. Login to Mobile App

- Open the mobile app
- Enter admin credentials
- Access the dashboard

### 4. Add Students and Data

- Navigate to Students section
- Add student profiles
- Enter marks, attendance, and activities
- View AI risk predictions

---

## 📚 API Documentation

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | User login (returns JWT token) |
| POST | `/api/auth/register` | Register new user |
| GET | `/api/auth/me` | Get current user info |

### Student Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/students` | List all students (with filters) |
| POST | `/api/students` | Create new student |
| GET | `/api/students/{id}` | Get student by ID |
| GET | `/api/students/{id}/profile` | Get 360° student profile |
| PUT | `/api/students/{id}` | Update student |
| DELETE | `/api/students/{id}` | Delete student |

### Marks Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/marks` | Add marks entry |
| GET | `/api/marks/student/{id}` | Get student marks |
| DELETE | `/api/marks/{id}` | Delete mark entry |

### Attendance Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/attendance` | Record attendance |
| GET | `/api/attendance/student/{id}` | Get student attendance |
| DELETE | `/api/attendance/{id}` | Delete attendance record |

### Activity Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/activities` | Create activity |
| GET | `/api/activities` | List activities |
| POST | `/api/activities/participation` | Record participation |
| GET | `/api/activities/participation/student/{id}` | Get student participations |

### Analytics Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/analytics/dashboard` | Dashboard statistics |
| GET | `/api/analytics/department/{id}` | Department analytics |

### ML Prediction Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/predict/risk` | Predict student risk |
| GET | `/api/predict/at-risk-students` | List at-risk students |
| GET | `/api/predict/history/{id}` | Prediction history |

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

1. **Login Screen**: Secure authentication with validation
2. **Dashboard**: Quick stats, charts, at-risk students
3. **Students List**: Search, filter, and navigation
4. **Student Profile**: 360° view with tabs (Info, Marks, Attendance, Activities, AI Insights)
5. **Analytics**: Charts and visualizations

---

## 🌐 Database Schema

### Core Tables

- `users` - User authentication and roles
- `departments` - Department master data
- `students` - Student profiles
- `subjects` - Subject master data
- `marks` - Academic marks records
- `attendance` - Attendance tracking
- `activities` - Activity master data
- `activity_participation` - Student participation records
- `risk_predictions` - AI prediction results

---

## 🔒 Security

- JWT token-based authentication
- Password hashing with bcrypt
- Role-based access control
- CORS middleware for API security
- Input validation with Pydantic schemas

---

## 🎯 Future Enhancements

- [ ] Real-time notifications
- [ ] Email integration for alerts
- [ ] Advanced analytics with more ML models
- [ ] Parent portal
- [ ] Timetable management
- [ ] Fee management
- [ ] Library integration
- [ ] Mobile app for students
- [ ] Push notifications
- [ ] Dark mode

---

## 📄 License

This project is licensed under the MIT License.

---

## 👥 Contributors

- **Your Name** - Initial work - Final Year Project

---

## 📞 Support

For support, email your-email@example.com or open an issue in the repository.

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
