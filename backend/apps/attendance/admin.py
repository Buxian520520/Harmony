from django.contrib import admin
from .models import Course, CourseEnrollment, AttendanceRecord, LeaveRequest


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ['name', 'teacher', 'class_name', 'semester', 'is_active']
    list_filter = ['semester', 'is_active']
    search_fields = ['name', 'class_name', 'teacher__username']


@admin.register(CourseEnrollment)
class CourseEnrollmentAdmin(admin.ModelAdmin):
    list_display = ['student', 'course', 'enrolled_at']
    list_filter = ['course']


@admin.register(AttendanceRecord)
class AttendanceRecordAdmin(admin.ModelAdmin):
    list_display = ['student', 'course', 'status', 'checkin_time', 'is_abnormal']
    list_filter = ['status', 'is_abnormal', 'course']
    search_fields = ['student__username', 'course__name']


@admin.register(LeaveRequest)
class LeaveRequestAdmin(admin.ModelAdmin):
    list_display = ['student', 'course', 'leave_date', 'status', 'created_at']
    list_filter = ['status', 'course']
