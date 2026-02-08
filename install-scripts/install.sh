#!/bin/bash
#
# Nginx Installation Script
# Supports both system-wide and user-local installation
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
INSTALL_PREFIX="/usr/local/nginx"
INSTALL_TYPE="system"
CREATE_SERVICE=true

# Print colored message
print_msg() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Show usage
usage() {
    cat << EOF
Nginx Installation Script

Usage: $0 [OPTIONS]

Options:
    --prefix PATH       Installation directory (default: /usr/local/nginx)
    --user              Install for current user only (no root required)
    --no-service        Don't create systemd service
    -h, --help          Show this help message

Examples:
    # System-wide installation (requires root)
    sudo $0

    # User installation (no root required)
    $0 --user

    # Custom location
    sudo $0 --prefix /opt/nginx

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --prefix)
            INSTALL_PREFIX="$2"
            shift 2
            ;;
        --user)
            INSTALL_TYPE="user"
            INSTALL_PREFIX="$HOME/.local/nginx"
            CREATE_SERVICE=false
            shift
            ;;
        --no-service)
            CREATE_SERVICE=false
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_msg "$RED" "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if running as root for system installation
if [ "$INSTALL_TYPE" = "system" ] && [ "$EUID" -ne 0 ]; then
    print_msg "$RED" "Error: System installation requires root privileges"
    print_msg "$YELLOW" "Run with: sudo $0"
    print_msg "$YELLOW" "Or use: $0 --user (for user installation)"
    exit 1
fi

print_msg "$GREEN" "=== Nginx Installation ==="
print_msg "$YELLOW" "Installation type: $INSTALL_TYPE"
print_msg "$YELLOW" "Installation path: $INSTALL_PREFIX"

# Create installation directory
mkdir -p "$INSTALL_PREFIX"

# Copy nginx files
print_msg "$GREEN" "Copying nginx files..."
cp -r sbin conf html logs "$INSTALL_PREFIX/"

# Create nginx user for system installation
if [ "$INSTALL_TYPE" = "system" ]; then
    if ! id nginx &>/dev/null; then
        print_msg "$GREEN" "Creating nginx user..."
        useradd -r -s /sbin/nologin nginx
    fi
fi

# Set permissions
if [ "$INSTALL_TYPE" = "system" ]; then
    chown -R nginx:nginx "$INSTALL_PREFIX"
    chmod 755 "$INSTALL_PREFIX/sbin/nginx"
else
    chmod 755 "$INSTALL_PREFIX/sbin/nginx"
fi

# Create systemd service
if [ "$CREATE_SERVICE" = true ]; then
    print_msg "$GREEN" "Creating systemd service..."
    cat > /etc/systemd/system/nginx.service << EOF
[Unit]
Description=Nginx HTTP Server
After=network.target

[Service]
Type=forking
PIDFile=$INSTALL_PREFIX/logs/nginx.pid
ExecStartPre=$INSTALL_PREFIX/sbin/nginx -t
ExecStart=$INSTALL_PREFIX/sbin/nginx
ExecReload=$INSTALL_PREFIX/sbin/nginx -s reload
ExecStop=$INSTALL_PREFIX/sbin/nginx -s quit
PrivateTmp=true
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    print_msg "$GREEN" "✓ Systemd service created"
fi

# Add to PATH for user installation
if [ "$INSTALL_TYPE" = "user" ]; then
    SHELL_RC="$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
    fi
    
    if ! grep -q "$INSTALL_PREFIX/sbin" "$SHELL_RC"; then
        echo "export PATH=\"$INSTALL_PREFIX/sbin:\$PATH\"" >> "$SHELL_RC"
        print_msg "$GREEN" "✓ Added to PATH in $SHELL_RC"
    fi
fi

# Create symlink for system installation
if [ "$INSTALL_TYPE" = "system" ] && [ "$INSTALL_PREFIX" != "/usr/local/nginx" ]; then
    ln -sf "$INSTALL_PREFIX/sbin/nginx" /usr/local/bin/nginx
    print_msg "$GREEN" "✓ Created symlink in /usr/local/bin"
fi

print_msg "$GREEN" "=== Installation Complete ==="
print_msg "$YELLOW" "Nginx installed to: $INSTALL_PREFIX"

# Show next steps
if [ "$INSTALL_TYPE" = "system" ]; then
    cat << EOF

Next steps:
  1. Start nginx:
     sudo systemctl start nginx

  2. Enable auto-start:
     sudo systemctl enable nginx

  3. Check status:
     sudo systemctl status nginx

  4. View logs:
     sudo journalctl -u nginx -f

Configuration:
  - Main config: $INSTALL_PREFIX/conf/nginx.conf
  - Site configs: $INSTALL_PREFIX/conf/conf.d/
  - Web root: $INSTALL_PREFIX/html/

Commands:
  - Test config: sudo nginx -t
  - Reload: sudo systemctl reload nginx
  - Stop: sudo systemctl stop nginx
EOF
else
    cat << EOF

Next steps:
  1. Reload shell:
     source ~/.bashrc  # or source ~/.zshrc

  2. Start nginx:
     nginx

  3. Stop nginx:
     nginx -s quit

Configuration:
  - Main config: $INSTALL_PREFIX/conf/nginx.conf
  - Web root: $INSTALL_PREFIX/html/

Commands:
  - Test config: nginx -t
  - Reload: nginx -s reload
  - Stop: nginx -s quit

Note: Nginx will run on port 8080 by default for user installation.
Edit $INSTALL_PREFIX/conf/nginx.conf to change the port.
EOF
fi

print_msg "$GREEN" "Installation successful!"
