#!/bin/bash
# اسکریپت راه‌اندازی سریع Paqet

echo "🚀 راه‌اندازی سریع Paqet"
echo "=========================="
echo ""

# تشخیص نوع سرور
read -p "این سرور کلاینت است (A) یا سرور (B)? [A/B]: " server_type

if [[ "$server_type" == "A" || "$server_type" == "a" ]]; then
    echo "✓ حالت کلاینت انتخاب شد"
    CONFIG_FILE="config_client.yaml"
    SERVER_NAME="کلاینت"
elif [[ "$server_type" == "B" || "$server_type" == "b" ]]; then
    echo "✓ حالت سرور انتخاب شد"
    CONFIG_FILE="config_server.yaml"
    SERVER_NAME="سرور"
    
    # اعمال iptables روی سرور B
    echo ""
    echo "📋 اعمال قوانین iptables..."
    if [ -f "iptables_rules.sh" ]; then
        chmod +x iptables_rules.sh
        sudo ./iptables_rules.sh
    else
        echo "⚠️  فایل iptables_rules.sh پیدا نشد!"
    fi
else
    echo "❌ انتخاب نامعتبر!"
    exit 1
fi

# چک کردن وجود فایل کانفیگ
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ فایل $CONFIG_FILE پیدا نشد!"
    exit 1
fi

# چک کردن وجود paqet
if ! command -v paqet &> /dev/null; then
    echo ""
    echo "📥 Paqet پیدا نشد. در حال دانلود..."
    wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet
    chmod +x paqet
    sudo mv paqet /usr/local/bin/paqet
    echo "✓ Paqet نصب شد"
fi

echo ""
echo "✅ همه چیز آماده است!"
echo ""
echo "برای اجرای $SERVER_NAME، دستور زیر را اجرا کن:"
echo "sudo paqet -c $CONFIG_FILE"
echo ""
echo "یا برای اجرا در پس‌زمینه با screen:"
echo "screen -S paqet sudo paqet -c $CONFIG_FILE"
echo ""
