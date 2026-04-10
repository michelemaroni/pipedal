#!/usr/bin/bash
set -e

INSTALL_PREFIX="${INSTALL_PREFIX:-$HOME/pipedal-portable}"
LV2_PATH="${LV2_PATH:-$HOME/.lv2}"
EXTRA_LV2_PATHS="${EXTRA_LV2_PATHS:-/usr/lib/lv2:/usr/local/lib/lv2}"
PRESETS_PATH="${PRESETS_PATH:-$HOME/.local/share/pipedal/presets}"
MODELS_PATH="${MODELS_PATH:-$HOME/.local/share/pipedal/models}"
CAB_PATH="${CAB_PATH:-$HOME/.local/share/pipedal/cabs}"
JACK_NAME="${JACK_NAME:-pipedal}"
SAMPLE_RATE="${SAMPLE_RATE:-48000}"
BUFFER_SIZE="${BUFFER_SIZE:-256}"
WEB_PORT="${WEB_PORT:-8080}"
MDNS_DOMAIN="${MDNS_DOMAIN:-local}"

if [ "$MDNS_DOMAIN" = "none" ]; then
    MDNS_DOMAIN=""
fi

LV2_PATH_FULL="${INSTALL_PREFIX}/lib/lv2"
if [ -n "$EXTRA_LV2_PATHS" ]; then
    LV2_PATH_FULL="${LV2_PATH_FULL}:${EXTRA_LV2_PATHS}"
fi

echo "=== pipedal Portable Installer ==="
echo
echo "Install prefix:    $INSTALL_PREFIX"
echo "LV2 path:         $LV2_PATH_FULL"
echo "Presets path:      $PRESETS_PATH"
echo "Models path:       $MODELS_PATH"
echo "Cab path:          $CAB_PATH"
echo "Jack name:         $JACK_NAME"
echo "Sample rate:       $SAMPLE_RATE"
echo "Buffer size:       $BUFFER_SIZE"
echo "Web port:          $WEB_PORT"
echo

read -p "Continue with installation? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]*$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

mkdir -p "$INSTALL_PREFIX"/{bin,sbin,lib/lv2,share/pipedal/{presets,models,cabs},config,var,var/presets}

echo "Copying executables..."
cp /home/raspberry/pipedal/build/src/pipedald "$INSTALL_PREFIX/sbin/"
cp /home/raspberry/pipedal/build/src/pipedalconfig "$INSTALL_PREFIX/bin/"
cp /home/raspberry/pipedal/build/src/pipedal_kconfig "$INSTALL_PREFIX/bin/"
cp /home/raspberry/pipedal/build/src/pipedaladmind "$INSTALL_PREFIX/sbin/"
cp /home/raspberry/pipedal/build/src/pipedal_update "$INSTALL_PREFIX/sbin/"
cp /home/raspberry/pipedal/build/src/pipedal_latency_test "$INSTALL_PREFIX/bin/"
cp /home/raspberry/pipedal/build/src/pipedal_alsa_info "$INSTALL_PREFIX/bin/"
cp /home/raspberry/pipedal/build/src/pipedalProfilePlugin "$INSTALL_PREFIX/bin/"

echo "Copying LV2 plugin bundles..."
mkdir -p "$INSTALL_PREFIX/lib/lv2"
if [ -d "/home/raspberry/pipedal/lv2/aarch64/ToobAmp.lv2" ]; then
    cp -r /home/raspberry/pipedal/lv2/aarch64/ToobAmp.lv2 "$INSTALL_PREFIX/lib/lv2/"
fi

echo "Copying React frontend..."
mkdir -p "$INSTALL_PREFIX/react"
if [ -d "/home/raspberry/pipedal/vite/dist" ]; then
    cp -r /home/raspberry/pipedal/vite/dist/* "$INSTALL_PREFIX/react/"
fi

echo "Copying default presets..."
mkdir -p "$INSTALL_PREFIX/config/default_presets"
if [ -d "/home/raspberry/pipedal/default_presets" ]; then
    cp -r /home/raspberry/pipedal/default_presets/* "$INSTALL_PREFIX/config/default_presets/"
fi
rm -rf "$INSTALL_PREFIX/var/presets" 2>/dev/null || sudo rm -rf "$INSTALL_PREFIX/var/presets"

echo "Copying plugin classes..."
if [ -f "/home/raspberry/pipedal/config/plugin_classes.json" ]; then
    cp /home/raspberry/pipedal/config/plugin_classes.json "$INSTALL_PREFIX/config/"
fi

echo "Creating config.json..."
cat > "$INSTALL_PREFIX/config/config.json" << CONFEOF
{
    "local_storage_path": "$INSTALL_PREFIX/var",
    "lv2_path": "$LV2_PATH_FULL",
    "mlock": true,
    "threads": 5,
    "socketServerAddress": "0.0.0.0:$WEB_PORT",
    "logHttpRequests": false,
    "logLevel": 3,
    "maxUploadSize": 536870912
}
CONFEOF

echo "Creating service.conf..."
mkdir -p "$INSTALL_PREFIX/var/config"
cat > "$INSTALL_PREFIX/var/config/service.conf" << CONFEOF
server_port = $WEB_PORT
uuid = "portable"
deviceName = "pipedal"
CONFEOF

echo "Creating /var/pipedal symlink (requires sudo)..."
if [ ! -d "/var/pipedal" ] || [ -L "/var/pipedal" ]; then
    sudo rm -rf /var/pipedal
    sudo ln -sf "$INSTALL_PREFIX/var" /var/pipedal
fi

echo "Creating symlink for LV2 discovery..."
mkdir -p "$LV2_PATH"
if [ ! -e "$LV2_PATH/ToobAmp" ]; then
    ln -sf "$INSTALL_PREFIX/lib/lv2/ToobAmp.lv2" "$LV2_PATH/ToobAmp"
fi

if [ -n "$MDNS_DOMAIN" ]; then
    echo "Configuring mDNS domain: $MDNS_DOMAIN"
    
    echo "Updating avahi-daemon.conf..."
    if [ -f "/etc/avahi/avahi-daemon.conf" ]; then
        if grep -q "^domain-name=" /etc/avahi/avahi-daemon.conf; then
            sudo sed -i "s/^domain-name=.*/domain-name=$MDNS_DOMAIN/" /etc/avahi/avahi-daemon.conf
        else
            sudo sed -i "/^\[server\]/a domain-name=$MDNS_DOMAIN" /etc/avahi/avahi-daemon.conf
        fi
        echo "Restarting avahi-daemon..."
        sudo systemctl restart avahi-daemon 2>/dev/null || sudo service avahi-daemon restart 2>/dev/null || true
    fi
    
    echo "mDNS domain configured to: $MDNS_DOMAIN"
    echo "You can now access pipedal at: http://$(hostname).$MDNS_DOMAIN:$WEB_PORT"
