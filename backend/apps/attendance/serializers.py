from rest_framework import serializers
from .models import (
    Course, CourseEnrollment, AttendanceRecord,
    AttendanceStatus, LeaveRequest, LeaveStatus,
)
from apps.accounts.serializers import UserSerializer


class CourseSerializer(serializers.ModelSerializer):
    """课程序列化器"""
    teacher_name = serializers.CharField(source='teacher.username', read_only=True)
    student_count = serializers.SerializerMethodField()

    class Meta:
        model = Course
        fields = '__all__'
        read_only_fields = ['created_at']

    def get_student_count(self, obj):
        return obj.students.count()


class CourseCreateSerializer(serializers.ModelSerializer):
    """课程创建序列化器（教师/管理员）"""

    class Meta:
        model = Course
        fields = '__all__'
        read_only_fields = ['created_at']

    def validate_teacher(self, value):
        if value.role != 'teacher':
            raise serializers.ValidationError('授课教师角色必须为教师')
        return value


class CourseEnrollmentSerializer(serializers.ModelSerializer):
    """选课序列化器"""
    student_name = serializers.CharField(source='student.username', read_only=True)
    course_name = serializers.CharField(source='course.name', read_only=True)

    class Meta:
        model = CourseEnrollment
        fields = ['id', 'student', 'student_name', 'course', 'course_name', 'enrolled_at']
        read_only_fields = ['enrolled_at']


class AttendanceRecordSerializer(serializers.ModelSerializer):
    """考勤记录序列化器"""
    student_name = serializers.CharField(source='student.username', read_only=True)
    course_name = serializers.CharField(source='course.name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = AttendanceRecord
        fields = [
            'id', 'student', 'student_name', 'course', 'course_name',
            'status', 'status_display', 'checkin_time',
            'checkin_latitude', 'checkin_longitude', 'device_id',
            'face_verified', 'is_abnormal', 'abnormal_reason',
            'remark', 'created_at',
        ]
        read_only_fields = ['created_at', 'is_abnormal', 'abnormal_reason']


class CheckinSerializer(serializers.Serializer):
    """签到请求序列化器"""
    course_id = serializers.IntegerField()
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    device_id = serializers.CharField(max_length=128)


class LeaveRequestSerializer(serializers.ModelSerializer):
    """请假申请序列化器"""
    student_name = serializers.CharField(source='student.username', read_only=True)
    course_name = serializers.CharField(source='course.name', read_only=True, allow_null=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = LeaveRequest
        fields = [
            'id', 'student', 'student_name', 'course', 'course_name',
            'leave_date', 'start_time', 'end_time', 'reason',
            'status', 'status_display', 'review_comment',
            'reviewed_by', 'reviewed_at', 'created_at',
        ]
        read_only_fields = [
            'status', 'review_comment', 'reviewed_by', 'reviewed_at', 'created_at',
        ]


class LeaveReviewSerializer(serializers.Serializer):
    """请假审批序列化器"""
    action = serializers.ChoiceField(choices=['approve', 'reject'])
    comment = serializers.CharField(required=False, allow_blank=True)
