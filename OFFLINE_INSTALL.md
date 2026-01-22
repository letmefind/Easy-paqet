# راهنمای نصب Offline Paqet

این راهنما برای نصب Paqet روی سرورهای بدون اینترنت است.

## 📦 فایل‌های مورد نیاز

برای نصب Offline، به این فایل‌ها نیاز دارید:

### 1. فایل‌های اسکریپت
- `setup.sh` - راه‌انداز اصلی
- `setup_fa.sh` - اسکریپت فارسی
- `setup_en.sh` - اسکریپت انگلیسی
- `setup_interactive.sh` - اسکریپت دو زبانه (اختیاری)

### 2. فایل‌های کانفیگ Template
- `config_server.yaml` - template برای سرور
- `config_client.yaml` - template برای کلاینت

### 3. فایل‌های باینری Paqet
- `paqet-linux-amd64-v1.0.0-alpha.6.tar.gz` - برای Linux x86_64
- `paqet-linux-arm64-v1.0.0-alpha.6.tar.gz` - برای Linux ARM64
- `paqet-darwin-amd64-v1.0.0-alpha.6.tar.gz` - برای macOS Intel (اختیاری)
- `paqet-darwin-arm64-v1.0.0-alpha.6.tar.gz` - برای macOS Apple Silicon (اختیاری)
- `paqet-windows-amd64-v1.0.0-alpha.6.zip` - برای Windows (اختیاری)

### 4. فایل‌های کمکی
- `iptables_rules.sh` - اسکریپت اعمال قوانین iptables
- `README.md` - مستندات (اختیاری)

## 🔧 ساخت بسته Offline

### روش 1: استفاده از اسکریپت خودکار

```bash
# روی یک سرور با اینترنت
chmod +x create_offline_package.sh
./create_offline_package.sh
```

این اسکریپت:
- همه فایل‌های لازم رو جمع می‌کنه
- فایل‌های باینری paqet رو برای سیستم‌عامل‌های مختلف دانلود می‌کنه
- یک بسته tar.gz می‌سازه

### روش 2: ساخت دستی

```bash
# ساخت پوشه بسته
mkdir -p paqet-offline-installer/binaries

# کپی اسکریپت‌ها
cp setup.sh setup_fa.sh setup_en.sh paqet-offline-installer/
cp config_server.yaml config_client.yaml paqet-offline-installer/
cp iptables_rules.sh paqet-offline-installer/ 2>/dev/null || true

# دانلود فایل‌های باینری
cd paqet-offline-installer/binaries
wget https://github.com/hanselime/paqet/releases/download/v1.0.0-alpha.6/paqet-linux-amd64-v1.0.0-alpha.6.tar.gz
wget https://github.com/hanselime/paqet/releases/download/v1.0.0-alpha.6/paqet-linux-arm64-v1.0.0-alpha.6.tar.gz
# ... سایر فایل‌ها

# ساخت بسته
cd ..
tar -czf paqet-offline-installer.tar.gz paqet-offline-installer/
```

## 📥 انتقال به سرور بدون اینترنت

### روش 1: SCP
```bash
scp paqet-offline-installer-*.tar.gz user@server:/tmp/
```

### روش 2: USB/SD Card
```bash
# کپی فایل به USB
cp paqet-offline-installer-*.tar.gz /media/usb/

# روی سرور
cp /media/usb/paqet-offline-installer-*.tar.gz /tmp/
```

### روش 3: از طریق سرور میانی
```bash
# روی سرور میانی
scp paqet-offline-installer-*.tar.gz intermediate-server:/tmp/
# سپس از سرور میانی به سرور نهایی
```

## 🚀 نصب روی سرور بدون اینترنت

### مرحله 1: استخراج بسته

```bash
cd /tmp
tar -xzf paqet-offline-installer-*.tar.gz
cd paqet-offline-installer-*
```

### مرحله 2: نصب Paqet

```bash
# اگر اسکریپت install_offline.sh موجود باشه
chmod +x install_offline.sh
./install_offline.sh

# یا دستی:
cd binaries
tar -xzf paqet-linux-amd64-*.tar.gz
mv paqet_linux_amd64 ../paqet
chmod +x ../paqet
cd ..
```

### مرحله 3: راه‌اندازی

```bash
# استفاده از اسکریپت راه‌اندازی
chmod +x setup.sh
./setup.sh

# یا مستقیماً فارسی
chmod +x setup_fa.sh
./setup_fa.sh
```

## 📋 چک‌لیست فایل‌های مورد نیاز

قبل از انتقال به سرور بدون اینترنت، مطمئن شو که این فایل‌ها موجود هستند:

- [ ] `setup.sh`
- [ ] `setup_fa.sh`
- [ ] `setup_en.sh`
- [ ] `config_server.yaml`
- [ ] `config_client.yaml`
- [ ] `iptables_rules.sh`
- [ ] `binaries/paqet-linux-amd64-*.tar.gz` (حداقل این یکی)
- [ ] `binaries/paqet-linux-arm64-*.tar.gz` (اگر سرور ARM64 دارید)

## ⚠️ نکات مهم

1. **حداقل فایل‌های باینری**: حداقل فایل باینری برای سیستم عامل سرور خودتون رو داشته باشید
2. **دسترسی root**: برای اجرای paqet نیاز به sudo دارید
3. **iptables**: روی سرور باید قوانین iptables اعمال بشن
4. **کلید رمزنگاری**: کلید تولید شده رو با سرور دیگه به اشتراک بذارید

## 🔍 عیب‌یابی

### مشکل: فایل باینری پیدا نشد

```bash
# چک کردن فایل‌های موجود
ls -lh binaries/

# اگر فایل موجود نیست، از سرور با اینترنت دانلود کن و اضافه کن
```

### مشکل: دسترسی اجرا نداره

```bash
chmod +x setup.sh setup_fa.sh setup_en.sh
chmod +x paqet
```

### مشکل: اسکریپت کار نمی‌کنه

```bash
# چک کردن syntax
bash -n setup_fa.sh

# اجرای با debug
bash -x setup_fa.sh
```
