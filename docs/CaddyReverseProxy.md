## Using Caddy as a Reverse Proxy for PiPedal

If you have another web service running on your machine (e.g., a system configuration tool) that you want to keep on port 80 while also running PiPedal, Caddy provides a lightweight reverse proxy that routes traffic based on the hostname.

### How it works

- `http://hostname.local` → your existing service (e.g., webconf)
- `http://hostname.pipedal` → PiPedal

Both hostnames resolve to the same machine. Caddy inspects the HTTP `Host` header and proxies to the correct backend.

### 1. Install Caddy

**Via apt:**

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install caddy
```

**Static binary** (no dependencies):

```bash
wget https://github.com/caddyserver/caddy/releases/latest/download/caddy-linux-$(dpkg --print-architecture) -O /usr/bin/caddy
chmod +x /usr/bin/caddy
```

### 2. Configure PiPedal on port 8080

Edit `/var/pipedal/config/service.conf`:

```
server_port = 8080
```

Or pass the port at startup:

```bash
pipedald /etc/pipedal/config /etc/pipedal/react -port 8080
```

### 3. Caddyfile

Create `/etc/caddy/Caddyfile`:

```caddy
:80 {
    @pipedal host *.pipedal
    handle @pipedal {
        reverse_proxy localhost:8080
    }

    handle {
        reverse_proxy localhost:8081
    }
}
```

Replace `localhost:8081` with the address and port of your other service.

### 4. Publish the `.pipedal` hostname via Avahi

Create `/etc/avahi/aliases.d/pipedal` with one line (replace `hostname` with your machine's hostname):

```
hostname.pipedal
```

Restart Avahi:

```bash
sudo systemctl restart avahi-daemon
```

Now `hostname.pipedal` resolves to your machine's IP, just like `hostname.local`.

### 5. Start Caddy

```bash
sudo systemctl enable --now caddy
```

### Result

| URL | Resolves to | Routes to |
|---|---|---|
| `http://hostname.local` | Machine IP | Your other service (port 8081) |
| `http://hostname.pipedal` | Machine IP | PiPedal (port 8080) |

### Troubleshooting

- Check Caddy logs: `journalctl -u caddy`
- Verify the Avahi alias: `avahi-resolve-host-name hostname.pipedal`
- Verify PiPedal is listening: `ss -tlnp | grep 8080`
- Verify your other service is listening: `ss -tlnp | grep 8081`

--------
[<< Configuring PiPedal After Installation](Configuring.md)
