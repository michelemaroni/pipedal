#!/usr/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="$SCRIPT_DIR"

echo "=== PiPedal Portable Configuration Tool ==="
echo
echo "This tool reconfigures the portable PiPedal installation for the current machine."
echo "Use it when you've copied the portable installation to a new machine."
echo

echo "Current paths in configuration:"
echo "  Install prefix: $INSTALL_PREFIX"
echo ""

echo "Step 1: Basic Configuration"
echo "----------------------------"
read -p "Web port [8080]: " WEB_PORT
WEB_PORT=${WEB_PORT:-8080}

read -p "Device name [pipedal]: " DEVICE_NAME
DEVICE_NAME=${DEVICE_NAME:-pipedal}

echo ""
echo "Step 2: LV2 Plugins Configuration"
echo "----------------------------------"
echo "Where should PiPedal look for LV2 plugins?"
echo "  1. Use portable plugins only (\$SCRIPT_DIR/lib/lv2)"
echo "  2. Use system paths (/usr/lib/lv2, /usr/local/lib/lv2)"
echo "  3. Custom path"
echo "  4. Both portable and system paths"
read -p "Choice [4]: " LV2_CHOICE
LV2_CHOICE=${LV2_CHOICE:-4}

case $LV2_CHOICE in
    1)
        LV2_PATH="$SCRIPT_DIR/lib/lv2"
        ;;
    2)
        LV2_PATH="/usr/lib/lv2:/usr/local/lib/lv2"
        ;;
    3)
        read -p "Enter custom LV2 path (colon-separated): " LV2_PATH
        ;;
    4)
        LV2_PATH="$SCRIPT_DIR/lib/lv2:/usr/lib/lv2:/usr/local/lib/lv2"
        ;;
    *)
        LV2_PATH="$SCRIPT_DIR/lib/lv2:/usr/lib/lv2:/usr/local/lib/lv2"
        ;;
esac

echo ""
echo "Step 3: Data Directories"
echo "-------------------------"
read -p "Local storage path [\$SCRIPT_DIR/var]: " LOCAL_STORAGE
LOCAL_STORAGE=${LOCAL_STORAGE:-$SCRIPT_DIR/var}

read -p "Presets path [\$SCRIPT_DIR/var/presets]: " PRESETS_PATH
PRESETS_PATH=${PRESETS_PATH:-$SCRIPT_DIR/var/presets}

read -p "Models path [\$SCRIPT_DIR/var/models]: " MODELS_PATH
MODELS_PATH=${MODELS_PATH:-$SCRIPT_DIR/var/models}

read -p "Cab IR path [\$SCRIPT_DIR/var/cabs]: " CAB_PATH
CAB_PATH=${CAB_PATH:-$SCRIPT_DIR/var/cabs}

echo ""
echo "Step 4: Audio Configuration"
echo "---------------------------"
read -p "JACK client name [pipedal]: " JACK_NAME
JACK_NAME=${JACK_NAME:-pipedal}

read -p "Sample rate [48000]: " SAMPLE_RATE
SAMPLE_RATE=${SAMPLE_RATE:-48000}

read -p "Buffer size [256]: " BUFFER_SIZE
BUFFER_SIZE=${BUFFER_SIZE:-256}

echo ""
echo "Step 5: System Configuration"
echo "----------------------------"
echo "Configure /var/pipedal symlink? (required for runtime)"
read -p "(y/n) [y]: " CONFIGURE_SYMLINK
CONFIGURE_SYMLINK=${CONFIGURE_SYMLINK:-y}

echo "Configure mDNS domain? (for network discovery)"
echo "  1. Default (.local)"
echo "  2. Custom domain (e.g., .pipedal)"
echo "  3. Disable mDNS"
read -p "Choice [1]: " MDNS_CHOICE
MDNS_CHOICE=${MDNS_CHOICE:-1}

echo ""
echo "=== Summary ==="
echo "Web port:       $WEB_PORT"
echo "Device name:    $DEVICE_NAME"
echo "LV2 path:       $LV2_PATH"
echo "Local storage:  $LOCAL_STORAGE"
echo "Presets path:   $PRESETS_PATH"
echo "Models path:    $MODELS_PATH"
echo "Cab path:       $CAB_PATH"
echo "JACK name:      $JACK_NAME"
echo "Sample rate:    $SAMPLE_RATE"
echo "Buffer size:    $BUFFER_SIZE"
echo ""

read -p "Apply these settings? (y/n) [y]: " CONFIRM
CONFIRM=${CONFIRM:-y}
if [[ ! $CONFIRM =~ ^[Yy]*$ ]]; then
    echo "Configuration cancelled."
    exit 0
fi

echo ""
echo "Applying configuration..."

