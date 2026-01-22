#!/bin/bash

# Paqet Interactive Setup Script - دو زبانه (Bilingual)
# This script guides you step by step and does everything automatically

# تنظیم locale
export LC_ALL=C.UTF-8 2>/dev/null || export LANG=C.UTF-8 2>/dev/null

# انتخاب زبان / Language Selection
clear
echo "╔════════════════════════════════════════════════════════╗"
echo "║     Paqet - Interactive Setup / راه‌اندازی تعاملی   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Select Language / انتخاب زبان:"
echo "  1) English"
echo "  2) فارسی (Persian)"
read -p "Choose [1/2]: " lang_choice

if [[ "$lang_choice" == "1" ]]; then
    LANG="fa"
else
    LANG="en"
fi

# توابع نمایش پیام / Message display functions
msg() {
    if [ "$LANG" == "fa" ]; then
        echo "$1"
    else
        echo "$2"
    fi
}

msg_title() {
    if [ "$LANG" == "fa" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "$1"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "$2"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
    echo ""
}

msg_prompt() {
    if [ "$LANG" == "fa" ]; then
        read -p "$1: " answer
    else
        read -p "$2: " answer
    fi
    echo "$answer"
}

clear
msg_title "📋 Paqet Interactive Setup" "📋 راه‌اندازی تعاملی Paqet"

# تشخیص نوع سرور / Server type detection
SERVER_TYPE=$(msg_prompt "🔹 Is this server Client (A) or Server (B)? [A/B]" "🔹 این سرور کلاینت است (A) یا سرور (B)? [A/B]")

if [[ "$SERVER_TYPE" == "A" || "$SERVER_TYPE" == "a" ]]; then
    ROLE="client"
    CONFIG_FILE="config_client.yaml"
    SERVER_NAME=$(msg "کلاینت" "Client")
    msg "✓ Client mode selected" "✓ حالت کلاینت انتخاب شد"
elif [[ "$SERVER_TYPE" == "B" || "$SERVER_TYPE" == "b" ]]; then
    ROLE="server"
    CONFIG_FILE="config_server.yaml"
    SERVER_NAME=$(msg "سرور" "Server")
    msg "✓ Server mode selected" "✓ حالت سرور انتخاب شد"
else
    msg "❌ Invalid selection!" "❌ انتخاب نامعتبر!"
    exit 1
fi

msg_title "📋 Network Information Collection" "📋 جمع‌آوری اطلاعات شبکه"

# پیدا کردن اینترفیس‌های شبکه / Finding network interfaces
msg "🔹 Available network interfaces:" "🔹 اینترفیس‌های شبکه موجود:"
ip -o link show | awk -F': ' '{print "   - " $2}' | grep -v lo
echo ""

INTERFACE=$(msg_prompt "Enter network interface name (e.g., eth0, ens3)" "نام اینترفیس شبکه را وارد کن (مثلا eth0, ens3)")

# پیدا کردن آی‌پی محلی / Finding local IP
LOCAL_IP=$(ip -4 addr show $INTERFACE 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(msg_prompt "Enter local IP address of this server" "آی‌پی محلی این سرور را وارد کن")
else
    msg "🔹 Found local IP: $LOCAL_IP" "🔹 آی‌پی محلی پیدا شد: $LOCAL_IP"
    CONFIRM=$(msg_prompt "Is this IP correct? [Y/n]" "آیا این آی‌پی درست است؟ [Y/n]")
    if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
        LOCAL_IP=$(msg_prompt "Enter local IP address" "آی‌پی محلی را وارد کن")
    fi
fi

# پیدا کردن MAC روتر / Finding router MAC
GATEWAY_IP=$(ip route | grep default | awk '{print $3}' | head -1)
if [ -n "$GATEWAY_IP" ]; then
    msg "🔹 Found Gateway IP: $GATEWAY_IP" "🔹 Gateway IP پیدا شد: $GATEWAY_IP"
    ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
    if [ -n "$ROUTER_MAC" ]; then
        msg "🔹 Found router MAC address: $ROUTER_MAC" "🔹 MAC آدرس روتر پیدا شد: $ROUTER_MAC"
        CONFIRM=$(msg_prompt "Is this MAC address correct? [Y/n]" "آیا این MAC آدرس درست است؟ [Y/n]")
        if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
            ROUTER_MAC=$(msg_prompt "Enter router MAC address (e.g., aa:bb:cc:dd:ee:ff)" "MAC آدرس روتر را وارد کن (مثلا aa:bb:cc:dd:ee:ff)")
        fi
    else
        ROUTER_MAC=$(msg_prompt "Enter router MAC address (e.g., aa:bb:cc:dd:ee:ff)" "MAC آدرس روتر را وارد کن (مثلا aa:bb:cc:dd:ee:ff)")
    fi
else
    ROUTER_MAC=$(msg_prompt "Enter router MAC address (e.g., aa:bb:cc:dd:ee:ff)" "MAC آدرس روتر را وارد کن (مثلا aa:bb:cc:dd:ee:ff)")
fi

msg_title "🔐 Connection and Encryption Settings" "🔐 تنظیمات اتصال و رمزنگاری"

if [ "$ROLE" == "client" ]; then
    SERVER_IP=$(msg_prompt "Enter Server B IP address" "آی‌پی سرور B را وارد کن")
    SERVER_PORT=$(msg_prompt "Connection port to Server B (default: 9999)" "پورت اتصال به سرور B (پیش‌فرض: 9999)")
    SERVER_PORT=${SERVER_PORT:-9999}
    SERVER_ADDR="$SERVER_IP:$SERVER_PORT"
    LOCAL_PORT=0
else
    LISTEN_PORT=$(msg_prompt "Server listen port (default: 9999)" "پورت گوش دادن سرور (پیش‌فرض: 9999)")
    LISTEN_PORT=${LISTEN_PORT:-9999}
    LOCAL_PORT=$LISTEN_PORT
fi

# تولید یا استفاده از کلید موجود / Generate or use existing key
echo ""
msg "🔹 For encryption key:" "🔹 برای کلید رمزنگاری:"
if [ "$LANG" == "fa" ]; then
    echo "   1) تولید کلید جدید (توصیه می‌شه)"
    echo "   2) استفاده از کلید موجود"
else
    echo "   1) Generate new key (recommended)"
    echo "   2) Use existing key"
fi
KEY_CHOICE=$(msg_prompt "   Select [1/2]" "   انتخاب کن [1/2]")

if [ "$KEY_CHOICE" == "1" ]; then
    if command -v openssl &> /dev/null; then
        SECRET_KEY=$(openssl rand -base64 32)
        msg "✓ New key generated" "✓ کلید جدید تولید شد"
    else
        msg "⚠️  openssl not found, using default key" "⚠️  openssl پیدا نشد، از کلید پیش‌فرض استفاده می‌شه"
        SECRET_KEY="AY9Frl1VHWJB01lmKqLgE6dJllLhF3Sn4Lw/6BrcyYY="
    fi
else
    SECRET_KEY=$(msg_prompt "Enter encryption key" "کلید رمزنگاری را وارد کن")
fi

msg_title "📝 Configuration Summary" "📝 خلاصه تنظیمات"

if [ "$LANG" == "fa" ]; then
    echo "نوع سرور: $SERVER_NAME"
    echo "اینترفیس: $INTERFACE"
    echo "آی‌پی محلی: $LOCAL_IP"
    echo "MAC روتر: $ROUTER_MAC"
    if [ "$ROLE" == "client" ]; then
        echo "آدرس سرور: $SERVER_ADDR"
    else
        echo "پورت گوش دادن: $LISTEN_PORT"
    fi
    echo "کلید رمزنگاری: ${SECRET_KEY:0:20}..."
else
    echo "Server Type: $SERVER_NAME"
    echo "Interface: $INTERFACE"
    echo "Local IP: $LOCAL_IP"
    echo "Router MAC: $ROUTER_MAC"
    if [ "$ROLE" == "client" ]; then
        echo "Server Address: $SERVER_ADDR"
    else
        echo "Listen Port: $LISTEN_PORT"
    fi
    echo "Encryption Key: ${SECRET_KEY:0:20}..."
fi
echo ""

CONFIRM=$(msg_prompt "Are these settings correct? [Y/n]" "آیا این اطلاعات درست هستند؟ [Y/n]")

if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
    msg "❌ Setup cancelled" "❌ راه‌اندازی لغو شد"
    exit 1
fi

msg_title "⚙️  Creating Configuration File" "⚙️  ساخت فایل کانفیگ"

# ساخت فایل کانفیگ کلاینت / Creating client config
if [ "$ROLE" == "client" ]; then
    CONFIG_COMMENT=$(msg "# Client config (Server A)" "# کانفیگ کلاینت (سرور A)")
    CONFIG_MADE_BY=$(msg "# Created by interactive setup script" "# ساخته شده توسط اسکریپت راه‌اندازی تعاملی")
    
    cat > $CONFIG_FILE <<EOF
$CONFIG_COMMENT
$CONFIG_MADE_BY

role: "client"

log:
  level: "info"

socks5:
  - listen: "127.0.0.1:1080"
    username: ""
    password: ""

network:
  interface: "$INTERFACE"
  local_addr: "$LOCAL_IP:$LOCAL_PORT"
  router_mac: "$ROUTER_MAC"
  
  pcap:
    sockbuf: 4194304
  
  tcp:
    local_flag: ["PA"]
    remote_flag: ["PA"]

server:
  addr: "$SERVER_ADDR"

transport:
  protocol: "kcp"
  conn: 1
  
  kcp:
    mode: "fast3"
    mtu: 1350
    rcvwnd: 512
    sndwnd: 512
    
    block: "aes"
    key: "$SECRET_KEY"
    
    smuxbuf: 4194304
    streambuf: 2097152
EOF
else
    # ساخت فایل کانفیگ سرور / Creating server config
    CONFIG_COMMENT=$(msg "# Server config (Server B)" "# کانفیگ سرور (سرور B)")
    CONFIG_MADE_BY=$(msg "# Created by interactive setup script" "# ساخته شده توسط اسکریپت راه‌اندازی تعاملی")
    
    cat > $CONFIG_FILE <<EOF
$CONFIG_COMMENT
$CONFIG_MADE_BY

role: "server"

log:
  level: "info"

listen:
  addr: ":$LISTEN_PORT"

network:
  interface: "$INTERFACE"
  local_addr: "$LOCAL_IP:$LOCAL_PORT"
  router_mac: "$ROUTER_MAC"
  
  pcap:
    sockbuf: 8388608
  
  tcp:
    local_flag: ["PA"]

transport:
  protocol: "kcp"
  conn: 1
  
  kcp:
    mode: "fast3"
    mtu: 1350
    rcvwnd: 1024
    sndwnd: 1024
    
    block: "aes"
    key: "$SECRET_KEY"
    
    smuxbuf: 4194304
    streambuf: 2097152
EOF
fi

msg "✓ Configuration file $CONFIG_FILE created" "✓ فایل کانفیگ $CONFIG_FILE ساخته شد"

# اگر سرور است، اعمال iptables / Apply iptables if server
if [ "$ROLE" == "server" ]; then
    msg_title "🔥 Applying iptables Rules" "🔥 اعمال قوانین iptables"
    
    APPLY=$(msg_prompt "Do you want to apply iptables rules? [Y/n]" "آیا می‌خوای قوانین iptables اعمال بشن؟ [Y/n]")
    
    if [[ "$APPLY" != "n" && "$APPLY" != "N" ]]; then
        msg "Applying iptables rules..." "در حال اعمال قوانین iptables..."
        
        PORT=$LISTEN_PORT
        
        # اعمال قوانین / Apply rules
        sudo iptables -t raw -A PREROUTING -p tcp --dport $PORT -j NOTRACK 2>/dev/null
        sudo iptables -t raw -A OUTPUT -p tcp --sport $PORT -j NOTRACK 2>/dev/null
        sudo iptables -t mangle -A OUTPUT -p tcp --sport $PORT --tcp-flags RST RST -j DROP 2>/dev/null
        sudo iptables -t filter -A INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null
        sudo iptables -t filter -A OUTPUT -p tcp --sport $PORT -j ACCEPT 2>/dev/null
        
        # ذخیره قوانین / Save rules
        if command -v iptables-save &> /dev/null; then
            sudo mkdir -p /etc/iptables
            sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
        fi
        
        if [ -f /etc/redhat-release ]; then
            sudo service iptables save 2>/dev/null || sudo iptables-save > /etc/sysconfig/iptables
        fi
        
        msg "✓ iptables rules applied" "✓ قوانین iptables اعمال شدند"
    fi
fi

# چک کردن نصب paqet / Check paqet installation
msg_title "📥 Checking Paqet Installation" "📥 بررسی نصب Paqet"

if command -v paqet &> /dev/null; then
    msg "✓ Paqet found" "✓ Paqet پیدا شد"
    PAQET_CMD="paqet"
else
    if [ -f "./paqet" ]; then
        msg "✓ Paqet file found in current directory" "✓ فایل paqet در مسیر فعلی پیدا شد"
        PAQET_CMD="./paqet"
    else
        msg "⚠️  Paqet not found" "⚠️  Paqet پیدا نشد"
        DOWNLOAD=$(msg_prompt "Do you want to download it now? [Y/n]" "آیا می‌خوای الان دانلود کنی؟ [Y/n]")
        
        if [[ "$DOWNLOAD" != "n" && "$DOWNLOAD" != "N" ]]; then
            msg "Downloading paqet..." "در حال دانلود paqet..."
            wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet
            chmod +x paqet
            PAQET_CMD="./paqet"
            msg "✓ Paqet downloaded" "✓ Paqet دانلود شد"
        else
            PAQET_CMD="paqet"
        fi
    fi
fi

msg_title "✅ Setup Complete!" "✅ راه‌اندازی کامل شد!"

if [ "$LANG" == "fa" ]; then
    echo "📄 فایل کانفیگ: $CONFIG_FILE"
    echo "🔑 کلید رمزنگاری: ${SECRET_KEY:0:30}..."
    echo ""
    echo "🚀 برای اجرا، دستور زیر رو استفاده کن:"
    echo ""
    echo "   sudo $PAQET_CMD run -c $CONFIG_FILE"
    echo ""
    if [ "$ROLE" == "client" ]; then
        echo "🧪 برای تست اتصال:"
        echo ""
        echo "   curl -x socks5://127.0.0.1:1080 http://httpbin.org/ip"
        echo ""
    fi
else
    echo "📄 Configuration file: $CONFIG_FILE"
    echo "🔑 Encryption key: ${SECRET_KEY:0:30}..."
    echo ""
    echo "🚀 To run, use the following command:"
    echo ""
    echo "   sudo $PAQET_CMD run -c $CONFIG_FILE"
    echo ""
    if [ "$ROLE" == "client" ]; then
        echo "🧪 To test the connection:"
        echo ""
        echo "   curl -x socks5://127.0.0.1:1080 http://httpbin.org/ip"
        echo ""
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ذخیره کلید در فایل جداگانه / Save key to separate file
echo "$SECRET_KEY" > .paqet_secret_key.txt
chmod 600 .paqet_secret_key.txt
msg "💾 Encryption key saved to .paqet_secret_key.txt" "💾 کلید رمزنگاری در فایل .paqet_secret_key.txt ذخیره شد"
msg "   ⚠️  Share this file with the other server!" "   ⚠️  این فایل رو با سرور دیگه به اشتراک بذار!"
