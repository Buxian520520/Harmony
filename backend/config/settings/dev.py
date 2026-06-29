"""
Development settings.
"""
from .base import *

DEBUG = True
ALLOWED_HOSTS = ['*']

# Print SQL queries to console (dev only)
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django.db.backends': {
            'handlers': ['console'],
            'level': 'WARNING',  # Set to DEBUG to see all SQL queries
            'propagate': False,
        },
    },
}
