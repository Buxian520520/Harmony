FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Project code
COPY . .

# Create media and static directories
RUN mkdir -p media static

EXPOSE 8000

# Use daphne for ASGI (Channels WebSocket support)
CMD ["daphne", "-b", "0.0.0.0", "-p", "8000", "config.asgi:application"]
