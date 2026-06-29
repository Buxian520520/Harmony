"""Application configuration."""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="FACE_SERVICE_",
        extra="ignore",
    )

    app_name: str = "Face Recognition Service"
    api_key: str = "dev-api-key"
    model_dir: str = "model_weights"
    vector_store_path: str = "data/faiss_index.bin"
    embedding_dim: int = 512
    confidence_threshold: float = 0.6
    debug: bool = True


settings = Settings()
