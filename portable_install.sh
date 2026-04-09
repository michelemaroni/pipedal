#!/usr/bin/bash
set -e

INSTALL_PREFIX="${INSTALL_PREFIX:-$HOME/pipedal-portable}"
LV2_PATH="${LV2_PATH:-$HOME/.lv2}"
PRESETS_PATH="${PRESETS_PATH:-$HOME/.local/share/pipedal/presets}"
MODELS_PATH="${MODELS_PATH:-$HOME/.local/share/pipedal/models}"
CAB_PATH="${CAB_PATH:-$HOME/.local/share/pipedal/cabs}"
JACK_NAME="${JACK_NAME:-pipedal}"
SAMPLE_RATE="${SAMPLE_RATE:-48000}"
BUFFER_SIZE="${BUFFER_SIZE:-256}"

echo "=== pipedal Portable Installer ==="
echo
echo "Install prefix: $INSTALL_PREFIX"
echo "LV2 path:       $LV2_PATH"
echo "Presets path:    $PRESETS_PATH"
echo "Models path:     $MODELS_PATH"
echo "Cab path:        $CAB_PATH"
echo "Jack name:       $JACK_NAME"
echo "Sample rate:    $SAMPLE_RATE"
echo "Buffer size:    $BUFFER_SIZE"
echo

read -p "Continue with installation? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]*$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

mkdir -p "$INSTALL_PREFIX"/{bin,lib/lv2,share/pipedal/{presets,models,cabs},config}

cmake --install build --prefix "$INSTALL_PREFIX" --config Release

mkdir -p "$LV2_PATH"
if [ ! -e "$LV2_PATH/pipedal" ]; then
    ln -sf "$INSTALL_PREFIX/lib/lv2" "$LV2_PATH/pipedal"
fi

cat > "$INSTALL_PREFIX/env.sh" << 'ENVEOF'
#!/bin/bash
export LV2_PATH="$HOME/.lv2"
export PIPEDAL_PRESETS="$HOME/.local/share/pipedal/presets"
export PIPEDAL_MODELS="$HOME/.local/share/pipedal/models"
export PIPEDAL_CABS="$HOME/.local/share/pipedal/cabs"
export PIPEDAL_CONFIG="__PREFIX__/config"
export PIPEDAL_JACK_NAME="pipedal"
export PIPEDAL_SAMPLE_RATE="48000"
export PIPEDAL_BUFFER_SIZE="256"
ENVEOF

sed -i "s|__PREFIX__|$INSTALL_PREFIX|g" "$INSTALL_PREFIX/env.sh"
chmod +x "$INSTALL_PREFIX/env.sh"

cat > "$INSTALL_PREFIX/config/pipedal.conf" << 'CONFEOF'
[audio]
jack_name = pipedal
sample_rate = 48000
buffer_size = 256

[paths]
lv2 = ~/.lv2
presets = ~/.local/share/pipedal/presets
models = ~/.local/share/pipedal/models
cabs = ~/.local/share/pipedal/cabs
CONFEOF

sed -i "s|pipedal = pipedal|jack_name = $JACK_NAME|g" "$INSTALL_PREFIX/config/pipedal.conf"
sed -i "s|sample_rate = 48000|sample_rate = $SAMPLE_RATE|g" "$INSTALL_PREFIX/config/pipedal.conf"
sed -i "s|buffer_size = 256|buffer_size = $BUFFER_SIZE|g" "$INSTALL_PREFIX/config/pipedal.conf"

mkdir -p "$PRESETS_PATH" "$MODELS_PATH" "$CAB_PATH"

echo
echo "=== Installation Complete ==="
echo
echo "Installed to: $INSTALL_PREFIX"
echo
echo "To use:"
echo "  source $INSTALL_PREFIX/env.sh"
echo "  $INSTALL_PREFIX/bin/pipedal"
echo
