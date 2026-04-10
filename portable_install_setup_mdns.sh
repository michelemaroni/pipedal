#!/bin/bash
set -e

echo "=== PiPedal mDNS Domain Setup ==="
echo

if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges."
    exit 1
fi

echo "Current avahi domain: $(grep '^domain-name=' /etc/avahi/avahi-daemon.conf 2>/dev/null | cut -d= -f2 || echo 'default (local)')"
echo "Current hostname: $(hostname)"
echo

echo "Options:"
echo "  1. Use .local domain (default)"
echo "  2. Use custom domain (e.g., .pipedal)"
echo "  3. Disable mDNS entirely"
echo

read -p "Select option [1]: " choice
choice=${choice:-1}

case $choice in
    1)
        DOMAIN="local"
        echo "Setting domain to: $DOMAIN"
        ;;
    2)
        read -p "Enter custom domain (without dot, e.g., pipedal): " DOMAIN
        if [ -z "$DOMAIN" ]; then
            echo "No domain entered. Keeping current setting."
            exit 0
        fi
        echo "Setting domain to: $DOMAIN"
        ;;
    3)
        DOMAIN="no"
        echo "Disabling mDNS service announcement"
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac

if [ "$DOMAIN" != "no" ]; then
    if [ -f "/etc/avahi/avahi-daemon.conf" ]; then
        if grep -q "^domain-name=" /etc/avahi/avahi-daemon.conf; then
            sudo sed -i "s/^domain-name=.*/domain-name=$DOMAIN/" /etc/avahi/avahi-daemon.conf
        else
            sudo sed -i "/^\[server\]/a domain-name=$DOMAIN" /etc/avahi/avahi-daemon.conf
        fi
        echo "Updated /etc/avahi/avahi-daemon.conf"
    fi
else
    if grep -q "^domain-name=" /etc/avahi/avahi-daemon.conf; then
        sudo sed -i "s/^domain-name=.*/domain-name=no/" /etc/avahi/avahi-daemon.conf
    fi
fi

echo ""
echo "Restarting avahi-daemon..."
sudo systemctl restart avahi-daemon 2>/dev/null || sudo service avahi-daemon restart 2>/dev/null || true

echo ""
echo "=== Setup Complete ==="
echo ""
echo "You can now access pipedal at:"
if [ "$DOMAIN" = "no" ]; then
    echo "  http://localhost:8080"
    echo "  http://$(hostname -I | awk '{print $1}'):8080"
else
    echo "  http://$(hostname).$DOMAIN:8080 (mDNS - from any device on network)"
    echo "  http://localhost:8080 (local)"
fi
echo ""
echo "Note: Some devices may need to flush DNS cache or restart to see the new domain."
