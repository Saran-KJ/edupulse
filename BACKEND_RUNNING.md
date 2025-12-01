# 🎉 EduPulse Backend is Running!

## ✅ Successfully Started

**Backend Server:** http://localhost:8000  
**API Documentation:** http://localhost:8000/docs  
**Alternative Docs:** http://localhost:8000/redoc  

---

## 🔑 Login Credentials

### Admin Account
- **Email:** `admin@edupulse.com`
- **Password:** `admin123`

### Staff Account
- **Email:** `staff@edupulse.com`
- **Password:** `staff123`

---

## 👥 Sample Data Loaded

### Students
1. **Rahul Kumar** - Reg No: 2021CSE001
2. **Priya Sharma** - Reg No: 2021CSE002
3. **Amit Patel** - Reg No: 2021CSE003

### Data Includes
- ✅ Student profiles
- ✅ Marks records (internal & external)
- ✅ Attendance records
- ✅ Activities and participations
- ✅ Departments (CSE, ECE, MECH)
- ✅ Subjects

---

## 🧪 Test the API

### Option 1: Using Swagger UI (Recommended)
1. Open: http://localhost:8000/docs
2. Click "Authorize" button
3. Login with:
   - **username:** `admin@edupulse.com`
   - **password:** `admin123`
4. Copy the `access_token` from response
5. Paste in authorization dialog
6. Test any endpoint!

### Option 2: Using curl
```bash
# Login
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin@edupulse.com&password=admin123"

# Get students (use token from login)
curl -X GET "http://localhost:8000/api/students" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 📊 Available API Endpoints

### Authentication
- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Register user
- `GET /api/auth/me` - Get current user

### Students
- `GET /api/students` - List students
- `POST /api/students` - Create student
- `GET /api/students/{id}` - Get student
- `GET /api/students/{id}/profile` - Get 360° profile
- `PUT /api/students/{id}` - Update student
- `DELETE /api/students/{id}` - Delete student

### Marks
- `POST /api/marks` - Add marks
- `GET /api/marks/student/{id}` - Get student marks

### Attendance
- `POST /api/attendance` - Record attendance
- `GET /api/attendance/student/{id}` - Get attendance

### Activities
- `POST /api/activities` - Create activity
- `GET /api/activities` - List activities
- `POST /api/activities/participation` - Record participation

### Analytics
- `GET /api/analytics/dashboard` - Dashboard stats
- `GET /api/analytics/department/{id}` - Department analytics

### ML Predictions
- `POST /api/predict/risk` - Predict student risk
- `GET /api/predict/at-risk-students` - List at-risk students

---

## 🔧 Configuration

### Database
- **Type:** SQLite
- **File:** `e:\final-year-project-demo\backend\edupulse.db`

### Secret Key
- **Generated:** `FiSdFNJpkAKEUGsYDyyYa5OjyfOu3-LCOW9jxhXVTxE`
- **Location:** `e:\final-year-project-demo\backend\.env`

### ML Model
- **Status:** Using rule-based fallback (no trained model yet)
- **Features:** Attendance %, internal marks, GPA, activities, backlogs
- **Output:** Risk level (Low/Medium/High) + score + reasons

---

## 📱 Next Steps

### 1. Run Flutter Mobile App
```bash
cd e:\final-year-project-demo\mobile
flutter pub get
# Update lib/config/app_config.dart baseUrl to: http://10.0.2.2:8000
flutter run
```

### 2. Train ML Model (Optional)
```bash
cd e:\final-year-project-demo\ml_models
pip install -r requirements.txt
python generate_sample_data.py
python train_model.py
```

### 3. Test the System
- Login to API docs
- Create new students
- Add marks and attendance
- Test risk prediction
- View analytics

---

## 🛑 To Stop the Server

Press `CTRL+C` in the terminal where the server is running

---

## 📚 Documentation

- **Main README:** `e:\final-year-project-demo\README.md`
- **Backend Setup:** `e:\final-year-project-demo\backend\SETUP.md`
- **Mobile App:** `e:\final-year-project-demo\mobile\README.md`
- **ML Models:** `e:\final-year-project-demo\ml_models\README.md`

---

**🎉 Your EduPulse backend is ready to use!**
