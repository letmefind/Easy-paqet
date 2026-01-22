#!/bin/bash

# اسکریپت ساخت بسته Offline برای نصب Paqet
# این اسکریپت همه فایل‌های لازم رو جمع می‌کنه و یک بسته tar.gz می‌سازه

set -e

PACKAGE_NAME="paqet-offline-installer"
VERSION=$(date +%Y%m%d)
PACKAGE_DIR="${PACKAGE_NAME}-${VERSION}"
ARCHIVE_NAME="${PACKAGE_NAME}-${VERSION}.tar.gz"

echo "╔════════════════════════════════════════════════════════╗"
echo "║     ساخت بسته Offline برای نصب Paqet                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# ساخت پوشه بسته
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

echo "📦 در حال جمع‌آوری فایل‌ها..."

# کپی اسکریپت‌های setup
cp setup.sh "$PACKAGE_DIR/"
cp setup_fa.sh "$PACKAGE_DIR/"
cp setup_en.sh "$PACKAGE_DIR/"
cp setup_interactive.sh "$PACKAGE_DIR/" 2>/dev/null || true

# کپی فایل‌های کانفیگ template
cp config_server.yaml "$PACKAGE_DIR/"
cp config_client.yaml "$PACKAGE_DIR/"

# کپی اسکریپت iptables
cp iptables_rules.sh "$PACKAGE_DIR/" 2>/dev/null || true

# کپی مستندات
cp README.md "$PACKAGE_DIR/" 2>/dev/null || true
cp SETUP_GUIDE_FA.md "$PACKAGE_DIR/" 2>/dev/null || true
cp QUICK_START.md "$PACKAGE_DIR/" 2>/dev/null || true
cp TERMINAL_FIX.md "$PACKAGE_DIR/" 2>/dev/null || true

# ساخت پوشه binaries برای فایل‌های paqet
mkdir -p "$PACKAGE_DIR/binaries"

echo ""
echo "🔽 در حال دانلود فایل‌های paqet برای سیستم‌عامل‌های مختلف..."

# لیست سیستم‌عامل‌ها و معماری‌ها
declare -a PLATFORMS=(
    "linux-amd64"
    "linux-arm64"
    "darwin-amd64"
    "darwin-arm64"
    "windows-amd64"
)

LATEST_RELEASE="v1.0.0-alpha.6"

# استفاده از GitHub API برای پیدا کردن آخرین release
if command -v curl &> /dev/null; then
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/hanselime/paqet/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "v1.0.0-alpha.6")
fi

echo "   آخرین نسخه: $LATEST_RELEASE"
echo ""

DOWNLOADED_COUNT=0

for PLATFORM in "${PLATFORMS[@]}"; do
    OS=$(echo "$PLATFORM" | cut -d'-' -f1)
    ARCH=$(echo "$PLATFORM" | cut -d'-' -f2)
    
    if [ "$OS" == "windows" ]; then
        FILE_EXT=".zip"
    else
        FILE_EXT=".tar.gz"
    fi
    
    FILENAME="paqet-${PLATFORM}-${LATEST_RELEASE}${FILE_EXT}"
    DOWNLOAD_URL="https://github.com/hanselime/paqet/releases/download/${LATEST_RELEASE}/${FILENAME}"
    
    echo "   دانلود: $FILENAME..."
    
    if wget -q --spider "$DOWNLOAD_URL" 2>/dev/null; then
        wget "$DOWNLOAD_URL" -O "$PACKAGE_DIR/binaries/${FILENAME}" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "   ✓ دانلود شد"
            DOWNLOADED_COUNT=$((DOWNLOADED_COUNT + 1))
        else
            echo "   ✗ خطا در دانلود"
        fi
    else
        echo "   ✗ فایل موجود نیست"
    fi
done

echo ""
echo "📝 در حال ساخت اسکریپت نصب Offline..."

# ساخت اسکریپت نصب Offline
cat > "$PACKAGE_DIR/install_offline.sh" <<'INSTALL_EOF'
#!/bin/bash

