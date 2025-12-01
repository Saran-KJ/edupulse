from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import schemas
import auth
import models

router = APIRouter(prefix="/api/admin", tags=["Admin"])

@router.post("/users", response_model=schemas.UserResponse)
async def create_user(
    user_data: schemas.AdminUserCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_admin)
):
    """Admin creates high-privilege user accounts"""
    # Check if user exists
    existing_user = db.query(models.User).filter(models.User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Create new user with immediate approval
    hashed_password = auth.get_password_hash(user_data.password)
    new_user = models.User(
        name=user_data.name,
        email=user_data.email,
        password=hashed_password,
        role=user_data.role,
        secret_pin=user_data.secret_pin,
        is_approved=1,  # Admin-created users are auto-approved
        is_active=1
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.get("/pending-users", response_model=List[schemas.PendingUserResponse])
async def get_pending_users(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_admin)
):
    """Get all pending registration requests"""
    pending_users = db.query(models.User).filter(models.User.is_approved == 0).all()
    return pending_users

@router.post("/approve-user/{user_id}")
async def approve_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_admin)
):
    """Approve a pending registration request"""
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_approved = 1
    db.commit()
    return {"message": f"User {user.name} approved successfully"}

@router.post("/reject-user/{user_id}")
async def reject_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_admin)
):
    """Reject and delete a pending registration request"""
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(user)
    db.commit()
    return {"message": f"User {user.name} rejected and removed"}

@router.get("/users", response_model=List[schemas.UserResponse])
async def get_all_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, le=500),
    role: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_admin)
):
    """Get all users with optional filtering"""
    query = db.query(models.User)
    
    if role:
        query = query.filter(models.User.role == role)
    
    users = query.offset(skip).limit(limit).all()
    return users

@router.put("/users/{user_id}", response_model=schemas.UserResponse)
async def update_user(
    user_id: int,
    user_data: schemas.UserUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_admin)
):
    """Update user information"""
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Update fields if provided
    if user_data.name is not None:
        user.name = user_data.name
    if user_data.email is not None:
        # Check if email already exists
        existing = db.query(models.User).filter(
            models.User.email == user_data.email,
            models.User.user_id != user_id
        ).first()
        if existing:
            raise HTTPException(status_code=400, detail="Email already in use")
        user.email = user_data.email
    if user_data.role is not None:
        user.role = user_data.role
    if user_data.is_active is not None:
        user.is_active = user_data.is_active
    
    db.commit()
    db.refresh(user)
    return user

@router.post("/users/{user_id}/reset-password")
async def admin_reset_password(
    user_id: int,
    new_password: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_admin)
):
    """Admin resets user password"""
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.password = auth.get_password_hash(new_password)
    db.commit()
    return {"message": f"Password reset for {user.name}"}

@router.post("/users/{user_id}/toggle-status")
async def toggle_user_status(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_admin)
):
    """Enable or disable user account"""
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Prevent admin from disabling themselves
    if user.user_id == current_user.user_id:
        raise HTTPException(status_code=400, detail="Cannot disable your own account")
    
    user.is_active = 1 if user.is_active == 0 else 0
    db.commit()
    
    status_text = "enabled" if user.is_active == 1 else "disabled"
    return {"message": f"User {user.name} {status_text}"}

@router.get("/login-logs", response_model=List[schemas.LoginLogResponse])
async def get_login_logs(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, le=500),
    success_only: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_admin)
):
    """Get login logs for security monitoring"""
    query = db.query(models.LoginLog)
    
    if success_only is not None:
        query = query.filter(models.LoginLog.success == (1 if success_only else 0))
    
    logs = query.order_by(models.LoginLog.timestamp.desc()).offset(skip).limit(limit).all()
    return logs

@router.delete("/users/{user_id}")
async def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.require_admin)
):
    """Delete a user account"""
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Prevent admin from deleting themselves
    if user.user_id == current_user.user_id:
        raise HTTPException(status_code=400, detail="Cannot delete your own account")
    
    user_name = user.name
    db.delete(user)
    db.commit()
    return {"message": f"User {user_name} deleted successfully"}
