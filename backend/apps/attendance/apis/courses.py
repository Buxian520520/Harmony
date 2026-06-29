from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsAdminOrTeacher, IsStudent, IsAdmin
from ..models import Course, CourseEnrollment
from ..serializers import CourseSerializer, CourseCreateSerializer, CourseEnrollmentSerializer


class CourseViewSet(viewsets.ModelViewSet):
    """课程管理 API"""
    queryset = Course.objects.all()
    filterset_fields = ['teacher', 'is_active', 'semester']

    def get_serializer_class(self):
        if self.action == 'create' or self.action in ('update', 'partial_update'):
            return CourseCreateSerializer
        return CourseSerializer

    def get_permissions(self):
        if self.action in ('create', 'destroy', 'update', 'partial_update'):
            return [IsAdminOrTeacher()]
        if self.action in ('enroll', 'unenroll'):
            return [IsAuthenticated(), IsStudent()]
        return [IsAuthenticated()]

    @action(detail=True, methods=['post'])
    def enroll(self, request, pk=None):
        """学生选课"""
        course = self.get_object()
        if CourseEnrollment.objects.filter(student=request.user, course=course).exists():
            return Response({'error': '已选修该课程'}, status=status.HTTP_400_BAD_REQUEST)
        enrollment = CourseEnrollment.objects.create(student=request.user, course=course)
        return Response(CourseEnrollmentSerializer(enrollment).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def unenroll(self, request, pk=None):
        """学生退选"""
        course = self.get_object()
        deleted, _ = CourseEnrollment.objects.filter(student=request.user, course=course).delete()
        if deleted:
            return Response({'detail': '退选成功'})
        return Response({'error': '未选修该课程'}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'])
    def enrolled_students(self, request, pk=None):
        """查看课程选课学生列表（教师/管理员）"""
        course = self.get_object()
        enrollments = CourseEnrollment.objects.filter(course=course)
        return Response(CourseEnrollmentSerializer(enrollments, many=True).data)

    @action(detail=False, methods=['get'])
    def my_courses(self, request):
        """查看自己的课程列表"""
        user = request.user
        if user.role == 'student':
            courses = user.enrolled_courses.all()
        elif user.role == 'teacher':
            courses = Course.objects.filter(teacher=user)
        else:
            courses = Course.objects.all()
        return Response(CourseSerializer(courses, many=True).data)
