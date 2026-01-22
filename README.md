# راهنمای نصب و راه‌اندازی Paqet 🚀

سلام! اینجا می‌خوایم paqet رو روی دو سرور لینوکسی راه‌اندازی کنیم. نگران نباش، خیلی راحته!

## چیه این paqet؟

paqet یک پروکسی دوطرفه در سطح پکت هست که ترافیک رو از یک سرور به سرور دیگه منتقل می‌کنه. با استفاده از raw sockets کار می‌کنه و از KCP برای رمزنگاری استفاده می‌کنه.

---

## چی نیاز داری؟

- دو سرور لینوکسی (یکی به عنوان کلاینت، یکی به عنوان سرور)
- دسترسی root یا sudo
- اینترنت برای دانلود فایل‌ها

---

## روش ساده: استفاده از اسکریپت تعاملی (توصیه می‌شه!)

اگه می‌خوای همه چیز خودکار باشه و فقط به چند سوال جواب بدی، این روش رو انتخاب کن:

```bash
chmod +x setup.sh
./setup.sh
```

اسکریپت اول ازت می‌پرسه که چه زبانی می‌خوای (فارسی یا انگلیسی) و بعد همه چیز رو خودش انجام می‌ده.

> **نکته:** اگه حروف فارسی در terminal برعکس نمایش داده می‌شن، این مشکل از terminal شماست نه از اسکریپت. برای راه حل، فایل [TERMINAL_FIX.md](TERMINAL_FIX.md) رو بخون. یا می‌تونی مستقیماً از اسکریپت انگلیسی استفاده کنی: `./setup_en.sh`

### اسکریپت چی کار می‌کنه؟

- مرحله به مرحله ازت سوال می‌پرسه
- اطلاعات شبکه رو خودش پیدا می‌کنه
- فایل کانفیگ رو خودش می‌سازه
- قوانین iptables رو خودش اعمال می‌کنه
- کلید رمزنگاری رو تولید می‌کنه
- دستورات اجرا رو نشونت می‌ده

---

## روش دستی: نصب و راه‌اندازی گام به گام

اگه می‌خوای خودت همه چیز رو انجام بدی، این مراحل رو دنبال کن:

### مرحله ۱: دانلود paqet

روی هر دو سرور (کلاینت و سرور) این دستورات رو اجرا کن:

```bash
# دانلود آخرین نسخه
wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet

# دادن دسترسی اجرا
chmod +x paqet

# انتقال به مسیر مناسب (اختیاری)
sudo mv paqet /usr/local/bin/
```

### مرحله ۲: تنظیم کانفیگ

در این repository دو فایل کانفیگ آماده وجود داره:

- `config_client.yaml` - برای سرور کلاینت
- `config_server.yaml` - برای سرور اصلی

#### روی سرور کلاینت:

1. فایل `config_client.yaml` رو باز کن:
```bash
nano config_client.yaml
```

2. این قسمت‌ها رو ویرایش کن:
   - `network.interface`: نام اینترفیس شبکه‌ات (مثلا `eth0`)
   - `network.local_addr`: آی‌پی سرور کلاینت با پورت `0` (مثلا `192.168.1.100:0`)
   - `network.router_mac`: MAC آدرس روترت
   - `server.addr`: آی‌پی سرور اصلی و پورت (مثلا `203.0.113.10:9999`)

#### روی سرور اصلی:

1. فایل `config_server.yaml` رو باز کن:
```bash
nano config_server.yaml
```

2. این قسمت‌ها رو ویرایش کن:
   - `network.interface`: نام اینترفیس شبکه‌ات
   - `network.local_addr`: آی‌پی سرور اصلی و پورت (مثلا `10.0.0.100:9999`)
   - `network.router_mac`: MAC آدرس روترت
   - `listen.addr`: پورت گوش دادن (مثلا `:9999`)

**نکته مهم:** کلید رمزنگاری (`transport.kcp.key`) باید در هر دو فایل **دقیقاً یکسان** باشه!

### مرحله ۳: پیدا کردن اطلاعات شبکه

اگه نمی‌دونی اینترفیس یا MAC آدرس روترت چیه، این دستورات رو اجرا کن:

```bash
# پیدا کردن اینترفیس و آی‌پی
ip a

# پیدا کردن آی‌پی روتر
ip route | grep default

# پیدا کردن MAC آدرس روتر (بعد از پیدا کردن آی‌پی روتر)
arp -n <آی‌پی_روتر>
```

