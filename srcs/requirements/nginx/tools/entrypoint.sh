#!/bin/sh
set -e

CERT_DIR=/etc/nginx/certs
CRT=$CERT_DIR/nginx.crt
KEY=$CERT_DIR/nginx.key
DOMAIN=fcatala-.42.fr

# Create directory
mkdir -p "$CERT_DIR"

if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then
    echo "Generating self-signed certificate for $DOMAIN..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "$KEY" -out "$CRT" -subj "/CN=$DOMAIN"
fi

# Start nginx in foreground
exec nginx -g 'daemon off;'
