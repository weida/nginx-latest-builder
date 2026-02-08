# Nginx Docker Usage Guide

## Features

- ✅ HTTP/2 support
- ✅ HTTP/3 (QUIC) support
- ✅ TLS 1.3
- ✅ Post-Quantum Cryptography
- ✅ Multi-architecture support (x86_64, ARM64)

## Quick Start

### Using Docker

```bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -p 443:443/udp \
  caoweida2004/nginx-latest:latest
```

### Using Docker Compose

1. Create directory structure:
```bash
mkdir -p conf/conf.d html ssl
```

2. Copy configuration files to corresponding directories

3. Start container:
```bash
docker-compose up -d
```

## Configuration Files

- `conf/nginx.conf` - Main configuration file
- `conf/conf.d/*.conf` - Site configuration files
- `html/` - Static files directory
- `ssl/` - SSL certificates directory

## Common Commands

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Restart
docker-compose restart

# Reload configuration (without restart)
docker-compose exec nginx /usr/local/nginx/sbin/nginx -s reload

# View logs
docker-compose logs -f nginx

# Test configuration
docker-compose exec nginx /usr/local/nginx/sbin/nginx -t

# Check version
docker-compose exec nginx /usr/local/nginx/sbin/nginx -V
```

## SSL Certificate Configuration

Place certificate files in the `ssl/` directory:
- `ssl/cert.pem` - Certificate file
- `ssl/key.pem` - Private key file

Then modify the `server_name` in `conf/conf.d/https-example.conf`.

## HTTP/3 Testing

```bash
# Test HTTP/3 with curl
curl --http3 https://your-domain.com

# Test with browser
# Chrome: chrome://flags/#enable-quic
# Firefox: about:config -> network.http.http3.enabled
```

## Custom Configuration

### Mount custom configuration

```bash
docker run -d \
  -v /path/to/nginx.conf:/usr/local/nginx/conf/nginx.conf:ro \
  -v /path/to/conf.d:/usr/local/nginx/conf/conf.d:ro \
  -v /path/to/html:/usr/local/nginx/html:ro \
  -v /path/to/ssl:/usr/local/nginx/ssl:ro \
  -p 80:80 -p 443:443 -p 443:443/udp \
  caoweida2004/nginx-latest:latest
```

## Directory Structure

```
.
├── conf/
│   ├── nginx.conf              # Main configuration
│   └── conf.d/
│       ├── default.conf        # Default site
│       └── https-example.conf  # HTTPS + HTTP/3 example
├── html/                       # Static files
├── ssl/                        # SSL certificates
└── docker-compose.yml
```

## Troubleshooting

### View error logs
```bash
docker-compose logs nginx
```

### Enter container
```bash
docker-compose exec nginx bash
```

### Test configuration file
```bash
docker-compose exec nginx /usr/local/nginx/sbin/nginx -t
```

## Performance Optimization Tips

1. Adjust `worker_processes` based on CPU cores
2. Tune `worker_connections` according to concurrency needs
3. Enable HTTP/2 and HTTP/3 for better performance
4. Configure appropriate caching strategies
5. Use gzip compression to reduce transfer size

## Security Recommendations

1. Regularly update images to get latest security patches
2. Use strong cipher suites and TLS 1.3
3. Configure appropriate security headers
4. Limit request size and rate
5. Use post-quantum cryptography for future-proof security

## Support

- GitHub: https://github.com/weida/nginx-latest-builder
- Issues: https://github.com/weida/nginx-latest-builder/issues
