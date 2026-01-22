#!/bin/bash

# اسکریپت راه‌اندازی تعاملی Paqet - فارسی
# این اسکریپت مرحله به مرحله ازت سوال می‌پرسه و همه کارها رو انجام می‌ده

export LC_ALL=C.UTF-8 2>/dev/null || export LANG=C.UTF-8 2>/dev/null

clear
echo "╔════════════════════════════════════════════════════════╗"
echo "║          راه‌اندازی تعاملی Paqet                     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 راه‌اندازی تعاملی Paqet"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# تشخیص نوع سرور
read -p "🔹 این سرور کلاینت است (A) یا سرور (B)? [A/B]: " SERVER_TYPE

if [[ "$SERVER_TYPE" == "A" || "$SERVER_TYPE" == "a" ]]; then
    ROLE="client"
    CONFIG_FILE="config_client.yaml"
    SERVER_NAME="کلاینت"
    echo "✓ حالت کلاینت انتخاب شد"
elif [[ "$SERVER_TYPE" == "B" || "$SERVER_TYPE" == "b" ]]; then
    ROLE="server"
    CONFIG_FILE="config_server.yaml"
    SERVER_NAME="سرور"
    echo "✓ حالت سرور انتخاب شد"
else
    echo "❌ انتخاب نامعتبر!"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 جمع‌آوری اطلاعات شبکه"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# پیدا کردن اینترفیس‌های شبکه
echo "🔹 اینترفیس‌های شبکه موجود:"
echo ""

