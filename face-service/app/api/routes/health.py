"""Health check endpoint."""
from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def health_check():
    """Health check - always returns ok even without models loaded."""
    return {
        "status": "ok",
        "service": "face-recognition",
        "version": "0.1.0",
        "models_loaded": False,  # TODO: update when models are loaded
    }
