#!/bin/bash
# دستورات iptables برای سرور B
# این اسکریپت جلوی ارسال پکت‌های RST توسط سیستم‌عامل رو می‌گیره

PORT=9999  # پورت listen سرور (اگه تغییر دادی، اینجا هم تغییر بده)

echo "در حال اعمال قوانین iptables برای جلوگیری از RST packets روی پورت $PORT..."

# 1. دور زدن connection tracking (conntrack) برای پورت اتصال - این خیلی مهمه!
# این به کرنل می‌گه که پکت‌های این پورت رو برای state tracking نادیده بگیره
sudo iptables -t raw -A PREROUTING -p tcp --dport $PORT -j NOTRACK
sudo iptables -t raw -A OUTPUT -p tcp --sport $PORT -j NOTRACK

# 2. جلوگیری از ارسال پکت‌های TCP RST که می‌تونن session رو kill کنن
# این هر پکت RST که کرنل می‌خواد از پورت اتصال بفرسته رو drop می‌کنه
sudo iptables -t mangle -A OUTPUT -p tcp --sport $PORT --tcp-flags RST RST -j DROP

# جایگزین برای قانون 2 اگه مشکل ادامه داشت:
sudo iptables -t filter -A INPUT -p tcp --dport $PORT -j ACCEPT
sudo iptables -t filter -A OUTPUT -p tcp --sport $PORT -j ACCEPT

# ذخیره تنظیمات iptables (برای سیستم‌های مبتنی بر Debian/Ubuntu)
if command -v iptables-save &> /dev/null; then
    sudo mkdir -p /etc/iptables
    sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
    echo "✓ قوانین iptables ذخیره شدند در /etc/iptables/rules.v4"
fi

# برای سیستم‌های مبتنی بر RedHat/CentOS
if [ -f /etc/redhat-release ]; then
    sudo service iptables save 2>/dev/null || sudo iptables-save > /etc/sysconfig/iptables
    echo "✓ قوانین iptables ذخیره شدند"
fi

echo "✓ قوانین iptables با موفقیت اعمال شدند!"
echo ""
echo "برای بررسی قوانین اعمال شده، دستور زیر رو اجرا کن:"
echo "sudo iptables -L -n -v"
echo "sudo iptables -t raw -L -n -v"
echo "sudo iptables -t mangle -L -n -v"