### مرحله ۴: اعمال قوانین iptables روی سرور اصلی

این کار خیلی مهمه! باید جلوی ارسال پکت‌های RST توسط کرنل رو بگیری.

```bash
# اجرای اسکریپت آماده
chmod +x iptables_rules.sh
sudo ./iptables_rules.sh
```

یا اگه می‌خوای دستی انجام بدی:

```bash
PORT=9999  # پورت listen سرور

# دور زدن connection tracking
sudo iptables -t raw -A PREROUTING -p tcp --dport $PORT -j NOTRACK
sudo iptables -t raw -A OUTPUT -p tcp --sport $PORT -j NOTRACK

# جلوگیری از ارسال پکت‌های RST
sudo iptables -t mangle -A OUTPUT -p tcp --sport $PORT --tcp-flags RST RST -j DROP

# ذخیره کردن
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### مرحله ۵: اجرای paqet

**اول سرور اصلی رو اجرا کن:**

```bash
sudo paqet run -c config_server.yaml
```

**بعد سرور کلاینت رو اجرا کن:**

```bash
sudo paqet run -c config_client.yaml
```

**نکته:** اگه می‌خوای در پس‌زمینه اجرا بشه، از `screen` یا `tmux` استفاده کن:

```bash
# نصب screen (اگه نصب نیست)
sudo apt install screen  # برای Debian/Ubuntu
sudo yum install screen  # برای CentOS/RHEL

# اجرا در screen
screen -S paqet
sudo paqet run -c config_server.yaml

# برای جدا شدن: Ctrl+A سپس D
# برای برگشت: screen -r paqet
```

### مرحله ۶: تست کردن

روی سرور کلاینت یا هر کامپیوتری که به سرور کلاینت دسترسی داره:

```bash
# تست با curl
curl -x socks5://127.0.0.1:1080 http://httpbin.org/ip
```

اگه جواب گرفت، یعنی همه چیز درسته! 🎉

---

## عیب‌یابی

### اتصال برقرار نمیشه؟

1. **چک کن که فایروال پورت 9999 رو باز کرده باشه:**
```bash
# روی سرور اصلی
sudo ufw allow 9999/tcp  # برای ufw
# یا
sudo firewall-cmd --add-port=9999/tcp --permanent  # برای firewalld
sudo firewall-cmd --reload
```

2. **چک کن که آی‌پی و پورت درست باشه:**
```bash
ping <آی‌پی_سرور_اصلی>
telnet <آی‌پی_سرور_اصلی> 9999
```

3. **چک کن که کلید رمزنگاری یکسان باشه** در هر دو فایل کانفیگ

4. **چک کن که قوانین iptables اعمال شده باشن:**
```bash
sudo iptables -t raw -L -n -v
sudo iptables -t mangle -L -n -v
```

### SOCKS5 Proxy پاسخ نمی‌ده؟

1. چک کن که paqet روی سرور کلاینت در حال اجرا باشه
2. چک کن که پورت 1080 باز باشه:
```bash
sudo netstat -tlnp | grep 1080
# یا
sudo ss -tlnp | grep 1080
```

---

## نکات مهم

- **همیشه اول سرور اصلی رو اجرا کن، بعد سرور کلاینت**
- **کلید رمزنگاری باید در هر دو فایل یکسان باشه**
- **MAC آدرس روتر رو درست وارد کن** (اگه اشتباه باشه، کار نمی‌کنه)
- **برای سرور، پورت `network.local_addr` و `listen.addr` باید یکسان باشه**
- **برای کلاینت، از پورت `0` در `network.local_addr` استفاده کن**

---

## اجرای دائمی با systemd

اگه می‌خوای paqet همیشه اجرا باشه و با راه‌اندازی مجدد سرور، خودکار شروع بشه:

### روی سرور کلاینت:

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

### روی سرور اصلی:

همون کار رو انجام بده، فقط اسم سرویس رو `paqet-server` بذار و مسیر کانفیگ رو تغییر بده.

---

## خلاصه دستورات سریع

```bash
# نصب
wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet
chmod +x paqet
sudo mv paqet /usr/local/bin/

# ویرایش کانفیگ
nano config_client.yaml  # روی سرور کلاینت
nano config_server.yaml  # روی سرور اصلی

# اعمال iptables (روی سرور اصلی)
sudo ./iptables_rules.sh

# اجرا
sudo paqet run -c config_server.yaml  # روی سرور اصلی
sudo paqet run -c config_client.yaml  # روی سرور کلاینت

