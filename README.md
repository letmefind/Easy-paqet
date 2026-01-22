# paqet - Transport over Raw Packet

[![Go Version](https://img.shields.io/badge/go-1.25+-blue.svg)](https://golang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

`paqet` یک پروکسی دوطرفه در سطح پکت است که با استفاده از raw sockets در Go ساخته شده است. این پروژه ترافیک را از یک کلاینت محلی به یک سرور ریموت منتقل می‌کند که سپس به سرویس‌های هدف متصل می‌شود. با کار در سطح پکت، کاملاً از پشته TCP/IP سیستم‌عامل میزبان عبور می‌کند و از KCP برای انتقال امن و قابل اعتماد استفاده می‌کند.

> **⚠️ هشدار وضعیت توسعه**
>
> این پروژه در حال **توسعه فعال** است. APIها، فرمت‌های کانفیگ، مشخصات پروتکل و رابط‌های خط فرمان ممکن است بدون اطلاع تغییر کنند. انتظار تغییرات شکست‌آمیز بین نسخه‌ها را داشته باشید. در محیط‌های production با احتیاط استفاده کنید.

---

# راهنمای نصب و راه‌اندازی Paqet 🚀

سلام! این راهنما بهت کمک می‌کنه که پروژه paqet رو روی دو سرور لینوکسی راه‌اندازی کنی. خیلی راحت و ساده!

## 📋 چیزایی که نیاز داری:

- دو سرور لینوکسی (سرور A و سرور B)
- دسترسی root یا sudo
- اینترنت برای دانلود فایل‌ها
- `libpcap` development libraries (برای نصب: `sudo apt-get install libpcap-dev` در Debian/Ubuntu یا `sudo yum install libpcap-devel` در RHEL/CentOS)

---

## 🎯 روش سریع: استفاده از اسکریپت تعاملی (توصیه می‌شه!)

اگه می‌خوای همه چیز خودکار باشه و فقط به سوالات جواب بدی، از اسکریپت تعاملی استفاده کن:

```bash
chmod +x setup_interactive.sh
./setup_interactive.sh
```

این اسکریپت:
- ✅ مرحله به مرحله ازت سوال می‌پرسه
- ✅ اطلاعات شبکه رو خودش پیدا می‌کنه
- ✅ فایل کانفیگ رو خودش می‌سازه
- ✅ قوانین iptables رو خودش اعمال می‌کنه
- ✅ کلید رمزنگاری رو تولید می‌کنه
- ✅ دستورات اجرا رو نشونت می‌ده

---

## 🔧 مرحله ۱: نصب Paqet روی هر دو سرور

### روی سرور A (کلاینت):

```bash
# دانلود آخرین نسخه paqet
wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet

# یا اگر نسخه خاصی می‌خوای:
# wget https://github.com/hanselime/paqet/releases/download/v1.0.0/paqet-linux-amd64 -O paqet

# دادن دسترسی اجرا
chmod +x paqet

# انتقال به مسیر مناسب (اختیاری)
sudo mv paqet /usr/local/bin/
```

### روی سرور B (سرور):

همون کارها رو انجام بده:

```bash
wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet
chmod +x paqet
sudo mv paqet /usr/local/bin/
```

---

## ⚙️ مرحله ۲: تنظیم کانفیگ‌ها

در این repository دو فایل کانفیگ آماده وجود داره که می‌تونی استفاده کنی:

- `config_client.yaml` - برای سرور A (کلاینت)
- `config_server.yaml` - برای سرور B (سرور)

### روی سرور A:

1. فایل `config_client.yaml` رو با ویرایشگر باز کن (مثلا nano یا vim):

```bash
nano config_client.yaml
```

2. این قسمت‌ها رو ویرایش کن:
   - `network.interface`: نام اینترفیس شبکه‌ات (مثلا `eth0` یا `ens3`)
   - `network.local_addr`: آی‌پی سرور A با پورت `0` (مثلا `192.168.1.100:0`)
   - `network.router_mac`: MAC آدرس روترت (میتونی با `ip route | grep default` و سپس `arp -n <gateway_ip>` پیدا کنی)
   - `server.addr`: آی‌پی سرور B و پورت (مثلا `203.0.113.10:9999`)

### روی سرور B:

1. فایل `config_server.yaml` رو باز کن:

```bash
nano config_server.yaml
```

2. این قسمت‌ها رو ویرایش کن:
   - `network.interface`: نام اینترفیس شبکه‌ات
   - `network.local_addr`: آی‌پی سرور B و پورت (مثلا `10.0.0.100:9999` - باید با `listen.addr` یکسان باشه)
   - `network.router_mac`: MAC آدرس روترت
   - `listen.addr`: پورت گوش دادن (مثلا `:9999`)

**نکته مهم:** کلید رمزنگاری (`transport.kcp.key`) باید در هر دو فایل **دقیقاً یکسان** باشه!

---

## 🔥 مرحله ۳: اعمال قوانین iptables روی سرور B

این کار خیلی مهمه! باید جلوی ارسال پکت‌های RST توسط کرنل رو بگیری.

```bash
# اجرای اسکریپت آماده
chmod +x iptables_rules.sh
sudo ./iptables_rules.sh
```

یا اگه می‌خوای دستی انجام بدی:

```bash
PORT=9999  # پورت listen سرور

# 1. دور زدن connection tracking
sudo iptables -t raw -A PREROUTING -p tcp --dport $PORT -j NOTRACK
sudo iptables -t raw -A OUTPUT -p tcp --sport $PORT -j NOTRACK

# 2. جلوگیری از ارسال پکت‌های RST
sudo iptables -t mangle -A OUTPUT -p tcp --sport $PORT --tcp-flags RST RST -j DROP

# ذخیره کردن (برای Debian/Ubuntu)
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# یا برای RedHat/CentOS
sudo service iptables save
```

---

## 🚀 مرحله ۴: اجرای Paqet

### روی سرور B (اول سرور رو اجرا کن):

```bash
# اجرای سرور
sudo paqet run -c config_server.yaml

# یا اگه در مسیر دیگه‌ای هستی:
sudo /usr/local/bin/paqet run -c /path/to/config_server.yaml
```

### روی سرور A (بعد کلاینت رو اجرا کن):

```bash
# اجرای کلاینت
sudo paqet run -c config_client.yaml

# یا اگه در مسیر دیگه‌ای هستی:
sudo /usr/local/bin/paqet run -c /path/to/config_client.yaml
```

**نکته:** اگه می‌خوای در پس‌زمینه اجرا بشه، از `screen` یا `tmux` استفاده کن:

```bash
# نصب screen (اگه نصب نیست)
sudo apt install screen  # برای Debian/Ubuntu
# یا
sudo yum install screen  # برای CentOS/RHEL

# اجرا در screen
screen -S paqet
sudo paqet run -c config_server.yaml

# برای جدا شدن: Ctrl+A سپس D
# برای برگشت: screen -r paqet
```

---

## 🧪 مرحله ۵: تست کردن اتصال

### تست ۱: بررسی اینکه SOCKS5 Proxy کار می‌کنه

روی سرور A یا هر کامپیوتری که به سرور A دسترسی داره:

```bash
# تست با curl
curl -x socks5://127.0.0.1:1080 http://httpbin.org/ip

# یا تست با یک سایت دیگه
curl -x socks5://127.0.0.1:1080 https://www.google.com
```

اگه جواب گرفت، یعنی همه چیز درسته! 🎉

### تست ۲: استفاده از دستور ping

```bash
# روی کلاینت (سرور A)
sudo paqet ping -c config_client.yaml
```

---

## 🔍 عیب‌یابی (Troubleshooting)

### مشکل: اتصال برقرار نمیشه

1. **چک کن که فایروال پورت 9999 رو باز کرده باشه:**
```bash
# روی سرور B
sudo ufw allow 9999/tcp  # برای ufw
# یا
sudo firewall-cmd --add-port=9999/tcp --permanent  # برای firewalld
sudo firewall-cmd --reload
```

2. **چک کن که آی‌پی و پورت درست باشه:**
```bash
# روی سرور A
ping YOUR_SERVER_B_IP
telnet YOUR_SERVER_B_IP 9999
```

3. **چک کن که کلید رمزنگاری یکسان باشه** در هر دو فایل کانفیگ

4. **چک کن که قوانین iptables اعمال شده باشن:**
```bash
sudo iptables -t raw -L -n -v
sudo iptables -t mangle -L -n -v
```

### مشکل: پکت‌های RST ارسال می‌شن

مطمئن شو که دستورات iptables رو درست اجرا کردی (مرحله ۳ رو دوباره چک کن).

### مشکل: SOCKS5 Proxy پاسخ نمی‌ده

1. چک کن که paqet روی سرور A در حال اجرا باشه
2. چک کن که پورت 1080 باز باشه:
```bash
sudo netstat -tlnp | grep 1080
# یا
sudo ss -tlnp | grep 1080
```

---

## 📝 نکات مهم

- **همیشه اول سرور B رو اجرا کن، بعد سرور A**
- **کلید رمزنگاری (`transport.kcp.key`) باید در هر دو فایل یکسان باشه**
- **MAC آدرس روتر رو درست وارد کن** (اگه اشتباه باشه، کار نمی‌کنه)
- **برای سرور، پورت `network.local_addr` و `listen.addr` باید یکسان باشه**
- **برای کلاینت، از پورت `0` در `network.local_addr` استفاده کن** تا خودکار انتخاب بشه

---

## 🔄 اجرای دائمی با systemd (اختیاری)

اگه می‌خوای paqet همیشه اجرا باشه و با راه‌اندازی مجدد سرور، خودکار شروع بشه:

### روی سرور A:

```bash
sudo nano /etc/systemd/system/paqet-client.service
```

محتوای زیر رو بذار:

```ini
[Unit]
Description=Paqet Client
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/paqet run -c /path/to/config_client.yaml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

سپس:

```bash
sudo systemctl daemon-reload
sudo systemctl enable paqet-client
sudo systemctl start paqet-client
```

### روی سرور B:

همون کار رو انجام بده، فقط اسم سرویس رو `paqet-server` بذار و مسیر کانفیگ رو تغییر بده.

---

## 🎯 خلاصه دستورات سریع

```bash
# نصب
wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet
chmod +x paqet
sudo mv paqet /usr/local/bin/

# ویرایش کانفیگ
nano config_client.yaml  # روی سرور A
nano config_server.yaml  # روی سرور B

# اعمال iptables (روی سرور B)
sudo ./iptables_rules.sh

# اجرا
sudo paqet run -c config_server.yaml  # روی سرور B
sudo paqet run -c config_client.yaml  # روی سرور A

# تست
curl -x socks5://127.0.0.1:1080 http://httpbin.org/ip
```

---

## 📚 دستورات Paqet

`paqet` یک برنامه چند دستوری است. دستور اصلی `run` است که پروکسی رو شروع می‌کنه:

| دستور | توضیحات |
| :-------- | :------------------------------------------------------------------------------- |
| `run`     | شروع پروکسی کلاینت یا سرور paqet. این دستور اصلی عملیاتی است. |
| `secret`  | تولید یک کلید رمزنگاری امن جدید. |
| `ping`    | ارسال یک پکت تست به سرور برای بررسی اتصال. |
| `dump`    | ابزار تشخیصی مشابه `tcpdump` که پکت‌ها رو capture و decode می‌کنه. |
| `version` | نمایش اطلاعات نسخه برنامه. |

---

## ⚠️ هشدار امنیتی

این پروژه یک اکتشاف از شبکه‌سازی سطح پایین است و مسئولیت‌های امنیتی قابل توجهی دارد. پروتکل انتقال KCP رمزنگاری، احراز هویت و یکپارچگی را با استفاده از رمزنگاری متقارن با کلید مشترک فراهم می‌کند.

امنیت کاملاً به مدیریت صحیح کلید بستگی دارد. از دستور `secret` برای تولید یک کلید قوی استفاده کن که باید در هر دو کلاینت و سرور یکسان باقی بماند.

---

## 📄 فایل‌های موجود در این Repository

- `config_client.yaml` - کانفیگ آماده برای کلاینت (سرور A)
- `config_server.yaml` - کانفیگ آماده برای سرور (سرور B)
- `iptables_rules.sh` - اسکریپت اعمال قوانین iptables
- `quick_setup.sh` - اسکریپت راه‌اندازی خودکار
- `QUICK_START.md` - راهنمای سریع

---

<details>
<summary><b>📖 English Documentation (Click to expand)</b></summary>

# paqet - Transport over Raw Packet

`paqet` is a bidirectional Packet-level proxy built using raw sockets in Go. It forwards traffic from a local client to a remote server, which then connects to target services. By operating at the packet level, it completely bypasses the host operating system's TCP/IP stack and uses KCP for secure, reliable transport.

> **⚠️ Development Status Notice**
>
> This project is in **active development**. APIs, configuration formats, protocol specifications, and command-line interfaces may change without notice. Expect breaking changes between versions. Use with caution in production environments.

This project serves as an example of low-level network programming in Go, demonstrating concepts like:

- Raw packet crafting and injection with `gopacket`.
- Packet capture with `pcap`.
- Custom binary network protocols.
- The security implications of operating below the standard OS firewall.

## Use Cases and Motivation

`paqet` is designed for specific scenarios where standard VPN or SSH tunnels may be insufficient. Its primary use cases include bypassing firewalls that detect standard handshake protocols by using custom packet structures, network security research for penetration testing and data exfiltration, and evading kernel-level connection tracking for monitoring avoidance.

While `paqet` includes built-in encryption via KCP, it is more complex to configure than general-purpose VPN solutions.

## How It Works

`paqet` creates a transport channel using KCP over raw TCP packets, bypassing the OS's TCP/IP stack entirely. It captures packets using pcap and injects crafted TCP packets containing encrypted transport data, allowing it to bypass kernel-level connection tracking and evade firewalls.

```
[Your App] <------> [paqet Client] <===== Raw TCP Packet =====> [paqet Server] <------> [Target Server]
(e.g. curl)        (localhost:1080)        (Internet)          (Public IP:PORT)     (e.g. https://httpbin.org)
```

The system operates in three layers: raw TCP packet injection, encrypted transport (KCP), and application-level connection multiplexing.

KCP provides reliable, encrypted communication with aggressive retransmission and forward error correction optimized for high-loss networks. It uses symmetric encryption with a shared secret key and offers multiple congestion control modes with SMUX multiplexing.

KCP is optimized for real-time applications, gaming, or unpredictable network conditions where low latency and simple setup are preferred.

## Getting Started

### Prerequisites

- `libpcap` development libraries must be installed on both the client and server machines.
  - **Debian/Ubuntu:** `sudo apt-get install libpcap-dev`
  - **RHEL/CentOS/Fedora:** `sudo yum install libpcap-devel`
  - **macOS:** Comes pre-installed with Xcode Command Line Tools. Install with `xcode-select --install`
  - **Windows:** Install Npcap. Download from [npcap.com](https://npcap.com/).

### 1. Download a Release

Download the pre-compiled binary for your client and server operating systems from the project's **Releases page**.

You will also need the configuration files from the `example/` directory or use the ready-made configs in this repository:
- `config_client.yaml` - Client configuration
- `config_server.yaml` - Server configuration

### 2. Configure the Connection

paqet uses a unified configuration approach with role-based settings. You can use the ready-made config files in this repository or copy and modify from:
- `example/client.yaml.example` - Client configuration example
- `example/server.yaml.example` - Server configuration example

You must correctly set the interfaces, IP addresses, MAC addresses, and ports.

> **⚠️ Important:**
>
> - **Role Configuration**: Role must be explicitly set as `role: "client"` or `role: "server"`
> - **Transport Security**: KCP requires identical keys on client/server.
> - **Configuration**: See "Critical Configuration Points" section below for detailed security requirements

#### Finding Your Network Details

You'll need to find your network interface name, local IP, and the MAC address of your network's gateway (router).

**On Linux:**

1.  **Find Interface and Local IP:** Run `ip a`. Look for your primary network card (e.g., `eth0`, `ens3`). Its IP address is listed under `inet`.
2.  **Find Gateway MAC:**
    - First, find your gateway's IP: `ip r | grep default`
    - Then, find its MAC address with `arp -n <gateway_ip>` (e.g., `arp -n 192.168.1.1`).

**On macOS:**

1.  **Find Interface and Local IP:** Run `ifconfig`. Look for your primary interface (e.g., `en0`). Its IP is listed under `inet`.
2.  **Find Gateway MAC:**
    - First, find your gateway's IP: `netstat -rn | grep default`
    - Then, find its MAC address with `arp <gateway_ip>` (e.g., `arp 192.168.1.1`).

**On Windows:**

1.  **Find Interface and Local IP:** Open Command Prompt or PowerShell and run `ipconfig /all`. Look for your active network adapter (e.g., "Ethernet adapter Ethernet", "Wi-Fi adapter Wi-Fi"). Note the "IPv4 Address".
2.  **Find Interface Name:** Run `netsh interface show interface` to list interface names. Use the "Interface Name" column value (e.g., "Ethernet", "Wi-Fi").
3.  **Find Gateway MAC:**
    - First, find your gateway's IP: `ipconfig /all` (look for "Default Gateway")
    - Then, find its MAC address with `arp -a <gateway_ip>` (e.g., `arp -a 192.168.1.1`)

#### Client Configuration - SOCKS5 Proxy Mode

The client acts as a SOCKS5 proxy server, accepting connections from applications and dynamically forwarding them through the raw TCP packets to any destination.

#### Example Client Configuration (`config.yaml`)

```yaml
# Role must be explicitly set
role: "client"

# Logging configuration
log:
  level: "info" # none, debug, info, warn, error, fatal

# SOCKS5 proxy configuration (client mode)
socks5:
  - listen: "127.0.0.1:1080" # SOCKS5 proxy listen address

# Network interface settings
network:
  interface: "en0" # CHANGE ME: Network interface (en0, eth0, wlan0, etc.)
  local_addr: "192.168.1.100:0" # CHANGE ME: Local IP (use port 0 for random port)
  router_mac: "aa:bb:cc:dd:ee:ff" # CHANGE ME: Gateway/router MAC address

# Server connection settings
server:
  addr: "SERVER_IP:9999" # CHANGE ME: paqet server address and port

# Transport protocol configuration
transport:
  protocol: "kcp" # Transport protocol (currently only "kcp" supported)
  kcp:
    block: "aes" # Encryption algorithm
    key: "your-secret-key-here" # CHANGE ME: Secret key (must match server)
```

#### Example Server Configuration (`config.yaml`)

```yaml
# Role must be explicitly set
role: "server"

# Logging configuration
log:
  level: "info" # none, debug, info, warn, error, fatal

# Server listen configuration
listen:
  addr: ":9999" # CHANGE ME: Server listen port (must match network.local_addr port)

# Network interface settings
network:
  interface: "eth0" # CHANGE ME: Network interface (eth0, ens3, en0, etc.)
  local_addr: "10.0.0.100:9999" # CHANGE ME: Server IP and port (port must match listen.addr)
  router_mac: "aa:bb:cc:dd:ee:ff" # CHANGE ME: Gateway/router MAC address

# Transport protocol configuration
transport:
  protocol: "kcp" # Transport protocol (currently only "kcp" supported)
  kcp:
    block: "aes" # Encryption algorithm
    key: "your-secret-key-here" # CHANGE ME: Secret key (must match client)
```

#### Critical Firewall Configuration

This application uses `pcap` to receive and inject packets at a low level, **bypassing traditional firewalls like `ufw` or `firewalld`**. However, the OS kernel will still see incoming packets for the connection port and, not knowing about the connection, will generate TCP `RST` (reset) packets. While your connection may appear to work initially, these kernel-generated RST packets can corrupt connection state in NAT devices and stateful firewalls, leading to connection instability, packet drops, and premature connection termination in complex network environments.

You **must** configure `iptables` on the server to prevent the kernel from interfering.

Run these commands as root on your server:

```bash
# Replace <PORT> with your server listen port (e.g., 9999)

# 1. Bypass connection tracking (conntrack) for the connection port. This is essential.
# This tells the kernel's netfilter to ignore packets on this port for state tracking.
sudo iptables -t raw -A PREROUTING -p tcp --dport <PORT> -j NOTRACK
sudo iptables -t raw -A OUTPUT -p tcp --sport <PORT> -j NOTRACK

# 2. Prevent the kernel from sending TCP RST packets that would kill the session.
# This drops any RST packets the kernel tries to send from the connection port.
sudo iptables -t mangle -A OUTPUT -p tcp --sport <PORT> --tcp-flags RST RST -j DROP

# An alternative for rule 2 if issues persist:
sudo iptables -t filter -A INPUT -p tcp --dport <PORT> -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --sport <PORT> -j ACCEPT

# To make rules persistent across reboots:
# Debian/Ubuntu: sudo iptables-save > /etc/iptables/rules.v4
# RHEL/CentOS: sudo service iptables save
```

These rules ensure that only the application handles traffic for the connection port.

### 3. Run `paqet`

Make the downloaded binary executable (`chmod +x ./paqet_linux_amd64`). You will need root privileges to use raw sockets.

**On the Server:**
_Place your server configuration file in the same directory as the binary and run:_

```bash
# Make sure to use the binary name you downloaded for your server's OS/Arch.
sudo ./paqet_linux_amd64 run -c config.yaml
```

**On the Client:**
_Place your client configuration file in the same directory as the binary and run:_

```bash
# Make sure to use the binary name you downloaded for your client's OS/Arch.
sudo ./paqet_darwin_arm64 run -c config.yaml
```

### 4. Test the Connection

Once the client and server are running, test the SOCKS5 proxy:

```bash
# Test with curl using the SOCKS5 proxy
curl -v https://httpbin.org/ip --proxy socks5h://127.0.0.1:1080
```

This request will be proxied over raw TCP packets to the server, and then forwarded according to the client mode configuration. The output should show your server's public IP address, confirming the connection is working.

## Command-Line Usage

`paqet` is a multi-command application. The primary command is `run`, which starts the proxy, but several utility commands are included to help with configuration and debugging.

The general syntax is:

```bash
sudo ./paqet <command> [arguments]
```

| Command   | Description                                                                      |
| :-------- | :------------------------------------------------------------------------------- |
| `run`     | Starts the `paqet` client or server proxy. This is the main operational command. |
| `secret`  | Generates a new, cryptographically secure secret key.                            |
| `ping`    | Sends a single test packet to the server to verify connectivity .                |
| `dump`    | A diagnostic tool similar to `tcpdump` that captures and decodes packets.        |
| `version` | Prints the application's version information.                                    |

## Configuration Reference

paqet uses a unified YAML configuration that works for both clients and servers. The `role` field must be explicitly set to either `"client"` or `"server"`.

**📁 For complete parameter documentation, see the example files:**

- [`example/client.yaml.example`](example/client.yaml.example) - Client configuration reference
- [`example/server.yaml.example`](example/server.yaml.example) - Server configuration reference

### Critical Configuration Points

**Transport Security:** KCP requires identical keys on client/server (use `secret` command to generate).

**Network Configuration:** Use your actual IP address in `network.local_addr`, not `127.0.0.1`. For servers, `network.local_addr` and `listen.addr` ports must match. For clients, use port `0` in `network.local_addr` to automatically assign a random available port and avoid conflicts.

**TCP Flag Cycling:** The `network.tcp.local_flag` and `network.tcp.remote_flag` arrays cycle through flag combinations to vary traffic patterns. Common patterns: `["PA"]` (standard data), `["S"]` (connection setup), `["A"]` (acknowledgment).

# Architecture & Security Model

### The `pcap` Approach and Firewall Bypass

Understanding _why_ standard firewalls are bypassed is key to using this tool securely.

A normal application uses the OS's TCP/IP stack. When a packet arrives, it travels up the stack where `netfilter` (the backend for `ufw`/`firewalld`) inspects it. If a firewall rule blocks the port, the packet is dropped and never reaches the application.

```
      +------------------------+
      |   Normal Application   |  <-- Data is received here
      +------------------------+
                   ^
      +------------------------+
      |    OS TCP/IP Stack     |  <-- Firewall (netfilter) runs here
      |  (Connection Tracking) |
      +------------------------+
                   ^
      +------------------------+
      |     Network Driver     |
      +------------------------+
```

`paqet` uses `pcap` to hook in at a much lower level. It requests a **copy** of every packet directly from the network driver, _before_ the main OS TCP/IP stack and firewall get to process it.

```
      +------------------------+
      |    paqet Application   |  <-- Gets a packet copy immediately
      +------------------------+
              ^       \
 (pcap copy) /         \  (Original packet continues up)
            /           v
      +------------------------+
      |     OS TCP/IP Stack    |  <-- Firewall drops the *original* packet,
      |  (Connection Tracking) |      but paqet already has its copy.
      +------------------------+
                  ^
      +------------------------+
      |     Network Driver     |
      +------------------------+
```

This means a rule like `ufw deny <PORT>` will have no effect on the proxy's operation, as `paqet` receives and processes the packet before `ufw` can block it.

## ⚠️ Security Warning

This project is an exploration of low-level networking and carries significant security responsibilities. The KCP transport protocol provides encryption, authentication, and integrity using symmetric encryption with a shared secret key.

Security depends entirely on proper key management. Use the `secret` command to generate a strong key that must remain identical on both client and server.

## Troubleshooting

1.  **Permission Denied:** Ensure you are running with `sudo`.
2.  **Connection Times Out:**
    - **Transport Configuration Mismatch:**
      - **KCP**: Ensure `transport.kcp.key` is exactly identical on client and server
    - **`iptables` Rules:** Did you apply the firewall rules on the server?
    - **Incorrect Network Details:** Double-check all IPs, MAC addresses, and interface names.
    - **Cloud Provider Firewalls:** Ensure your cloud provider's security group allows TCP traffic on your `listen.addr` port.
    - **NAT/Port Configuration:** For servers, ensure `listen.addr` and `network.local_addr` ports match. For clients, use port `0` in `network.local_addr` for automatic port assignment to avoid conflicts.
3.  **Use `ping` and `dump`:** Use `paqet ping -c config.yaml` to test the connection. Use `paqet dump -p <PORT>` on the server to see if packets are arriving.

## Acknowledgments

This work draws inspiration from the research and implementation in the [gfw_resist_tcp_proxy](https://github.com/GFW-knocker/gfw_resist_tcp_proxy) project by GFW-knocker, which explored the use of raw sockets to circumvent certain forms of network filtering. This project serves as a Go-based exploration of those concepts.

- Uses [pcap](https://github.com/gopacket/gopacket/pcap) for low-level packet capture and injection
- Uses [gopacket](https://github.com/gopacket/gopacket) for raw packet crafting and decoding
- Uses [kcp-go](https://github.com/xtaci/kcp-go) for reliable transport with encryption
- Uses [smux](https://github.com/xtaci/smux) for connection multiplexing

## License

This project is licensed under the MIT License. See the see [LICENSE](LICENSE) file for details.

</details>

---

خب، دیگه همه چیز آماده! اگه مشکلی پیش اومد، لاگ‌ها رو چک کن یا بهم بگو تا کمک کنم. موفق باشی! 🚀
