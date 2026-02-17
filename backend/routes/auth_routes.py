from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
from database import get_db
from config import get_settings
import schemas
import auth
import models

router = APIRouter(prefix="/api/auth", tags=["Authentication"])
settings = get_settings()

@router.post("/login", response_model=schemas.Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db), request: Request = None):
    result = auth.authenticate_user(db, form_data.username, form_data.password)
    
    # Handle tuple return (user, error_message) or False
    if isinstance(result, tuple):
        user, error_msg = result
        if user:
            # Successful login
            auth.log_login_attempt(
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
        secret_pin=user.secret_pin,
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

@router.post("/forgot-password")
async def forgot_password(reset_data: schemas.PasswordReset, db: Session = Depends(get_db)):
    # Find user by email
    user = db.query(models.User).filter(models.User.email == reset_data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Verify secret PIN
    if not user.secret_pin or user.secret_pin != reset_data.secret_pin:
        raise HTTPException(status_code=400, detail="Invalid secret PIN")
    
    # Update password
    user.password = auth.get_password_hash(reset_data.new_password)
    db.commit()
    
    return {"message": "Password reset successful"}

@router.get("/me", response_model=schemas.UserResponse)
async def read_users_me(current_user = Depends(auth.get_current_active_user)):
    return current_user
