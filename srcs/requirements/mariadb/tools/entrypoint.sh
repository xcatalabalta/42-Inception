#!/bin/sh
set -e

# Load secrets if present
if [ -f "$MYSQL_PASSWORD_FILE" ]; then
    export MYSQL_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
fi
if [ -f "$MYSQL_ROOT_PASSWORD_FILE" ]; then
    export MYSQL_ROOT_PASSWORD=$(cat "$MYSQL_ROOT_PASSWORD_FILE")
fi

# Check if the database has been initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing database..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
    
    # Start temporary server for initialization
    mariadbd --user=mysql --skip-networking --socket=/tmp/mysql.sock &
    pid="$!"
    
    # Wait for server to start
    sleep 10
    
    # Run initialization commands
    mariadb --socket=/tmp/mysql.sock << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
-- Create users for both network access (%) and local access (localhost)
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Remove anonymous users to prevent authentication conflicts
DELETE FROM mysql.user WHERE User = '';
DROP DATABASE IF EXISTS test;

FLUSH PRIVILEGES;
EOF
    
    # Stop temporary server
    kill "$pid"
    wait "$pid"
    
    echo "Database initialized successfully"
fi

exec mariadbd --user=mysql --console

