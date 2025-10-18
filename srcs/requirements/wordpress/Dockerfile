FROM alpine:3.21

# Install necessary packages: PHP-FPM and required extensions for WordPress on Alpine
RUN apk update && \
    apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-session \
    php83-mbstring \
    php83-curl \
    php83-dom \
    php83-xml \
    php83-simplexml \
    php83-json \
    php83-gd \
    php83-zlib \
    php83-phar \
    curl \
    tar \
    shadow \
    && rm -rf /var/cache/apk/*

# Create the base web directory before extraction
RUN mkdir -p /var/www 

# Ensure the www-data group and user exist.
RUN addgroup -S www-data 2>/dev/null || true && \
    adduser -D -S -G www-data www-data 2>/dev/null || true

# Download, extract, and move latest WordPress core files using curl
RUN curl -L https://wordpress.org/latest.tar.gz -o /tmp/latest.tar.gz && \
    tar -xzf /tmp/latest.tar.gz -C /var/www/ && \
    rm /tmp/latest.tar.gz && \
    mv /var/www/wordpress /var/www/html

# Download and install wp-cli
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

# Create the php-fpm run directory and set permissions
RUN mkdir -p /run/php && \
    chown -R www-data:www-data /var/www/html

# Copy configuration files
COPY conf/my_www.conf /etc/php83/php-fpm.d/www.conf
COPY conf/php.ini /etc/php83/php.ini
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Ensure the entrypoint script is executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default PHP-FPM port
EXPOSE 9000

# Set the working directory
WORKDIR /var/www/html

# The entrypoint script will handle wp-config.php generation and start php-fpm
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Command to run PHP-FPM in the foreground
CMD ["php-fpm83", "-F"]
