FROM alpine:3.21

RUN apk add --no-cache nginx openssl
RUN apk update && apk add --no-cache wget curl
RUN mkdir -p /run/nginx /etc/nginx/certs /usr/share/nginx/html

# Remove the default nginx config and use your complete config
COPY conf/my_nginx.conf /etc/nginx/nginx.conf

COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# COPY html/index.html /usr/share/nginx/html/index.html

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
