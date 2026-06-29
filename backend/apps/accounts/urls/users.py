from django.urls import path, include
from rest_framework.routers import DefaultRouter

from ..apis.users import UserViewSet

router = DefaultRouter()
router.register(r'', UserViewSet, basename='users')

urlpatterns = [
    path('me/', UserViewSet.as_view({'get': 'me', 'patch': 'update_me'}), name='users-me'),
    path('', include(router.urls)),
]
