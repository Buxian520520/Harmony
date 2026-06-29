from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    """通知序列化器"""
    type_display = serializers.CharField(source='get_notification_type_display', read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id', 'notification_type', 'type_display', 'title', 'body',
            'is_read', 'related_course', 'extra_data', 'created_at',
        ]
        read_only_fields = '__all__'
