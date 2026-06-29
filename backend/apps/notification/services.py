import json
import logging

from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

from .models import Notification, NotificationType

logger = logging.getLogger(__name__)


class NotificationService:
    """通知推送服务"""

    @staticmethod
    def create_notification(recipient, notification_type: str, title: str, body: str,
                            related_course=None, extra_data=None):
        """创建通知并推送"""
        notification = Notification.objects.create(
            recipient=recipient,
            notification_type=notification_type,
            title=title,
            body=body,
            related_course=related_course,
            extra_data=extra_data or {},
        )
        # 通过 WebSocket 实时推送
        NotificationService._push_via_websocket(notification)
        return notification

    @staticmethod
    def _push_via_websocket(notification):
        """通过 WebSocket 通道推送通知"""
        try:
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f'notifications_{notification.recipient.id}',
                {
                    'type': 'notification_message',
                    'data': {
                        'id': notification.id,
                        'type': notification.notification_type,
                        'title': notification.title,
                        'body': notification.body,
                        'created_at': notification.created_at.isoformat(),
                        'extra_data': notification.extra_data,
                    },
                },
            )
        except Exception as e:
            logger.error(f'WebSocket push failed: {e}')

    @staticmethod
    def notify_checkin_reminder(user, course):
        """签到提醒"""
        return NotificationService.create_notification(
            recipient=user,
            notification_type=NotificationType.CHECKIN_REMINDER,
            title='签到提醒',
            body=f'课程「{course.name}」即将开始，请及时签到！',
            related_course=course,
        )

    @staticmethod
    def notify_leave_result(user, leave_request, approved: bool):
        """请假审批结果通知"""
        status_text = '已通过' if approved else '已驳回'
        return NotificationService.create_notification(
            recipient=user,
            notification_type=NotificationType.LEAVE_RESULT,
            title='请假审批结果',
            body=f'您的请假申请{status_text}：{leave_request.reason[:50]}',
            related_course=leave_request.course,
            extra_data={'leave_id': leave_request.id, 'approved': approved},
        )

    @staticmethod
    def notify_abnormal_alert(user, record):
        """异常考勤预警"""
        return NotificationService.create_notification(
            recipient=user,
            notification_type=NotificationType.ABNORMAL_ALERT,
            title='考勤异常提醒',
            body=f'您的考勤记录被标记为异常：{record.abnormal_reason or "系统检测到异常"}',
            related_course=record.course,
            extra_data={'record_id': record.id},
        )
