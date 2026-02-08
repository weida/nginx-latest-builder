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

# Full description from file
FULL_DESC=$(cat << 'EOF'
# Nginx with HTTP/3 & Latest Dependencies

High-performance Nginx compiled from source with the latest stable versions of all dependencies. Automatically built and updated weekly.

## 🚀 Quick Start

```bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -p 443:443/udp \
  caoweida2004/nginx-http3:latest
```

## ✨ Features

- **HTTP/2** - Full HTTP/2 support
- **HTTP/3 (QUIC)** - Next-generation protocol over UDP
- **TLS 1.3** - Modern encryption with latest cipher suites
- **Latest OpenSSL** - Version 3.4+ with security patches
- **Multi-Architecture** - Native support for amd64 and arm64
- **Auto-Updated** - Weekly builds with latest nginx and dependencies

## 📦 Available Tags

- \`latest\` - Always the newest build
- \`1.29.5\` - Specific nginx version (recommended for production)
- \`1.29.4\`, \`1.28.2\` - Previous versions available

## 🔧 Usage Examples

### Basic Usage
\`\`\`bash
docker run -d -p 80:80 caoweida2004/nginx-http3:latest
\`\`\`

### With Custom Configuration
\`\`\`bash
docker run -d \\
  -v \$(pwd)/nginx.conf:/usr/local/nginx/conf/nginx.conf:ro \\
  -v \$(pwd)/html:/usr/local/nginx/html:ro \\
  -v \$(pwd)/ssl:/usr/local/nginx/ssl:ro \\
  -p 80:80 -p 443:443 -p 443:443/udp \\
  caoweida2004/nginx-http3:latest
\`\`\`

### Docker Compose
\`\`\`yaml
version: '3.8'
services:
  nginx:
    image: caoweida2004/nginx-http3:latest
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./nginx.conf:/usr/local/nginx/conf/nginx.conf:ro
      - ./html:/usr/local/nginx/html:ro
    restart: unless-stopped
\`\`\`

## 📋 Included Modules

- \`http_ssl_module\` - SSL/TLS support
- \`http_v2_module\` - HTTP/2 protocol
- \`http_v3_module\` - HTTP/3 (QUIC) protocol
- \`http_gzip_static_module\` - Pre-compressed content
- \`http_stub_status_module\` - Status monitoring
- \`http_realip_module\` - Real IP detection
- \`stream_module\` - TCP/UDP load balancing
- \`stream_ssl_module\` - Stream SSL support

## 📂 File Locations

- **Config**: \`/usr/local/nginx/conf/nginx.conf\`
- **Sites**: \`/usr/local/nginx/conf/conf.d/\`
- **Web Root**: \`/usr/local/nginx/html/\`
- **Logs**: \`/usr/local/nginx/logs/\`
- **Binary**: \`/usr/local/nginx/sbin/nginx\`

## 🔍 Verify Installation

\`\`\`bash
# Check nginx version
docker run --rm caoweida2004/nginx-http3:latest /usr/local/nginx/sbin/nginx -V

# Test HTTP/3 support
curl --http3 https://your-domain.com
\`\`\`

## 🛠️ Common Commands

\`\`\`bash
# Reload configuration
docker exec <container> /usr/local/nginx/sbin/nginx -s reload

# Test configuration
docker exec <container> /usr/local/nginx/sbin/nginx -t

# View logs
docker logs -f <container>

# Stop gracefully
docker exec <container> /usr/local/nginx/sbin/nginx -s quit
\`\`\`

## 📊 Build Information

- **Base Image**: Ubuntu 24.04
- **Build Frequency**: Weekly (every Sunday)
- **Source**: Compiled from official nginx source
- **Dependencies**: Latest stable versions from GitHub

## 🔗 Links

- **GitHub**: https://github.com/weida/nginx-latest-builder
- **Documentation**: https://github.com/weida/nginx-latest-builder/blob/main/README-Docker.md
- **Examples**: https://github.com/weida/nginx-latest-builder/tree/main/examples
- **Issues**: https://github.com/weida/nginx-latest-builder/issues

## 📄 License

Nginx is licensed under the 2-clause BSD license.

## 🤝 Contributing

Contributions welcome! Please visit the GitHub repository.
EOF
)

echo "Updating Docker Hub repository description..."

# Login to Docker Hub and get JWT token
LOGIN_RESPONSE=$(curl -s -X POST \
  https://hub.docker.com/v2/users/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${DOCKERHUB_USERNAME}\",\"password\":\"${DOCKERHUB_TOKEN}\"}")

JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

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
  -d "{\"description\":\"${SHORT_DESC}\",\"full_description\":\"${FULL_DESC}\"}")

if echo "$UPDATE_RESPONSE" | grep -q "description"; then
    echo "✓ Successfully updated Docker Hub repository description"
    echo "  Repository: ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPOSITORY}"
    echo "  View at: https://hub.docker.com/r/${DOCKERHUB_USERNAME}/${DOCKERHUB_REPOSITORY}"
else
    echo "Error: Failed to update description"
    echo "Response: $UPDATE_RESPONSE"
    exit 1
fi
