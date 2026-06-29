"""Face detection endpoint.
TODO: Paste your face detection code here.
"""
from fastapi import APIRouter, UploadFile, File, HTTPException
from app.core.exceptions import NoFaceDetectedError

router = APIRouter()


@router.post("/detect")
async def detect_faces(image: UploadFile = File(...)):
    """
    Detect faces in an image.
    
    Returns bounding boxes and landmarks for each detected face.
    
    TODO: Implement using GitHub code (RetinaFace / MTCNN / YOLO-face)
    """
    raise HTTPException(
        status_code=501,
        detail="Not implemented yet. Paste your face detection code from GitHub.",
    )
