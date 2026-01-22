#!/bin/bash

# Paqet Setup Launcher
# این اسکریپت فقط زبان رو می‌پرسه و اسکریپت مربوطه رو اجرا می‌کنه

clear
echo "╔════════════════════════════════════════════════════════╗"
echo "║     Paqet - Interactive Setup / راه‌اندازی تعاملی   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Select Language / انتخاب زبان:"
echo "  1) فارسی (Persian)"
echo "  2) English"
read -p "Choose [1/2]: " lang_choice

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$lang_choice" == "1" ]]; then
    if [ -f "$SCRIPT_DIR/setup_fa.sh" ]; then
        bash "$SCRIPT_DIR/setup_fa.sh"
    else
        echo "❌ فایل setup_fa.sh پیدا نشد!"
        exit 1
    fi
elif [[ "$lang_choice" == "2" ]]; then
    if [ -f "$SCRIPT_DIR/setup_en.sh" ]; then
        bash "$SCRIPT_DIR/setup_en.sh"
    else
        echo "❌ File setup_en.sh not found!"
        exit 1
    fi
else
    echo "❌ Invalid selection! / انتخاب نامعتبر!"
    exit 1
fi
