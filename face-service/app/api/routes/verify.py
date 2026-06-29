"""1:1 face verification endpoint.
TODO: Paste your face verification code here.
"""
from fastapi import APIRouter, UploadFile, File, HTTPException

router = APIRouter()


@router.post("/verify")
async def verify_faces(
    image1: UploadFile = File(...),
    image2: UploadFile = File(...),
):
    """
    1:1 Face verification - check if two images are the same person.
    
    TODO: Implement using GitHub code (embedding extraction + cosine similarity)
    """
    raise HTTPException(
        status_code=501,
        detail="Not implemented yet. Paste your face verification code from GitHub.",
    )
