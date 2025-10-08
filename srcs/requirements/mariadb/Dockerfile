FROM alpine:3.21

# Install MariaDB
RUN apk update && apk add --no-cache \
    mariadb mariadb-client mariadb-server-utils

# Remove Alpine’s default client config that forces host=mariadb
RUN rm -f /etc/mysql/mariadb.conf.d/50-client.cnf

# Create required directories and permissions
RUN mkdir -p /run/mysqld /var/lib/mysql \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Copy configuration and entrypoint
COPY ./conf/my.cnf /etc/my.cnf
COPY ./tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3306
ENTRYPOINT ["/entrypoint.sh"]

