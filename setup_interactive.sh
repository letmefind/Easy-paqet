#!/bin/bash

# Paqet Interactive Setup Script - دو زبانه (Bilingual)
# This script guides you step by step and does everything automatically
# 
# NOTE: This script is deprecated. Please use setup.sh instead!
# This script is kept for backward compatibility.

# تنظیم locale
export LC_ALL=C.UTF-8 2>/dev/null || export LANG=C.UTF-8 2>/dev/null

# انتخاب زبان / Language Selection
clear
echo "╔════════════════════════════════════════════════════════╗"
echo "║     Paqet - Interactive Setup / راه‌اندازی تعاملی   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  NOTE: This script is deprecated. Use './setup.sh' instead!"
echo "⚠️  توجه: این اسکریپت قدیمی است. از './setup.sh' استفاده کن!"
echo ""
echo "Select Language / انتخاب زبان:"
echo "  1) فارسی (Persian)"
echo "  2) English"
read -p "Choose [1/2]: " lang_choice

if [[ "$lang_choice" == "1" ]]; then
    LANG="fa"
else
    LANG="en"
fi

# توابع نمایش پیام / Message display functions
# آرگومان اول: فارسی، آرگومان دوم: انگلیسی
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
    # آرگومان اول: فارسی، آرگومان دوم: انگلیسی
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
SERVER_TYPE=$(msg_prompt "🔹 این سرور کلاینت است (A) یا سرور (B)? [A/B]" "🔹 Is this server Client (A) or Server (B)? [A/B]")

if [[ "$SERVER_TYPE" == "A" || "$SERVER_TYPE" == "a" ]]; then
    ROLE="client"
    CONFIG_FILE="config_client.yaml"
    SERVER_NAME=$(msg "کلاینت" "Client")
    msg "✓ حالت کلاینت انتخاب شد" "✓ Client mode selected"
elif [[ "$SERVER_TYPE" == "B" || "$SERVER_TYPE" == "b" ]]; then
    ROLE="server"
    CONFIG_FILE="config_server.yaml"
    SERVER_NAME=$(msg "سرور" "Server")
    msg "✓ حالت سرور انتخاب شد" "✓ Server mode selected"
else
    msg "❌ انتخاب نامعتبر!" "❌ Invalid selection!"
    exit 1
fi

msg_title "📋 Network Information Collection" "📋 جمع‌آوری اطلاعات شبکه"

# پیدا کردن اینترفیس‌های شبکه / Finding network interfaces
msg "🔹 اینترفیس‌های شبکه موجود:" "🔹 Available network interfaces:"
echo ""

