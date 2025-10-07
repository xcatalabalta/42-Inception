#!/bin/sh
set -e

echo "Starting MariaDB entrypoint..."

# Read secrets from Docker secret files
if [ -f "/run/secrets/db_password" ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
    echo "✓ DB password loaded from secret"
else
    echo "ERROR: db_password secret not found!"
    exit 1
fi

if [ -f "/run/secrets/db_root_password" ]; then
    MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    echo "✓ DB root password loaded from secret"
else
    echo "ERROR: db_root_password secret not found!"
    exit 1
fi

# Check if database has been initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing database..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
    
    echo "Starting temporary MariaDB server..."
    mariadbd --user=mysql --skip-networking --socket=/tmp/mysql_init.sock &
    pid="$!"
    
    # Wait for server to start (with timeout)
    echo "Waiting for MariaDB to start..."
    for i in $(seq 1 30); do
        if mariadb --socket=/tmp/mysql_init.sock -e "SELECT 1" >/dev/null 2>&1; then
            echo "✓ MariaDB temporary server is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "ERROR: MariaDB failed to start in time"
            kill "$pid" 2>/dev/null || true
            exit 1
        fi
        sleep 1
    done
    
    echo "Running initialization SQL..."
    mariadb --socket=/tmp/mysql_init.sock << EOF_SQL
-- Create database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Create users for both network (%) and localhost access
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Grant privileges
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';

-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Security: Remove anonymous users and test database
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Apply changes
FLUSH PRIVILEGES;
EOF_SQL
    
    echo "✓ Database initialized successfully"
    
    # Stop temporary server
    echo "Stopping temporary server..."
    kill "$pid"
    wait "$pid" 2>/dev/null || true
    
    echo "✓ Initialization complete"
else
    echo "Database already initialized, skipping..."
fi

echo "Starting MariaDB server..."
exec mariadbd --user=mysql --console


