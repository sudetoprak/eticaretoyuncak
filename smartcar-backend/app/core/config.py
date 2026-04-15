from pydantic_settings import BaseSettings
from typing import List
import json


class Settings(BaseSettings):
    MONGO_URI: str = "mongodb://localhost:27017"
    MONGO_DB: str = "smartcar"
    SECRET_KEY: str = "change-this-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    REDIS_URL: str = "redis://localhost:6379"
    CORS_ORIGINS: str = '["http://localhost:3000"]'
    RATE_LIMIT_PER_MINUTE: int = 60
    WS_RATE_LIMIT_PER_MINUTE: int = 120
    ENVIRONMENT: str = "development"
    CAR_DEVICE_SECRET: str = "smartcar-esp32-secret-2024"

    @property
    def cors_origins_list(self) -> List[str]:
        return json.loads(self.CORS_ORIGINS)

    class Config:
        env_file = ".env"


settings = Settings()