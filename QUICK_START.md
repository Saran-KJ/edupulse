# EduPulse - Quick Start Guide

## 🚀 Getting Started

### Step 1: Install PostgreSQL (if not installed)

Download and install PostgreSQL from: https://www.postgresql.org/download/windows/

During installation, remember your postgres password!

### Step 2: Create Database

Open **pgAdmin** or **psql** and run:

```sql
CREATE DATABASE edupulse;
```

### Step 3: Update Database Connection

Edit `backend\.env` file and update the DATABASE_URL with your PostgreSQL password:

```
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/edupulse
```

Replace `YOUR_PASSWORD` with your actual PostgreSQL password.

### Step 4: Install Backend Dependencies (Currently Running)

The installation is in progress. This may take 5-10 minutes.

### Step 5: Initialize Database with Sample Data

Once dependencies are installed, run:

```bash
cd e:\final-year-project-demo\backend
venv\Scripts\python init_db.py
```

This will create:
- Admin user: admin@edupulse.com / admin123
- Staff user: staff@edupulse.com / staff123
- 3 sample students with data

### Step 6: Start Backend Server

```bash
venv\Scripts\python main.py
```

Server will start at: http://localhost:8000
API Docs: http://localhost:8000/docs

### Step 7: Train ML Model (Optional but Recommended)

Open a new terminal:

```bash
cd e:\final-year-project-demo\ml_models
pip install -r requirements.txt
python generate_sample_data.py
python train_model.py
```

### Step 8: Run Flutter Mobile App

Open a new terminal:

```bash
cd e:\final-year-project-demo\mobile
flutter pub get
flutter run
```

**Important:** Update `lib/config/app_config.dart` with correct backend URL:
- For Android Emulator: `http://10.0.2.2:8000`
- For real device: `http://YOUR_COMPUTER_IP:8000`

---

## ⚠️ Common Issues

### Issue: "Database connection error"
**Solution:** Make sure PostgreSQL is running and DATABASE_URL in .env is correct

### Issue: "Port 8000 already in use"
**Solution:** Kill the process or change port in main.py

### Issue: "Module not found"
**Solution:** Make sure virtual environment is activated and dependencies are installed

---

## 📞 Need Help?

Check the detailed guides:
- Backend: `backend\SETUP.md`
- ML Models: `ml_models\README.md`
- Mobile App: `mobile\README.md`

---

**Current Status:** Installing backend dependencies... ⏳
