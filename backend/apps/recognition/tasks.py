import logging

from celery import shared_task
from django.core.files.base import ContentFile

from .client import FaceRecognitionClient

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=5)
def async_register_face(self, user_id: int, image_data: bytes):
    """
    Async face registration task.
    Called by Celery when a user uploads a face image.
    """
    from django.contrib.auth import get_user_model
    from .models import FaceImage, FaceEmbedding

    User = get_user_model()
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        logger.error(f'User {user_id} not found')
        return {'success': False, 'error': 'User not found'}

    try:
        client = FaceRecognitionClient()
        result = client.register(image_data, user_id)

        if result.get('success'):
            # Save image
            face_image = FaceImage.objects.create(user=user)
            face_image.image.save(
                f'{user_id}_face.jpg',
                ContentFile(image_data),
            )

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

    except Exception as exc:
        logger.exception(f'Face registration failed for user {user_id}')
        raise self.retry(exc=exc)