# تست
curl -x socks5://127.0.0.1:1080 http://httpbin.org/ip
```

---

## دستورات Paqet

`paqet` یک برنامه چند دستوری است. دستور اصلی `run` است که پروکسی رو شروع می‌کنه:

| دستور | توضیحات |
| :-------- | :------------------------------------------------------------------------------- |
| `run`     | شروع پروکسی کلاینت یا سرور paqet |
| `secret`  | تولید یک کلید رمزنگاری امن جدید |
| `ping`    | ارسال یک پکت تست به سرور برای بررسی اتصال |
| `dump`    | ابزار تشخیصی مشابه `tcpdump` |
| `version` | نمایش اطلاعات نسخه برنامه |

---

## هشدار امنیتی

این پروژه یک اکتشاف از شبکه‌سازی سطح پایین است و مسئولیت‌های امنیتی قابل توجهی دارد. پروتکل انتقال KCP رمزنگاری، احراز هویت و یکپارچگی را با استفاده از رمزنگاری متقارن با کلید مشترک فراهم می‌کند.

امنیت کاملاً به مدیریت صحیح کلید بستگی دارد. از دستور `secret` برای تولید یک کلید قوی استفاده کن که باید در هر دو کلاینت و سرور یکسان باقی بماند.

---

## فایل‌های موجود

- `config_client.yaml` - کانفیگ آماده برای کلاینت
- `config_server.yaml` - کانفیگ آماده برای سرور
- `iptables_rules.sh` - اسکریپت اعمال قوانین iptables
- `setup.sh` - اسکریپت تعاملی راه‌اندازی
- `QUICK_START.md` - راهنمای سریع

---

<details>
<summary><b>📖 English Documentation (Click to expand)</b></summary>

# paqet - Transport over Raw Packet

`paqet` is a bidirectional Packet-level proxy built using raw sockets in Go. It forwards traffic from a local client to a remote server, which then connects to target services. By operating at the packet level, it completely bypasses the host operating system's TCP/IP stack and uses KCP for secure, reliable transport.

> **⚠️ Development Status Notice**
>
> This project is in **active development**. APIs, configuration formats, protocol specifications, and command-line interfaces may change without notice. Expect breaking changes between versions. Use with caution in production environments.

## Quick Start: Interactive Setup Script (Recommended!)

If you want everything automated and just answer a few questions, use the interactive setup script:

```bash
chmod +x setup.sh
./setup.sh
```

The script will first ask you which language you prefer (Persian or English) and then handle everything automatically.

### What does the script do?

- Asks you questions step by step
- Automatically finds network information
- Creates configuration files
- Applies iptables rules
- Generates encryption keys
- Shows you the run commands

---

## Manual Installation: Step by Step

If you want to do everything manually, follow these steps:

### Step 1: Download paqet

On both servers (client and server), run these commands:

```bash
# Download latest version
wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet

# Make executable
chmod +x paqet

# Move to appropriate location (optional)
sudo mv paqet /usr/local/bin/
```

### Step 2: Configure

This repository contains two ready-made configuration files:

- `config_client.yaml` - For the client server
- `config_server.yaml` - For the main server

#### On the client server:

1. Open `config_client.yaml`:
```bash
nano config_client.yaml
```

2. Edit these parts:
   - `network.interface`: Your network interface name (e.g., `eth0`)
   - `network.local_addr`: Client server IP with port `0` (e.g., `192.168.1.100:0`)
   - `network.router_mac`: Your router's MAC address
   - `server.addr`: Main server IP and port (e.g., `203.0.113.10:9999`)

#### On the main server:

1. Open `config_server.yaml`:
```bash
nano config_server.yaml
```

2. Edit these parts:
   - `network.interface`: Your network interface name
   - `network.local_addr`: Main server IP and port (e.g., `10.0.0.100:9999`)
   - `network.router_mac`: Your router's MAC address
   - `listen.addr`: Listen port (e.g., `:9999`)

**Important:** The encryption key (`transport.kcp.key`) must be **exactly the same** in both files!

### Step 3: Find Network Information

If you don't know your interface or router MAC address, run these commands:

```bash
# Find interface and IP
ip a

# Find router IP
ip route | grep default

# Find router MAC address (after finding router IP)
arp -n <router_ip>
```

### Step 4: Apply iptables Rules on Main Server

This is very important! You need to prevent the kernel from sending RST packets.

```bash
# Run the ready-made script
chmod +x iptables_rules.sh
sudo ./iptables_rules.sh
```

Or if you want to do it manually:

```bash
PORT=9999  # Server listen port

