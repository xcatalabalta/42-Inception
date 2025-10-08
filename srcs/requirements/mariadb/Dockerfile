FROM alpine:3.21

# Install MariaDB server and client.
# The `mariadb` package on Alpine includes both the server and client tools.
RUN apk update && \
    apk add --no-cache mariadb

# Create necessary directories for MariaDB run files and data, and set correct ownership.
# MariaDB runs as the 'mysql' user, so these directories must be owned by 'mysql'.
RUN mkdir -p /run/mysqld /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld

# Copy configuration and entrypoint script. 
# Paths are relative to the build context (srcs/requirements/mariadb/).
COPY conf/my.cnf /etc/my.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Ensure the entrypoint script is executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default MariaDB port
EXPOSE 3306

# REMOVED: USER mysql - User switching is now handled by entrypoint.sh

# The entrypoint script will handle database initialization and start the server
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

