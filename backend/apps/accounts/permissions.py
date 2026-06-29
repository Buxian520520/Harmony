from rest_framework.permissions import BasePermission, SAFE_METHODS
from .models import RoleType


class IsAdmin(BasePermission):
    """仅管理员可访问"""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == RoleType.ADMIN


class IsTeacher(BasePermission):
    """仅教师可访问"""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == RoleType.TEACHER


class IsStudent(BasePermission):
    """仅学生可访问"""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == RoleType.STUDENT


class IsAdminOrTeacher(BasePermission):
    """管理员或教师可访问"""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.role in (RoleType.ADMIN, RoleType.TEACHER)


class IsAdminOrReadOnly(BasePermission):
    """管理员可写，其他用户只读"""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.method in SAFE_METHODS:
            return True
        return request.user.role == RoleType.ADMIN
