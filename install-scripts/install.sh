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
    --no-service        Don't create systemd service
    --start             Start nginx service after installation
    --enable            Enable nginx service to start on boot
    -h, --help          Show this help message

Examples:
    # Install only
    sudo $0

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
