from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    database_url: str = "postgresql://postgres:password@localhost:5432/edupulse"
    secret_key: str = "your-secret-key-change-this-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    smtp_email: str = "edupulsesmartlearn@gmail.com"
    smtp_password: str = ""
    youtube_api_key: str = ""
    gemini_api_key: str = ""
    
    class Config:
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()
