# راهنمای نصب و راه‌اندازی Paqet 🚀

سلام! این راهنما بهت کمک می‌کنه که پروژه paqet رو روی دو سرور لینوکسی راه‌اندازی کنی. خیلی راحت و ساده!

## 📋 چیزایی که نیاز داری:

- دو سرور لینوکسی (سرور A و سرور B)
- دسترسی root یا sudo
- اینترنت برای دانلود فایل‌ها

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

### روی سرور A:

1. فایل `config_client.yaml` رو با ویرایشگر باز کن (مثلا nano یا vim):

```bash
nano config_client.yaml
```

2. این قسمت‌ها رو ویرایش کن:
   - `interface`: نام اینترفیس شبکه‌ات (مثلا `eth0` یا `ens3`)
   - `gateway_mac`: MAC آدرس روترت (میتونی با `ip route | grep default` پیدا کنی)
   - `remote_addr`: آی‌پی سرور B رو بذار (مثلا `203.0.113.10:9999`)

### روی سرور B:

1. فایل `config_server.yaml` رو باز کن:

```bash
nano config_server.yaml
```

2. این قسمت‌ها رو ویرایش کن:
   - `interface`: نام اینترفیس شبکه‌ات
   - `gateway_mac`: MAC آدرس روترت
   - `target`: پورت محلی که می‌خوای ترافیک بهش برسه (مثلا `127.0.0.1:8080`)

---

## 🔥 مرحله ۳: اعمال قوانین iptables روی سرور B

این کار خیلی مهمه! باید جلوی ارسال پکت‌های RST رو بگیری.

```bash
# کپی کردن فایل اسکریپت iptables
# (اگر فایل رو از جای دیگه آوردی)

# اجرای اسکریپت
chmod +x iptables_rules.sh
sudo ./iptables_rules.sh
```

یا اگه می‌خوای دستی انجام بدی:

```bash
sudo iptables -A OUTPUT -p tcp --tcp-flags RST RST -j DROP
sudo iptables -A FORWARD -p tcp --tcp-flags RST RST -j DROP

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
sudo paqet -c config_server.yaml

# یا اگه در مسیر دیگه‌ای هستی:
sudo /usr/local/bin/paqet -c /path/to/config_server.yaml
```

### روی سرور A (بعد کلاینت رو اجرا کن):

```bash
# اجرای کلاینت
sudo paqet -c config_client.yaml

# یا اگه در مسیر دیگه‌ای هستی:
sudo /usr/local/bin/paqet -c /path/to/config_client.yaml
```

**نکته:** اگه می‌خوای در پس‌زمینه اجرا بشه، از `screen` یا `tmux` استفاده کن:

```bash
# نصب screen (اگه نصب نیست)
sudo apt install screen  # برای Debian/Ubuntu
# یا
sudo yum install screen  # برای CentOS/RHEL

# اجرا در screen
screen -S paqet
sudo paqet -c config_server.yaml

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

### تست ۲: بررسی لاگ‌ها

روی هر دو سرور، لاگ‌های paqet رو چک کن تا ببینی اتصال برقرار شده یا نه.

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

### مشکل: پکت‌های RST ارسال می‌شن

مطمئن شو که دستورات iptables رو درست اجرا کردی:

```bash
sudo iptables -L -n -v | grep RST
```

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
- **کلید رمزنگاری (`secret`) باید در هر دو فایل یکسان باشه**
- **MAC آدرس روتر رو درست وارد کن** (اگه اشتباه باشه، کار نمی‌کنه)
- **برای اجرای دائمی، از systemd service استفاده کن** (در ادامه می‌گم چطوری)

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
ExecStart=/usr/local/bin/paqet -c /path/to/config_client.yaml
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
sudo paqet -c config_server.yaml  # روی سرور B
sudo paqet -c config_client.yaml  # روی سرور A

# تست
curl -x socks5://127.0.0.1:1080 http://httpbin.org/ip
```

---

خب، دیگه همه چیز آماده! اگه مشکلی پیش اومد، لاگ‌ها رو چک کن یا بهم بگو تا کمک کنم. موفق باشی! 🚀
