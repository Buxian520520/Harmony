from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .apis.checkin import CheckinViewSet
from .apis.leave import LeaveViewSet
from .apis.statistics import StatisticsViewSet

router = DefaultRouter()
router.register(r'checkin', CheckinViewSet, basename='checkin')
router.register(r'leave', LeaveViewSet, basename='leave')
router.register(r'statistics', StatisticsViewSet, basename='statistics')

urlpatterns = [
    path('', include(router.urls)),
    path('courses/', include('apps.attendance.apis.course_urls')),
]
