# 環境變數設定：用 pydantic BaseSettings 集中管理所有外部設定
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    GEMINI_API_KEY: str
    DATABASE_URL: str = ""  # postgresql+asyncpg://user:pass@host:port/db
    CHROMA_HOST: str = "localhost"
    CHROMA_PORT: int = 8000
    ENVIRONMENT: str = "development"  # development / production

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
