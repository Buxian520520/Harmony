from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['username', 'role', 'phone', 'student_id', 'face_registered', 'is_active']
    list_filter = ['role', 'is_active', 'face_registered']
    search_fields = ['username', 'phone', 'student_id']
    ordering = ['-date_joined']

    fieldsets = BaseUserAdmin.fieldsets + (
        ('额外信息', {'fields': ('role', 'phone', 'student_id', 'face_registered', 'device_id')}),
    )
