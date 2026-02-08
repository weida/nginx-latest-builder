#!/bin/bash
#
# Update Docker Hub repository description
# Usage: ./update-dockerhub-description.sh
#

DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-caoweida2004}"
DOCKERHUB_REPOSITORY="nginx-http3"
DOCKERHUB_TOKEN="${DOCKERHUB_TOKEN}"

if [ -z "$DOCKERHUB_TOKEN" ]; then
    echo "Error: DOCKERHUB_TOKEN environment variable is not set"
    echo "Get your token from: https://hub.docker.com/settings/security"
    exit 1
fi

# Short description (100 characters max)
SHORT_DESC="Nginx with HTTP/3, TLS 1.3, latest OpenSSL. Multi-arch (amd64/arm64). Auto-updated weekly."

# Full description - read from file or use inline
FULL_DESC_FILE="dockerhub-description.md"

if [ -f "$FULL_DESC_FILE" ]; then
    FULL_DESC=$(cat "$FULL_DESC_FILE")
else
    FULL_DESC="# Nginx with HTTP/3

High-performance Nginx with HTTP/3 (QUIC), TLS 1.3, and latest dependencies.

## Quick Start
\`\`\`bash
docker run -d -p 80:80 -p 443:443 -p 443:443/udp caoweida2004/nginx-http3:latest
\`\`\`

## Features
- HTTP/2 and HTTP/3 (QUIC)
- TLS 1.3
- Latest OpenSSL 3.4+
- Multi-architecture (amd64, arm64)

## Links
- GitHub: https://github.com/weida/nginx-latest-builder
- Documentation: https://github.com/weida/nginx-latest-builder/blob/main/README-Docker.md"
fi

echo "Updating Docker Hub repository description..."

# Escape JSON properly
SHORT_DESC_JSON=$(echo "$SHORT_DESC" | jq -Rs .)
FULL_DESC_JSON=$(echo "$FULL_DESC" | jq -Rs .)

# Login to Docker Hub and get JWT token
LOGIN_RESPONSE=$(curl -s -X POST \
  https://hub.docker.com/v2/users/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${DOCKERHUB_USERNAME}\",\"password\":\"${DOCKERHUB_TOKEN}\"}")

JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token // empty')

if [ -z "$JWT_TOKEN" ]; then
    echo "Error: Failed to login to Docker Hub"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

# Update repository description
UPDATE_RESPONSE=$(curl -s -X PATCH \
  "https://hub.docker.com/v2/repositories/${DOCKERHUB_USERNAME}/${DOCKERHUB_REPOSITORY}/" \
  -H "Authorization: JWT ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"description\":${SHORT_DESC_JSON},\"full_description\":${FULL_DESC_JSON}}")

if echo "$UPDATE_RESPONSE" | jq -e '.description' > /dev/null 2>&1; then
    echo "✓ Successfully updated Docker Hub repository description"
    echo "  Repository: ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPOSITORY}"
    echo "  View at: https://hub.docker.com/r/${DOCKERHUB_USERNAME}/${DOCKERHUB_REPOSITORY}"
else
    echo "Error: Failed to update description"
    echo "Response: $UPDATE_RESPONSE"
    exit 1
fi
