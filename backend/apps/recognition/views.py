import logging

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .services import FaceRecognitionService

logger = logging.getLogger(__name__)
service = FaceRecognitionService()


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def face_register(request):
    """注册人脸"""
    if 'image' not in request.FILES:
        return Response({'error': '请上传人脸图片'}, status=status.HTTP_400_BAD_REQUEST)

    image_file = request.FILES['image']
    image_data = image_file.read()

    try:
        result = service.register_face(request.user, image_data)
        return Response(result)
    except Exception as e:
        logger.exception('Face register failed')
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def face_verify(request):
    """人脸验证（1:1）"""
    if 'image' not in request.FILES:
        return Response({'error': '请上传人脸图片'}, status=status.HTTP_400_BAD_REQUEST)

    image_data = request.FILES['image'].read()

    try:
        result = service.verify_face(request.user, image_data)
        return Response(result)
    except Exception as e:
        logger.exception('Face verify failed')
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def face_identify(request):
    """人脸识别（1:N）"""
    if 'image' not in request.FILES:
        return Response({'error': '请上传人脸图片'}, status=status.HTTP_400_BAD_REQUEST)

    image_data = request.FILES['image'].read()
    top_k = request.data.get('top_k', 5)

    try:
        matches = service.identify_face(image_data, top_k=int(top_k))
        return Response({'matches': matches})
    except Exception as e:
        logger.exception('Face identify failed')
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def face_service_health(request):
    """人脸服务健康检查"""
    is_healthy = service.check_service_health()
    return Response({
        'service_available': is_healthy,
        'message': '服务正常' if is_healthy else '人脸识别服务暂不可用',
    })
