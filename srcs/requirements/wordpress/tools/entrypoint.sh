#!/bin/sh

# Environment variables (DB credentials, site details) are assumed to be set 
# in the docker-compose.yml file.
# 1. Wait for MariaDB service to be ready
echo "Waiting for MariaDB service to be ready at mariadb:3306..."
# This command tries to connect to the database container until it is available.
while ! nc -z mariadb 3306; do
  sleep 10
done
echo "MariaDB is ready. Starting configuration."

# 2. Check if wp-config.php exists (indicates initial setup is done)
if [ ! -f /var/www/html/wp-config.php ];
then
    echo "wp-config.php not found. Starting initial WordPress setup..."

    # IMPLEMENTING A ROBUST WAIT: This loop retries the critical 'wp config create' 
    # command until the database user is fully configured by MariaDB's entrypoint script.
    TRIES=0
    # Increased maximum attempts to 60 (60 * 5s = 300s total wait)
    MAX_TRIES=60
    DB_READY=0

    while [ $TRIES -lt $MAX_TRIES ]; do
        TRIES=$((TRIES + 1))
        
        # a. Use wp-cli to generate wp-config.php
        # This command is the first to fail if the user is not created yet.
        # We redirect stderr to suppress ugly wp-cli error messages during retries.
        wp config create \
            --allow-root \
            --dbname="$MYSQL_DATABASE" \
            --dbuser="$MYSQL_USER" \
            --dbpass="$MYSQL_PASSWORD" \
            --dbhost="mariadb:3306" \
            --path="/var/www/html" 2>/dev/null
        
        # Check the exit status of wp config create
        if [ $? -eq 0 ]; then
            echo "wp-config.php generated successfully. Database is ready."
            DB_READY=1
            break
        else
            # Ensure sleep time and echo text are consistent at 5 seconds.
            echo "Database connection failed (Attempt $TRIES/$MAX_TRIES). Waiting 5 seconds for MariaDB configuration to complete..."
            sleep 5
        fi
    done

    if [ $DB_READY -eq 0 ]; then
        echo "Error: Could not connect to the database after $MAX_TRIES attempts."
        exit 1
    fi

    # b. Install WordPress core
    # We use secrets for admin user, password, and email
    wp core install \
        --allow-root \
        --url="$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --path="/var/www/html" \
        --skip-email

    echo "WordPress core installed."
    
    # c. Create a regular user (if desired)
    # wp user create \
    #     --allow-root \
    #     "$WP_USER" \
    #     "$WP_USER_EMAIL" \
    #     --user_pass="$WP_USER_PASSWORD" \
    #     --role=author \
    #     --path="/var/www/html"

    # echo "Regular WordPress user created."
else
    echo "wp-config.php found. Skipping initial WordPress setup."
fi

# 3. Ensure correct permissions for the WordPress files
echo "Setting file permissions..."
chown -R www-data:www-data /var/www/html
echo "Permissions set. Starting PHP-FPM."

# 4. Execute the command to start PHP-FPM (passed via CMD in Dockerfile)
exec "$@"
