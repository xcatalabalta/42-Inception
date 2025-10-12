# Adminer (single-file DB management tool) - Alpine + PHP
FROM alpine:3.21

# Install PHP and required extensions for Adminer
RUN apk add --no-cache \
    php83 \
    php83-session \
    php83-mysqli \
    php83-phar \
    php83-json \
    php83-mbstring \
    wget \
    ca-certificates

# Create directory for Adminer
RUN mkdir -p /var/www/html

WORKDIR /var/www/html

# Download a stable Adminer release and save as index.php
# (Using a specific release URL avoids unexpected breaking changes)
RUN wget -q -O index.php \
    https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php

# Expose non-HTTPS port (Adminer is accessed via browser on this port)
EXPOSE 8080

# Use PHP built-in server to serve Adminer
CMD ["php83", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]
