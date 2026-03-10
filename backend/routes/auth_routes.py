from fastapi import APIRouter, Depends, HTTPException, status, Request, BackgroundTasks
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import random
from database import get_db
from config import get_settings
import schemas
import auth
import models

router = APIRouter(prefix="/api/auth", tags=["Authentication"])
settings = get_settings()

@router.post("/login", response_model=schemas.Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db), request: Request = None, background_tasks: BackgroundTasks = None):
    result = auth.authenticate_user(db, form_data.username, form_data.password)
    
    # Handle tuple return (user, error_message) or False
    if isinstance(result, tuple):
        user, error_msg = result
        if user:
            # Successful login — log in background (non-blocking)
            if background_tasks:
                background_tasks.add_task(
                    auth.log_login_attempt,
                    db, form_data.username, True, user.user_id,
                    ip_address=request.client.host if request else None
                )
            access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
            access_token = auth.create_access_token(
                data={"sub": user.email}, expires_delta=access_token_expires
            )
            return {"access_token": access_token, "token_type": "bearer"}
        else:
            # Failed login with reason
            auth.log_login_attempt(
                db, form_data.username, False,
                failure_reason=error_msg,
                ip_address=request.client.host if request else None
            )
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=error_msg,
                headers={"WWW-Authenticate": "Bearer"},
            )
    else:
        # Old-style False return
        auth.log_login_attempt(
            db, form_data.username, False,
            failure_reason="Authentication failed",
            ip_address=request.client.host if request else None
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

@router.post("/register", response_model=schemas.UserResponse)
async def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # Block registration for high-privilege roles
    high_privilege_roles = [
        models.RoleEnum.HOD,
        models.RoleEnum.VICE_PRINCIPAL,
        models.RoleEnum.PRINCIPAL,
        models.RoleEnum.ADMIN
    ]
    
    if user.role in high_privilege_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Cannot self-register as {user.role}. Contact administrator."
        )
    
    # Check if user exists
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Create new user with approval pending for self-registration
    hashed_password = auth.get_password_hash(user.password)
    db_user = models.User(
        name=user.name,
        email=user.email,
        password=hashed_password,
        role=user.role,
        reg_no=user.reg_no,
        phone=user.phone,
        dept=user.dept,
        year=user.year,
        section=user.section,
        # Parent-specific fields
        child_name=user.child_name,
        child_phone=user.child_phone,
        child_reg_no=user.child_reg_no,
        occupation=user.occupation,
        is_approved=0,  # Pending approval
        is_active=1     # Active but needs approval
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.post("/forgot-password/request-otp")
async def request_password_reset_otp(request_data: schemas.PasswordResetRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == request_data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Generate 6-digit OTP
    otp = "".join([str(random.randint(0, 9)) for _ in range(6)])
    
    # Expire in 10 minutes
    expires_at = datetime.utcnow() + timedelta(minutes=10)
    
    # Delete existing OTPs for this email to prevent spam/clutter
    db.query(models.PasswordReset).filter(models.PasswordReset.email == request_data.email).delete()
    
    reset_entry = models.PasswordReset(
        email=request_data.email,
        otp=otp,
        expires_at=expires_at
    )
    db.add(reset_entry)
    db.commit()
    
    # Send email
    email_sent = auth.send_otp_email(request_data.email, otp)
    if not email_sent:
        raise HTTPException(status_code=500, detail="Failed to send OTP email. Please check server configuration.")
        
    return {"message": "OTP sent successfully to your email"}

@router.post("/forgot-password/verify-otp")
async def verify_password_reset_otp(verify_data: schemas.PasswordResetVerify, db: Session = Depends(get_db)):
    # Find OTP
    reset_entry = db.query(models.PasswordReset).filter(
        models.PasswordReset.email == verify_data.email,
        models.PasswordReset.otp == verify_data.otp
    ).first()
    
    if not reset_entry:
        raise HTTPException(status_code=400, detail="Invalid OTP")
        
    if reset_entry.expires_at < datetime.utcnow():
        raise HTTPException(status_code=400, detail="OTP has expired")
        
    return {"message": "OTP verified successfully"}

@router.post("/forgot-password/confirm")
async def confirm_password_reset(confirm_data: schemas.PasswordResetConfirm, db: Session = Depends(get_db)):
    # Verify OTP again to be secure
    reset_entry = db.query(models.PasswordReset).filter(
        models.PasswordReset.email == confirm_data.email,
        models.PasswordReset.otp == confirm_data.otp
    ).first()
    
    if not reset_entry:
        raise HTTPException(status_code=400, detail="Invalid OTP")
        
    if reset_entry.expires_at < datetime.utcnow():
        raise HTTPException(status_code=400, detail="OTP has expired")
        
    # Update password
    user = db.query(models.User).filter(models.User.email == confirm_data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.password = auth.get_password_hash(confirm_data.new_password)
    
    # Clean up OTP
    db.delete(reset_entry)
    db.commit()
    
    return {"message": "Password reset successful"}

@router.get("/me", response_model=schemas.UserResponse)
async def read_users_me(current_user = Depends(auth.get_current_active_user)):
    return current_user
