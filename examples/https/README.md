# HTTPS Setup with Self-Signed Certificate

Run nginx with HTTPS support using a self-signed certificate (for testing).

## Quick Start

1. Generate SSL certificate:
   ```bash
   ./generate-cert.sh
   ```

2. Start nginx:
   ```bash
   docker-compose up -d
   ```

3. Visit: https://localhost (accept the security warning)

## Files

- `docker-compose.yml` - Docker configuration
- `generate-cert.sh` - Script to create SSL certificate
- `nginx.conf` - Nginx configuration with HTTPS
- `html/` - Your website files
- `ssl/` - SSL certificates (auto-generated)

## For Production

Replace self-signed certificates with real ones from Let's Encrypt or your CA:
1. Put your certificate in `ssl/cert.pem`
2. Put your private key in `ssl/key.pem`
3. Update `server_name` in `nginx.conf`

## Commands

```bash
# Generate certificate
./generate-cert.sh

# Start nginx
docker-compose up -d

# View logs
docker-compose logs -f

# Reload after config changes
docker-compose exec nginx /usr/local/nginx/sbin/nginx -s reload
```
