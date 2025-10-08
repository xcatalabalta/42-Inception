#!/bin/sh
set -e

echo "Starting MariaDB entrypoint..."

# ---------------------------------------------------------------------------
# Load secrets
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Ensure required environment variables
# ---------------------------------------------------------------------------

if [ -z "$MYSQL_DATABASE" ]; then
	echo "⚠ MYSQL_DATABASE not set, using default: inception_db"
	MYSQL_DATABASE="inception_db"
fi

if [ -z "$MYSQL_USER" ]; then
	echo "⚠ MYSQL_USER not set, using default: inception_user"
	MYSQL_USER="inception_user"
fi

# ---------------------------------------------------------------------------
# Initialize database if not present
# ---------------------------------------------------------------------------

if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "Initializing database..."
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

	echo "Starting temporary MariaDB server..."
	mariadbd --user=mysql --skip-networking \
		--socket=/tmp/mysql_init.sock &
	pid="$!"

	echo "Waiting for MariaDB to be ready..."
	for i in $(seq 1 60); do
		if mariadb-admin --socket=/tmp/mysql_init.sock ping >/dev/null 2>&1; then
			echo "✓ MariaDB temporary server is ready"
			break
		fi
		if [ "$i" -eq 60 ]; then
			echo "ERROR: MariaDB failed to start in time"
			kill "$pid" 2>/dev/null || true
			exit 1
		fi
		sleep 1
	done

	echo "Running initialization SQL..."

	cat <<- EOF_SQL | mariadb --no-defaults --protocol=socket --socket=/tmp/mysql_init.sock
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';
		CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		DELETE FROM mysql.user WHERE User='';
		DROP DATABASE IF EXISTS test;
		DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
		FLUSH PRIVILEGES;
	EOF_SQL

	echo "✓ Database initialized successfully"

	echo "Stopping temporary server..."
	mariadb-admin --socket=/tmp/mysql_init.sock shutdown
	wait "$pid" 2>/dev/null || true

	echo "✓ Initialization complete"
else
	echo "Database already initialized, skipping..."
fi

echo "Starting MariaDB server..."
exec mariadbd --user=mysql --console

