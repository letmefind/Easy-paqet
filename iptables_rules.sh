#!/bin/bash
# دستورات iptables برای سرور B
# این اسکریپت جلوی ارسال پکت‌های RST توسط سیستم‌عامل رو می‌گیره

echo "در حال اعمال قوانین iptables برای جلوگیری از RST packets..."

# جلوگیری از ارسال پکت‌های RST در OUTPUT chain
sudo iptables -A OUTPUT -p tcp --tcp-flags RST RST -j DROP

# جلوگیری از ارسال پکت‌های RST در FORWARD chain (اگر از forwarding استفاده می‌کنی)
sudo iptables -A FORWARD -p tcp --tcp-flags RST RST -j DROP

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
