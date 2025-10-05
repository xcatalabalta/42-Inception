FROM alpine:3.21

# Install PHP-FPM and required PHP extensions for WordPress
RUN apk add --no-cache \
    php82 \
    php82-fpm \
    php82-mysqli \
    php82-json \
    php82-curl \
    php82-dom \
    php82-exif \
    php82-fileinfo \
    php82-mbstring \
    php82-openssl \
    php82-xml \
    php82-zip \
    php82-phar \
    php82-intl \
    php82-opcache \
    php82-session \
    php82-gd \
    curl \
    mysql-client

# Create necessary directories
RUN mkdir -p /var/www/html /run/php

# Download wp-cli (WordPress command line tool)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Copy PHP-FPM configuration
COPY conf/my_www.conf /etc/php82/php-fpm.d/www.conf

# Copy entrypoint script
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]