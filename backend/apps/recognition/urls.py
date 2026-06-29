from django.urls import path
from . import views

urlpatterns = [
    path('register/', views.face_register, name='face-register'),
    path('verify/', views.face_verify, name='face-verify'),
    path('identify/', views.face_identify, name='face-identify'),
    path('health/', views.face_service_health, name='face-health'),
]
