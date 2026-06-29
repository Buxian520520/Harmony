"""Custom exceptions and error handlers."""
from fastapi import Request
from fastapi.responses import JSONResponse


class FaceServiceError(Exception):
    """Base face service exception."""
    def __init__(self, message: str, status_code: int = 500):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class NoFaceDetectedError(FaceServiceError):
    def __init__(self):
        super().__init__("No face detected in the image", status_code=400)


class MultipleFacesError(FaceServiceError):
    def __init__(self):
        super().__init__("Multiple faces detected, please provide a single face image", status_code=400)


class FaceNotRegisteredError(FaceServiceError):
    def __init__(self):
        super().__init__("Face not registered in database", status_code=404)


async def face_service_exception_handler(request: Request, exc: FaceServiceError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.message},
    )
