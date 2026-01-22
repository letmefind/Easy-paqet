# راهنمای سریع Paqet ⚡

این یک راهنمای خیلی کوتاه و سریع برای راه‌اندازی paqet است. اگه می‌خوای همه چیز خودکار باشه، از اسکریپت تعاملی استفاده کن:

```bash
chmod +x setup.sh
./setup.sh
```

اگه می‌خوای خودت انجام بدی، این مراحل رو دنبال کن:

## 📁 فایل‌های موجود:

- `config_client.yaml` - کانفیگ سرور کلاینت
- `config_server.yaml` - کانفیگ سرور اصلی
- `iptables_rules.sh` - اسکریپت اعمال قوانین iptables
- `setup.sh` - اسکریپت تعاملی راه‌اندازی

## 🎯 مراحل سریع:

### 1️⃣ نصب Paqet (روی هر دو سرور):

```bash
wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet
chmod +x paqet
sudo mv paqet /usr/local/bin/
```

### 2️⃣ ویرایش کانفیگ‌ها:

**روی سرور کلاینت:** فایل `config_client.yaml` رو باز کن و این قسمت‌ها رو ویرایش کن:
- `network.interface`: نام اینترفیس (مثلا eth0)
- `network.local_addr`: آی‌پی سرور کلاینت با پورت 0 (مثلا 192.168.1.100:0)
- `network.router_mac`: MAC آدرس روتر
- `server.addr`: آی‌پی سرور اصلی و پورت (مثلا 203.0.113.10:9999)

**روی سرور اصلی:** فایل `config_server.yaml` رو باز کن و این قسمت‌ها رو ویرایش کن:
- `network.interface`: نام اینترفیس
- `network.local_addr`: آی‌پی سرور اصلی و پورت (مثلا 10.0.0.100:9999)
- `network.router_mac`: MAC آدرس روتر
- `listen.addr`: پورت گوش دادن (مثلا :9999)

**نکته مهم:** کلید رمزنگاری (`transport.kcp.key`) باید در هر دو فایل یکسان باشه!

### 3️⃣ اعمال iptables (فقط روی سرور اصلی):

```bash
chmod +x iptables_rules.sh
sudo ./iptables_rules.sh
```

### 4️⃣ اجرا:

**روی سرور اصلی (اول):**
```bash
sudo paqet run -c config_server.yaml
```

**روی سرور کلاینت (بعد):**
```bash
sudo paqet run -c config_client.yaml
```

### 5️⃣ تست:

```bash
curl -x socks5://127.0.0.1:1080 http://httpbin.org/ip
```

اگه جواب گرفت، یعنی همه چیز درسته! 🎉

## 🔑 نکات مهم:

- ✅ کلید رمزنگاری (`transport.kcp.key`) در هر دو فایل یکسان باشه
- ✅ پورت اتصال: **9999** (یا هر پورت دیگه‌ای که انتخاب کردی)
- ✅ SOCKS5 روی: **127.0.0.1:1080**
- ✅ اول سرور اصلی رو اجرا کن، بعد سرور کلاینت
- ✅ MAC آدرس روتر رو درست وارد کن

---

برای اطلاعات بیشتر و راهنمای کامل، `README.md` رو بخون! 📖
