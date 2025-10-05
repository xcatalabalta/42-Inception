#!/bin/sh
set -e

# Load secrets if present
if [ -f "$MYSQL_PASSWORD_FILE" ]; then
    export MYSQL_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
fi

# Wait for MariaDB to be ready
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

# Download WordPress if not already present
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root --path=/var/www/html
    
    echo "Creating wp-config.php..."
    wp config create \
        --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOST:--127.0.0.1}" \
        --path=/var/www/html
    
    echo "WordPress files ready"
fi

# Start PHP-FPM
echo "Starting PHP-FPM..."
exec php-fpm82 -F