from collections import defaultdict
from datetime import datetime, timedelta

from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsAdminOrTeacher
from ..models import Course, AttendanceRecord, AttendanceStatus, CourseEnrollment


class StatisticsViewSet(viewsets.GenericViewSet):
    """考勤统计报表 API"""
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def course_summary(self, request):
        """课程出勤汇总（教师/管理员）"""
        course_id = request.query_params.get('course_id')
        if not course_id:
            return Response({'error': 'course_id required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            course = Course.objects.get(id=course_id)
        except Course.DoesNotExist:
            return Response({'error': '课程不存在'}, status=status.HTTP_404_NOT_FOUND)

        if request.user.role == 'teacher' and course.teacher != request.user:
            return Response({'error': '无权查看'}, status=status.HTTP_403_FORBIDDEN)

        # 获取所有学生
        students = course.students.all()
        total_students = students.count()

        # 统计各状态
        stats = AttendanceRecord.objects.filter(course=course).aggregate(
            present=Count('id', filter=Q(status=AttendanceStatus.PRESENT)),
            late=Count('id', filter=Q(status=AttendanceStatus.LATE)),
            absent=Count('id', filter=Q(status=AttendanceStatus.ABSENT)),
            leave=Count('id', filter=Q(status=AttendanceStatus.LEAVE)),
            early_leave=Count('id', filter=Q(status=AttendanceStatus.EARLY_LEAVE)),
            abnormal=Count('id', filter=Q(is_abnormal=True)),
        )

        total_records = sum(stats.values()) - stats['abnormal']
        attendance_rate = round(
            (stats['present'] + stats['late']) / max(total_records, 1) * 100, 1
        )

        return Response({
            'course_id': course.id,
            'course_name': course.name,
            'total_students': total_students,
            'stats': stats,
            'attendance_rate': attendance_rate,
        })

    @action(detail=False, methods=['get'])
    def my_trend(self, request):
        """个人考勤趋势（学生）"""
        days = int(request.query_params.get('days', 30))
        since = timezone.now().date() - timedelta(days=days)

        records = AttendanceRecord.objects.filter(
            student=request.user,
            created_at__date__gte=since,
        ).order_by('created_at__date')

        # 按日期分组
        trend = defaultdict(lambda: {'present': 0, 'late': 0, 'absent': 0, 'leave': 0, 'total': 0})
        for record in records:
            date_key = record.created_at.strftime('%Y-%m-%d')
            trend[date_key][record.status] += 1
            trend[date_key]['total'] += 1

        # 计算每日出勤率
        result = []
        for date_str, data in sorted(trend.items()):
            rate = round(
                (data['present'] + data['late']) / max(data['total'], 1) * 100, 1
            )
            result.append({
                'date': date_str,
                **data,
                'attendance_rate': rate,
            })

        return Response({
            'student_id': request.user.id,
            'days': days,
            'trend': result,
        })

    @action(detail=False, methods=['get'])
    def class_rank(self, request):
        """班级出勤排名（教师/管理员）"""
        course_id = request.query_params.get('course_id')
        if not course_id:
            return Response({'error': 'course_id required'}, status=status.HTTP_400_BAD_REQUEST)

        records = AttendanceRecord.objects.filter(course_id=course_id)
        student_stats = records.values('student', 'student__username').annotate(
            total=Count('id'),
            present=Count('id', filter=Q(status=AttendanceStatus.PRESENT)),
            late=Count('id', filter=Q(status=AttendanceStatus.LATE)),
            absent=Count('id', filter=Q(status=AttendanceStatus.ABSENT)),
        )

        result = []
        for s in student_stats:
            attended = s['present'] + s['late']
            rate = round(attended / max(s['total'], 1) * 100, 1)
            result.append({
                'student_id': s['student'],
                'student_name': s['student__username'],
                'total': s['total'],
                'present': s['present'],
                'late': s['late'],
                'absent': s['absent'],
                'attendance_rate': rate,
            })

        result.sort(key=lambda x: x['attendance_rate'], reverse=True)
        return Response(result)
