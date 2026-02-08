#!/bin/bash
#
# Nginx Uninstallation Script
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_msg() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Detect installation
INSTALL_PREFIX="/usr/local/nginx"
if [ -d "$HOME/.local/nginx" ]; then
    INSTALL_PREFIX="$HOME/.local/nginx"
    INSTALL_TYPE="user"
else
    INSTALL_TYPE="system"
fi

print_msg "$YELLOW" "Detected installation: $INSTALL_TYPE"
print_msg "$YELLOW" "Installation path: $INSTALL_PREFIX"

# Confirm
read -p "Are you sure you want to uninstall nginx? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_msg "$YELLOW" "Uninstallation cancelled"
    exit 0
fi

# Stop nginx
if [ "$INSTALL_TYPE" = "system" ]; then
    if systemctl is-active --quiet nginx; then
        print_msg "$GREEN" "Stopping nginx service..."
        systemctl stop nginx
    fi
    
    if systemctl is-enabled --quiet nginx 2>/dev/null; then
        systemctl disable nginx
    fi
    
    if [ -f /etc/systemd/system/nginx.service ]; then
        rm /etc/systemd/system/nginx.service
        systemctl daemon-reload
        print_msg "$GREEN" "✓ Removed systemd service"
    fi
else
    if [ -f "$INSTALL_PREFIX/logs/nginx.pid" ]; then
        print_msg "$GREEN" "Stopping nginx..."
        "$INSTALL_PREFIX/sbin/nginx" -s quit 2>/dev/null || true
    fi
fi

# Remove files
if [ -d "$INSTALL_PREFIX" ]; then
    print_msg "$GREEN" "Removing nginx files..."
    rm -rf "$INSTALL_PREFIX"
    print_msg "$GREEN" "✓ Removed $INSTALL_PREFIX"
fi

# Remove symlink
if [ -L /usr/local/bin/nginx ]; then
    rm /usr/local/bin/nginx
    print_msg "$GREEN" "✓ Removed symlink"
fi

# Remove from PATH (user installation)
if [ "$INSTALL_TYPE" = "user" ]; then
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rc" ]; then
            sed -i "\|$INSTALL_PREFIX/sbin|d" "$rc"
        fi
    done
    print_msg "$GREEN" "✓ Removed from PATH"
fi

print_msg "$GREEN" "=== Uninstallation Complete ==="
print_msg "$YELLOW" "Nginx has been removed from your system"
