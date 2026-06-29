"""
Face Recognition Microservice
FastAPI + PyTorch entry point.
TODO: Paste your GitHub face recognition code into app/models/ and app/api/routes/
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.api.routes import health, detect, register, verify, identify

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle: load models on startup, cleanup on shutdown."""
    logger.info("Face recognition service starting up...")
    # TODO: Load models here when you paste the GitHub code
    # from app.models.registry import ModelRegistry
    # app.state.model_registry = ModelRegistry()
    # app.state.model_registry.load_all()
    yield
    logger.info("Face recognition service shutting down...")
    # TODO: Cleanup


app = FastAPI(
    title="Face Recognition Service",
    description="PyTorch face recognition microservice for attendance system",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(health.router, prefix="/api/v1", tags=["health"])
app.include_router(detect.router, prefix="/api/v1", tags=["detect"])
app.include_router(register.router, prefix="/api/v1", tags=["register"])
app.include_router(verify.router, prefix="/api/v1", tags=["verify"])
app.include_router(identify.router, prefix="/api/v1", tags=["identify"])


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8001, reload=True)