# اسکریپت نصب Offline Paqet
# این اسکریپت برای سرورهای بدون اینترنت طراحی شده

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARIES_DIR="$SCRIPT_DIR/binaries"

echo "╔════════════════════════════════════════════════════════╗"
echo "║     نصب Offline Paqet                                  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# تشخیص سیستم عامل و معماری
OS=""
ARCH=""

case "$(uname -s)" in
    Linux*)     OS="linux" ;;
    Darwin*)    OS="darwin" ;;
    CYGWIN*)    OS="windows" ;;
    MINGW*)     OS="windows" ;;
    MSYS*)      OS="windows" ;;
    *)          OS="linux" ;;
esac

case "$(uname -m)" in
    x86_64|amd64)   ARCH="amd64" ;;
    aarch64|arm64)  ARCH="arm64" ;;
    armv7l|armv6l)  ARCH="arm" ;;
    *)              ARCH="amd64" ;;
esac

PLATFORM="${OS}-${ARCH}"
echo "سیستم عامل: $OS"
echo "معماری: $ARCH"
echo ""

# پیدا کردن فایل مناسب
if [ "$OS" == "windows" ]; then
    FILE_PATTERN="paqet-${PLATFORM}-*.zip"
else
    FILE_PATTERN="paqet-${PLATFORM}-*.tar.gz"
fi

BINARY_FILE=$(find "$BINARIES_DIR" -name "$FILE_PATTERN" 2>/dev/null | head -1)

if [ -z "$BINARY_FILE" ]; then
    echo "❌ فایل باینری برای $PLATFORM پیدا نشد!"
    echo ""
    echo "فایل‌های موجود در binaries/:"
    ls -lh "$BINARIES_DIR" 2>/dev/null || echo "پوشه binaries خالی است"
    exit 1
fi

echo "✓ فایل پیدا شد: $(basename $BINARY_FILE)"
echo ""