fi

cat > "$INSTALL_PREFIX/env.sh" << 'ENVEOF'
#!/bin/bash
export PIPEDAL_CONFIG="__PREFIX__/config"
ENVEOF

sed -i "s|__PREFIX__|$INSTALL_PREFIX|g" "$INSTALL_PREFIX/env.sh"
chmod +x "$INSTALL_PREFIX/env.sh"

mkdir -p "$PRESETS_PATH" "$MODELS_PATH" "$CAB_PATH"

chmod +x "$INSTALL_PREFIX"/bin/* "$INSTALL_PREFIX"/sbin/* 2>/dev/null || true

echo "Creating launch scripts..."

cat > "$INSTALL_PREFIX/start.sh" << 'LAUNCHEOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTNAME=$(hostname)

source "$SCRIPT_DIR/env.sh"

if [ -f "$SCRIPT_DIR/config/service.conf" ]; then
    WEB_PORT=$(grep "server_port" "$SCRIPT_DIR/config/service.conf" | grep -o '[0-9]*' | head -1)
fi
WEB_PORT=${WEB_PORT:-8080}

MDNS_DOMAIN=$(grep "^domain-name=" /etc/avahi/avahi-daemon.conf 2>/dev/null | cut -d= -f2)
MDNS_DOMAIN=${MDNS_DOMAIN:-local}

echo "Starting pipedal..."
echo "  Config: $SCRIPT_DIR/config"
echo "  Web UI: $SCRIPT_DIR/react"
echo "  Logs:   /tmp/pipedal.log"
echo ""

sudo "$SCRIPT_DIR/sbin/pipedald" "$SCRIPT_DIR/config" "$SCRIPT_DIR/react" > /tmp/pipedal.log 2>&1 &
PID=$!

echo "pipedal started (PID: $PID)"
echo ""
echo "Access URLs:"
echo "  Local:   http://localhost:$WEB_PORT"
if [ "$MDNS_DOMAIN" != "no" ]; then
    echo "  Network: http://$HOSTNAME.$MDNS_DOMAIN:$WEB_PORT"
fi
echo ""
echo "To view logs: $SCRIPT_DIR/logs.sh"
echo "To stop:      $SCRIPT_DIR/stop.sh"
LAUNCHEOF

cat > "$INSTALL_PREFIX/stop.sh" << 'STOPEOF'
#!/bin/bash
echo "Stopping pipedal..."
sudo pkill -f "pipedald.*config.*react" 2>/dev/null || true
echo "pipedal stopped."
STOPEOF

cat > "$INSTALL_PREFIX/restart.sh" << 'RESTARTEOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/stop.sh"
sleep 1
"$SCRIPT_DIR/start.sh"
RESTARTEOF

cat > "$INSTALL_PREFIX/logs.sh" << 'LOGSEOF'
#!/bin/bash
if [ -f /tmp/pipedal.log ]; then
    tail -f /tmp/pipedal.log
else
    echo "No log file found. Is pipedal running?"
fi
LOGSEOF

chmod +x "$INSTALL_PREFIX/start.sh" "$INSTALL_PREFIX/stop.sh" "$INSTALL_PREFIX/restart.sh" "$INSTALL_PREFIX/logs.sh"

echo "Copying mDNS setup script..."
cp /home/raspberry/pipedal/portable_install_setup_mdns.sh "$INSTALL_PREFIX/setup_mdns.sh" 2>/dev/null || true
chmod +x "$INSTALL_PREFIX/setup_mdns.sh" 2>/dev/null || true

echo
echo "=== Installation Complete ==="
echo
echo "Installed to: $INSTALL_PREFIX"
echo
echo "LV2 paths configured:"
echo "  - $INSTALL_PREFIX/lib/lv2 (portable plugins)"
if [ -n "$EXTRA_LV2_PATHS" ]; then
    echo "  - $EXTRA_LV2_PATHS (system plugins)"
fi
echo
echo "mDNS Domain: $MDNS_DOMAIN"
if [ -n "$MDNS_DOMAIN" ]; then
    echo "  Access URL: http://$(hostname).$MDNS_DOMAIN:$WEB_PORT"
else
    echo "  mDNS disabled"
fi
echo
echo "Commands:"
echo "  $INSTALL_PREFIX/start.sh    - Start pipedal"
echo "  $INSTALL_PREFIX/stop.sh     - Stop pipedal"
echo "  $INSTALL_PREFIX/restart.sh  - Restart pipedal"
echo "  $INSTALL_PREFIX/logs.sh     - View logs"
echo
echo "Then open: http://localhost:$WEB_PORT"
echo
