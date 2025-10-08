#!/bin/sh

# Set the execution context for debugging
echo "Starting MariaDB entrypoint as user: $(whoami)"

# 1. READ SECRETS AND SET ENVIRONMENT VARIABLES
# Read the secret files mounted by Docker Compose secrets feature (requires root access)
export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
export MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Check if the database has already been initialized
if [ ! -f /var/lib/mysql/mysql/user.frm ]; then
    echo "MariaDB data directory not found or not initialized. Initializing database..."

    # 2. INITIALIZE DATABASE (using modern command)
    mariadb-install-db --user=mysql --datadir="/var/lib/mysql"

    # Start the MariaDB server in the background temporarily for setup (using modern command).
    # --skip-networking prevents external connections during configuration.
    /usr/bin/mariadbd --user=mysql --datadir="/var/lib/mysql" --skip-networking &
    MYSQL_PID=$!
    
    # Wait a few seconds for the temporary server to start. This is simpler and generally reliable in Docker.
    echo "Waiting for MariaDB server to be ready..."
    sleep 5
    
    echo "MariaDB server started for configuration."

    # 3. CONFIGURE DATABASE 
    # Use the 'mariadb' command for SQL execution (modern client)
    mariadb -u root <<EOF
-- Set the root password using the secret file content
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create the application database (uses MYSQL_DATABASE from .env)
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Create the application user (uses MYSQL_USER from .env)
-- Grant privileges using the secret password
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
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
exec /usr/bin/mariadbd --user=mysql --datadir="/var/lib/mysql"
