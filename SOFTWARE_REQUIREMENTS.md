# Software Requirements Specification (SRS) 
## EduPulse - AI-Powered Student 360° Performance & Activity Management System

---

## 1. Introduction

### 1.1 Purpose
The purpose of this document is to outline the software requirements for EduPulse, a comprehensive college management platform. This system utilizes traditional management techniques along with AI and machine learning insights to predict academic risks, generate learning strategies, and provide a 360-degree view of student performance.

### 1.2 Scope
EduPulse is a cross-platform (Mobile and Web) application powered by a FastAPI backend and PostgreSQL database. It tracks academic metrics, calculates attendance, tracks extra-curricular activities, facilitates advanced project tracking, and integrates an NVIDIA NIM AI engine (Llama-3.1-70B) for generating quizzes and study plans. The predictive analytics use Logistic Regression, Random Forest, and XGBoost to classify student risk levels.

### 1.3 Definitions and Acronyms
* **JWT**: JSON Web Token
* **RBAC**: Role-Based Access Control
* **NIM**: NVIDIA Inference Microservices
* **SRS**: Software Requirements Specification
* **HOD**: Head of Department
* **CIA**: Continuous Internal Assessment

---

## 2. Overall Description

### 2.1 Product Perspective
EduPulse replaces manual and disparate college management spreadsheets by consolidating all aspects of student academics, project progress, and activities into a unified, reliable digital ecosystem. Through 8 distinct user roles, it supports all institutional stakeholders.

### 2.2 User Classes and Characteristics
The platform caters to 8 primary user roles:
1. **Admin**: System configuration and complete access.
2. **Principal / Vice Principal**: Institution-level oversight.
3. **HOD**: Department-level oversight and approvals.
4. **Class Advisor**: Class-specific performance analysis and alerts.
5. **Faculty / Staff**: Attendance entry, mark recording, and activity verification.
6. **Student**: View personal attendance, timetable, results, and AI-generated learning strategies.
7. **Parent**: Real-time view of child's academic and activity metrics.
8. **Guide / Coordinator**: Specific roles for managing Final Year Project batches and checkpoints.

### 2.3 Operating Environment
* **Backend**: Python 3.9+ environments running FastAPI.
* **Database**: PostgreSQL 12+.
* **Mobile App**: Android 8.0+ / iOS 12+ (built with Flutter).
* **Web App**: Modern standard-compliant web browsers (Chrome, Edge, Safari, Firefox).
* **Machine Learning Environment**: Python with Scikit-learn, XGBoost, Pandas.

---

## 3. System Features

### 3.1 Authentication and Role Management
* **Description**: Users must authenticate securely into the platform based on their institutional role.
* **Requirements**:
  * Secure JWT token-based authentication.
  * Role-based routing (RBAC) to ensure specific user interfaces are provided to matching roles.
  * PIN-based password recovery.
  * Full registration and admin-approval workflow for new users.

### 3.2 Academic and Activity Tracking
* **Description**: Complete CRUD capabilities for daily operations in an academic institution.
* **Requirements**:
  * Track daily attendance with sub-status options (Present, Absent, On Duty).
  * Calculate periodic attendance percentages.
  * Record marks across various phases (Assignments, Slip Tests, CIA 1 & 2, Model, and University).
  * Record co-curricular/extra-curricular activities by level (College, State, National, International).

### 3.3 Advanced AI and ML Integrations
* **Description**: Utilization of ML for risk prediction and AI for generative academic support.
* **Requirements**:
  * Apply Machine Learning classifications to determine "Low", "Medium", and "High" risk students using marks, attendance, and backlogs.
  * Utilize LLMs (Llama-3.1-70B-Instruct) via NVIDIA NIM to generate unit-specific adaptive quizzes (MCQ, MCS, NAT).
  * Generate personalized, dynamic weekly strategies based on skill gaps.
  * Display a 360-degree analytics profile detailing AI insights for every student.

### 3.4 Project Management and Batch Allocation
* **Description**: Extensive tracking of Final Year Projects for regulation compliance (e.g., Regulation 2021).
* **Requirements**:
  * Group students into project batches.
  * Assign project Guides and Coordinators to batches.
  * Track specific project roadmap milestones (e.g., Literature Survey, Review Checkpoints).
  * Grade and evaluate reviews directly within the batch management module.

### 3.5 Learning Mastery and Quiz System
* **Description**: Ensures active engagement with educational resources before summative assessment.
* **Requirements**:
  * Validate that students have completed assigned material before unlocking the Final Mastery Quiz.
  * Provide dynamic progress bars indicating material completion.

### 3.6 Reporting and Analytics
* **Description**: Systematized summaries of all stored data.
* **Requirements**:
  * Provide visual dashboards for Admins, HODs, and Class Advisors using dynamic charts.
  * Enable PDF and Excel export features for marks, participation, and attendance spreadsheets.

---

## 4. Non-Functional Requirements

### 4.1 Performance Requirements
* The Backend API must handle up to concurrent 200 HTTP requests rapidly without timing out.
* The Flutter application must run at 60 FPS on supported mobile devices to ensure a smooth UI experience.
* Real-time search in student lists and drop-down selectors must filter efficiently within 300ms.

### 4.2 Security Requirements
* All passwords must be securely hashed heavily (using Bcrypt) prior to storage.
* APIs must enforce strict CORS policies.
* Student data visibility must remain rigidly scoped to pertinent Guides, Advisors, HODs, and Admin explicitly.

### 4.3 Software Quality Attributes
* **Usability**: Material Design 3 guidelines shall be used to ensure high user-friendliness.
* **Maintainability**: Maintainable clean code architecture and modular Flutter widgets.
* **Scalability**: PostgreSQL utilization and structured database relationships (like `Reg_No` Foreign Keys) will ensure smooth scaling for multiple departments (CSE, ECE, EEE, etc.).

---

## 5. Technology Stack Overview

1. **Framework (Backend)**: FastAPI (Python 3.9+)
2. **Framework (Frontend)**: Flutter 3.0+
3. **Database**: PostgreSQL 12+ / SQLAlchemy ORM
4. **AI/ML Layer**: Scikit-Learn, XGBoost, NVIDIA NIM API, Joblib
5. **Additional Utilities**: PyJWT, passlib, Provider (Flutter state management), fl_chart

---
**End of Document**
