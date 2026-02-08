#!/bin/bash

# Create ssl directory if it doesn't exist
mkdir -p ssl

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem \
  -out ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

echo "✓ SSL certificate generated in ssl/ directory"
echo "  - ssl/cert.pem (certificate)"
echo "  - ssl/key.pem (private key)"
echo ""
echo "Now run: docker-compose up -d"
