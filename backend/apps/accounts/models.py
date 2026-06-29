from django.contrib.auth.models import AbstractUser
from django.db import models


class RoleType(models.TextChoices):
    """三级角色体系：管理员、教师、学生"""
    ADMIN = 'admin', '管理员'
    TEACHER = 'teacher', '教师'
    STUDENT = 'student', '学生'


class User(AbstractUser):
    """自定义用户模型，支持三级角色"""
    role = models.CharField(
        max_length=10,
        choices=RoleType.choices,
        default=RoleType.STUDENT,
        verbose_name='角色',
    )
    phone = models.CharField(max_length=20, blank=True, verbose_name='手机号')
    avatar = models.ImageField(upload_to='avatars/', blank=True, verbose_name='头像')
    face_registered = models.BooleanField(default=False, verbose_name='是否已注册人脸')
    device_id = models.CharField(max_length=128, blank=True, verbose_name='绑定设备标识')
    student_id = models.CharField(max_length=20, blank=True, verbose_name='学号/工号')

    class Meta:
        verbose_name = '用户'
        verbose_name_plural = '用户'
        ordering = ['-date_joined']

    def __str__(self):
        return f'{self.get_role_display()} - {self.username}'

    @property
    def is_admin(self) -> bool:
        return self.role == RoleType.ADMIN

    @property
    def is_teacher(self) -> bool:
        return self.role == RoleType.TEACHER

    @property
    def is_student(self) -> bool:
        return self.role == RoleType.STUDENT