# ساخت آرایه از اینترفیس‌ها
INTERFACES=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))
INTERFACE_COUNT=${#INTERFACES[@]}

echo "لیست اینترفیس‌های موجود:"
for i in "${!INTERFACES[@]}"; do
    echo "  $((i+1))) ${INTERFACES[$i]}"
done
echo ""

read -p "کدوم اینترفیس رو می‌خوای؟ (شماره یا نام) [1-$INTERFACE_COUNT]: " interface_choice

# چک کردن که آیا عدد وارد شده یا نام
if [[ "$interface_choice" =~ ^[0-9]+$ ]]; then
    if [ "$interface_choice" -ge 1 ] && [ "$interface_choice" -le "$INTERFACE_COUNT" ]; then
        INTERFACE="${INTERFACES[$((interface_choice-1))]}"
        echo "✓ اینترفیس انتخاب شد: $INTERFACE"
    else
        echo "❌ شماره نامعتبر! از لیست بالا انتخاب کن."
        exit 1
    fi
else
    if [[ " ${INTERFACES[@]} " =~ " ${interface_choice} " ]]; then
        INTERFACE="$interface_choice"
        echo "✓ اینترفیس انتخاب شد: $INTERFACE"
    else
        echo "❌ اینترفیس پیدا نشد! از لیست بالا انتخاب کن."
        exit 1
    fi
fi
echo ""

# پیدا کردن آی‌پی محلی
LOCAL_IP=$(ip -4 addr show $INTERFACE 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
if [ -z "$LOCAL_IP" ]; then
    read -p "آی‌پی محلی این سرور را وارد کن: " LOCAL_IP
else
    echo "🔹 آی‌پی محلی پیدا شد: $LOCAL_IP"
    read -p "آیا این آی‌پی درست است؟ [Y/n]: " CONFIRM
    if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
        read -p "آی‌پی محلی را وارد کن: " LOCAL_IP
    fi
fi

# پیدا کردن MAC روتر
GATEWAY_IP=$(ip route | grep default | awk '{print $3}' | head -1)
if [ -n "$GATEWAY_IP" ]; then
    echo "🔹 Gateway IP از routing table: $GATEWAY_IP"
    
    # چک کردن که آیا Gateway IP یک IP خصوصی/داخلی هست
    if [[ "$GATEWAY_IP" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]+\.[0-9]+$ ]] || \
       [[ "$GATEWAY_IP" =~ ^10\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
       [[ "$GATEWAY_IP" =~ ^192\.168\.[0-9]+\.[0-9]+$ ]]; then
        echo "   ⚠️  این یک IP خصوصی/داخلی است (معمولاً در سرورهای cloud درسته)"
        echo "   این IP برای پیدا کردن MAC address استفاده می‌شه، نه برای routing"
    fi
    
    # پیدا کردن MAC address از ARP table
    ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
    
    # اگر MAC پیدا نشد، سعی کن با ping پیدا کنی
    if [ -z "$ROUTER_MAC" ]; then
        echo "   در حال ping کردن Gateway برای پیدا کردن MAC..."
        ping -c 1 -W 1 $GATEWAY_IP > /dev/null 2>&1
        sleep 1
        ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
    fi
    
    if [ -n "$ROUTER_MAC" ]; then
        echo "🔹 MAC آدرس روتر پیدا شد: $ROUTER_MAC"
        echo ""
        echo "   📝 نکته: این MAC address برای ارسال پکت‌ها استفاده می‌شه."
        echo "   در سرورهای cloud، Gateway IP ممکنه یک IP داخلی باشه که درست است."
        echo ""
        read -p "آیا این MAC آدرس درست است؟ [Y/n]: " CONFIRM
        if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
            read -p "MAC آدرس روتر را وارد کن (مثلا aa:bb:cc:dd:ee:ff): " ROUTER_MAC
        fi
    else
        echo "⚠️  MAC آدرس روتر پیدا نشد"
        echo ""
        echo "   برای پیدا کردن MAC address، می‌تونی از دستور زیر استفاده کنی:"
        echo "   arp -n $GATEWAY_IP"
        echo "   یا"
        echo "   ip neigh show $GATEWAY_IP"
        echo ""
        read -p "MAC آدرس روتر را وارد کن (مثلا aa:bb:cc:dd:ee:ff): " ROUTER_MAC
    fi
else
    echo "⚠️  Gateway IP پیدا نشد"
    echo ""
    echo "   برای پیدا کردن Gateway IP، می‌تونی از دستور زیر استفاده کنی:"
    echo "   ip route | grep default"
    echo ""
    read -p "Gateway IP را وارد کن (یا Enter برای رد کردن): " GATEWAY_IP
    if [ -n "$GATEWAY_IP" ]; then
        ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
        if [ -z "$ROUTER_MAC" ]; then
            ping -c 1 -W 1 $GATEWAY_IP > /dev/null 2>&1
            sleep 1
            ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
        fi
        if [ -n "$ROUTER_MAC" ]; then
            echo "✓ MAC آدرس پیدا شد: $ROUTER_MAC"
        else
            read -p "MAC آدرس روتر را وارد کن (مثلا aa:bb:cc:dd:ee:ff): " ROUTER_MAC
        fi
    else
        read -p "MAC آدرس روتر را مستقیماً وارد کن (مثلا aa:bb:cc:dd:ee:ff): " ROUTER_MAC
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 تنظیمات اتصال و رمزنگاری"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$ROLE" == "client" ]; then
    read -p "آی‌پی سرور B را وارد کن: " SERVER_IP
    read -p "پورت اتصال به سرور B (پیش‌فرض: 9999): " SERVER_PORT
    SERVER_PORT=${SERVER_PORT:-9999}
    SERVER_ADDR="$SERVER_IP:$SERVER_PORT"
    LOCAL_PORT=0
else
    read -p "پورت گوش دادن سرور (پیش‌فرض: 9999): " LISTEN_PORT
    LISTEN_PORT=${LISTEN_PORT:-9999}
    LOCAL_PORT=$LISTEN_PORT
fi

# تولید یا استفاده از کلید موجود
echo ""
echo "🔹 برای کلید رمزنگاری:"
echo "   1) تولید کلید جدید (توصیه می‌شه)"
echo "   2) استفاده از کلید موجود"
read -p "   انتخاب کن [1/2]: " KEY_CHOICE

if [ "$KEY_CHOICE" == "1" ]; then
    if command -v openssl &> /dev/null; then
        SECRET_KEY=$(openssl rand -base64 32)
        echo "✓ کلید جدید تولید شد"
    else
        echo "⚠️  openssl پیدا نشد، از کلید پیش‌فرض استفاده می‌شه"
        SECRET_KEY="AY9Frl1VHWJB01lmKqLgE6dJllLhF3Sn4Lw/6BrcyYY="
    fi
else
    read -p "کلید رمزنگاری را وارد کن: " SECRET_KEY
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 خلاصه تنظیمات"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
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
echo ""
read -p "آیا این اطلاعات درست هستند؟ [Y/n]: " CONFIRM

if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
    echo "❌ راه‌اندازی لغو شد"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  ساخت فایل کانفیگ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ساخت فایل کانفیگ کلاینت
if [ "$ROLE" == "client" ]; then
    cat > $CONFIG_FILE <<EOF
# کانفیگ کلاینت (سرور A)
# ساخته شده توسط اسکریپت راه‌اندازی تعاملی

role: "client"

log:
  level: "info"

socks5:
  - listen: "127.0.0.1:1080"
    username: ""
    password: ""

network:
  interface: "$INTERFACE"
  ipv4:
    addr: "$LOCAL_IP:$LOCAL_PORT"
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
    # ساخت فایل کانفیگ سرور
    cat > $CONFIG_FILE <<EOF
# کانفیگ سرور (سرور B)
# ساخته شده توسط اسکریپت راه‌اندازی تعاملی

role: "server"

log:
  level: "info"

listen:
  addr: ":$LISTEN_PORT"

network:
  interface: "$INTERFACE"
  ipv4:
    addr: "$LOCAL_IP:$LOCAL_PORT"
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

echo "✓ فایل کانفیگ $CONFIG_FILE ساخته شد"

# اگر سرور است، اعمال iptables
if [ "$ROLE" == "server" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔥 اعمال قوانین iptables"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    read -p "آیا می‌خوای قوانین iptables اعمال بشن؟ [Y/n]: " APPLY
    
    if [[ "$APPLY" != "n" && "$APPLY" != "N" ]]; then
        echo "در حال اعمال قوانین iptables..."
        
        PORT=$LISTEN_PORT
        
        sudo iptables -t raw -A PREROUTING -p tcp --dport $PORT -j NOTRACK 2>/dev/null
        sudo iptables -t raw -A OUTPUT -p tcp --sport $PORT -j NOTRACK 2>/dev/null
        sudo iptables -t mangle -A OUTPUT -p tcp --sport $PORT --tcp-flags RST RST -j DROP 2>/dev/null
        sudo iptables -t filter -A INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null
        sudo iptables -t filter -A OUTPUT -p tcp --sport $PORT -j ACCEPT 2>/dev/null
        
        if command -v iptables-save &> /dev/null; then
            sudo mkdir -p /etc/iptables
            sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
        fi
        
        if [ -f /etc/redhat-release ]; then
            sudo service iptables save 2>/dev/null || sudo iptables-save > /etc/sysconfig/iptables
        fi
        
        echo "✓ قوانین iptables اعمال شدند"
    fi
fi

# چک کردن نصب paqet
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📥 بررسی نصب Paqet"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v paqet &> /dev/null; then
    echo "✓ Paqet پیدا شد"
    PAQET_CMD="paqet"
else
    if [ -f "./paqet" ]; then
        echo "✓ فایل paqet در مسیر فعلی پیدا شد"
        PAQET_CMD="./paqet"
    else
        echo "⚠️  Paqet پیدا نشد"
        read -p "آیا می‌خوای الان دانلود کنی؟ [Y/n]: " DOWNLOAD
        
        if [[ "$DOWNLOAD" != "n" && "$DOWNLOAD" != "N" ]]; then
            echo "در حال دانلود paqet..."
            
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
            
            echo "   سیستم عامل: $OS"
            echo "   معماری: $ARCH"
            
            # استفاده از GitHub API برای پیدا کردن آخرین release و فایل‌های موجود
            if command -v curl &> /dev/null; then
                echo "   در حال بررسی آخرین release..."
                RELEASE_INFO=$(curl -s https://api.github.com/repos/hanselime/paqet/releases/latest)
                LATEST_RELEASE=$(echo "$RELEASE_INFO" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
                
                if [ -n "$LATEST_RELEASE" ]; then
                    echo "   آخرین نسخه پیدا شد: $LATEST_RELEASE"
                    
                    # تعیین فرمت فایل بر اساس سیستم عامل
                    if [ "$OS" == "windows" ]; then
                        FILE_EXT=".zip"
                    else
                        FILE_EXT=".tar.gz"
                    fi
                    
                    # ساخت نام فایل صحیح: paqet-OS-ARCH-VERSION.EXT
                    CORRECT_FILENAME="paqet-${OS}-${ARCH}-${LATEST_RELEASE}${FILE_EXT}"
                    DOWNLOAD_URL="https://github.com/hanselime/paqet/releases/download/${LATEST_RELEASE}/${CORRECT_FILENAME}"
                    echo "   امتحان فرمت صحیح: $CORRECT_FILENAME..."
                    
                    DOWNLOAD_SUCCESS=false
                    
                    if wget -q --spider "$DOWNLOAD_URL" 2>/dev/null; then
                        TEMP_FILE=$(mktemp)
                        wget "$DOWNLOAD_URL" -O "$TEMP_FILE" 2>/dev/null
                        
                        if [ $? -eq 0 ] && [ -f "$TEMP_FILE" ]; then
                            echo "   در حال استخراج از tar.gz..."
                            tar -xzf "$TEMP_FILE" -C . 2>/dev/null
                            rm "$TEMP_FILE"
                            # پیدا کردن فایل paqet استخراج شده (ممکنه در یک پوشه باشه یا اسم متفاوت داشته باشه)
                            if [ -f "./paqet" ]; then
                                chmod +x paqet
                                PAQET_CMD="./paqet"
                                echo "✓ Paqet دانلود و استخراج شد ($CORRECT_FILENAME)"
                                DOWNLOAD_SUCCESS=true
                            else
                                # جستجو برای فایل‌های paqet (paqet, paqet_linux_amd64 و غیره)
                                PAQET_FILE=$(find . -type f \( -name "paqet" -o -name "paqet_*" -o -name "paqet-*" \) ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.md" ! -name "*.yaml" ! -name "*.sh" 2>/dev/null | head -1)
                                if [ -n "$PAQET_FILE" ]; then
                                    mv "$PAQET_FILE" ./paqet
                                    chmod +x paqet
                                    PAQET_CMD="./paqet"
                                    echo "✓ Paqet دانلود و استخراج شد ($CORRECT_FILENAME)"
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
                                echo "   امتحان فایل واقعی: $ASSET_NAME..."
                            
                            # دانلود فایل
                            if wget -q --spider "$DOWNLOAD_URL" 2>/dev/null; then
                                TEMP_FILE=$(mktemp)
                                wget "$DOWNLOAD_URL" -O "$TEMP_FILE" 2>/dev/null
                                
                                if [ $? -eq 0 ] && [ -f "$TEMP_FILE" ]; then
                                    # اگر tar.gz یا tar بود، extract کن
                                    if [[ "$ASSET_NAME" == *.tar.gz ]] || [[ "$ASSET_NAME" == *.tgz ]]; then
                                        echo "   در حال استخراج از tar.gz..."
                                        tar -xzf "$TEMP_FILE" -C . 2>/dev/null
                                        rm "$TEMP_FILE"
                                        # پیدا کردن فایل paqet استخراج شده (ممکنه در یک پوشه باشه یا اسم متفاوت داشته باشه)
                                        if [ -f "./paqet" ]; then
                                            chmod +x paqet
                                            PAQET_CMD="./paqet"
                                            echo "✓ Paqet دانلود و استخراج شد ($ASSET_NAME)"
                                            DOWNLOAD_SUCCESS=true
                                            break
                                        else
                                            # جستجو برای فایل‌های paqet (paqet, paqet_linux_amd64 و غیره)
                                            PAQET_FILE=$(find . -type f \( -name "paqet" -o -name "paqet_*" -o -name "paqet-*" \) ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.md" ! -name "*.yaml" ! -name "*.sh" 2>/dev/null | head -1)
                                            if [ -n "$PAQET_FILE" ]; then
                                                mv "$PAQET_FILE" ./paqet
                                                chmod +x paqet
                                                PAQET_CMD="./paqet"
                                                echo "✓ Paqet دانلود و استخراج شد ($ASSET_NAME)"
                                                DOWNLOAD_SUCCESS=true
                                                break
                                            fi
                                        fi
                                    elif [[ "$ASSET_NAME" == *.zip ]]; then
                                        echo "   در حال استخراج از zip..."
                                        unzip -q "$TEMP_FILE" -d . 2>/dev/null
                                        rm "$TEMP_FILE"
                                        if [ -f "./paqet" ]; then
                                            chmod +x paqet
                                            PAQET_CMD="./paqet"
                                            echo "✓ Paqet دانلود و استخراج شد ($ASSET_NAME)"
                                            DOWNLOAD_SUCCESS=true
                                            break
                                        else
                                            # جستجو برای فایل‌های paqet (paqet, paqet_linux_amd64 و غیره)
                                            PAQET_FILE=$(find . -type f \( -name "paqet" -o -name "paqet_*" -o -name "paqet-*" \) ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.md" ! -name "*.yaml" ! -name "*.sh" 2>/dev/null | head -1)
                                            if [ -n "$PAQET_FILE" ]; then
                                                mv "$PAQET_FILE" ./paqet
                                                chmod +x paqet
                                                PAQET_CMD="./paqet"
                                                echo "✓ Paqet دانلود و استخراج شد ($ASSET_NAME)"
                                                DOWNLOAD_SUCCESS=true
                                                break
                                            fi
                                        fi
                                    else
                                        # فایل باینری مستقیم
                                        mv "$TEMP_FILE" paqet
                                        chmod +x paqet
                                        PAQET_CMD="./paqet"
                                        echo "✓ Paqet دانلود شد ($ASSET_NAME)"
                                        DOWNLOAD_SUCCESS=true
                                        break
                                    fi
                                fi
                            fi
                        done
                    fi
                    
                    if [ "$DOWNLOAD_SUCCESS" == false ]; then
                        echo ""
                        echo "⚠️  دانلود خودکار موفق نشد!"
                        echo ""
                        echo "لطفاً دستی از لینک زیر دانلود کن:"
                        echo "   https://github.com/hanselime/paqet/releases/tag/${LATEST_RELEASE}"
                        echo ""
                        echo "یا از دستور زیر استفاده کن (نام فایل رو از صفحه release پیدا کن):"
                        echo "   wget https://github.com/hanselime/paqet/releases/download/${LATEST_RELEASE}/[نام-فایل] -O paqet"
                        echo ""
                        read -p "آیا فایل رو دستی دانلود کردی و در همین مسیر هست؟ [Y/n]: " MANUAL_DOWNLOAD
                        if [[ "$MANUAL_DOWNLOAD" != "n" && "$MANUAL_DOWNLOAD" != "N" ]]; then
                            if [ -f "./paqet" ]; then
                                chmod +x paqet
                                PAQET_CMD="./paqet"
                                echo "✓ فایل paqet پیدا شد"
                            else
                                PAQET_CMD="paqet"
                            fi
                        else
                            PAQET_CMD="paqet"
                        fi
                    fi
                else
                    echo "⚠️  نتوانست آخرین release رو پیدا کنه"
                    echo "لطفاً دستی دانلود کن: https://github.com/hanselime/paqet/releases"
                    PAQET_CMD="paqet"
                fi
            else
                # اگر curl موجود نبود، از روش قدیمی استفاده کن
                echo "⚠️  curl پیدا نشد، استفاده از روش ساده..."
                wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet 2>&1
                if [ $? -eq 0 ] && [ -f "./paqet" ]; then
                    chmod +x paqet
                    PAQET_CMD="./paqet"
                    echo "✓ Paqet دانلود شد"
                else
                    echo ""
                    echo "❌ دانلود موفق نشد!"
                    echo "لطفاً دستی از لینک زیر دانلود کن:"
                    echo "   https://github.com/hanselime/paqet/releases/latest"
                    PAQET_CMD="paqet"
                fi
            fi
        else
            PAQET_CMD="paqet"
        fi
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ راه‌اندازی کامل شد!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ذخیره کلید در فایل جداگانه
echo "$SECRET_KEY" > .paqet_secret_key.txt
chmod 600 .paqet_secret_key.txt
echo "💾 کلید رمزنگاری در فایل .paqet_secret_key.txt ذخیره شد"
echo "   ⚠️  این فایل رو با سرور دیگه به اشتراک بذار!"