# استخراج فایل
echo "در حال استخراج..."
if [[ "$BINARY_FILE" == *.tar.gz ]] || [[ "$BINARY_FILE" == *.tgz ]]; then
    tar -xzf "$BINARY_FILE" -C "$SCRIPT_DIR" 2>/dev/null
    
    # پیدا کردن فایل paqet
    PAQET_FILE=$(find "$SCRIPT_DIR" -type f \( -name "paqet" -o -name "paqet_*" -o -name "paqet-*" \) ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.md" ! -name "*.yaml" ! -name "*.sh" 2>/dev/null | head -1)
    
    if [ -n "$PAQET_FILE" ]; then
        mv "$PAQET_FILE" "$SCRIPT_DIR/paqet"
        chmod +x "$SCRIPT_DIR/paqet"
        echo "✓ Paqet استخراج شد"
    else
        echo "❌ فایل paqet پیدا نشد!"
        exit 1
    fi
elif [[ "$BINARY_FILE" == *.zip ]]; then
    unzip -q "$BINARY_FILE" -d "$SCRIPT_DIR" 2>/dev/null
    
    PAQET_FILE=$(find "$SCRIPT_DIR" -type f \( -name "paqet" -o -name "paqet_*" -o -name "paqet-*" \) ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.md" ! -name "*.yaml" ! -name "*.sh" 2>/dev/null | head -1)
    
    if [ -n "$PAQET_FILE" ]; then
        mv "$PAQET_FILE" "$SCRIPT_DIR/paqet"
        chmod +x "$SCRIPT_DIR/paqet"
        echo "✓ Paqet استخراج شد"
    else
        echo "❌ فایل paqet پیدا نشد!"
        exit 1
    fi
fi

echo ""
echo "✅ نصب کامل شد!"
echo ""
echo "برای راه‌اندازی از یکی از اسکریپت‌های زیر استفاده کن:"
echo "  ./setup.sh          (راه‌انداز اصلی)"
echo "  ./setup_fa.sh       (فارسی)"
echo "  ./setup_en.sh       (انگلیسی)"
echo ""
INSTALL_EOF

chmod +x "$PACKAGE_DIR/install_offline.sh"

# ساخت فایل README برای بسته
cat > "$PACKAGE_DIR/OFFLINE_README.md" <<README_EOF
# بسته Offline نصب Paqet

این بسته برای نصب Paqet روی سرورهای بدون اینترنت طراحی شده است.

## محتویات بسته:

- **setup.sh** - اسکریپت راه‌انداز اصلی
- **setup_fa.sh** - اسکریپت راه‌اندازی فارسی
- **setup_en.sh** - اسکریپت راه‌اندازی انگلیسی
- **config_server.yaml** - فایل کانفیگ template برای سرور
- **config_client.yaml** - فایل کانفیگ template برای کلاینت
- **iptables_rules.sh** - اسکریپت اعمال قوانین iptables
- **binaries/** - فایل‌های باینری paqet برای سیستم‌عامل‌های مختلف
- **install_offline.sh** - اسکریپت نصب Offline

## مراحل نصب:

### 1. انتقال بسته به سرور

```bash
# انتقال فایل tar.gz به سرور (از طریق USB، SCP، و غیره)
scp paqet-offline-installer-*.tar.gz user@server:/tmp/
```

### 2. استخراج بسته

```bash
cd /tmp
tar -xzf paqet-offline-installer-*.tar.gz
cd paqet-offline-installer-*
```

### 3. نصب Paqet

```bash
# اجرای اسکریپت نصب Offline
chmod +x install_offline.sh
./install_offline.sh
```

این اسکریپت:
- سیستم عامل و معماری رو تشخیص می‌ده
- فایل باینری مناسب رو از پوشه binaries پیدا می‌کنه
- استخراج می‌کنه و در مسیر فعلی قرار می‌ده

### 4. راه‌اندازی

```bash
# استفاده از اسکریپت راه‌اندازی
chmod +x setup.sh
./setup.sh
```

یا مستقیماً:

```bash
chmod +x setup_fa.sh
./setup_fa.sh
```

## فایل‌های باینری موجود:

فایل‌های باینری در پوشه `binaries/` قرار دارند:
- `paqet-linux-amd64-*.tar.gz` - برای Linux x86_64
- `paqet-linux-arm64-*.tar.gz` - برای Linux ARM64
- `paqet-darwin-amd64-*.tar.gz` - برای macOS Intel
- `paqet-darwin-arm64-*.tar.gz` - برای macOS Apple Silicon
- `paqet-windows-amd64-*.zip` - برای Windows x86_64

## نکات مهم:

1. **دسترسی root**: برای اجرای paqet نیاز به دسترسی root دارید (به خاطر raw sockets)
2. **iptables**: روی سرور باید قوانین iptables اعمال بشن (اسکریپت خودش انجام می‌ده)
3. **کلید رمزنگاری**: کلید تولید شده رو با سرور دیگه به اشتراک بذارید

## عیب‌یابی:

اگر فایل باینری برای سیستم شما موجود نیست:
1. از یک سرور با اینترنت، فایل مناسب رو دانلود کن
2. در پوشه `binaries/` قرار بده
3. دوباره `install_offline.sh` رو اجرا کن
README_EOF

# ساخت فایل tar.gz
echo ""
echo "📦 در حال ساخت فایل بسته..."
tar -czf "$ARCHIVE_NAME" "$PACKAGE_DIR"

echo ""
echo "✅ بسته ساخته شد: $ARCHIVE_NAME"
echo ""
echo "📊 خلاصه:"
echo "   - تعداد فایل‌های باینری دانلود شده: $DOWNLOADED_COUNT"
echo "   - حجم بسته: $(du -h "$ARCHIVE_NAME" | cut -f1)"
echo ""
echo "🚀 برای استفاده:"
echo "   1. فایل $ARCHIVE_NAME رو به سرور بدون اینترنت منتقل کن"
echo "   2. استخراج کن: tar -xzf $ARCHIVE_NAME"
echo "   3. اجرا کن: cd $PACKAGE_DIR && ./install_offline.sh"
echo "   4. راه‌اندازی کن: ./setup.sh"
echo ""
