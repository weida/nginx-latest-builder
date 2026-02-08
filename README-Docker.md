# Nginx Docker Usage Guide

Complete beginner-friendly guide with ready-to-use examples.

## 🚀 Quick Start (Choose One)

### Option 1: Instant Start (No Configuration)
```bash
docker run -d -p 80:80 caoweida2004/nginx-latest:latest
```
Visit: http://localhost

### Option 2: With Your Website (3 Steps)
```bash
# 1. Create folder and add your website
mkdir my-website && cd my-website
mkdir html
echo "<h1>Hello World</h1>" > html/index.html

# 2. Download docker-compose.yml
curl -O https://raw.githubusercontent.com/weida/nginx-latest-builder/main/examples/basic/docker-compose.yml

# 3. Start
docker-compose up -d
```
Visit: http://localhost

## 📦 Ready-to-Use Examples

Download complete working examples from `examples/` folder:

### 1. Basic HTTP Server (`examples/basic/`)
Simplest setup - just add HTML files
```bash
cd examples/basic
docker-compose up -d
```

### 2. HTTPS Server (`examples/https/`)
HTTPS + HTTP/3 with auto-generated certificate
```bash
cd examples/https
./generate-cert.sh
docker-compose up -d
```

## 📖 Complete Beginner Tutorial

### Step 1: Install Docker
- **Windows/Mac**: Download [Docker Desktop](https://www.docker.com/products/docker-desktop)
- **Linux**: `curl -fsSL https://get.docker.com | sh`

### Step 2: Create Your Project
```bash
mkdir my-nginx
cd my-nginx
```

### Step 3: Create docker-compose.yml
```yaml
version: '3.8'
services:
  nginx:
    image: caoweida2004/nginx-latest:latest
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/local/nginx/html:ro
    restart: unless-stopped
```

### Step 4: Add Your Website
```bash
mkdir html
echo "<h1>My Website</h1>" > html/index.html
```

### Step 5: Start Nginx
```bash
docker-compose up -d
```

### Step 6: View Your Site
Open browser: http://localhost

## 🛠️ Common Commands

```bash
# Start nginx
docker-compose up -d

# Stop nginx
docker-compose down

# Restart nginx
docker-compose restart

# View logs
docker-compose logs -f

# Update to latest version
docker-compose pull && docker-compose up -d
```

## 🔧 Customization

### Change Port
Edit `docker-compose.yml`:
```yaml
ports:
  - "8080:80"  # Use port 8080
```

### Add Multiple Pages
```bash
html/
├── index.html
├── about.html
└── contact.html
```

## ❓ Troubleshooting

### "Port already in use"
```bash
# Use different port
docker run -d -p 8080:80 caoweida2004/nginx-latest:latest
```

### "Permission denied"
```bash
# Linux: add sudo
sudo docker-compose up -d
```

### Check if running
```bash
docker ps
```

### View errors
```bash
docker logs <container-name>
```

## 📚 More Examples

See `examples/` folder for:
- HTTPS setup
- Reverse proxy
- Load balancing
- Custom configuration

## 🔗 Links

- **Examples**: https://github.com/weida/nginx-latest-builder/tree/main/examples
- **GitHub**: https://github.com/weida/nginx-latest-builder
- **Get Help**: https://github.com/weida/nginx-latest-builder/issues

## ✨ Features

- HTTP/2 and HTTP/3 (QUIC)
- TLS 1.3
- Latest OpenSSL 3.4+
- Multi-architecture (amd64, arm64)
- Auto-updated weekly
