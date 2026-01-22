# راهنمای رفع مشکل نمایش برعکس حروف فارسی در Terminal

## مشکل چیست؟

اگر حروف فارسی در terminal برعکس نمایش داده می‌شوند، این مشکل از terminal emulator شماست، نه از اسکریپت.

## راه حل‌های سریع:

### 1️⃣ استفاده از Terminal Emulator بهتر

برخی terminal emulator ها بهتر از RTL (Right-to-Left) پشتیبانی می‌کنند:

**برای Linux:**
- **Alacritty** - بهترین پشتیبانی از RTL
- **Kitty** - پشتیبانی خوب از RTL
- **GNOME Terminal** - معمولاً خوب کار می‌کنه
- **Konsole** (KDE) - پشتیبانی عالی از RTL

**برای macOS:**
- **iTerm2** - بهترین گزینه برای macOS
- **Alacritty** - گزینه خوب دیگه
- Terminal پیش‌فرض macOS معمولاً مشکل داره

**برای Windows:**
- **Windows Terminal** (جدیدترین)
- **Alacritty**
- **ConEmu**

### 2️⃣ تنظیم Locale

قبل از اجرای اسکریپت، این دستورات رو اجرا کن:

```bash
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LANGUAGE=C.UTF-8

# سپس اسکریپت رو اجرا کن
./setup_interactive.sh
```

یا برای دائمی کردن:

```bash
# اضافه کردن به ~/.bashrc یا ~/.zshrc
echo 'export LC_ALL=C.UTF-8' >> ~/.bashrc
echo 'export LANG=C.UTF-8' >> ~/.bashrc
source ~/.bashrc
```

### 3️⃣ استفاده از tmux یا screen

اگر از SSH استفاده می‌کنی، می‌تونی از tmux یا screen استفاده کنی:

```bash
# نصب tmux
sudo apt install tmux  # Debian/Ubuntu
sudo yum install tmux  # CentOS/RHEL

# اجرا در tmux
tmux
./setup_interactive.sh
```

### 4️⃣ استفاده از SSH Client بهتر

اگر از SSH استفاده می‌کنی:

**برای Windows:**
- **MobaXterm** - پشتیبانی عالی از RTL
- **PuTTY** - نیاز به تنظیمات داره
- **Windows Terminal** با SSH

**برای macOS/Linux:**
- Terminal پیش‌فرض معمولاً خوبه
- یا از iTerm2/Alacritty استفاده کن

### 5️⃣ تنظیمات PuTTY (اگر استفاده می‌کنی)

1. باز کردن PuTTY
2. رفتن به **Window → Translation**
3. انتخاب **UTF-8** در **Character set encoding**
4. رفتن به **Window → Appearance → Font**
5. انتخاب یک فونت که از فارسی پشتیبانی می‌کنه (مثلا Tahoma, Arial Unicode MS)

### 6️⃣ راه حل موقت: استفاده از متن انگلیسی

اگر هیچکدوم کار نکرد، می‌تونی از فایل‌های کانفیگ آماده استفاده کنی و دستی ویرایش کنی:

```bash
# کپی کردن فایل‌های نمونه
cp config_client.yaml config_client_my.yaml
cp config_server.yaml config_server_my.yaml

# ویرایش دستی
nano config_client_my.yaml
```

## تست کردن Terminal

برای تست اینکه terminal شما از RTL پشتیبانی می‌کنه یا نه:

```bash
echo "این یک تست فارسی است"
```

اگر متن برعکس نمایش داده شد، terminal شما مشکل داره.

## توصیه نهایی

**بهترین راه حل:** استفاده از **iTerm2** (macOS) یا **Alacritty** (Linux/macOS/Windows) که بهترین پشتیبانی از RTL رو دارن.

---

**نکته:** اسکریپت `setup_interactive.sh` خودش سعی می‌کنه locale رو تنظیم کنه، اما اگر terminal شما از RTL پشتیبانی نکنه، باز هم مشکل خواهی داشت.
