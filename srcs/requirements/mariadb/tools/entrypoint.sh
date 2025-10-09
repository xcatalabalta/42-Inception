#!/bin/sh

# Set the execution context for debugging
echo "Starting MariaDB entrypoint as user: $(whoami)"

# 1. READ SECRETS AND SET ENVIRONMENT VARIABLES
export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
export MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Check if the database has already been initialized (use a robust check)
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "MariaDB data directory not initialized. Initializing database..."

    # 2. INITIALIZE DATABASE
    mariadb-install-db --user=mysql --datadir="/var/lib/mysql"

    # Start the MariaDB server in the background temporarily for setup.
    # We use --skip-bind-address to ensure clean localhost socket connection.
    /usr/bin/mariadbd --user=mysql --datadir="/var/lib/mysql" --skip-networking --skip-bind-address &
    MYSQL_PID=$!
    
    # CRITICAL FIX: Implement a robust readiness check (replaces 'sleep 10')
    TRIES=0
    MAX_TRIES=30
    echo "Waiting for temporary MariaDB server to be ready..."
    while ! mariadb-admin ping -h localhost --socket=/run/mysqld/mysqld.sock 2>/dev/null; do
        TRIES=$((TRIES + 1))
        if [ $TRIES -ge $MAX_TRIES ]; then
            echo "Error: Temporary MariaDB server failed to start after $MAX_TRIES attempts."
            kill $MYSQL_PID
            exit 1
        fi
        sleep 1
    done
    echo "Temporary MariaDB server is ready for configuration."

    # 3. CONFIGURE DATABASE (using direct heredoc and the 'mariadb' client)
    # The -h localhost ensures we use the proper socket connection.
    /usr/bin/mariadb -u root -h localhost --socket=/run/mysqld/mysqld.sock <<EOF
-- Set the root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create the application database
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Create the application user and grant privileges
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

-- Remove anonymous users and remote root access for security
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Apply the changes
FLUSH PRIVILEGES;
EOF

    # Stop the temporary MariaDB server
    kill $MYSQL_PID
    wait $MYSQL_PID
    echo "MariaDB configuration complete. Temporary server stopped."
else
    echo "MariaDB data directory already initialized. Skipping initialization..."
fi

# 4. START THE FINAL SERVER PROCESS
echo "Starting MariaDB server in production mode..."
exec /usr/bin/mariadbd --user=mysql --datadir="/var/lib/mysql" --bind-address=0.0.0.0 --port=3306

