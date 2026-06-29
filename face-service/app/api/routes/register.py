"""Face registration endpoint.
TODO: Paste your face registration code here.
"""
from fastapi import APIRouter, UploadFile, File, Form, HTTPException

router = APIRouter()


@router.post("/register")
async def register_face(
    image: UploadFile = File(...),
    user_id: int = Form(...),
):
    """
    Register a face: detect → extract embedding → store in vector DB.
    
    TODO: Implement using GitHub code (ArcFace / FaceNet embedding extraction)
    """
    raise HTTPException(
        status_code=501,
        detail="Not implemented yet. Paste your face registration code from GitHub.",
    )


@router.delete("/register/{face_id}")
async def delete_face(face_id: str):
    """Delete a registered face from the vector store."""
    raise HTTPException(
        status_code=501,
        detail="Not implemented yet.",
    )
