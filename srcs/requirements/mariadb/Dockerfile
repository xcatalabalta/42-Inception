FROM alpine:3.21

# Install MariaDB
RUN apk update && apk add --no-cache \
    mariadb \
    mariadb-client \
    mariadb-server-utils

# Create necessary directories with proper permissions
RUN mkdir -p /run/mysqld \
    && chown -R mysql:mysql /run/mysqld \
    && mkdir -p /var/lib/mysql \
    && chown -R mysql:mysql /var/lib/mysql

# Copy MariaDB configuration
COPY ./conf/my.cnf /etc/my.cnf

# Copy entrypoint script
COPY ./tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/entrypoint.sh"]
