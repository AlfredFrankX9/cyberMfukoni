import os
from dotenv import load_dotenv
load_dotenv()
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Cyber Mfukoni 2.0 API"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "super-secret-key-change-me-in-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 days
    
    SQLALCHEMY_DATABASE_URI: str = os.getenv("DATABASE_URL", "postgresql://postgres:password@localhost:5433/cybermfukoni")
    
    GEMINI_API_KEY: str = ""
    DATABASE_URL: str = "postgresql://postgres:password@localhost:5433/cybermfukoni"
    GNEWS_API_KEY: str = ""
    VIRUSTOTAL_API_KEY: str = ""
    
    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
