from django.urls import path
from rest_framework.routers import DefaultRouter

from ..apis.auth import LoginView, RegisterViewSet, LogoutView

urlpatterns = [
    path('login/', LoginView.as_view(), name='auth-login'),
    path('register/', RegisterViewSet.as_view({'post': 'create'}), name='auth-register'),
    path('logout/', LogoutView.as_view({'post': 'create'}), name='auth-logout'),
]
