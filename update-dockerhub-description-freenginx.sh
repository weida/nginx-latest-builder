#!/bin/bash
#
# Update Docker Hub repository description for freenginx
# Usage: ./update-dockerhub-description-freenginx.sh
#

DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-caoweida2004}"
DOCKERHUB_REPOSITORY="freenginx-http3"
DOCKERHUB_TOKEN="${DOCKERHUB_TOKEN}"

if [ -z "$DOCKERHUB_TOKEN" ]; then
    echo "Error: DOCKERHUB_TOKEN environment variable is not set"
    echo "Get your token from: https://hub.docker.com/settings/security"
    exit 1
fi

# Short description (100 characters max)
SHORT_DESC="freenginx with HTTP/3, TLS 1.3, latest OpenSSL. Multi-arch (amd64/arm64). Auto-updated weekly."

# Full description
FULL_DESC="# freenginx with HTTP/3

High-performance freenginx with HTTP/3 (QUIC), TLS 1.3, and latest dependencies.

## Quick Start

**Standard version** (Ubuntu 22.04+, Debian 12+, RHEL 9+):
\`\`\`bash
docker run -d -p 80:80 -p 443:443 -p 443:443/udp caoweida2004/freenginx-http3:latest
\`\`\`

**Compatible version** (CentOS 7, Alibaba Cloud Linux 3, Ubuntu 18.04+):
\`\`\`bash
docker run -d -p 80:80 -p 443:443 -p 443:443/udp caoweida2004/freenginx-http3:latest-compat
\`\`\`

## Features
- ✅ HTTP/2 and HTTP/3 (QUIC)
- ✅ TLS 1.3 with modern cipher suites
- ✅ Latest OpenSSL 3.4+, PCRE2, zlib
- ✅ Multi-architecture (amd64, arm64)
- ✅ Statically linked for minimal dependencies
- ✅ Automated weekly builds

## Version Selection

### Standard Version (latest)
- Base: Distroless Debian 12
- glibc: 2.39+
- Best for: Modern systems (Ubuntu 22.04+, Debian 12+, RHEL 9+)
- Minimal CVE vulnerabilities

### Compatible Version (latest-compat)
- Base: CentOS 7 build + AlmaLinux 8 minimal runtime
- glibc: 2.17+
- Best for: Older systems (CentOS 7, Alibaba Cloud Linux 2/3, Ubuntu 18.04+)

## Links
- GitHub: https://github.com/weida/nginx-latest-builder
- Documentation: https://github.com/weida/nginx-latest-builder/blob/main/README-Docker.md
- freenginx: https://freenginx.org"

echo "Updating Docker Hub repository description for freenginx..."

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
