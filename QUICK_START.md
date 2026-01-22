# راهنمای سریع Paqet ⚡

این یک راهنمای خیلی کوتاه و سریع برای راه‌اندازی paqet است.

## 📁 فایل‌های موجود:

- `config_client.yaml` - کانفیگ سرور A (کلاینت)
- `config_server.yaml` - کانفیگ سرور B (سرور)
- `iptables_rules.sh` - اسکریپت اعمال قوانین iptables
- `README.md` - راهنمای کامل و جامع

## 🎯 مراحل سریع:

### 1️⃣ نصب Paqet (روی هر دو سرور):

```bash
wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet
chmod +x paqet
sudo mv paqet /usr/local/bin/
```

### 2️⃣ ویرایش کانفیگ‌ها:

**روی سرور A:** `config_client.yaml`
- `interface`: نام اینترفیس (مثلا eth0)
- `gateway_mac`: MAC روتر
- `remote_addr`: آی‌پی سرور B:9999

**روی سرور B:** `config_server.yaml`
- `interface`: نام اینترفیس
- `gateway_mac`: MAC روتر
- `target`: پورت محلی (مثلا 127.0.0.1:8080)

### 3️⃣ اعمال iptables (فقط روی سرور B):

```bash
sudo ./iptables_rules.sh
```

### 4️⃣ اجرا:

**روی سرور B (اول):**
```bash
sudo paqet -c config_server.yaml
```

**روی سرور A (بعد):**
```bash
sudo paqet -c config_client.yaml
```

### 5️⃣ تست:

```bash
curl -x socks5://127.0.0.1:1080 http://httpbin.org/ip
```

## 🔑 نکات مهم:

- ✅ کلید رمزنگاری (`secret`) در هر دو فایل یکسان است
- ✅ پورت اتصال: **9999**
- ✅ SOCKS5 روی: **127.0.0.1:1080**
- ✅ اول سرور B رو اجرا کن، بعد سرور A

---

برای اطلاعات بیشتر، `README.md` رو بخون! 📖
