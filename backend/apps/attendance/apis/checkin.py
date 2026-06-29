import math
from datetime import datetime, timedelta

from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsStudent, IsTeacher, IsAdminOrTeacher
from ..models import Course, CourseEnrollment, AttendanceRecord, AttendanceStatus, LeaveRequest
from ..serializers import AttendanceRecordSerializer, CheckinSerializer


class CheckinViewSet(viewsets.GenericViewSet):
    """签到相关 API"""
    queryset = AttendanceRecord.objects.all()
    serializer_class = AttendanceRecordSerializer

    def get_permissions(self):
        if self.action == 'checkin':
            return [IsAuthenticated(), IsStudent()]
        return [IsAuthenticated()]

    @staticmethod
    def _haversine_distance(lat1, lon1, lat2, lon2):
        """计算两点间的球面距离（米）"""
        R = 6371000  # 地球半径
        phi1, phi2 = math.radians(lat1), math.radians(lat2)
        dphi = math.radians(lat2 - lat1)
        dlambda = math.radians(lon2 - lon1)
        a = math.sin(dphi / 2) ** 2 + \
            math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
        return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    @action(detail=False, methods=['post'])
    def checkin(self, request):
        """
        定位签到
        1. 校验课程存在且学生已选课
        2. 地理围栏校验
        3. 时间窗校验
        4. 设备标识记录
        5. 确定考勤状态（正常/迟到）
        """
        serializer = CheckinSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data
        student = request.user

        # 1. 获取课程
        try:
            course = Course.objects.get(id=data['course_id'], is_active=True)
        except Course.DoesNotExist:
            return Response({'error': '课程不存在或已停用'}, status=status.HTTP_404_NOT_FOUND)

        # 2. 检查是否选课
        if not CourseEnrollment.objects.filter(student=student, course=course).exists():
            return Response({'error': '未选修该课程'}, status=status.HTTP_403_FORBIDDEN)

        # 3. 检查是否已签到
        today = timezone.localdate()
        if AttendanceRecord.objects.filter(
            student=student, course=course,
            created_at__date=today
        ).exists():
            return Response({'error': '今日已签到'}, status=status.HTTP_400_BAD_REQUEST)

        # 4. 地理围栏校验
        distance = self._haversine_distance(
            data['latitude'], data['longitude'],
            course.latitude, course.longitude,
        )
        if distance > course.fence_radius:
            return Response({
                'error': f'不在签到范围内（距离 {distance:.0f}m > 围栏 {course.fence_radius}m）',
            }, status=status.HTTP_403_FORBIDDEN)

        # 5. 时间窗校验
        now = timezone.localtime()
        course_start = datetime.combine(today, course.start_time, tzinfo=now.tzinfo)
        course_end = datetime.combine(today, course.end_time, tzinfo=now.tzinfo)
        allow_early = timedelta(minutes=course.allow_early_minutes)
        allow_late = timedelta(minutes=course.allow_late_minutes)

        if now < course_start - allow_early:
            return Response({
                'error': f'签到未开始（提前超过{course.allow_early_minutes}分钟）',
            }, status=status.HTTP_403_FORBIDDEN)

        if now > course_end + allow_late:
            return Response({
                'error': f'签到已结束（课后超过{course.allow_late_minutes}分钟）',
            }, status=status.HTTP_403_FORBIDDEN)

        # 6. 确定考勤状态
        if now <= course_start:
            attendance_status = AttendanceStatus.PRESENT
        else:
            attendance_status = AttendanceStatus.LATE

        # 7. 创建记录
        record = AttendanceRecord.objects.create(
            student=student,
            course=course,
            status=attendance_status,
            checkin_time=now,
            checkin_latitude=data['latitude'],
            checkin_longitude=data['longitude'],
            device_id=data.get('device_id', ''),
        )

        # 8. 如果之前有当天请假且已通过，自动设为请假状态
        leave = LeaveRequest.objects.filter(
            student=student, course=course,
            leave_date=today, status='approved',
        ).first()
        if leave:
            record.status = AttendanceStatus.LEAVE
            record.save(update_fields=['status'])

        return Response(
            AttendanceRecordSerializer(record).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=False, methods=['get'])
    def my_records(self, request):
        """查看自己的考勤记录"""
        course_id = request.query_params.get('course_id')
        page = request.query_params.get('page', 1)

        records = AttendanceRecord.objects.filter(student=request.user)
        if course_id:
            records = records.filter(course_id=course_id)

        # 分页
        from django.core.paginator import Paginator
        paginator = Paginator(records, 20)
        page_obj = paginator.get_page(page)

        return Response({
            'count': paginator.count,
            'results': AttendanceRecordSerializer(page_obj, many=True).data,
        })

    @action(detail=False, methods=['get'])
    def course_records(self, request):
        """查看课程考勤记录（教师用）"""
        course_id = request.query_params.get('course_id')
        if not course_id:
            return Response({'error': 'course_id required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            course = Course.objects.get(id=course_id)
        except Course.DoesNotExist:
            return Response({'error': '课程不存在'}, status=status.HTTP_404_NOT_FOUND)

        # 教师只能看自己的课程
        if request.user.role == 'teacher' and course.teacher != request.user:
            return Response({'error': '无权查看'}, status=status.HTTP_403_FORBIDDEN)

        date_str = request.query_params.get('date')
        if date_str:
            records = AttendanceRecord.objects.filter(course=course, created_at__date=date_str)
        else:
            records = AttendanceRecord.objects.filter(course=course)

        return Response(AttendanceRecordSerializer(records, many=True).data)
