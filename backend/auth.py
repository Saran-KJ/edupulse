from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
import bcrypt
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from config import get_settings
from database import get_db
import models
import schemas

settings = get_settings()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt

def authenticate_user(db: Session, email: str, password: str):
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        return False, "User not found"
    if not verify_password(password, user.password):
        return False, "Incorrect password"
    if user.is_approved == 0:
        return False, "Account pending approval"
    if user.is_active == 0:
        return False, "Account disabled"
    return user, None

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    return await verify_token(token, db)

async def get_current_user_from_query(token: str, db: Session = Depends(get_db)):
    """Authenticate user from query parameter token"""
    return await verify_token(token, db)

async def verify_token(token: str, db: Session):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = schemas.TokenData(email=email)
    except JWTError:
        raise credentials_exception
    user = db.query(models.User).filter(models.User.email == token_data.email).first()
    if user is None:
        raise credentials_exception
    return user

async def get_current_active_user(current_user: models.User = Depends(get_current_user)):
    if current_user.is_active == 0:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is disabled"
        )
    if current_user.is_approved == 0:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account pending approval"
        )
    return current_user

def log_login_attempt(db: Session, email: str, success: bool, user_id: Optional[int] = None, 
                     failure_reason: Optional[str] = None, ip_address: Optional[str] = None,
                     user_agent: Optional[str] = None):
    """Log all login attempts for security monitoring"""
    log_entry = models.LoginLog(
        user_id=user_id,
        email=email,
        success=1 if success else 0,
        ip_address=ip_address,
        user_agent=user_agent,
        failure_reason=failure_reason
    )
    db.add(log_entry)
    db.commit()

def require_role(allowed_roles: list):
    def role_checker(current_user: models.User = Depends(get_current_active_user)):
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not enough permissions"
            )
        return current_user
    return role_checker

def require_admin(current_user: models.User = Depends(get_current_active_user)):
    """Decorator to require admin role"""
    if current_user.role != models.RoleEnum.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user

def send_otp_email(to_email: str, otp: str):
    """Send OTP via email for password reset."""
    if not settings.smtp_password:
        print("Warning: SMTP password not set, skipping email sending.")
        return False
        
    sender_email = settings.smtp_email
    sender_password = settings.smtp_password

    # Create the email message
    message = MIMEMultipart("alternative")
    message["Subject"] = "Your Verification Code - EduPulse"
    message["From"] = sender_email
    message["To"] = to_email

    # Email body
    text = f"""\
    Hello,
    
    You have requested to reset your password.
    Your verification code is: {otp}
    
    This code is valid for 10 minutes.
    If you did not request this, please ignore this email.
    
    Regards,
    EduPulse Team
    """
    
    html = f"""\
    <html>
      <body>
        <h2>Password Reset Verification</h2>
        <p>Hello,</p>
        <p>You have requested to reset your password.</p>
        <p>Your verification code is: <strong><span style="font-size: 24px;">{otp}</span></strong></p>
        <p>This code is valid for 10 minutes.</p>
        <p><em>If you did not request this, please ignore this email.</em></p>
        <br>
        <p>Regards,<br>EduPulse Team</p>
      </body>
    </html>
    """

    part1 = MIMEText(text, "plain")
    part2 = MIMEText(html, "html")
    message.attach(part1)
    message.attach(part2)

    try:
        # Connect to Gmail SMTP server
        server = smtplib.SMTP_SSL("smtp.gmail.com", 465)
        server.login(sender_email, sender_password)
        server.sendmail(sender_email, to_email, message.as_string())
        server.quit()
        return True
    except Exception as e:
        print(f"Error sending email: {e}")
        return False
