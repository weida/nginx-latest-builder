# Basic Nginx Setup

The simplest way to run nginx with custom content.

## Quick Start

1. Put your website files in the `html/` folder
2. Run: `docker-compose up -d`
3. Visit: http://localhost

## Files

- `docker-compose.yml` - Docker configuration
- `html/index.html` - Your website homepage

## Commands

```bash
# Start nginx
docker-compose up -d

# Stop nginx
docker-compose down

# View logs
docker-compose logs -f

# Restart nginx
docker-compose restart
```

## Customization

Edit `html/index.html` to change your website content.
