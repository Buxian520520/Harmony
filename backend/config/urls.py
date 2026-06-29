"""
Main URL configuration for the attendance project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/auth/', include('apps.accounts.urls.auth')),
    path('api/v1/users/', include('apps.accounts.urls.users')),
    path('api/v1/attendance/', include('apps.attendance.urls')),
    path('api/v1/recognition/', include('apps.recognition.urls')),
    path('api/v1/notifications/', include('apps.notification.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
