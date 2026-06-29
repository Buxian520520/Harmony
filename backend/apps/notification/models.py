from django.db import models
from django.conf import settings


class NotificationType(models.TextChoices):
    CHECKIN_REMINDER = 'checkin_reminder', '签到提醒'
    LEAVE_RESULT = 'leave_result', '请假审批结果'
    ABNORMAL_ALERT = 'abnormal_alert', '异常考勤预警'
    SYSTEM_NOTICE = 'system_notice', '系统通知'


class Notification(models.Model):
    """通知消息模型"""
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications',
        verbose_name='接收者',
    )
    notification_type = models.CharField(
        max_length=30,
        choices=NotificationType.choices,
        verbose_name='通知类型',
    )
    title = models.CharField(max_length=128, verbose_name='标题')
    body = models.TextField(verbose_name='内容')
    is_read = models.BooleanField(default=False, verbose_name='是否已读')
    related_course = models.ForeignKey(
        'attendance.Course',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        verbose_name='关联课程',
    )
    extra_data = models.JSONField(default=dict, blank=True, verbose_name='额外数据')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='创建时间')

    class Meta:
        verbose_name = '通知'
        verbose_name_plural = '通知'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['recipient', 'is_read']),
        ]

    def __str__(self):
        return f'{self.recipient.username} - {self.title}'
