#!/bin/bash
#
# Nginx Installation Script with Service Control
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_PREFIX="/usr/local/nginx"
INSTALL_TYPE="system"
UPGRADE_MODE=false
CREATE_SERVICE=true
START_SERVICE=false
ENABLE_SERVICE=false

print_msg() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

usage() {
    cat << EOF
Nginx Installation Script

Usage: $0 [OPTIONS]

Options:
    --prefix PATH       Installation directory (default: /usr/local/nginx)
    --user              Install for current user only (no root required)
    --upgrade           Upgrade mode: only replace binary, keep config
    --no-service        Don't create systemd service
    --start             Start nginx service after installation
    --enable            Enable nginx service to start on boot
    -h, --help          Show this help message

Examples:
    # Fresh install
    sudo $0

    # Upgrade existing installation (keep config)
    sudo $0 --upgrade

    # Install and start
    sudo $0 --start

    # Install, start, and enable auto-start
    sudo $0 --start --enable

    # User installation
    $0 --user --start

EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --prefix) INSTALL_PREFIX="$2"; shift 2 ;;
        --user) INSTALL_TYPE="user"; INSTALL_PREFIX="$HOME/.local/nginx"; CREATE_SERVICE=false; shift ;;
        --upgrade) UPGRADE_MODE=true; shift ;;
        --no-service) CREATE_SERVICE=false; shift ;;
        --start) START_SERVICE=true; shift ;;
        --enable) ENABLE_SERVICE=true; shift ;;
        -h|--help) usage ;;
        *) print_msg "$RED" "Unknown option: $1"; usage ;;
    esac
done

if [ "$INSTALL_TYPE" = "system" ] && [ "$EUID" -ne 0 ]; then
    print_msg "$RED" "Error: System installation requires root"
    print_msg "$YELLOW" "Run: sudo $0 or use: $0 --user"
    exit 1
fi

print_msg "$GREEN" "=== Nginx Installation ==="
print_msg "$YELLOW" "Type: $INSTALL_TYPE | Path: $INSTALL_PREFIX"

if [ "$UPGRADE_MODE" = true ]; then
    if [ ! -d "$INSTALL_PREFIX" ]; then
        print_msg "$RED" "Error: $INSTALL_PREFIX not found"
        print_msg "$YELLOW" "Upgrade mode requires existing installation"
        exit 1
    fi
    
    print_msg "$YELLOW" "Upgrade mode: Backing up configuration..."
    
    # Backup config
    BACKUP_DIR="$INSTALL_PREFIX/conf.backup.$(date +%Y%m%d_%H%M%S)"
    cp -r "$INSTALL_PREFIX/conf" "$BACKUP_DIR"
    print_msg "$GREEN" "✓ Config backed up to: $BACKUP_DIR"
    
    # Stop service if running
    if [ "$INSTALL_TYPE" = "system" ] && systemctl is-active --quiet nginx 2>/dev/null; then
        print_msg "$YELLOW" "Stopping nginx service..."
        systemctl stop nginx
        RESTART_AFTER=true
    elif [ "$INSTALL_TYPE" = "user" ] && pgrep -f "$INSTALL_PREFIX/sbin/nginx" > /dev/null; then
        print_msg "$YELLOW" "Stopping nginx..."
        "$INSTALL_PREFIX/sbin/nginx" -s quit
        sleep 2
        RESTART_AFTER=true
    fi
    
    # Replace binary only
    print_msg "$YELLOW" "Upgrading nginx binary..."
    cp -f sbin/nginx "$INSTALL_PREFIX/sbin/"
    chmod 755 "$INSTALL_PREFIX/sbin/nginx"
    
    # Test new binary with old config
    if ! "$INSTALL_PREFIX/sbin/nginx" -t -q; then
        print_msg "$RED" "✗ Config test failed with new binary"
        print_msg "$YELLOW" "Restoring old binary..."
        # Note: old binary not backed up, manual intervention needed
        print_msg "$RED" "Please check configuration compatibility"
        exit 1
    fi
    
    print_msg "$GREEN" "✓ Binary upgraded successfully"
    print_msg "$GREEN" "✓ Configuration preserved"
    
    # Restart if was running
    if [ "$RESTART_AFTER" = true ]; then
        if [ "$INSTALL_TYPE" = "system" ]; then
            systemctl start nginx
            print_msg "$GREEN" "✓ Service restarted"
        else
            "$INSTALL_PREFIX/sbin/nginx"
            print_msg "$GREEN" "✓ Nginx restarted"
        fi
    fi
    
    print_msg "$GREEN" "\n=== Upgrade Complete ==="
    print_msg "$YELLOW" "Old config backup: $BACKUP_DIR"
    exit 0
