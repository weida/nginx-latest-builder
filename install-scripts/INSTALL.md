# Nginx Binary Installation Guide

Complete guide for installing pre-compiled nginx binaries.

## Quick Install

### System-wide Installation (Recommended)
```bash
# Download and extract
tar xzf nginx-1.29.5-linux-amd64.tar.gz
cd nginx-1.29.5-linux-amd64

# Install (requires root)
sudo ./install.sh

# Start nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### User Installation (No Root Required)
```bash
# Download and extract
tar xzf nginx-1.29.5-linux-amd64.tar.gz
cd nginx-1.29.5-linux-amd64

# Install for current user
./install.sh --user

# Reload shell
source ~/.bashrc

# Start nginx
nginx
```

## Installation Options

### System Installation
```bash
# Default location (/usr/local/nginx)
sudo ./install.sh

# Custom location
sudo ./install.sh --prefix /opt/nginx

# Without systemd service
sudo ./install.sh --no-service
```

### User Installation
```bash
# Install to ~/.local/nginx
./install.sh --user

# Custom location
./install.sh --user --prefix ~/my-nginx
```

## What Gets Installed

```
/usr/local/nginx/          # or custom prefix
├── sbin/
│   └── nginx              # Nginx binary
├── conf/
│   ├── nginx.conf         # Main configuration
│   ├── mime.types         # MIME types
│   └── conf.d/            # Site configurations
├── html/                  # Web root
│   └── index.html         # Default page
└── logs/                  # Log files
    ├── access.log
    └── error.log
```

## System Service (System Installation)

```bash
# Start nginx
sudo systemctl start nginx

# Stop nginx
sudo systemctl stop nginx

# Restart nginx
sudo systemctl restart nginx

# Reload configuration
sudo systemctl reload nginx

# Enable auto-start
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx

# View logs
sudo journalctl -u nginx -f
```

## Manual Control (User Installation)

```bash
# Start nginx
nginx

# Stop nginx
nginx -s quit

# Reload configuration
nginx -s reload

# Test configuration
nginx -t

# Check version
nginx -V
```

## Configuration

### Main Configuration
Edit `/usr/local/nginx/conf/nginx.conf` (or your custom prefix)

### Add a Website
Create a file in `/usr/local/nginx/conf/conf.d/mysite.conf`:
```nginx
server {
    listen 80;
    server_name example.com;
    
    location / {
        root /usr/local/nginx/html;
        index index.html;
    }
}
```

### Enable HTTPS
```nginx
server {
    listen 443 ssl;
    listen 443 quic reuseport;  # HTTP/3
    http2 on;
    http3 on;
    
    server_name example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        root /usr/local/nginx/html;
        index index.html;
    }
}
```

## Uninstallation

```bash
# System installation
sudo ./uninstall.sh

# User installation
./uninstall.sh
```

## Troubleshooting

### Port 80 Already in Use
```bash
# Check what's using port 80
sudo lsof -i :80

# Use different port (edit nginx.conf)
listen 8080;
```

### Permission Denied
```bash
# System installation needs root
sudo systemctl start nginx

# User installation: use port > 1024
listen 8080;  # in nginx.conf
```

### Configuration Test Failed
```bash
# Test configuration
nginx -t

# Check error details
tail -f /usr/local/nginx/logs/error.log
```

## Architecture Selection

- **x86_64 / amd64**: Intel/AMD processors
  - Download: `nginx-{version}-linux-amd64.tar.gz`
  
- **aarch64 / arm64**: ARM processors (Raspberry Pi, Apple Silicon via Rosetta)
  - Download: `nginx-{version}-linux-arm64.tar.gz`

Check your architecture:
```bash
uname -m
```

## Features Included

- ✅ HTTP/2
- ✅ HTTP/3 (QUIC)
- ✅ TLS 1.3
- ✅ Latest OpenSSL 3.4+
- ✅ PCRE2 for regex
- ✅ Gzip compression
- ✅ Stream module (TCP/UDP proxy)
- ✅ Real IP module
- ✅ Stub status module

## Support

- GitHub: https://github.com/weida/nginx-latest-builder
- Issues: https://github.com/weida/nginx-latest-builder/issues
- Documentation: https://nginx.org/en/docs/
