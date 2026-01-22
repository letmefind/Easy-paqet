#!/bin/bash

# اسکریپت ساخت بسته Offline برای کلاینت
# این اسکریپت فایل‌های لازم برای نصب روی سرور کلاینت رو جمع می‌کنه

set -e

if [ $# -lt 1 ]; then
    echo "استفاده: $0 <secret-key> [paqet-binary-path]"
    echo "مثال: $0 'your-secret-key-here' ./paqet"
    exit 1
fi

SECRET_KEY="$1"
PAQET_BINARY="${2:-./paqet}"
PACKAGE_NAME="paqet-client-offline"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
PACKAGE_DIR="${PACKAGE_NAME}-${TIMESTAMP}"
ARCHIVE_NAME="${PACKAGE_NAME}-${TIMESTAMP}.tar"

echo "╔════════════════════════════════════════════════════════╗"
echo "║     ساخت بسته Offline برای کلاینت                    ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# ساخت پوشه بسته
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

echo "📦 در حال جمع‌آوری فایل‌ها..."

# کپی اسکریپت‌های setup
cp setup.sh "$PACKAGE_DIR/" 2>/dev/null || echo "⚠️  setup.sh پیدا نشد"
cp setup_fa.sh "$PACKAGE_DIR/" 2>/dev/null || echo "⚠️  setup_fa.sh پیدا نشد"
cp setup_en.sh "$PACKAGE_DIR/" 2>/dev/null || echo "⚠️  setup_en.sh پیدا نشد"

# کپی فایل کانفیگ کلاینت
cp config_client.yaml "$PACKAGE_DIR/" 2>/dev/null || echo "⚠️  config_client.yaml پیدا نشد"

# کپی فایل paqet
if [ -f "$PAQET_BINARY" ]; then
    cp "$PAQET_BINARY" "$PACKAGE_DIR/paqet"
    chmod +x "$PACKAGE_DIR/paqet"
    echo "✓ فایل paqet کپی شد"
else
    echo "⚠️  فایل paqet پیدا نشد: $PAQET_BINARY"
    echo "   باید دستی در بسته قرار بدی"
fi

# ذخیره کلید رمزنگاری
echo "$SECRET_KEY" > "$PACKAGE_DIR/.paqet_secret_key.txt"
chmod 600 "$PACKAGE_DIR/.paqet_secret_key.txt"
echo "✓ کلید رمزنگاری ذخیره شد"

# ساخت فایل README برای بسته
cat > "$PACKAGE_DIR/README_CLIENT.md" <<EOF
# بسته Offline نصب Paqet - کلاینت

این بسته برای نصب Paqet روی سرور کلاینت (بدون اینترنت) طراحی شده است.

## محتویات:

- **setup.sh** - راه‌انداز اصلی
- **setup_fa.sh** - اسکریپت راه‌اندازی فارسی
- **setup_en.sh** - اسکریپت راه‌اندازی انگلیسی
- **config_client.yaml** - فایل کانفیگ template برای کلاینت
- **paqet** - فایل باینری paqet
- **.paqet_secret_key.txt** - کلید رمزنگاری (باید با سرور یکسان باشه)

## مراحل نصب:

### 1. انتقال بسته به سرور کلاینت

```bash
# از طریق SCP
scp ${ARCHIVE_NAME} user@client-server:/tmp/

# یا از طریق USB/SD Card
```

### 2. استخراج بسته

```bash
cd /tmp
tar -xf ${ARCHIVE_NAME}
cd ${PACKAGE_DIR}
```

**نکته:** از `tar -xf` استفاده می‌کنیم (بدون z) چون فایل tar ساده است و نیاز به gzip نداره.

### 3. راه‌اندازی

```bash
# استفاده از اسکریپت راه‌اندازی
chmod +x setup.sh
./setup.sh

# یا مستقیماً فارسی
chmod +x setup_fa.sh
./setup_fa.sh
```

اسکریپت:
- ازت می‌پرسه که این سرور کلاینت است (A)
- اطلاعات شبکه رو جمع می‌کنه
- از کلید موجود در `.paqet_secret_key.txt` استفاده می‌کنه
- فایل کانفیگ رو می‌سازه

### 4. اجرا

```bash
sudo ./paqet run -c config_client.yaml
```

## نکات مهم:

1. **کلید رمزنگاری**: کلید در `.paqet_secret_key.txt` ذخیره شده و باید با سرور یکسان باشه
2. **دسترسی root**: برای اجرای paqet نیاز به sudo دارید
3. **اطلاعات سرور**: باید آی‌پی سرور B رو در کانفیگ وارد کنی
EOF

# ساخت فایل tar (بدون gzip - ساده‌تر برای اکسترکت)
echo ""
echo "📦 در حال ساخت فایل بسته..."
tar -cf "$ARCHIVE_NAME" "$PACKAGE_DIR"

echo ""
echo "✅ بسته ساخته شد: $ARCHIVE_NAME"
echo ""
echo "📊 خلاصه:"
echo "   - حجم بسته: $(du -h "$ARCHIVE_NAME" | cut -f1)"
echo "   - تعداد فایل‌ها: $(find "$PACKAGE_DIR" -type f | wc -l)"
echo ""
echo "🚀 برای استفاده:"
echo "   1. فایل $ARCHIVE_NAME رو به سرور کلاینت منتقل کن"
echo "   2. استخراج کن: tar -xf $ARCHIVE_NAME"
echo "   3. راه‌اندازی کن: cd $PACKAGE_DIR && ./setup.sh"
echo ""
echo "💡 نکته: این فایل tar ساده است و با tar -xf اکسترکت می‌شه (نیاز به gzip نداره)"