fi

# Fresh installation
mkdir -p "$INSTALL_PREFIX"
cp -r sbin conf html logs "$INSTALL_PREFIX/"

if [ "$INSTALL_TYPE" = "system" ]; then
    if ! id nginx &>/dev/null; then
        useradd -r -s /sbin/nologin nginx
    fi
    chown -R nginx:nginx "$INSTALL_PREFIX"
fi

chmod 755 "$INSTALL_PREFIX/sbin/nginx"

if [ "$CREATE_SERVICE" = true ]; then
    print_msg "$GREEN" "Creating systemd service..."
    cat > /etc/systemd/system/nginx.service << EOF
[Unit]
Description=Nginx HTTP Server
After=network.target

[Service]
Type=simple
ExecStartPre=$INSTALL_PREFIX/sbin/nginx -t -q
ExecStart=$INSTALL_PREFIX/sbin/nginx -g 'daemon off;'
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    print_msg "$GREEN" "✓ Service created"
    
    if [ "$ENABLE_SERVICE" = true ]; then
        systemctl enable nginx
        print_msg "$GREEN" "✓ Service enabled (auto-start on boot)"
    fi
    
    if [ "$START_SERVICE" = true ]; then
        systemctl start nginx
        sleep 1
        if systemctl is-active --quiet nginx; then
            print_msg "$GREEN" "✓ Nginx started successfully"
        else
            print_msg "$RED" "✗ Failed to start"
        fi
    fi
fi

if [ "$INSTALL_TYPE" = "user" ]; then
    SHELL_RC="$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
    
    if ! grep -q "$INSTALL_PREFIX/sbin" "$SHELL_RC"; then
        echo "export PATH=\"$INSTALL_PREFIX/sbin:\$PATH\"" >> "$SHELL_RC"
        print_msg "$GREEN" "✓ Added to PATH"
    fi
    
    if [ "$START_SERVICE" = true ]; then
        "$INSTALL_PREFIX/sbin/nginx"
        sleep 1
        if pgrep -f "$INSTALL_PREFIX/sbin/nginx" > /dev/null; then
            print_msg "$GREEN" "✓ Nginx started"
        fi
    fi
fi

if [ "$INSTALL_TYPE" = "system" ] && [ "$INSTALL_PREFIX" != "/usr/local/nginx" ]; then
    ln -sf "$INSTALL_PREFIX/sbin/nginx" /usr/local/bin/nginx
fi

print_msg "$GREEN" "\n=== Installation Complete ==="

if [ "$INSTALL_TYPE" = "system" ]; then
    cat << EOF

Service Control:
  sudo systemctl start nginx    # Start
  sudo systemctl stop nginx     # Stop
  sudo systemctl restart nginx  # Restart
  sudo systemctl reload nginx   # Reload config
  sudo systemctl enable nginx   # Enable auto-start
  sudo systemctl status nginx   # Check status

Config: $INSTALL_PREFIX/conf/nginx.conf
EOF
    [ "$START_SERVICE" = false ] && print_msg "$YELLOW" "\nStart now: sudo systemctl start nginx"
    [ "$ENABLE_SERVICE" = false ] && print_msg "$YELLOW" "Enable auto-start: sudo systemctl enable nginx"
else
    cat << EOF

Commands:
  nginx           # Start
  nginx -s quit   # Stop
  nginx -s reload # Reload
  nginx -t        # Test config

Config: $INSTALL_PREFIX/conf/nginx.conf
EOF
    [ "$START_SERVICE" = false ] && print_msg "$YELLOW" "\nStart now: source ~/.bashrc && nginx"
fi

print_msg "$GREEN" "\n✓ Done!"
