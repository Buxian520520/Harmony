"""
Face Recognition Service Client
================================
HTTP client that calls the face-service (FastAPI + PyTorch).
All face recognition logic is delegated to the microservice.
"""
import logging
from typing import Optional

import httpx
from django.conf import settings

logger = logging.getLogger(__name__)


class FaceRecognitionClient:
    """
    Client for the face recognition microservice.
    
    API Contract (face-service endpoints):
        POST /api/v1/detect      - Face detection
        POST /api/v1/register    - Register face (upload → detect → embedding → store)
        POST /api/v1/verify      - 1:1 face verification
        POST /api/v1/identify    - 1:N face identification
        GET  /api/v1/health      - Health check
    """

    def __init__(self):
        self.base_url = settings.FACE_SERVICE_URL
        self.api_key = settings.FACE_SERVICE_API_KEY
        self.timeout = 30.0
        self.client = httpx.Client(
            base_url=self.base_url,
            headers={'X-API-Key': self.api_key},
            timeout=self.timeout,
        )

    def health(self) -> dict:
        """Check if face-service is alive"""
        try:
            resp = self.client.get('/api/v1/health')
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.error(f'Face service health check failed: {e}')
            return {'status': 'unreachable', 'error': str(e)}

    def detect(self, image_bytes: bytes) -> dict:
        """
        Detect faces in an image.
        
        Args:
            image_bytes: Raw image data (JPEG/PNG)
            
        Returns:
            { 'faces': [{'bbox': [x1,y1,x2,y2], 'landmarks': [...]}, ...] }
        """
        resp = self.client.post(
            '/api/v1/detect',
            files={'image': image_bytes},
        )
        resp.raise_for_status()
        return resp.json()

    def register(self, image_bytes: bytes, user_id: int) -> dict:
        """
        Register a face: detect → extract embedding → store in vector DB.
        
        Args:
            image_bytes: Raw image data
            user_id: User ID in Django
            
        Returns:
            { 'face_id': str, 'embedding_dim': int, 'success': bool }
        """
        resp = self.client.post(
            '/api/v1/register',
            files={'image': image_bytes},
            data={'user_id': user_id},
        )
        resp.raise_for_status()
        return resp.json()

    def verify(self, image1_bytes: bytes, image2_bytes: bytes) -> dict:
        """
        1:1 face verification - check if two images are the same person.
        
        Returns:
            { 'is_match': bool, 'confidence': float, 'distance': float }
        """
        resp = self.client.post(
            '/api/v1/verify',
            files={'image1': image1_bytes, 'image2': image2_bytes},
        )
        resp.raise_for_status()
        return resp.json()

    def identify(self, image_bytes: bytes, top_k: int = 5) -> dict:
        """
        1:N face identification - find top-K matches.
        
        Returns:
            { 'matches': [{'user_id': int, 'confidence': float, 'distance': float}, ...] }
        """
        resp = self.client.post(
            '/api/v1/identify',
            files={'image': image_bytes},
            data={'top_k': top_k},
        )
        resp.raise_for_status()
        return resp.json()

    def delete_face(self, face_id: str) -> dict:
        """Delete a registered face by face_id"""
        resp = self.client.delete(f'/api/v1/register/{face_id}')
        resp.raise_for_status()
        return resp.json()