# Bypass connection tracking
sudo iptables -t raw -A PREROUTING -p tcp --dport $PORT -j NOTRACK
sudo iptables -t raw -A OUTPUT -p tcp --sport $PORT -j NOTRACK

# Prevent RST packet sending
sudo iptables -t mangle -A OUTPUT -p tcp --sport $PORT --tcp-flags RST RST -j DROP

# Save
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### Step 5: Run paqet

**First run the main server:**

```bash
sudo paqet run -c config_server.yaml
```

**Then run the client server:**

```bash
sudo paqet run -c config_client.yaml
```

**Note:** If you want to run it in the background, use `screen` or `tmux`:

```bash
# Install screen (if not installed)
sudo apt install screen  # For Debian/Ubuntu
sudo yum install screen  # For CentOS/RHEL

# Run in screen
screen -S paqet
sudo paqet run -c config_server.yaml

# To detach: Ctrl+A then D
# To return: screen -r paqet
```

### Step 6: Test

On the client server or any computer that has access to the client server:

```bash
# Test with curl
curl -x socks5://127.0.0.1:1080 http://httpbin.org/ip
```

If you get a response, everything is working! 🎉

---

## Troubleshooting

### Connection not established?

1. **Check that firewall has port 9999 open:**
```bash
# On main server
sudo ufw allow 9999/tcp  # For ufw
# Or
sudo firewall-cmd --add-port=9999/tcp --permanent  # For firewalld
sudo firewall-cmd --reload
```

2. **Check that IP and port are correct:**
```bash
ping <main_server_ip>
telnet <main_server_ip> 9999
```

3. **Check that encryption key is the same** in both config files

4. **Check that iptables rules are applied:**
```bash
sudo iptables -t raw -L -n -v
sudo iptables -t mangle -L -n -v
```

### SOCKS5 Proxy not responding?

1. Check that paqet is running on the client server
2. Check that port 1080 is open:
```bash
sudo netstat -tlnp | grep 1080
# Or
sudo ss -tlnp | grep 1080
```

---

## Important Notes

- **Always run the main server first, then the client server**
- **Encryption key must be the same in both files**
- **Enter router MAC address correctly** (if wrong, it won't work)
- **For server, `network.local_addr` and `listen.addr` ports must match**
- **For client, use port `0` in `network.local_addr`**

---

## Running as a Service with systemd

If you want paqet to always run and start automatically on server reboot:

### On client server:

```bash
sudo nano /etc/systemd/system/paqet-client.service
```

Put the following content:

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

Then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable paqet-client
sudo systemctl start paqet-client
```

### On main server:

Do the same, just name the service `paqet-server` and change the config path.

---

## Quick Command Summary

```bash
# Install
wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet
chmod +x paqet
sudo mv paqet /usr/local/bin/

# Edit config
nano config_client.yaml  # On client server
nano config_server.yaml  # On main server

# Apply iptables (on main server)
sudo ./iptables_rules.sh

# Run
sudo paqet run -c config_server.yaml  # On main server
sudo paqet run -c config_client.yaml  # On client server

# Test
curl -x socks5://127.0.0.1:1080 http://httpbin.org/ip
```

---

## Paqet Commands

`paqet` is a multi-command application. The main command is `run` which starts the proxy:

| Command   | Description                                                                      |
| :-------- | :------------------------------------------------------------------------------- |
| `run`     | Starts the `paqet` client or server proxy |
| `secret`  | Generates a new, cryptographically secure secret key |
| `ping`    | Sends a single test packet to the server to verify connectivity |
| `dump`    | A diagnostic tool similar to `tcpdump` |
| `version` | Prints the application's version information |

---

## Security Warning

This project is an exploration of low-level networking and carries significant security responsibilities. The KCP transport protocol provides encryption, authentication, and integrity using symmetric encryption with a shared secret key.

Security depends entirely on proper key management. Use the `secret` command to generate a strong key that must remain identical on both client and server.

---

## Files in This Repository

- `config_client.yaml` - Ready-made config for client
- `config_server.yaml` - Ready-made config for server
- `iptables_rules.sh` - Script to apply iptables rules
- `setup.sh` - Interactive setup script
- `QUICK_START.md` - Quick start guide

</details>

---

خب، دیگه همه چیز آماده! اگه مشکلی پیش اومد، لاگ‌ها رو چک کن یا بهم بگو تا کمک کنم. موفق باشی! 🚀
