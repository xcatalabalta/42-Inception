#!/bin/sh
set -e

if [ -f "$MYSQL_PASSWORD_FILE" ]; then
    export MYSQL_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
fi

echo "Waiting for MariaDB to be ready..."
MAX_TRIES=30
TRIES=0

until mariadb -h"${MYSQL_HOST:-127.0.0.1}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    TRIES=$((TRIES + 1))
    if [ $TRIES -ge $MAX_TRIES ]; then
        echo "ERROR: MariaDB did not become ready in time"
        exit 1
    fi
    echo "MariaDB is unavailable - sleeping (attempt $TRIES/$MAX_TRIES)"
    sleep 2
done

echo "MariaDB is up and running!"

if [ ! -f /var/www/html/index.php ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root --path=/var/www/html
    echo "WordPress files downloaded"
fi

if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Creating wp-config.php..."
    wp config create \
        --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOST:-127.0.0.1}" \
        --path=/var/www/html
    echo "wp-config.php created"
fi

if ! wp core is-installed --allow-root --path=/var/www/html 2>/dev/null; then
    echo "Installing WordPress..."
    wp core install \
        --allow-root \
        --path=/var/www/html \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email
    
    echo "WordPress installed successfully!"
    
    echo "Creating additional user: ${WP_USER}..."
    wp user create \
        --allow-root \
        --path=/var/www/html \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WP_USER_PASSWORD}"
    
    echo "Additional user created successfully!"
else
    echo "WordPress is already installed"
fi

echo "Starting PHP-FPM..."
exec php-fpm82 -F
