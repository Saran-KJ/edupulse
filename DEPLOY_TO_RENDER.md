# 🚀 Deploying EduPulse to Render

This guide will help you deploy the **EduPulse Backend** to [Render](https://render.com) and connect your mobile app to it.

## 1. Prepare for Deployment

### ✅ Check Requirements
Your `backend/requirements.txt` already includes `uvicorn` and `psycopg2-binary`, which are ready for Render!

### 📄 Create a `render.yaml` (Optional but Recommended)
You can create a `render.yaml` file in the root of your repository to automate deployment, but for now, we'll do it manually via the dashboard.

---

## 2. Deploy Backend to Render

1. **Push your code to GitHub** (if you haven't already).
2. **Sign up/Login to [Render](https://dashboard.render.com/)**.
3. Click **New +** -> **Web Service**.
4. Connect your GitHub repository.
5. **Configure the Service:**
   - **Name:** `edupulse-backend` (or any name)
   - **Region:** Choose the one closest to you (e.g., Singapore, Frankfurt)
   - **Branch:** `main` (or your working branch)
   - **Root Directory:** `backend` (Important! 👈)
   - **Runtime:** `Python 3`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`

6. **Environment Variables:**
   Scroll down to "Environment Variables" and add:
   - `PYTHON_VERSION`: `3.11.0` (or your local version)
   - `SECRET_KEY`: (Generate a random string or use the one from your local `.env`)
   - `DATABASE_URL`: (See step 3 below)

---

## 3. Set Up Database (PostgreSQL)

Since Render doesn't support persistent SQLite files well (they get deleted on redeploy), you should use **PostgreSQL**.

1. On Render Dashboard, click **New +** -> **PostgreSQL**.
2. **Name:** `edupulse-db`
3. **Region:** Same as your Web Service.
4. Click **Create Database**.
5. Once created, copy the **Internal Database URL**.
6. Go back to your **Web Service** -> **Environment** -> **Environment Variables**.
7. Add/Update `DATABASE_URL` with the value you copied.

> **Note:** The backend will automatically create tables when it starts!

---

## 4. Update Mobile App

Once your backend is live (e.g., `https://edupulse-backend.onrender.com`), you need to update the mobile app to talk to it.

1. Open `mobile/lib/config/app_config.dart`.
2. Update the `baseUrl`:

```dart
class AppConfig {
  static String get baseUrl {
    // Replace with your actual Render URL
    const String productionUrl = 'https://edupulse-backend.onrender.com';
    
    if (kReleaseMode) return productionUrl; // Use Render URL in release mode
    
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }
  // ...
}
```

3. **Build the APK:**
   ```bash
   cd mobile
   flutter build apk --release
   ```

---

## 5. Troubleshooting

- **Logs:** Check the "Logs" tab in Render if the deployment fails.
- **Health Check:** Visit `https://your-app-name.onrender.com/health` to verify it's running.
- **Docs:** Visit `https://your-app-name.onrender.com/docs` to see the Swagger UI.
