from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsStudent, IsTeacher, IsAdminOrTeacher
from ..models import LeaveRequest, LeaveStatus, Course, CourseEnrollment
from ..serializers import LeaveRequestSerializer, LeaveReviewSerializer


class LeaveViewSet(viewsets.ModelViewSet):
    """请假申请 API"""
    queryset = LeaveRequest.objects.all()
    serializer_class = LeaveRequestSerializer

    def get_permissions(self):
        if self.action in ('create', 'my_requests'):
            return [IsAuthenticated(), IsStudent()]
        if self.action in ('review', 'pending_reviews'):
            return [IsAuthenticated(), IsTeacher()]
        return [IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'student':
            return LeaveRequest.objects.filter(student=user)
        elif user.role == 'teacher':
            # 教师看到与自己课程相关的请假
            return LeaveRequest.objects.filter(course__teacher=user)
        return LeaveRequest.objects.all()

    def perform_create(self, serializer):
        serializer.save(student=self.request.user)

    @action(detail=False, methods=['get'])
    def my_requests(self, request):
        """学生查看自己的请假记录"""
        requests = LeaveRequest.objects.filter(student=request.user)
        return Response(LeaveRequestSerializer(requests, many=True).data)

    @action(detail=False, methods=['get'])
    def pending_reviews(self, request):
        """教师查看待审批列表"""
        pending = LeaveRequest.objects.filter(
            course__teacher=request.user,
            status=LeaveStatus.PENDING,
        )
        return Response(LeaveRequestSerializer(pending, many=True).data)

    @action(detail=True, methods=['post'])
    def review(self, request, pk=None):
        """审批请假"""
        leave_request = self.get_object()
        serializer = LeaveReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        action = serializer.validated_data['action']
        comment = serializer.validated_data.get('comment', '')

        if action == 'approve':
            leave_request.status = LeaveStatus.APPROVED
        else:
            leave_request.status = LeaveStatus.REJECTED

        leave_request.review_comment = comment
        leave_request.reviewed_by = request.user
        leave_request.reviewed_at = timezone.now()
        leave_request.save()

        return Response(LeaveRequestSerializer(leave_request).data)
