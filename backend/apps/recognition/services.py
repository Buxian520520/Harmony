"""
Face recognition business logic.
Orchestrates calls to the face-service microservice.
"""
import logging
from typing import Optional

from django.core.files.base import ContentFile
from django.conf import settings

from .client import FaceRecognitionClient
from .models import FaceImage, FaceEmbedding

logger = logging.getLogger(__name__)


class FaceRecognitionService:
    """Face recognition business logic"""

    def __init__(self):
        self.client = FaceRecognitionClient()

    def register_face(self, user, image_data: bytes) -> dict:
        """
        Register a user's face.
        1. Save the image locally
        2. Call face-service to register (detect → embedding → store)
        3. Save the embedding reference
        """
        # Save image
        face_image = FaceImage.objects.create(user=user)
        face_image.image.save(
            f'{user.id}_{face_image.id}.jpg',
            ContentFile(image_data),
        )

        # Call face-service
        result = self.client.register(image_data, user.id)

        if result.get('success'):
            # Save embedding reference
            FaceEmbedding.objects.update_or_create(
                user=user,
                defaults={
                    'face_image': face_image,
                    'embedding_id': result['face_id'],
                },
            )
            user.face_registered = True
            user.save(update_fields=['face_registered'])

        return result

    def verify_face(self, user, image_data: bytes) -> dict:
        """
        Verify a user's face against their registered face.
        """
        try:
            embedding = FaceEmbedding.objects.get(user=user)
        except FaceEmbedding.DoesNotExist:
            return {'is_match': False, 'error': '人脸未注册'}

        # Get the registered image
        if not embedding.face_image:
            return {'is_match': False, 'error': '无人脸注册图片'}

        with open(embedding.face_image.image.path, 'rb') as f:
            registered_image = f.read()

        return self.client.verify(registered_image, image_data)

    def identify_face(self, image_data: bytes, top_k: int = 5) -> list:
        """
        Identify a person from face image.
        Returns list of matched users.
        """
        result = self.client.identify(image_data, top_k=top_k)
        return result.get('matches', [])

    def check_service_health(self) -> bool:
        """Check if face recognition service is available"""
        try:
            result = self.client.health()
            return result.get('status') == 'ok'
        except Exception:
            return False
