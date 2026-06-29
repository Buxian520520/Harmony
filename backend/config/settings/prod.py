"""
Production settings.
"""
from .base import *

DEBUG = False

# In production, specify allowed hosts explicitly
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

# Secure settings
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# CORS - restrict in production
CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOWED_ORIGINS = os.environ.get('CORS_ALLOWED_ORIGINS', '').split(',')

# Static & Media files
STATIC_ROOT = '/app/static'
MEDIA_ROOT = '/app/media'

# Database - use env vars with strong passwords
DATABASES['default']['OPTIONS'] = {
    'charset': 'utf8mb4',
    'connect_timeout': 10,
}

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
        'file': {
            'class': 'logging.FileHandler',
            'filename': '/var/log/attendance/app.log',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': 'INFO',
    },
}
