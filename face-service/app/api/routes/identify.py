"""1:N face identification endpoint.
TODO: Paste your face identification code here.
"""
from fastapi import APIRouter, UploadFile, File, Form, HTTPException

router = APIRouter()


@router.post("/identify")
async def identify_face(
    image: UploadFile = File(...),
    top_k: int = Form(5),
):
    """
    1:N Face identification - find top-K matches from registered faces.
    
    TODO: Implement using GitHub code (embedding extraction + FAISS search)
    """
    raise HTTPException(
        status_code=501,
        detail="Not implemented yet. Paste your face identification code from GitHub.",
    )
