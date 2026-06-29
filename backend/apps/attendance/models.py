from django.db import models
from django.conf import settings


class Course(models.Model):
    """课程模型"""
    name = models.CharField(max_length=128, verbose_name='课程名称')
    teacher = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='teaching_courses',
        verbose_name='授课教师',
        limit_choices_to={'role': 'teacher'},
    )
    students = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        through='CourseEnrollment',
        related_name='enrolled_courses',
        verbose_name='选课学生',
    )
    class_name = models.CharField(max_length=64, verbose_name='班级名称')
    semester = models.CharField(max_length=32, verbose_name='学期')
    start_time = models.TimeField(verbose_name='上课时间')
    end_time = models.TimeField(verbose_name='下课时间')
    weekdays = models.CharField(
        max_length=20,
        help_text='上课星期，用逗号分隔，如 1,3,5 表示周一、三、五',
        verbose_name='上课星期',
    )
    classroom = models.CharField(max_length=64, blank=True, verbose_name='教室/地点')
    latitude = models.FloatField(default=0, verbose_name='签到围栏纬度')
    longitude = models.FloatField(default=0, verbose_name='签到围栏经度')
    fence_radius = models.FloatField(default=100, verbose_name='签到围栏半径(米)')
    allow_early_minutes = models.IntegerField(default=15, verbose_name='允许课前签到分钟数')
    allow_late_minutes = models.IntegerField(default=15, verbose_name='允许课后补签分钟数')
    is_active = models.BooleanField(default=True, verbose_name='是否启用')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')

    class Meta:
        verbose_name = '课程'
        verbose_name_plural = '课程'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.name} ({self.class_name})'


class CourseEnrollment(models.Model):
    """选课记录"""
    student = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        verbose_name='学生',
    )
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        verbose_name='课程',
    )
    enrolled_at = models.DateTimeField(auto_now_add=True, verbose_name='选课时间')

    class Meta:
        verbose_name = '选课记录'
        verbose_name_plural = '选课记录'
        unique_together = ['student', 'course']

    def __str__(self):
        return f'{self.student.username} → {self.course.name}'


class AttendanceStatus(models.TextChoices):
    PRESENT = 'present', '已签到'
    LATE = 'late', '迟到'
    EARLY_LEAVE = 'early_leave', '早退'
    ABSENT = 'absent', '缺勤'
    LEAVE = 'leave', '请假'


class AttendanceRecord(models.Model):
    """考勤记录"""
    student = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='attendance_records',
        verbose_name='学生',
    )
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='attendance_records',
        verbose_name='课程',
    )
    status = models.CharField(
        max_length=20,
        choices=AttendanceStatus.choices,
        default=AttendanceStatus.ABSENT,
        verbose_name='考勤状态',
    )
    checkin_time = models.DateTimeField(null=True, blank=True, verbose_name='签到时间')
    checkin_latitude = models.FloatField(null=True, blank=True, verbose_name='签到纬度')
    checkin_longitude = models.FloatField(null=True, blank=True, verbose_name='签到经度')
    device_id = models.CharField(max_length=128, blank=True, verbose_name='签到设备标识')
    face_image = models.ImageField(upload_to='face_images/', blank=True, verbose_name='签到人脸照')
    face_verified = models.BooleanField(default=False, verbose_name='人脸验证通过')
    remark = models.TextField(blank=True, verbose_name='备注')
    is_abnormal = models.BooleanField(default=False, verbose_name='是否异常标记')
    abnormal_reason = models.TextField(blank=True, verbose_name='异常原因')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='记录创建时间')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='最后修改时间')

    class Meta:
        verbose_name = '考勤记录'
        verbose_name_plural = '考勤记录'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['student', 'course', 'created_at']),
        ]

    def __str__(self):
        return f'{self.student.username} - {self.course.name} - {self.get_status_display()}'


class LeaveStatus(models.TextChoices):
    PENDING = 'pending', '待审批'
    APPROVED = 'approved', '已通过'
    REJECTED = 'rejected', '已驳回'


class LeaveRequest(models.Model):
    """请假申请"""
    student = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='leave_requests',
        verbose_name='申请人',
    )
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        verbose_name='课程（可选，为空则全天请假）',
    )
    leave_date = models.DateField(verbose_name='请假日期')
    start_time = models.TimeField(verbose_name='开始时间')
    end_time = models.TimeField(verbose_name='结束时间')
    reason = models.TextField(verbose_name='请假原因')
    status = models.CharField(
        max_length=20,
        choices=LeaveStatus.choices,
        default=LeaveStatus.PENDING,
        verbose_name='审批状态',
    )
    review_comment = models.TextField(blank=True, verbose_name='审批意见')
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_leaves',
        verbose_name='审批人',
    )
    reviewed_at = models.DateTimeField(null=True, blank=True, verbose_name='审批时间')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='提交时间')

    class Meta:
        verbose_name = '请假申请'
        verbose_name_plural = '请假申请'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.student.username} 请假 {self.leave_date}'
