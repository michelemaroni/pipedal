# PiPedal Portable Installation

This document describes the portable installation method for PiPedal, allowing you to run PiPedal from any directory without system-wide installation.

## Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration Parameters](#configuration-parameters)
- [Launch Scripts](#launch-scripts)
- [Directory Structure](#directory-structure)
- [Customization Examples](#customization-examples)
- [Troubleshooting](#troubleshooting)

## Quick Start

```bash
# Default installation to ~/pipedal-portable
./portable_install.sh

# Start pipedal
~/pipedal-portable/start.sh

# Access the web UI
# Open: http://localhost:8080
```

## Installation

### Basic Installation

```bash
./portable_install.sh
```

This will install PiPedal to `~/pipedal-portable` with default settings.

### Custom Installation Directory

```bash
INSTALL_PREFIX=/opt/pipedal ./portable_install.sh
```

### Offline Installation

The portable install copies all necessary files from the build directory, making it suitable for offline use on identical systems.

## Configuration Parameters

All parameters can be set via environment variables when running the install script.

### Core Parameters

| Parameter | Environment Variable | Default | Description |
|-----------|-------------------|---------|-------------|
| Install Location | `INSTALL_PREFIX` | `~/pipedal-portable` | Base directory for the portable installation |
| Web Server Port | `WEB_PORT` | `8080` | HTTP port for the web UI |
| LV2 Path | `LV2_PATH` | `~/.lv2` | User's LV2 plugin directory |
| Extra LV2 Paths | `EXTRA_LV2_PATHS` | `/usr/lib/lv2:/usr/local/lib/lv2` | Additional system LV2 paths (colon-separated) |

### Audio Parameters

| Parameter | Environment Variable | Default | Description |
|-----------|-------------------|---------|-------------|
| Jack Client Name | `JACK_NAME` | `pipedal` | Name for the JACK audio client |
| Sample Rate | `SAMPLE_RATE` | `48000` | Audio sample rate in Hz |
| Buffer Size | `BUFFER_SIZE` | `256` | JACK buffer size |

### Path Parameters

| Parameter | Environment Variable | Default | Description |
|-----------|-------------------|---------|-------------|
| Presets Path | `PRESETS_PATH` | `~/.local/share/pipedal/presets` | User presets directory |
| Models Path | `MODELS_PATH` | `~/.local/share/pipedal/models` | Neural amp model files |
| Cab Path | `CAB_PATH` | `~/.local/share/pipedal/cabs` | Cabinet IR files |

## Usage Examples

### Example 1: Custom Port

```bash
WEB_PORT=9000 ./portable_install.sh
```

Access at: `http://localhost:9000`

### Example 2: Different LV2 Plugin Locations

```bash
EXTRA_LV2_PATHS="/opt/kars:/home/user/plugins" ./portable_install.sh
```

### Example 3: Full Customization

```bash
INSTALL_PREFIX=/mnt/usb/pipedal \
WEB_PORT=8080 \
JACK_NAME=myguitar \
SAMPLE_RATE=44100 \
LV2_PATH=/mnt/usb/lv2 \
./portable_install.sh
```

### Example 4: Portable USB Installation

```bash
INSTALL_PREFIX=/media/usb/pipedal \
EXTRA_LV2_PATHS="" \
WEB_PORT=8080 \
./portable_install.sh
```

## Launch Scripts

After installation, the following scripts are available in the install directory:

| Script | Description |
|--------|-------------|
| `./start.sh` | Start pipedal in the background |
| `./stop.sh` | Stop pipedal |
| `./restart.sh` | Restart pipedal |
| `./logs.sh` | View live logs (tail -f) |

### Using Launch Scripts

```bash
cd ~/pipedal-portable

# Start pipedal
./start.sh

# View logs
./logs.sh

# Stop pipedal
./stop.sh

# Restart pipedal
./restart.sh
```

## Directory Structure

```
~/pipedal-portable/
├── bin/                    # User-facing executables
│   ├── pipedalconfig       # Configuration tool
│   ├── pipedal_kconfig     # Keyboard configuration
│   └── ...
├── sbin/                   # System executables (requires sudo)
│   ├── pipedald            # Main daemon
│   └── ...
├── lib/
│   └── lv2/
│       └── ToobAmp.lv2/   # LV2 plugin bundle with effects
├── config/                 # Configuration files
│   ├── config.json         # Main configuration
│   ├── plugin_classes.json # Plugin metadata
│   └── default_presets/   # Factory presets
├── react/                 # Web UI frontend
├── var/                    # Runtime data
│   ├── config/
│   │   └── service.conf   # Service settings
│   ├── presets/           # User presets
│   └── audio_uploads/     # Uploaded files
├── env.sh                  # Environment variables
├── start.sh               # Start script
├── stop.sh                # Stop script
├── restart.sh             # Restart script
├── logs.sh                # Logs viewer
├── configure.sh           # Configuration tool (run on destination machine)
├── setup_mdns.sh          # mDNS domain configuration script
└── ...
```

## Configuration Files

### config.json

Main configuration file located at `config/config.json`:

```json
{
    "local_storage_path": "/home/user/pipedal-portable/var",
    "lv2_path": "/home/user/pipedal-portable/lib/lv2:/usr/lib/lv2:/usr/local/lib/lv2",
    "mlock": true,
    "threads": 5,
    "socketServerAddress": "0.0.0.0:8080",
    "logHttpRequests": false,
    "logLevel": 3,
    "maxUploadSize": 536870912
}
```

### service.conf

Service configuration at `var/config/service.conf`:

```
server_port = 8080
uuid = "portable"
deviceName = "pipedal"
```

## Accessing PiPedal

After starting pipedal, access the web UI using one of these methods:

### Local Access

```
http://localhost:8080
```

### Network Access via IP

```
http://192.168.1.x:8080
```

### Network Access via mDNS

```
http://raspberrypi.local:8080
```

## mDNS Configuration

PiPedal uses mDNS (via Avahi) for network discovery on the local network. The mDNS domain is configured system-wide via Avahi, not in PiPedal's configuration files.

### Using the Configuration Tool

The easiest way is to use the interactive configuration tool:

```bash
cd ~/pipedal-portable
sudo ./configure.sh
```

The configuration tool will prompt you to set the mDNS domain as part of the setup process.

### Manual Configuration

To manually configure the mDNS domain:

1. Edit `/etc/avahi/avahi-daemon.conf`:
   ```bash
   sudo nano /etc/avahi/avahi-daemon.conf
   ```
   Find or add the `[server]` section and set:
   ```
   domain-name=pipedal
   ```

2. Restart avahi-daemon:
   ```bash
   sudo systemctl restart avahi-daemon
   ```

3. Access pipedal at: `http://raspberrypi.pipedal:8080`

**Note:** The mDNS domain can be:
- `.local` (default) - works out of the box on most networks
- Custom domain (e.g., `.pipedal`, `.home`) - requires router DNS or hosts file entries
- `no` - disables mDNS service announcement

**Note:** For custom mDNS domains to work on other devices:
- Configure your router's DNS to resolve the domain
- Or add entries to each device's `/etc/hosts` file:
  ```
  192.168.1.x  raspberrypi.pipedal
  ```

## Customization Examples

### Changing the Web Port

```bash
WEB_PORT=9000 ./portable_install.sh
```

Or edit `var/config/service.conf`:
```
server_port = 9000
```

### Using System LV2 Plugins

```bash
EXTRA_LV2_PATHS="/usr/lib/lv2:/usr/local/lib/lv2:/opt/my-plugins" ./portable_install.sh
```

### Disabling System LV2 Plugins

```bash
EXTRA_LV2_PATHS="" ./portable_install.sh
```

## Troubleshooting

### Connection Refused

1. Check if pipedal is running:
   ```bash
   ps aux | grep pipedald
   ```

2. Check logs for errors:
   ```bash
   ~/pipedal-portable/logs.sh
   ```

3. Check if port is in use:
   ```bash
   sudo fuser 8080/tcp
   ```

### Moving to Another Machine

When you copy the portable installation to a different machine, run the configuration tool to adapt to the new environment:

```bash
cd ~/pipedal-portable
sudo ./configure.sh
```

This interactive tool will prompt you for:
- Web port
- Device name
- LV2 plugin paths
- Local storage path
- Audio settings (sample rate, buffer size)
- mDNS domain configuration
- /var/pipedal symlink setup

### Web UI Not Loading

1. Verify web server is listening:
   ```bash
   curl -s http://localhost:8080 | head
   ```

2. Check the log file at `/tmp/pipedal.log`

### Audio Not Working

1. Check ALSA configuration
2. Verify JACK is running (if using JACK backend)
3. Check audio device settings in the web UI

### LV2 Plugins Not Found

1. Verify LV2 path in `config/config.json`
2. Check that plugin bundles contain `manifest.ttl` files
3. Check logs for LV2 scanning errors

### mDNS Not Working

1. Verify avahi-daemon is running:
   ```bash
   sudo systemctl status avahi-daemon
   ```

2. Check domain-name in avahi config:
   ```bash
   grep "^domain-name=" /etc/avahi/avahi-daemon.conf
   ```

3. For custom domains, ensure your network's DNS can resolve the hostname, or add entries to `/etc/hosts` on client machines.

To reset the portable installation:

```bash
sudo ~/pipedal-portable/stop.sh
sudo rm -rf ~/pipedal-portable
./portable_install.sh
```

## Advanced Configuration

### Environment Variables

Set permanent environment variables by editing `env.sh`:

```bash
#!/bin/bash
export PIPEDAL_CONFIG="/path/to/config"
export LD_LIBRARY_PATH="/path/to/libs:$LD_LIBRARY_PATH"
```

### Multiple Installations

Run multiple instances on different ports:

```bash
# First instance
WEB_PORT=8080 INSTALL_PREFIX=~/pipedal-instance1 ./portable_install.sh

# Second instance
WEB_PORT=8081 INSTALL_PREFIX=~/pipedal-instance2 ./portable_install.sh
```

### USB/Portable Drive Installation

For use on multiple machines:

```bash
# Install to USB drive
INSTALL_PREFIX=/media/usb/pipedal \
EXTRA_LV2_PATHS="" \
./portable_install.sh
```

## Technical Notes

- The portable install uses a symlink at `/var/pipedal` pointing to the runtime data directory
- This symlink requires sudo to create
- All paths in `config.json` are absolute paths to ensure portability
- The LV2 path is colon-separated, following the standard LV2 convention
- mDNS uses the system Avahi daemon configuration (`/etc/avahi/avahi-daemon.conf`)
