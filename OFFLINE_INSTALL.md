# راهنمای نصب Offline Paqet

این راهنما برای نصب Paqet روی سرورهای بدون اینترنت است.

## 📦 فایل‌های مورد نیاز

برای نصب Offline، به این فایل‌ها نیاز داری:

### 1. فایل‌های اسکریپت
- `setup.sh` - راه‌انداز اصلی
- `setup_fa.sh` - اسکریپت فارسی
- `setup_en.sh` - اسکریپت انگلیسی

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

### روش 1: استفاده از اسکریپت خودکار (توصیه می‌شه!)

اگه روی سرور اصلی (با اینترنت) هستی و می‌خوای بسته Offline برای کلاینت بسازی:

```bash
# روی سرور اصلی، وقتی اسکریپت setup.sh رو اجرا می‌کنی
# و می‌خوای بسته Offline بسازی، اسکریپت خودش ازت می‌پرسه
# که آیا می‌خوای بسته Offline بسازی یا نه

./setup.sh
# وقتی ازت پرسید، Y بزن
```

این اسکریپت:
- همه فایل‌های لازم رو جمع می‌کنه
- فایل باینری paqet رو دانلود می‌کنه
- یک بسته tar می‌سازه که می‌تونی به سرور کلاینت منتقل کنی

### روش 2: ساخت دستی

اگه می‌خوای خودت دستی بسازی:

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

### روش 1: SCP (توصیه می‌شه!)

```bash
scp paqet-client-offline-*.tar user@server:/tmp/
```

### روش 2: با ابزارهایی مثل WinSCP

اگه از Windows استفاده می‌کنی، می‌تونی از WinSCP استفاده کنی:
1. WinSCP رو باز کن
2. به سرور کلاینت متصل شو
3. فایل tar رو به `/tmp/` بکش

### روش 3: USB/SD Card

```bash
# کپی فایل به USB
cp paqet-client-offline-*.tar /media/usb/

# روی سرور
cp /media/usb/paqet-client-offline-*.tar /tmp/
```

## 🚀 نصب روی سرور بدون اینترنت

### مرحله 1: استخراج بسته

```bash
cd /tmp
tar -xf paqet-client-offline-*.tar
cd paqet-client-offline-*
```

### مرحله 2: راه‌اندازی

```bash
# استفاده از اسکریپت راه‌اندازی
chmod +x setup.sh
./setup.sh

# یا مستقیماً فارسی
chmod +x setup_fa.sh
./setup_fa.sh
```

اسکریپت خودش همه چیز رو انجام می‌ده:
- فایل paqet رو پیدا می‌کنه یا از بسته استفاده می‌کنه
- کانفیگ رو می‌سازه
- قوانین iptables رو اعمال می‌کنه

## 📋 چک‌لیست فایل‌های مورد نیاز

قبل از انتقال به سرور بدون اینترنت، مطمئن شو که این فایل‌ها موجود هستند:

- [ ] `setup.sh`
- [ ] `setup_fa.sh`
- [ ] `setup_en.sh`
- [ ] `config_server.yaml`
- [ ] `config_client.yaml`
- [ ] `iptables_rules.sh`
- [ ] `paqet` (باینری paqet)

## ⚠️ نکات مهم

1. **حداقل فایل‌های باینری**: حداقل فایل باینری برای سیستم عامل سرور خودت رو داشته باش
2. **دسترسی root**: برای اجرای paqet نیاز به sudo داری
3. **iptables**: روی سرور باید قوانین iptables اعمال بشن
4. **کلید رمزنگاری**: کلید تولید شده رو با سرور دیگه به اشتراک بذار

## 🔍 عیب‌یابی

### مشکل: فایل باینری پیدا نشد

```bash
# چک کردن فایل‌های موجود
ls -lh

# اگه فایل paqet موجود نیست، از سرور با اینترنت دانلود کن و اضافه کن
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

---

**نکته:** بهترین روش اینه که از اسکریپت تعاملی استفاده کنی. وقتی روی سرور اصلی (با اینترنت) هستی و می‌خوای بسته Offline بسازی، اسکریپت خودش همه چیز رو انجام می‌ده!
