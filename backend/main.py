from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
import models

# Import routes
from routes import (
    auth_routes,
    student_routes,
    mark_routes,
    attendance_routes,
    activity_routes,
    analytics_routes,
    prediction_routes,
    admin_routes,
    report_routes,
    faculty_routes,
    hod_routes,
    learning_routes,
    subject_routes,
    quiz_routes,
    project_routes,
    content_routes,
    opencode_routes
)

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="EduPulse API",
    description="AI-Powered Student 360° Performance & Activity Management System",
    version="1.0.0"
)

# CORS middleware - Fixed for Flutter Web (avoid wildcard + credentials conflict)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex="https?://.*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    max_age=3600,
)

# Include routers
app.include_router(auth_routes.router)
app.include_router(student_routes.router)
app.include_router(mark_routes.router)
app.include_router(attendance_routes.router)
app.include_router(activity_routes.router)
app.include_router(analytics_routes.router)
app.include_router(prediction_routes.router)
app.include_router(admin_routes.router)
app.include_router(report_routes.router)
app.include_router(faculty_routes.router)
app.include_router(hod_routes.router)
app.include_router(learning_routes.router, prefix="/api/learning", tags=["Learning"])
app.include_router(subject_routes.router)
app.include_router(quiz_routes.router)
app.include_router(content_routes.router)
app.include_router(opencode_routes.router)
app.include_router(project_routes.router)

@app.get("/")
async def root():
    return {
        "message": "Welcome to EduPulse API",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
