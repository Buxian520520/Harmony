import json
from channels.generic.websocket import AsyncWebsocketConsumer


class AttendanceConsumer(AsyncWebsocketConsumer):
    """考勤实时频道：学生签到后广播到教师端"""

    async def connect(self):
        self.course_id = self.scope['url_route']['kwargs']['course_id']
        self.group_name = f'attendance_{self.course_id}'

        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name,
        )
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name,
        )

    async def receive(self, text_data):
        """客户端发送的消息广播到同组"""
        await self.channel_layer.group_send(
            self.group_name,
            {
                'type': 'attendance_update',
                'data': json.loads(text_data),
            },
        )

    async def attendance_update(self, event):
        """发送考勤更新到 WebSocket"""
        await self.send(text_data=json.dumps(event['data']))