echo "Updating config.json..."
mkdir -p "$SCRIPT_DIR/config"
cat > "$SCRIPT_DIR/config/config.json" << CONFEOF
{
    "local_storage_path": "$LOCAL_STORAGE",
    "lv2_path": "$LV2_PATH",
    "mlock": true,
    "threads": 5,
    "socketServerAddress": "0.0.0.0:$WEB_PORT",
    "logHttpRequests": false,
    "logLevel": 3,
    "maxUploadSize": 536870912
}
CONFEOF

echo "Updating service.conf..."
mkdir -p "$SCRIPT_DIR/var/config"
cat > "$SCRIPT_DIR/var/config/service.conf" << CONFEOF
server_port = $WEB_PORT
uuid = "$(uuidgen 2>/dev/null || echo "portable-$(date +%s)")"
deviceName = "$DEVICE_NAME"
CONFEOF

echo "Updating env.sh..."
cat > "$SCRIPT_DIR/env.sh" << ENVEOF
#!/bin/bash
export PIPEDAL_CONFIG="$SCRIPT_DIR/config"
export PIPEDAL_JACK_NAME="$JACK_NAME"
export PIPEDAL_SAMPLE_RATE="$SAMPLE_RATE"
export PIPEDAL_BUFFER_SIZE="$BUFFER_SIZE"
export PIPEDAL_PRESETS="$PRESETS_PATH"
export PIPEDAL_MODELS="$MODELS_PATH"
export PIPEDAL_CABS="$CAB_PATH"
ENVEOF
chmod +x "$SCRIPT_DIR/env.sh"

if [[ "$CONFIGURE_SYMLINK" =~ ^[Yy]*$ ]]; then
    echo "Creating /var/pipedal symlink..."
    if [ ! -d "/var/pipedal" ] || [ -L "/var/pipedal" ]; then
        sudo rm -rf /var/pipedal 2>/dev/null || true
        sudo ln -sf "$SCRIPT_DIR/var" /var/pipedal
        echo "  Created: /var/pipedal -> $SCRIPT_DIR/var"
    else
        echo "  /var/pipedal already exists (not a symlink). Skipping."
    fi
fi

case $MDNS_CHOICE in
    1)
        MDNS_DOMAIN="local"
        echo "Configuring mDNS to .local..."
        if [ -f "/etc/avahi/avahi-daemon.conf" ]; then
            if grep -q "^domain-name=" /etc/avahi/avahi-daemon.conf; then
                sudo sed -i 's/^domain-name=.*/domain-name=local/' /etc/avahi/avahi-daemon.conf
            else
                sudo sed -i '/^\[server\]/a domain-name=local' /etc/avahi/avahi-daemon.conf
            fi
            sudo systemctl restart avahi-daemon 2>/dev/null || sudo service avahi-daemon restart 2>/dev/null || true
        fi
        ;;
    2)
        read -p "Enter mDNS domain (without dot, e.g., pipedal): " MDNS_DOMAIN
        if [ -n "$MDNS_DOMAIN" ]; then
            echo "Configuring mDNS to .$MDNS_DOMAIN..."
            if [ -f "/etc/avahi/avahi-daemon.conf" ]; then
                if grep -q "^domain-name=" /etc/avahi/avahi-daemon.conf; then
                    sudo sed -i "s/^domain-name=.*/domain-name=$MDNS_DOMAIN/" /etc/avahi/avahi-daemon.conf
                else
                    sudo sed -i "/^\[server\]/a domain-name=$MDNS_DOMAIN" /etc/avahi/avahi-daemon.conf
                fi
                sudo systemctl restart avahi-daemon 2>/dev/null || sudo service avahi-daemon restart 2>/dev/null || true
            fi
        fi
        ;;
    3)
        echo "Disabling mDNS..."
        if [ -f "/etc/avahi/avahi-daemon.conf" ]; then
            if grep -q "^domain-name=" /etc/avahi/avahi-daemon.conf; then
                sudo sed -i 's/^domain-name=.*/domain-name=no/' /etc/avahi/avahi-daemon.conf
            fi
            sudo systemctl restart avahi-daemon 2>/dev/null || sudo service avahi-daemon restart 2>/dev/null || true
        fi
        MDNS_DOMAIN="no"
        ;;
esac

mkdir -p "$PRESETS_PATH" "$MODELS_PATH" "$CAB_PATH" 2>/dev/null || true

echo ""
echo "=== Configuration Complete ==="
echo
echo "Updated paths:"
echo "  config.json:   $SCRIPT_DIR/config/config.json"
echo "  service.conf:  $SCRIPT_DIR/var/config/service.conf"
echo "  env.sh:        $SCRIPT_DIR/env.sh"
echo
echo "To start PiPedal:"
echo "  $SCRIPT_DIR/start.sh"
echo
echo "Access URLs:"
echo "  Local:   http://localhost:$WEB_PORT"
echo "  Network: http://$(hostname).local:$WEB_PORT"
echo