#!/bin/sh
set -e

echo "Starting WordPress entrypoint..."

# READ SECRETS FROM DOCKER SECRET FILES
if [ -f "/run/secrets/db_password" ]; then
    export MYSQL_PASSWORD=$(cat /run/secrets/db_password)
    echo "✓ DB password loaded from secret"
else
    echo "ERROR: db_password secret not found!"
    exit 1
fi

if [ -f "/run/secrets/wp_admin_user" ]; then
    export WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user)
    echo "✓ Admin user loaded from secret"
else
    echo "ERROR: wp_admin_user secret not found!"
    exit 1
fi

if [ -f "/run/secrets/wp_admin_password" ]; then
    export WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
    echo "✓ Admin password loaded from secret"
else
    echo "ERROR: wp_admin_password secret not found!"
    exit 1
fi

if [ -f "/run/secrets/wp_admin_email" ]; then
    export WP_ADMIN_EMAIL=$(cat /run/secrets/wp_admin_email)
    echo "✓ Admin email loaded from secret"
else
    echo "ERROR: wp_admin_email secret not found!"
    exit 1
fi

if [ -f "/run/secrets/wp_user" ]; then
    export WP_USER=$(cat /run/secrets/wp_user)
    echo "✓ Editor user loaded from secret"
else
    echo "ERROR: wp_user secret not found!"
    exit 1
fi

if [ -f "/run/secrets/wp_user_password" ]; then
    export WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
    echo "✓ Editor password loaded from secret"
else
    echo "ERROR: wp_user_password secret not found!"
    exit 1
fi

if [ -f "/run/secrets/wp_user_email" ]; then
    export WP_USER_EMAIL=$(cat /run/secrets/wp_user_email)
    echo "✓ Editor email loaded from secret"
else
    echo "ERROR: wp_user_email secret not found!"
    exit 1
fi

# Wait for MariaDB service to be ready
echo "Waiting for MariaDB service to be ready at ${MYSQL_HOST}:3306..."
while ! nc -z ${MYSQL_HOST} 3306; do
  sleep 2
done
echo "✓ MariaDB is ready"

# Check if wp-config.php exists
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "wp-config.php not found. Starting initial WordPress setup..."

    # Wait for database to accept connections with credentials
    TRIES=0
    MAX_TRIES=30
    DB_READY=0

    echo "Attempting to create wp-config.php..."
    while [ $TRIES -lt $MAX_TRIES ]; do
        TRIES=$((TRIES + 1))
        
        # Try to create wp-config.php
        if wp config create \
            --allow-root \
            --dbname="${MYSQL_DATABASE}" \
            --dbuser="${MYSQL_USER}" \
            --dbpass="${MYSQL_PASSWORD}" \
            --dbhost="${MYSQL_HOST}:3306" \
            --path="/var/www/html" 2>/dev/null; then
            echo "✓ wp-config.php created successfully"
            DB_READY=1
            break
        else
            echo "Database connection failed (Attempt $TRIES/$MAX_TRIES). Retrying in 2 seconds..."
            sleep 2
        fi
    done

    if [ $DB_READY -eq 0 ]; then
        echo "ERROR: Could not connect to database after $MAX_TRIES attempts"
        exit 1
    fi

    # Install WordPress core
    echo "Installing WordPress..."
    wp core install \
        --allow-root \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --path="/var/www/html" \
        --skip-email

    echo "✓ WordPress core installed"
    
    # Wait a moment for WordPress to fully initialize
    sleep 2
    
    # Check if editor user already exists before creating
    echo "Checking if editor user '${WP_USER}' already exists..."
    if wp user get "${WP_USER}" --allow-root --path="/var/www/html" >/dev/null 2>&1; then
        echo "⚠ Editor user '${WP_USER}' already exists. Updating password..."
        wp user update "${WP_USER}" \
            --allow-root \
            --user_pass="${WP_USER_PASSWORD}" \
            --path="/var/www/html"
        echo "✓ Editor user password updated"
    else
        # Create additional user
        echo "Creating editor user: ${WP_USER}..."
        if wp user create \
            --allow-root \
            "${WP_USER}" \
            "${WP_USER_EMAIL}" \
            --user_pass="${WP_USER_PASSWORD}" \
            --role=editor \
            --path="/var/www/html" 2>&1; then
            echo "✓ EDITOR CREATED SUCCESSFULLY"
        else
            echo "ERROR: Failed to create editor user"
            exit 1
        fi
    fi
    
    # Verify the user was created
    echo "Verifying editor user..."
    if wp user get "${WP_USER}" --allow-root --path="/var/www/html" >/dev/null 2>&1; then
        echo "✓ Editor user verified: ${WP_USER}"
        # Show user details for debugging
        wp user list --allow-root --path="/var/www/html" --fields=ID,user_login,user_email,roles
    else
        echo "ERROR: Editor user verification failed!"
        exit 1
    fi
else
    echo "wp-config.php found. Verifying WordPress setup..."
    
    # Verify editor user exists even if WordPress is already installed
    if ! wp user get "${WP_USER}" --allow-root --path="/var/www/html" >/dev/null 2>&1; then
        echo "⚠ Editor user missing. Creating now..."
        wp user create \
            --allow-root \
            "${WP_USER}" \
            "${WP_USER_EMAIL}" \
            --user_pass="${WP_USER_PASSWORD}" \
            --role=editor \
            --path="/var/www/html"
        echo "✓ Editor user created"
    else
        echo "✓ Editor user exists"
    fi
fi

# Set correct permissions
echo "Setting file permissions..."
chown -R www-data:www-data /var/www/html
echo "✓ Permissions set"

echo "Starting PHP-FPM..."
exec "$@"
