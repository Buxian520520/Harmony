"""
ASGI config for attendance project.
Supports HTTP + WebSocket via Django Channels.
"""
import os
from channels.auth import AuthMiddlewareStack
from channels.routing import ProtocolTypeRouter, URLRouter
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.dev')

django_asgi_app = get_asgi_application()

from apps.notification import routing as notification_routing
from apps.attendance import routing as attendance_routing

application = ProtocolTypeRouter({
    'http': django_asgi_app,
    'websocket': AuthMiddlewareStack(
        URLRouter(
            attendance_routing.websocket_urlpatterns +
            notification_routing.websocket_urlpatterns
        )
    ),
})