# ساخت آرایه از اینترفیس‌ها
INTERFACES=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))
INTERFACE_COUNT=${#INTERFACES[@]}

# نمایش لیست اینترفیس‌ها با شماره
if [ "$LANG" == "fa" ]; then
    echo "لیست اینترفیس‌های موجود:"
else
    echo "Available interfaces list:"
fi

for i in "${!INTERFACES[@]}"; do
    echo "  $((i+1))) ${INTERFACES[$i]}"
done
echo ""

# انتخاب اینترفیس
if [ "$LANG" == "fa" ]; then
    read -p "کدوم اینترفیس رو می‌خوای؟ (شماره یا نام) [1-$INTERFACE_COUNT]: " interface_choice
else
    read -p "Which interface do you want? (number or name) [1-$INTERFACE_COUNT]: " interface_choice
fi

# چک کردن که آیا عدد وارد شده یا نام
if [[ "$interface_choice" =~ ^[0-9]+$ ]]; then
    # اگر عدد بود
    if [ "$interface_choice" -ge 1 ] && [ "$interface_choice" -le "$INTERFACE_COUNT" ]; then
        INTERFACE="${INTERFACES[$((interface_choice-1))]}"
        if [ "$LANG" == "fa" ]; then
            echo "✓ اینترفیس انتخاب شد: $INTERFACE"
        else
            echo "✓ Selected interface: $INTERFACE"
        fi
    else
        if [ "$LANG" == "fa" ]; then
            echo "❌ شماره نامعتبر! از لیست بالا انتخاب کن."
        else
            echo "❌ Invalid number! Please select from the list above."
        fi
        exit 1
    fi
else
    # اگر نام وارد شده بود، چک کن که در لیست باشه
    if [[ " ${INTERFACES[@]} " =~ " ${interface_choice} " ]]; then
        INTERFACE="$interface_choice"
        if [ "$LANG" == "fa" ]; then
            echo "✓ اینترفیس انتخاب شد: $INTERFACE"
        else
            echo "✓ Selected interface: $INTERFACE"
        fi
    else
        if [ "$LANG" == "fa" ]; then
            echo "❌ اینترفیس پیدا نشد! از لیست بالا انتخاب کن."
        else
            echo "❌ Interface not found! Please select from the list above."
        fi
        exit 1
    fi
fi
echo ""

# پیدا کردن آی‌پی محلی / Finding local IP
LOCAL_IP=$(ip -4 addr show $INTERFACE 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(msg_prompt "آی‌پی محلی این سرور را وارد کن" "Enter local IP address of this server")
else
    msg "🔹 آی‌پی محلی پیدا شد: $LOCAL_IP" "🔹 Found local IP: $LOCAL_IP"
    CONFIRM=$(msg_prompt "آیا این آی‌پی درست است؟ [Y/n]" "Is this IP correct? [Y/n]")
    if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
        LOCAL_IP=$(msg_prompt "آی‌پی محلی را وارد کن" "Enter local IP address")
    fi
fi

# پیدا کردن MAC روتر / Finding router MAC
GATEWAY_IP=$(ip route | grep default | awk '{print $3}' | head -1)
if [ -n "$GATEWAY_IP" ]; then
    msg "🔹 Gateway IP پیدا شد: $GATEWAY_IP" "🔹 Found Gateway IP: $GATEWAY_IP"
    ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
    if [ -n "$ROUTER_MAC" ]; then
        msg "🔹 MAC آدرس روتر پیدا شد: $ROUTER_MAC" "🔹 Found router MAC address: $ROUTER_MAC"
        CONFIRM=$(msg_prompt "آیا این MAC آدرس درست است؟ [Y/n]" "Is this MAC address correct? [Y/n]")
        if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
            ROUTER_MAC=$(msg_prompt "MAC آدرس روتر را وارد کن (مثلا aa:bb:cc:dd:ee:ff)" "Enter router MAC address (e.g., aa:bb:cc:dd:ee:ff)")
        fi
    else
        ROUTER_MAC=$(msg_prompt "MAC آدرس روتر را وارد کن (مثلا aa:bb:cc:dd:ee:ff)" "Enter router MAC address (e.g., aa:bb:cc:dd:ee:ff)")
    fi
else
    ROUTER_MAC=$(msg_prompt "Enter router MAC address (e.g., aa:bb:cc:dd:ee:ff)" "MAC آدرس روتر را وارد کن (مثلا aa:bb:cc:dd:ee:ff)")
fi

msg_title "🔐 Connection and Encryption Settings" "🔐 تنظیمات اتصال و رمزنگاری"

if [ "$ROLE" == "client" ]; then
    SERVER_IP=$(msg_prompt "آی‌پی سرور B را وارد کن" "Enter Server B IP address")
    SERVER_PORT=$(msg_prompt "پورت اتصال به سرور B (پیش‌فرض: 9999)" "Connection port to Server B (default: 9999)")
    SERVER_PORT=${SERVER_PORT:-9999}
    SERVER_ADDR="$SERVER_IP:$SERVER_PORT"
    LOCAL_PORT=0
else
    LISTEN_PORT=$(msg_prompt "پورت گوش دادن سرور (پیش‌فرض: 9999)" "Server listen port (default: 9999)")
    LISTEN_PORT=${LISTEN_PORT:-9999}
    LOCAL_PORT=$LISTEN_PORT
fi

# تولید یا استفاده از کلید موجود / Generate or use existing key
echo ""
msg "🔹 برای کلید رمزنگاری:" "🔹 For encryption key:"
if [ "$LANG" == "fa" ]; then
    echo "   1) تولید کلید جدید (توصیه می‌شه)"
    echo "   2) استفاده از کلید موجود"
else
    echo "   1) Generate new key (recommended)"
    echo "   2) Use existing key"
fi
KEY_CHOICE=$(msg_prompt "   انتخاب کن [1/2]" "   Select [1/2]")

if [ "$KEY_CHOICE" == "1" ]; then
    if command -v openssl &> /dev/null; then
        SECRET_KEY=$(openssl rand -base64 32)
        msg "✓ کلید جدید تولید شد" "✓ New key generated"
    else
        msg "⚠️  openssl پیدا نشد، از کلید پیش‌فرض استفاده می‌شه" "⚠️  openssl not found, using default key"
        SECRET_KEY="AY9Frl1VHWJB01lmKqLgE6dJllLhF3Sn4Lw/6BrcyYY="
    fi
else
    SECRET_KEY=$(msg_prompt "کلید رمزنگاری را وارد کن" "Enter encryption key")
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

CONFIRM=$(msg_prompt "آیا این اطلاعات درست هستند؟ [Y/n]" "Are these settings correct? [Y/n]")

if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
    msg "❌ راه‌اندازی لغو شد" "❌ Setup cancelled"
    exit 1
fi

msg_title "⚙️  Creating Configuration File" "⚙️  ساخت فایل کانفیگ"

# ساخت فایل کانفیگ کلاینت / Creating client config
if [ "$ROLE" == "client" ]; then
    CONFIG_COMMENT=$(msg "# کانفیگ کلاینت (سرور A)" "# Client config (Server A)")
    CONFIG_MADE_BY=$(msg "# ساخته شده توسط اسکریپت راه‌اندازی تعاملی" "# Created by interactive setup script")
    
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
    CONFIG_COMMENT=$(msg "# کانفیگ سرور (سرور B)" "# Server config (Server B)")
    CONFIG_MADE_BY=$(msg "# ساخته شده توسط اسکریپت راه‌اندازی تعاملی" "# Created by interactive setup script")
    
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

msg "✓ فایل کانفیگ $CONFIG_FILE ساخته شد" "✓ Configuration file $CONFIG_FILE created"

# اگر سرور است، اعمال iptables / Apply iptables if server
if [ "$ROLE" == "server" ]; then
    msg_title "🔥 Applying iptables Rules" "🔥 اعمال قوانین iptables"
    
    APPLY=$(msg_prompt "آیا می‌خوای قوانین iptables اعمال بشن؟ [Y/n]" "Do you want to apply iptables rules? [Y/n]")
    
    if [[ "$APPLY" != "n" && "$APPLY" != "N" ]]; then
        msg "در حال اعمال قوانین iptables..." "Applying iptables rules..."
        
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
        
        msg "✓ قوانین iptables اعمال شدند" "✓ iptables rules applied"
    fi
fi

# چک کردن نصب paqet / Check paqet installation
msg_title "📥 Checking Paqet Installation" "📥 بررسی نصب Paqet"

if command -v paqet &> /dev/null; then
    msg "✓ Paqet پیدا شد" "✓ Paqet found"
    PAQET_CMD="paqet"
else
    if [ -f "./paqet" ]; then
        msg "✓ فایل paqet در مسیر فعلی پیدا شد" "✓ Paqet file found in current directory"
        PAQET_CMD="./paqet"
    else
        msg "⚠️  Paqet پیدا نشد" "⚠️  Paqet not found"
        DOWNLOAD=$(msg_prompt "آیا می‌خوای الان دانلود کنی؟ [Y/n]" "Do you want to download it now? [Y/n]")
        
        if [[ "$DOWNLOAD" != "n" && "$DOWNLOAD" != "N" ]]; then
            msg "در حال دانلود paqet..." "Downloading paqet..."
            
            # تشخیص سیستم عامل و معماری
            OS=""
            ARCH=""
            
            # تشخیص سیستم عامل
            case "$(uname -s)" in
                Linux*)     OS="linux" ;;
                Darwin*)    OS="darwin" ;;
                CYGWIN*)    OS="windows" ;;
                MINGW*)     OS="windows" ;;
                MSYS*)      OS="windows" ;;
                *)          OS="linux" ;;  # پیش‌فرض
            esac
            
            # تشخیص معماری
            case "$(uname -m)" in
                x86_64|amd64)   ARCH="amd64" ;;
                aarch64|arm64)  ARCH="arm64" ;;
                armv7l|armv6l)  ARCH="arm" ;;
                *)              ARCH="amd64" ;;  # پیش‌فرض
            esac
            
            msg "   سیستم عامل: $OS" "   Operating System: $OS"
            msg "   معماری: $ARCH" "   Architecture: $ARCH"
            
            # استفاده از GitHub API برای پیدا کردن آخرین release و فایل‌های موجود
            if command -v curl &> /dev/null; then
                msg "   در حال بررسی آخرین release..." "   Checking latest release..."
                RELEASE_INFO=$(curl -s https://api.github.com/repos/hanselime/paqet/releases/latest)
                LATEST_RELEASE=$(echo "$RELEASE_INFO" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
                
                if [ -n "$LATEST_RELEASE" ]; then
                    msg "   آخرین نسخه پیدا شد: $LATEST_RELEASE" "   Latest version found: $LATEST_RELEASE"
                    
                    # تعیین فرمت فایل بر اساس سیستم عامل
                    if [ "$OS" == "windows" ]; then
                        FILE_EXT=".zip"
                    else
                        FILE_EXT=".tar.gz"
                    fi
                    
                    # ساخت نام فایل صحیح: paqet-OS-ARCH-VERSION.EXT
                    CORRECT_FILENAME="paqet-${OS}-${ARCH}-${LATEST_RELEASE}${FILE_EXT}"
                    DOWNLOAD_URL="https://github.com/hanselime/paqet/releases/download/${LATEST_RELEASE}/${CORRECT_FILENAME}"
                    msg "   امتحان فرمت صحیح: $CORRECT_FILENAME..." "   Trying correct format: $CORRECT_FILENAME..."
                    
                    DOWNLOAD_SUCCESS=false
                    if wget -q --spider "$DOWNLOAD_URL" 2>/dev/null; then
                        TEMP_FILE=$(mktemp)
                        wget "$DOWNLOAD_URL" -O "$TEMP_FILE" 2>/dev/null
                        
                        if [ $? -eq 0 ] && [ -f "$TEMP_FILE" ]; then
                            msg "   در حال استخراج از tar.gz..." "   Extracting from tar.gz..."
                            tar -xzf "$TEMP_FILE" -C . 2>/dev/null
                            rm "$TEMP_FILE"
                            # پیدا کردن فایل paqet استخراج شده (ممکنه در یک پوشه باشه)
                            if [ -f "./paqet" ]; then
                                chmod +x paqet
                                PAQET_CMD="./paqet"
                                msg "✓ Paqet دانلود و استخراج شد ($CORRECT_FILENAME)" "✓ Paqet downloaded and extracted ($CORRECT_FILENAME)"
                                DOWNLOAD_SUCCESS=true
                            else
                                # جستجو برای paqet در پوشه‌های زیر
                                PAQET_FILE=$(find . -name "paqet" -type f 2>/dev/null | head -1)
                                if [ -n "$PAQET_FILE" ]; then
                                    mv "$PAQET_FILE" ./paqet
                                    chmod +x paqet
                                    PAQET_CMD="./paqet"
                                    msg "✓ Paqet دانلود و استخراج شد ($CORRECT_FILENAME)" "✓ Paqet downloaded and extracted ($CORRECT_FILENAME)"
                                    DOWNLOAD_SUCCESS=true
                                fi
                            fi
                        fi
                    fi
                    
                    # اگر پیدا نشد، فایل‌های واقعی موجود در release رو امتحان کن
                    if [ "$DOWNLOAD_SUCCESS" == false ]; then
                        # استخراج نام فایل‌های موجود از API که با OS و ARCH مطابقت دارن
                        ASSET_NAMES=$(echo "$RELEASE_INFO" | python3 -c "import sys, json; data=json.load(sys.stdin); print('\n'.join([a['name'] for a in data.get('assets', []) if '$OS' in a['name'].lower() and '$ARCH' in a['name'].lower()]))" 2>/dev/null || echo "$RELEASE_INFO" | grep '"name":' | grep -i "$OS.*$ARCH\|$ARCH.*$OS" | sed -E 's/.*"name":\s*"([^"]+)".*/\1/')
                        
                        if [ -n "$ASSET_NAMES" ]; then
                            for ASSET_NAME in $ASSET_NAMES; do
                                DOWNLOAD_URL="https://github.com/hanselime/paqet/releases/download/${LATEST_RELEASE}/${ASSET_NAME}"
                                msg "   امتحان فایل واقعی: $ASSET_NAME..." "   Trying actual file: $ASSET_NAME..."
                                
                                if wget -q --spider "$DOWNLOAD_URL" 2>/dev/null; then
                                    TEMP_FILE=$(mktemp)
                                    wget "$DOWNLOAD_URL" -O "$TEMP_FILE" 2>/dev/null
                                    
                                    if [ $? -eq 0 ] && [ -f "$TEMP_FILE" ]; then
                                        if [[ "$ASSET_NAME" == *.tar.gz ]] || [[ "$ASSET_NAME" == *.tgz ]]; then
                                            msg "   در حال استخراج از tar.gz..." "   Extracting from tar.gz..."
                                            tar -xzf "$TEMP_FILE" -C . 2>/dev/null
                                            rm "$TEMP_FILE"
                                            if [ -f "./paqet" ]; then
                                                chmod +x paqet
                                                PAQET_CMD="./paqet"
                                                msg "✓ Paqet دانلود و استخراج شد ($ASSET_NAME)" "✓ Paqet downloaded and extracted ($ASSET_NAME)"
                                                DOWNLOAD_SUCCESS=true
                                                break
                                            else
                                                # جستجو برای paqet در پوشه‌های زیر
                                                PAQET_FILE=$(find . -name "paqet" -type f 2>/dev/null | head -1)
                                                if [ -n "$PAQET_FILE" ]; then
                                                    mv "$PAQET_FILE" ./paqet
                                                    chmod +x paqet
                                                    PAQET_CMD="./paqet"
                                                    msg "✓ Paqet دانلود و استخراج شد ($ASSET_NAME)" "✓ Paqet downloaded and extracted ($ASSET_NAME)"
                                                    DOWNLOAD_SUCCESS=true
                                                    break
                                                fi
                                            fi
                                        elif [[ "$ASSET_NAME" == *.zip ]]; then
                                            msg "   در حال استخراج از zip..." "   Extracting from zip..."
                                            unzip -q "$TEMP_FILE" -d . 2>/dev/null
                                            rm "$TEMP_FILE"
                                            if [ -f "./paqet" ]; then
                                                chmod +x paqet
                                                PAQET_CMD="./paqet"
                                                msg "✓ Paqet دانلود و استخراج شد ($ASSET_NAME)" "✓ Paqet downloaded and extracted ($ASSET_NAME)"
                                                DOWNLOAD_SUCCESS=true
                                                break
                                            else
                                                # جستجو برای paqet در پوشه‌های زیر
                                                PAQET_FILE=$(find . -name "paqet" -type f 2>/dev/null | head -1)
                                                if [ -n "$PAQET_FILE" ]; then
                                                    mv "$PAQET_FILE" ./paqet
                                                    chmod +x paqet
                                                    PAQET_CMD="./paqet"
                                                    msg "✓ Paqet دانلود و استخراج شد ($ASSET_NAME)" "✓ Paqet downloaded and extracted ($ASSET_NAME)"
                                                    DOWNLOAD_SUCCESS=true
                                                    break
                                                fi
                                            fi
                                        else
                                            mv "$TEMP_FILE" paqet
                                            chmod +x paqet
                                            PAQET_CMD="./paqet"
                                            msg "✓ Paqet دانلود شد ($ASSET_NAME)" "✓ Paqet downloaded ($ASSET_NAME)"
                                            DOWNLOAD_SUCCESS=true
                                            break
                                        fi
                                    fi
                                fi
                            done
                        fi
                    fi
                    
                    if [ "$DOWNLOAD_SUCCESS" == false ]; then
                        echo ""
                        msg "⚠️  دانلود خودکار موفق نشد!" "⚠️  Automatic download failed!"
                        echo ""
                        msg "لطفاً دستی از لینک زیر دانلود کن:" "Please download manually from:"
                        echo "   https://github.com/hanselime/paqet/releases/tag/${LATEST_RELEASE}"
                        echo ""
                        msg "یا از دستور زیر استفاده کن (نام فایل رو از صفحه release پیدا کن):" "Or use this command (find the filename on the release page):"
                        echo "   wget https://github.com/hanselime/paqet/releases/download/${LATEST_RELEASE}/[نام-فایل] -O paqet"
                        echo ""
                        MANUAL_DOWNLOAD=$(msg_prompt "آیا فایل رو دستی دانلود کردی و در همین مسیر هست؟ [Y/n]" "Did you download the file manually and is it in this directory? [Y/n]")
                        if [[ "$MANUAL_DOWNLOAD" != "n" && "$MANUAL_DOWNLOAD" != "N" ]]; then
                            if [ -f "./paqet" ]; then
                                chmod +x paqet
                                PAQET_CMD="./paqet"
                                msg "✓ فایل paqet پیدا شد" "✓ Paqet file found"
                            else
                                PAQET_CMD="paqet"
                            fi
                        else
                            PAQET_CMD="paqet"
                        fi
                    fi
                else
                    msg "⚠️  نتوانست آخرین release رو پیدا کنه" "⚠️  Could not find latest release"
                    msg "لطفاً دستی دانلود کن: https://github.com/hanselime/paqet/releases" "Please download manually: https://github.com/hanselime/paqet/releases"
                    PAQET_CMD="paqet"
                fi
            else
                # اگر curl موجود نبود، از روش ساده استفاده کن
                msg "⚠️  curl پیدا نشد، استفاده از روش ساده..." "⚠️  curl not found, using simple method..."
                wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet 2>&1
                if [ $? -eq 0 ] && [ -f "./paqet" ]; then
                    chmod +x paqet
                    PAQET_CMD="./paqet"
                    msg "✓ Paqet دانلود شد" "✓ Paqet downloaded"
                else
                    echo ""
                    msg "❌ دانلود موفق نشد!" "❌ Download failed!"
                    msg "لطفاً دستی از لینک زیر دانلود کن:" "Please download manually from:"
                    echo "   https://github.com/hanselime/paqet/releases/latest"
                    PAQET_CMD="paqet"
                fi
            fi
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
msg "💾 کلید رمزنگاری در فایل .paqet_secret_key.txt ذخیره شد" "💾 Encryption key saved to .paqet_secret_key.txt"
msg "   ⚠️  این فایل رو با سرور دیگه به اشتراک بذار!" "   ⚠️  Share this file with the other server!"
