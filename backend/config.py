from pydantic_settings import BaseSettings
from pydantic import Field
from functools import lru_cache

class Settings(BaseSettings):
    database_url: str = "postgresql://postgres:password@localhost:5432/edupulse"
    secret_key: str = "your-secret-key-change-this-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    smtp_email: str = "edupulsesmartlearn@gmail.com"
    smtp_password: str = ""
    youtube_api_key: str = ""
    nvidia_api_key: str = ""
    gemini_api_key: str = ""
    skill_gemini_api_key: str = Field(default="", validation_alias="skill_development")
    programming_api_key: str = Field(default="", validation_alias="Programming")
    ollama_model: str = Field(default="qwen2.5:3b", validation_alias="OLLAMA_MODEL")
    ollama_base_url: str = Field(default="http://localhost:11434", validation_alias="OLLAMA_BASE_URL")
    opencode_base_url: str = Field(default="http://localhost:25725/v1", validation_alias="OPENCODE_BASE_URL")
    
    model_config = {
        "env_file": ".env",
        "extra": "ignore"  # Allow extra fields in .env without crashing
    }

@lru_cache()
def get_settings():
    return Settings()
