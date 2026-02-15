# 🚀 Paqet Tunnel Manager

<div align="center">

[![English](https://img.shields.io/badge/Language-English-blue.svg)](README.md)
[![Persian](https://img.shields.io/badge/زبان-فارسی-green.svg)](README_FA.md)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/letmefind/Easy-paqet?style=social)](https://github.com/letmefind/Easy-paqet)

**A production-ready, high-performance bidirectional packet-level proxy using raw sockets and KCP protocol**

[Features](#-features) • [Quick Start](#-quick-start) • [Installation](#-installation) • [Configuration](#-configuration) • [Management](#-management)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Performance Optimizations](#-performance-optimizations)
- [Management Tools](#-management-tools)
- [Troubleshooting](#-troubleshooting)
- [Support](#-support)

---

## 🎯 Overview

**Paqet** is a bidirectional packet-level proxy that uses raw sockets to bypass standard firewalls and KCP protocol for reliable, low-latency data transmission.

### Key Characteristics

- 🔒 **Raw Socket Technology** - Bypasses standard firewall rules
- ⚡ **KCP Protocol** - Reliable UDP-based protocol optimized for speed and latency
- 🔐 **Strong Encryption** - Multiple encryption algorithms (Salsa20, AES, Blowfish, etc.)
- 🛡️ **Stealth Service Names** - Services named as `udp-relay-*` for discretion
- 📊 **Production Ready** - Comprehensive management tools and optimizations
- 🎯 **Auto-Optimization** - Automatically tunes settings based on expected user count

---

## ✨ Features

### 🚀 Core Features

- ✅ **Bidirectional Proxy** - Full-duplex packet forwarding
- ✅ **Raw Socket Support** - Bypasses standard firewall rules
- ✅ **KCP Protocol** - Fast, reliable UDP-based transport
- ✅ **Multiple Encryption** - Salsa20, AES, Blowfish, CAST5, SM4
- ✅ **Stealth Services** - Discreet service naming (`udp-relay-*`)
- ✅ **Dedicated User** - Runs as `paqet` user (not root)

### ⚡ Performance Features

- ✅ **KCP Modes** - `normal`, `fast`, `fast2`, `fast3` for different speed/latency trade-offs
- ✅ **Auto-Optimization** - Tunes buffers and windows based on user count
- ✅ **BBR Support** - Automatic BBR congestion control
- ✅ **MTU Discovery** - Built-in tool to find optimal MTU
- ✅ **Sysctl Optimization** - Optional kernel parameter tuning

### 🛠️ Management Features

- ✅ **Interactive Setup** - User-friendly installation wizard
- ✅ **Config Management** - Create, edit, delete configurations
- ✅ **Service Management** - Start, stop, restart, enable/disable services
- ✅ **Log Management** - Control log levels per configuration
- ✅ **Client Packages** - Generate ready-to-install client packages
- ✅ **MTU Discovery** - Find optimal MTU for your network

---

## 🚀 Quick Start

### Prerequisites

- Linux server (Ubuntu 20.04+, Debian 11+, CentOS 8+)
- Root or sudo access
- At least 512MB RAM (2GB+ recommended)
- Network connectivity

### Installation

```bash
# Download and run the unified script
bash <(curl -fsSL https://raw.githubusercontent.com/letmefind/Easy-paqet/master/paqet.sh)
```

Or clone the repository:

```bash
git clone https://github.com/letmefind/Easy-paqet.git
cd Easy-paqet
sudo bash paqet.sh
```

### What Happens During Installation

1. **Language Selection** - Choose English or Persian
2. **Auto-Installation** - Paqet binary downloaded and installed automatically
3. **User Creation** - `paqet` user created automatically
4. **Network Optimization** - Optional BBR and sysctl optimizations
5. **Configuration** - Interactive setup for server or client
6. **Service Creation** - Systemd service created with discreet name
7. **Client Package** - Option to generate client package

---

## 🏗️ Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Foreign Server (Kharej)                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Paqet Server (udp-relay-tunnel1)            │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │   │
│  │  │ Port 9999 │  │ Port 8888│  │ Port 7777│  ...     │   │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘          │   │
│  │       │             │             │                 │   │
│  │       └─────────────┴─────────────┘                 │   │
│  │                    │                                  │   │
│  │              [KCP Tunnel]                           │   │
│  │         (Raw Socket + KCP)                           │   │
│  └──────────────────────┬───────────────────────────────┘   │
└──────────────────────────┼──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Iran Server (Iran)                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Paqet Client (udp-relay-tunnel1)             │   │
│  │  ┌──────────────────────────────────────────────┐    │   │
│  │  │         Tunnel Port (Receives from Kharej)     │    │   │
│  │  └──────────────────────┬───────────────────────┘    │   │
│  │                         │                             │   │
│  │              ┌──────────┴──────────┐                  │   │
│  │              │                     │                  │   │
│  │         ┌────▼────┐          ┌────▼────┐            │   │
│  │         │ Forward  │          │  Local  │            │   │
│  │         │  to C     │          │Services │            │   │
│  │         └──────────┘          └─────────┘            │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### How It Works

1. **Server Side (Kharej)**: Listens on specified ports, captures packets using raw sockets
2. **KCP Transport**: Encrypts and transmits packets via KCP protocol over UDP
3. **Client Side (Iran)**: Receives KCP packets, decrypts, and forwards to target addresses
4. **Bidirectional**: Works in both directions simultaneously

---

## 📦 Installation

### Step-by-Step Installation

#### 1. Setup Foreign Server (Kharej)

```bash
sudo bash paqet.sh
# Select: Setup Foreign Server
# Enter tunnel name, listen port
# Choose user count profile (affects optimization)
# Configure network settings
```

**Required Information:**
- Tunnel name (e.g., `tunnel1`)
- Listen port (e.g., `9999`)
- Network interface
- Router MAC address
- Expected concurrent users (for auto-optimization)
- Encryption key (auto-generated or custom)

**Generated Information (Save for Client):**
- Encryption key
- Server IP address
- Server port

#### 2. Setup Iran Client

```bash
sudo bash paqet.sh
# Select: Setup Iran Client
# Enter foreign server details
# Enter encryption key
# Configure target addresses
```

**Required Information:**
- Foreign server IP address
- Server port
- Encryption key (from server setup)
- Tunnel name
- Target addresses (where to forward traffic)
- Expected concurrent users (for auto-optimization)

### Installation Options

The script provides an interactive menu:

```
╔═══════════════════════════════════════════════════════════════╗
║                    Paqet Manager                              ║
╚═══════════════════════════════════════════════════════════════╝

1) Setup Foreign Server (Kharej)
2) Setup Iran Client
3) Manage Configs
4) Manage Services
5) Manage Logs
6) Find Optimal MTU
7) Exit
```

---

## ⚙️ Configuration

### Configuration File Structure

Paqet uses YAML configuration files located in `/etc/paqet/`:

```yaml
# Server Configuration Example
server:
  ipv4:
    addr: "192.168.1.1:9999"
    router_mac: "aa:bb:cc:dd:ee:ff"
  pcap:
    sockbuf: 16777216
  tcp:
    local_flag: ["PA"]

transport:
  protocol: "kcp"
  conn: 2
  kcp:
    mode: "fast2"
    mtu: 1480
    rcvwnd: 2048
    sndwnd: 2048
    block: "salsa20"
    key: "your-encryption-key-here"
    smuxbuf: 16777216
    streambuf: 8388608

forward:
  - listen: "0.0.0.0:8080"
    target: "127.0.0.1:8080"
    protocol: "tcp"
```

### Key Configuration Parameters

#### KCP Settings

- **mode**: `normal`, `fast`, `fast2`, `fast3`
  - `normal`: Balanced speed and latency
  - `fast`: Faster, higher CPU usage
  - `fast2`: Very fast, optimized for medium traffic
  - `fast3`: Maximum speed, high CPU usage

- **conn**: Number of parallel KCP connections (1-256)
  - More connections = better throughput but higher CPU

- **rcvwnd/sndwnd**: Receive/Send window sizes
  - Larger windows = better throughput but more memory

- **mtu**: Maximum Transmission Unit (default: 1480)
  - Use MTU discovery tool to find optimal value

#### Encryption Algorithms

| Algorithm | Speed | Security | CPU Usage |
|-----------|-------|----------|-----------|
| **salsa20** ⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **aes** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **blowfish** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **cast5** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **sm4** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

**Default**: `salsa20` (best balance of speed and security)

### Auto-Optimization Profiles

The script automatically optimizes settings based on expected concurrent users:

#### Under 50 Users
- KCP Mode: `fast`
- Connections: 1
- Buffers: 8MB SMUX, 4MB Stream

#### 50-100 Users
- KCP Mode: `fast`
- Connections: 1
- Buffers: 12MB SMUX, 6MB Stream

#### 100-300 Users
- KCP Mode: `fast2`
- Connections: 2
- Buffers: 16MB SMUX, 8MB Stream

#### Over 300 Users
- KCP Mode: `fast3`
- Connections: 4
- Buffers: 64MB SMUX, 32MB Stream

---

## ⚡ Performance Optimizations

### Network Optimizations

#### BBR Congestion Control

Automatically enabled during installation:

```bash
# Check BBR status
sysctl net.ipv4.tcp_congestion_control
# Should output: net.ipv4.tcp_congestion_control = bbr
```

#### Sysctl Optimizations (Optional)

The script can optionally apply kernel parameter optimizations:

- TCP buffer sizes
- Connection tracking limits
- TCP window scaling
- Fast Open support

**Note**: Sysctl optimizations are optional and require user confirmation.

### MTU Optimization

Use the built-in MTU discovery tool:

```bash
sudo bash paqet.sh
# Select: Find Optimal MTU
# Enter target IP
# Enter test duration (default: 300 seconds)
```

The tool will:
1. Rapidly test MTU range (1500 → 1200)
2. Validate stability with zero packet loss tolerance
3. Recommend optimal MTU and MSS

**Default MTU**: 1480 (recommended for most networks)

---

## 🛠️ Management Tools

### Config Management

```bash
sudo bash paqet.sh
# Select: Manage Configs
```

Features:
- List all configurations
- View configuration details
- Edit configurations
- Delete configurations
- Create new configurations

### Service Management

```bash
sudo bash paqet.sh
# Select: Manage Services
```

Features:
- List all services (`udp-relay-*`)
- Start/Stop services
- Restart services
- Enable/Disable services
- View service status
- View service logs

### Log Management

```bash
sudo bash paqet.sh
# Select: Manage Logs
```

Features:
- List all configs with current log levels
- Change log level per config or all configs
- Log levels: `none`, `debug`, `info`, `warn`, `error`, `fatal`

### MTU Discovery

```bash
sudo bash paqet.sh
# Select: Find Optimal MTU
```

Features:
- Rapid initial discovery (1500 → 1200)
- Stability validation (user-defined duration)
- Zero packet loss tolerance
- Automatic MTU reduction on failure
- MSS calculation

### Manual Service Commands

```bash
# Start service
sudo systemctl start udp-relay-tunnel1

# Stop service
sudo systemctl stop udp-relay-tunnel1

# Restart service
sudo systemctl restart udp-relay-tunnel1

# Enable on boot
sudo systemctl enable udp-relay-tunnel1

# View status
sudo systemctl status udp-relay-tunnel1

# View logs
sudo journalctl -u udp-relay-tunnel1 -f
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Service Won't Start

```bash
# Check service status
systemctl status udp-relay-tunnel1

# Check logs
journalctl -u udp-relay-tunnel1 -f

# Verify configuration
paqet run -c /etc/paqet/tunnel1.yaml --dry-run
```

#### 2. "No buffer space available" Error

This indicates buffer overflow. Solutions:

- Increase KCP buffers (`smuxbuf`, `streambuf`)
- Increase socket buffers (`pcap.sockbuf`)
- Reduce KCP window sizes (`rcvwnd`, `sndwnd`)
- Use auto-optimization with correct user count

#### 3. Connection Issues

**Check Encryption Key Match:**
```bash
# Server
grep "key:" /etc/paqet/tunnel1-server.yaml

# Client
grep "key:" /etc/paqet/tunnel1-client.yaml
```

**Check Port Accessibility:**
```bash
# On server
ss -ulnp | grep 9999

# Test connectivity
nc -u server-ip 9999
```

#### 4. High Packet Loss

- Use MTU discovery tool to find optimal MTU
- Reduce MTU value in configuration
- Check network quality
- Verify iptables rules (NOTRACK rules)

#### 5. Performance Issues

**Check KCP Mode:**
```bash
grep "mode:" /etc/paqet/tunnel1.yaml
```

**Check Buffer Sizes:**
```bash
grep -E "(smuxbuf|streambuf|sockbuf)" /etc/paqet/tunnel1.yaml
```

**Apply Optimizations:**
- Use auto-optimization based on actual user count
- Enable BBR if not already enabled
- Consider sysctl optimizations for high traffic

### Log Analysis

```bash
# View service logs
journalctl -u udp-relay-tunnel1 -f

# View with log level
journalctl -u udp-relay-tunnel1 -f --priority=info

# View errors only
journalctl -u udp-relay-tunnel1 -f --priority=err
```

### iptables Rules

Paqet requires specific iptables rules to prevent kernel interference:

```bash
# These are automatically applied during installation
iptables -t raw -A PREROUTING -p tcp --dport 9999 -j NOTRACK
iptables -t raw -A OUTPUT -p tcp --sport 9999 -j NOTRACK
iptables -t mangle -A OUTPUT -p tcp --sport 9999 --tcp-flags RST RST -j DROP
```

**Verify rules:**
```bash
iptables -t raw -L -n -v
iptables -t mangle -L -n -v
```

---

## 📚 Advanced Configuration

### Custom KCP Settings

Edit configuration file directly:

```bash
sudo nano /etc/paqet/tunnel1.yaml
```

Modify KCP section:

```yaml
transport:
  protocol: "kcp"
  conn: 4                    # Increase for more throughput
  kcp:
    mode: "fast3"            # Maximum speed
    mtu: 1480                # Use MTU discovery result
    rcvwnd: 8192             # Large receive window
    sndwnd: 8192             # Large send window
    block: "salsa20"         # Encryption algorithm
    key: "your-key"
    smuxbuf: 67108864        # 64MB SMUX buffer
    streambuf: 33554432      # 32MB stream buffer
```

### Multiple Tunnels

You can create multiple tunnels with different names:

```bash
sudo bash paqet.sh
# Select: Setup Foreign Server
# Enter different tunnel name: tunnel2
# Configure different port: 8888
```

Each tunnel runs as a separate service: `udp-relay-tunnel1`, `udp-relay-tunnel2`, etc.

### Client Package Generation

Generate ready-to-install client packages:

```bash
# During server setup, choose "Yes" when asked about client package
# Or manually:
sudo bash paqet.sh
# Select: Setup Foreign Server
# After configuration, choose to create client package
```

The package includes:
- Paqet binary
- Auto-install script
- Pre-configured settings
- Network optimization tools

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow existing code style
- Add comments for complex logic
- Update documentation for new features
- Test your changes thoroughly
- Follow semantic versioning

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

This project is provided for **educational and legitimate use cases only**. Users are responsible for:

- Compliance with local laws and regulations
- Proper authorization for network usage
- Ethical use of the software

The authors and contributors are not responsible for any misuse of this software.

---

## 📞 Support

### Getting Help

- **GitHub Issues**: [Open an issue](https://github.com/letmefind/Easy-paqet/issues)
- **Documentation**: Check this README and inline script help

### Reporting Issues

When reporting issues, please include:

- Paqet version (`paqet version`)
- Operating system and version
- Installation method
- Error messages and logs
- Steps to reproduce
- Configuration file (with sensitive data removed)

---

<div align="center">

**Made with ❤️ for communication freedom**

[⬆ Back to top](#-paqet-tunnel-manager)

</div>
