#!/bin/bash

# Paqet - Unified Management Script / اسکریپت مدیریتی یکپارچه
# Bilingual: English & Persian / دو زبانه: انگلیسی و فارسی

# غیرفعال کردن set -e برای جلوگیری از خروج زودهنگام در دستورات تعاملی
# set -e

export LC_ALL=C.UTF-8 2>/dev/null || export LANG=C.UTF-8 2>/dev/null

# رنگ‌ها و نمادها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# نمادها
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
WARN="${YELLOW}⚠${NC}"
INFO="${BLUE}ℹ${NC}"
ARROW="${CYAN}→${NC}"

# متغیرهای سراسری
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAQET_BINARY=""
CONFIG_DIR="/etc/paqet"
SERVICE_DIR="/etc/systemd/system"
PACKAGE_DIR="/root/paqet-packages"
LANG_SELECTED=""

# متغیرهای زبان - فارسی
declare -A MSG_FA
MSG_FA[title]="Paqet Manager - مدیریت یکپارچه"
MSG_FA[menu_title]="منوی اصلی"
MSG_FA[setup_server]="راه‌اندازی سرور خارج"
MSG_FA[setup_client]="راه‌اندازی کلاینت ایران"
MSG_FA[manage_configs]="مدیریت کانفیگ‌ها"
MSG_FA[manage_services]="مدیریت سرویس‌ها"
MSG_FA[manage_logs]="مدیریت لاگ‌ها"
MSG_FA[mtu_discovery]="یافتن MTU بهینه"
MSG_FA[exit]="خروج"
MSG_FA[paqet_installed]="Paqet نصب شده است"
MSG_FA[paqet_not_installed]="Paqet نصب نشده است (خودکار نصب می‌شود)"
MSG_FA[select_lang]="انتخاب زبان / Select Language"
MSG_FA[lang_fa]="فارسی (Persian)"
MSG_FA[lang_en]="English"
MSG_FA[invalid_choice]="انتخاب نامعتبر"
MSG_FA[press_enter]="برای ادامه Enter را فشار دهید"
MSG_FA[goodbye]="خداحافظ! 👋"

# متغیرهای زبان - انگلیسی
declare -A MSG_EN
MSG_EN[title]="Paqet Manager - Unified Management"
MSG_EN[menu_title]="Main Menu"
MSG_EN[setup_server]="Setup Foreign Server"
MSG_EN[setup_client]="Setup Iran Client"
MSG_EN[manage_configs]="Manage Configs"
MSG_EN[manage_services]="Manage Services"
MSG_EN[manage_logs]="Manage Logs"
MSG_EN[mtu_discovery]="Find Optimal MTU"
MSG_EN[exit]="Exit"
MSG_EN[paqet_installed]="Paqet is installed"
MSG_EN[paqet_not_installed]="Paqet is not installed (will auto-install)"
MSG_EN[select_lang]="Select Language / انتخاب زبان"
MSG_EN[lang_fa]="Persian (فارسی)"
MSG_EN[lang_en]="English"
MSG_EN[invalid_choice]="Invalid choice"
MSG_EN[press_enter]="Press Enter to continue"
MSG_EN[goodbye]="Goodbye! 👋"

# تابع انتخاب زبان
select_language() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}          ${BOLD}${GREEN}Paqet Manager${NC}${BOLD}                                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Select Language / انتخاب زبان:${NC}"
    echo ""
    echo -e "  ${CYAN}1${NC}) ${BOLD}فارسی${NC} (Persian)"
    echo -e "  ${CYAN}2${NC}) ${BOLD}English${NC}"
    echo ""
    
    # خواندن از stdin (که در main به /dev/tty redirect شده)
    read -p "Choose / انتخاب [1/2]: " LANG_CHOICE
    
    case "$LANG_CHOICE" in
        1|fa|persian|فارسی)
            LANG_SELECTED="fa"
            ;;
        2|en|english|انگلیسی)
            LANG_SELECTED="en"
            ;;
        *)
            LANG_SELECTED="fa"  # پیش‌فرض فارسی
            ;;
    esac
}

# تابع‌های ترجمه
t() {
    local key="$1"
    if [ "$LANG_SELECTED" == "en" ]; then
        echo -n "${MSG_EN[$key]}"
    else
        echo -n "${MSG_FA[$key]}"
    fi
}

# تابع خواندن ورودی از terminal واقعی
read_input() {
    local prompt="$1"
    local var_name="$2"
    local default_value="${3:-}"
    
    # همیشه از /dev/tty بخوان
    if [ -t 0 ] && [ -t 1 ]; then
        # اگر هر دو stdin و stdout terminal هستند، از stdin استفاده کن
        if [ -n "$default_value" ]; then
            read -p "$prompt [$default_value]: " "$var_name" < /dev/tty
        else
            read -p "$prompt: " "$var_name" < /dev/tty
        fi
    else
        # اگر stdin pipe است، از /dev/tty استفاده کن
        if [ -n "$default_value" ]; then
            echo -n "$prompt [$default_value]: " > /dev/tty
            read "$var_name" < /dev/tty
        else
            echo -n "$prompt: " > /dev/tty
            read "$var_name" < /dev/tty
        fi
    fi
    
    # اگر خالی بود و default وجود داشت، از default استفاده کن
    if [ -z "${!var_name}" ] && [ -n "$default_value" ]; then
        eval "$var_name=\"$default_value\""
    fi
}

# تابع‌های کمکی
print_header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}          ${BOLD}${GREEN}$(t title)${NC}${BOLD}                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() { echo -e "${CHECK} ${GREEN}$1${NC}"; }
print_error() { echo -e "${CROSS} ${RED}$1${NC}"; }
print_warning() { echo -e "${WARN} ${YELLOW}$1${NC}"; }
print_info() { echo -e "${INFO} ${BLUE}$1${NC}"; }
print_step() { echo -e "${ARROW} ${CYAN}$1${NC}"; }

print_separator() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_box() {
    local title="$1"
    local content="$2"
    echo -e "${CYAN}┌─${NC} ${BOLD}${title}${NC}"
    echo -e "${CYAN}│${NC} ${content}"
    echo -e "${CYAN}└${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_error "This script must be run as root"
            echo ""
            echo "Usage: ${BOLD}sudo $0${NC}"
        else
            print_error "این اسکریپت باید با دسترسی root اجرا شود"
            echo ""
            echo "استفاده: ${BOLD}sudo $0${NC}"
        fi
        exit 1
    fi
}

detect_architecture() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) echo "amd64" ;;
    esac
}

check_paqet_installed() {
    if command -v paqet &> /dev/null; then
        PAQET_BINARY=$(command -v paqet)
        return 0
    elif [ -f "$SCRIPT_DIR/paqet" ]; then
        PAQET_BINARY="$SCRIPT_DIR/paqet"
        return 0
    elif [ -f "/usr/local/bin/paqet" ]; then
        PAQET_BINARY="/usr/local/bin/paqet"
        return 0
    elif [ -d "/root/paqet" ]; then
        PAQET_FILE=$(find /root/paqet -name "paqet" -type f 2>/dev/null | head -1)
        if [ -n "$PAQET_FILE" ]; then
            PAQET_BINARY="$PAQET_FILE"
            return 0
        fi
    fi
    return 1
}

auto_install_paqet() {
    if [ "$LANG_SELECTED" == "en" ]; then
        print_step "Installing Paqet..."
    else
        print_step "در حال نصب Paqet..."
    fi
    
    # بررسی وجود در /root/paqet
    if [ -d "/root/paqet" ]; then
        TAR_FILE=$(find /root/paqet -name "paqet-linux-*.tar.gz" | head -1)
        BIN_FILE=$(find /root/paqet -name "paqet" -type f | head -1)
        
        if [ -n "$TAR_FILE" ]; then
            TEMP_DIR=$(mktemp -d)
            tar -xzf "$TAR_FILE" -C "$TEMP_DIR" 2>/dev/null
            # جستجوی فایل paqet با الگوهای مختلف
            PAQET_FILE=$(find "$TEMP_DIR" -type f \( -name "paqet" -o -name "paqet-*" -o -name "paqet_*" \) ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.md" ! -name "*.yaml" ! -name "*.sh" 2>/dev/null | head -1)
            # اگر پیدا نشد، همه فایل‌های قابل اجرا را بررسی کن
            if [ -z "$PAQET_FILE" ]; then
                PAQET_FILE=$(find "$TEMP_DIR" -type f -executable ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.md" ! -name "*.yaml" ! -name "*.sh" ! -name "*.txt" 2>/dev/null | head -1)
            fi
            if [ -n "$PAQET_FILE" ]; then
                chmod +x "$PAQET_FILE"
                cp "$PAQET_FILE" /usr/local/bin/paqet
                rm -rf "$TEMP_DIR"
                if [ "$LANG_SELECTED" == "en" ]; then
                    print_success "Paqet installed from /root/paqet"
                else
                    print_success "Paqet از /root/paqet نصب شد"
                fi
                return 0
            fi
            rm -rf "$TEMP_DIR"
        elif [ -n "$BIN_FILE" ]; then
            chmod +x "$BIN_FILE"
            cp "$BIN_FILE" /usr/local/bin/paqet
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Paqet installed from /root/paqet"
            else
                print_success "Paqet از /root/paqet نصب شد"
            fi
            return 0
        fi
    fi
    
    # دانلود از GitHub
    ARCH=$(detect_architecture)
    if [ "$LANG_SELECTED" == "en" ]; then
        print_info "Architecture: $ARCH"
    else
        print_info "معماری: $ARCH"
    fi
    
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/hanselime/paqet/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "v1.0.0-alpha.13")
    FILENAME="paqet-linux-${ARCH}-${LATEST_RELEASE}.tar.gz"
    DOWNLOAD_URL="https://github.com/hanselime/paqet/releases/download/${LATEST_RELEASE}/${FILENAME}"
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    if [ "$LANG_SELECTED" == "en" ]; then
        print_info "Downloading: $FILENAME"
    else
        print_info "در حال دانلود: $FILENAME"
    fi
    
    if wget -q --show-progress "$DOWNLOAD_URL" -O "$FILENAME" 2>&1; then
        # استخراج فایل
        if [ "$LANG_SELECTED" == "en" ]; then
            print_info "Extracting archive..."
        else
            print_info "در حال استخراج فایل..."
        fi
        
        tar -xzf "$FILENAME" 2>/dev/null
        
        # جستجوی فایل paqet با الگوهای مختلف
        PAQET_FILE=$(find . -type f \( -name "paqet" -o -name "paqet-*" -o -name "paqet_*" \) ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.md" ! -name "*.yaml" ! -name "*.sh" 2>/dev/null | head -1)
        
        # اگر پیدا نشد، همه فایل‌های قابل اجرا را بررسی کن
        if [ -z "$PAQET_FILE" ]; then
            PAQET_FILE=$(find . -type f -executable ! -name "*.tar.gz" ! -name "*.zip" ! -name "*.md" ! -name "*.yaml" ! -name "*.sh" ! -name "*.txt" 2>/dev/null | head -1)
        fi
        
        # اگر هنوز پیدا نشد، لیست فایل‌های استخراج شده را نمایش بده
        if [ -z "$PAQET_FILE" ]; then
            if [ "$LANG_SELECTED" == "en" ]; then
                print_warning "Paqet binary not found. Extracted files:"
            else
                print_warning "فایل paqet پیدا نشد. فایل‌های استخراج شده:"
            fi
            find . -type f ! -name "*.tar.gz" ! -name "*.zip" 2>/dev/null | head -10
        else
            chmod +x "$PAQET_FILE"
            mv "$PAQET_FILE" /usr/local/bin/paqet
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Paqet installed"
            else
                print_success "Paqet نصب شد"
            fi
            cd "$SCRIPT_DIR"
            rm -rf "$TEMP_DIR"
            return 0
        fi
    else
        if [ "$LANG_SELECTED" == "en" ]; then
            print_error "Failed to download Paqet"
        else
            print_error "خطا در دانلود Paqet"
        fi
    fi
    
    cd "$SCRIPT_DIR"
    rm -rf "$TEMP_DIR"
    if [ "$LANG_SELECTED" == "en" ]; then
        print_error "Failed to install Paqet. Please check the download URL or try manual installation."
    else
        print_error "خطا در نصب Paqet. لطفاً URL دانلود را بررسی کنید یا نصب دستی را امتحان کنید."
    fi
    return 1
}

auto_install_prerequisites() {
    if [ "$LANG_SELECTED" == "en" ]; then
        print_step "Installing prerequisites..."
    else
        print_step "در حال نصب prerequisites..."
    fi
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        if [ "$LANG_SELECTED" == "en" ]; then
            print_warning "Cannot detect distribution"
        else
            print_warning "نمی‌توان توزیع را تشخیص داد"
        fi
        return 0
    fi
    
    case "$OS" in
        ubuntu|debian)
            apt-get update -qq > /dev/null 2>&1
            apt-get install -y libpcap-dev iptables curl wget openssl iproute2 net-tools > /dev/null 2>&1
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y libpcap-devel iptables curl wget openssl iproute net-tools > /dev/null 2>&1
            else
                yum install -y libpcap-devel iptables curl wget openssl iproute net-tools > /dev/null 2>&1
            fi
            ;;
    esac
    
    if [ "$LANG_SELECTED" == "en" ]; then
        print_success "Prerequisites installed"
    else
        print_success "Prerequisites نصب شدند"
    fi
}

optimize_for_users() {
    local USER_COUNT="$1"
    
    if [ "$USER_COUNT" -lt 50 ]; then
        # زیر 50 کاربر - تنظیمات پایه (با buffer های کافی برای جلوگیری از overflow)
        KCP_MODE="fast"
        KCP_CONN=1
        KCP_RCVWND=1024           # افزایش از 512 به 1024 برای جلوگیری از buffer overflow
        KCP_SNDWND=1024           # افزایش از 512 به 1024 برای جلوگیری از buffer overflow
        KCP_SMUXBUF=8388608       # 8MB - افزایش از 4MB برای جلوگیری از buffer overflow
        KCP_STREAMBUF=4194304     # 4MB - افزایش از 2MB برای جلوگیری از buffer overflow
        PCAP_SOCKBUF_CLIENT=8388608   # 8MB - افزایش از 4MB برای جلوگیری از buffer overflow
        PCAP_SOCKBUF_SERVER=16777216  # 16MB - افزایش از 8MB برای جلوگیری از buffer overflow
    elif [ "$USER_COUNT" -lt 100 ]; then
        # 50-100 کاربر - تنظیمات متوسط-پایین
        KCP_MODE="fast"
        KCP_CONN=1
        KCP_RCVWND=1536           # افزایش برای جلوگیری از buffer overflow
        KCP_SNDWND=1536           # افزایش برای جلوگیری از buffer overflow
        KCP_SMUXBUF=12582912      # 12MB - افزایش برای جلوگیری از buffer overflow
        KCP_STREAMBUF=6291456     # 6MB - افزایش برای جلوگیری از buffer overflow
        PCAP_SOCKBUF_CLIENT=12582912  # 12MB - افزایش برای جلوگیری از buffer overflow
        PCAP_SOCKBUF_SERVER=25165824  # 24MB - افزایش برای جلوگیری از buffer overflow
    elif [ "$USER_COUNT" -lt 300 ]; then
        # 100-300 کاربر - تنظیمات متوسط
        # بافرهای متوسط برای جلوگیری از خطای "No buffer space available"
        KCP_MODE="fast2"
        KCP_CONN=2
        KCP_RCVWND=2048           # افزایش از 1024 به 2048 برای جلوگیری از خطای buffer space
        KCP_SNDWND=2048           # افزایش از 1024 به 2048 برای جلوگیری از خطای buffer space
        KCP_SMUXBUF=16777216      # 16MB - افزایش از 8MB برای جلوگیری از خطای buffer space
        KCP_STREAMBUF=8388608     # 8MB - افزایش از 4MB برای جلوگیری از خطای buffer space
        PCAP_SOCKBUF_CLIENT=16777216  # 16MB - افزایش از 8MB برای جلوگیری از خطای buffer space
        PCAP_SOCKBUF_SERVER=33554432  # 32MB - افزایش از 16MB برای جلوگیری از خطای buffer space
    else
        # بالای 300 کاربر - تنظیمات پیشرفته (بهینه شده برای ترافیک بالا)
        # بافرهای بزرگ برای جلوگیری از خطای "No buffer space available"
        KCP_MODE="fast3"
        KCP_CONN=4
        KCP_RCVWND=8192           # افزایش از 4096 به 8192 برای جلوگیری از خطای buffer space
        KCP_SNDWND=8192           # افزایش از 4096 به 8192 برای جلوگیری از خطای buffer space
        KCP_SMUXBUF=67108864      # 64MB - افزایش از 32MB برای جلوگیری از خطای buffer space
        KCP_STREAMBUF=33554432    # 32MB - افزایش از 16MB برای جلوگیری از خطای buffer space
        PCAP_SOCKBUF_CLIENT=67108864  # 64MB - افزایش از 32MB برای جلوگیری از خطای buffer space
        PCAP_SOCKBUF_SERVER=104857600 # 100MB - حداکثر مجاز paqet (افزایش از 64MB برای جلوگیری از خطای buffer space)
    fi
}

# بهینه‌سازی شبکه (BBR و TCP optimizations)
optimize_network() {
    if [ "$LANG_SELECTED" == "en" ]; then
        print_step "Optimizing network settings (BBR, TCP, sysctl)..."
    else
        print_step "بهینه‌سازی تنظیمات شبکه (BBR, TCP, sysctl)..."
    fi
    
    # بررسی و فعال کردن BBR
    if [ -f /proc/sys/net/ipv4/tcp_congestion_control ]; then
        CURRENT_CC=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo "")
        if [ "$CURRENT_CC" != "bbr" ]; then
            # بررسی وجود BBR
            if lsmod 2>/dev/null | grep -q tcp_bbr || modprobe tcp_bbr 2>/dev/null; then
                echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf 2>/dev/null || true
                echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf 2>/dev/null || true
                sysctl -w net.core.default_qdisc=fq > /dev/null 2>&1 || true
                sysctl -w net.ipv4.tcp_congestion_control=bbr > /dev/null 2>&1 || true
                if [ "$LANG_SELECTED" == "en" ]; then
                    print_success "BBR enabled"
                else
                    print_success "BBR فعال شد"
                fi
            else
                if [ "$LANG_SELECTED" == "en" ]; then
                    print_warning "BBR module not available (kernel >= 4.9 required)"
                else
                    print_warning "ماژول BBR در دسترس نیست (نیاز به kernel >= 4.9)"
                fi
            fi
        else
            if [ "$LANG_SELECTED" == "en" ]; then
                print_info "BBR already enabled"
            else
                print_info "BBR قبلاً فعال است"
            fi
        fi
    fi
    
    # اگر APPLY_SYSCTL خالی است، از کاربر بپرس
    if [ -z "$APPLY_SYSCTL" ]; then
        echo ""
        if [ "$LANG_SELECTED" == "en" ]; then
            echo -e "${YELLOW}⚠ Note:${NC} You may already have sysctl settings configured."
            echo -e "Do you want to apply Paqet's sysctl optimizations?"
            echo -e "  ${CYAN}1${NC}) Yes - Apply sysctl optimizations (recommended for high traffic)"
            echo -e "  ${CYAN}2${NC}) No - Skip sysctl (use your existing settings)"
            read -p "Choose [1/2] (default: 2): " APPLY_SYSCTL < /dev/tty
        else
            echo -e "${YELLOW}⚠ توجه:${NC} ممکن است شما قبلاً تنظیمات sysctl داشته باشید."
            echo -e "آیا می‌خواهید بهینه‌سازی‌های sysctl Paqet اعمال شوند؟"
            echo -e "  ${CYAN}1${NC}) بله - اعمال بهینه‌سازی‌های sysctl (پیشنهاد برای ترافیک بالا)"
            echo -e "  ${CYAN}2${NC}) خیر - رد کردن sysctl (استفاده از تنظیمات موجود شما)"
            read -p "انتخاب [1/2] (پیش‌فرض: 2): " APPLY_SYSCTL < /dev/tty
        fi
        APPLY_SYSCTL="${APPLY_SYSCTL:-2}"
    fi
    
    # اعمال sysctl فقط اگر کاربر بخواهد
    if [ "$APPLY_SYSCTL" = "1" ]; then
        # حذف تنظیمات قبلی Paqet از sysctl.conf (اگر وجود داشته باشد)
        if grep -q "# Paqet Network Optimizations" /etc/sysctl.conf 2>/dev/null; then
            if [ "$LANG_SELECTED" == "en" ]; then
                print_info "Removing previous Paqet sysctl settings..."
            else
                print_info "حذف تنظیمات قبلی sysctl Paqet..."
            fi
            
            # حذف بخش Paqet از sysctl.conf
            # استفاده از sed برای حذف از "# Paqet Network Optimizations" تا خط خالی بعد از آخرین خط Paqet
            # پیدا کردن خط شروع و پایان بخش Paqet
            local start_line=$(grep -n "# Paqet Network Optimizations" /etc/sysctl.conf 2>/dev/null | cut -d: -f1 | head -1)
            if [ -n "$start_line" ]; then
                # پیدا کردن خط خالی بعد از بخش Paqet (یا خط بعد از "# net.ipv4.ip_forward")
                local end_line=$(awk -v start="$start_line" 'NR>=start && /^# net\.ipv4\.ip_forward = 1$/ {print NR+1; exit}' /etc/sysctl.conf 2>/dev/null)
                if [ -z "$end_line" ]; then
                    # اگر پیدا نشد، خط خالی بعدی را پیدا کن
                    end_line=$(awk -v start="$start_line" 'NR>start && /^$/ {print NR; exit}' /etc/sysctl.conf 2>/dev/null)
                fi
                if [ -z "$end_line" ]; then
                    # اگر هنوز پیدا نشد، تا انتهای فایل
                    end_line=$(wc -l < /etc/sysctl.conf 2>/dev/null || echo "0")
                fi
                
                # حذف خطوط از start_line تا end_line
                if [ -n "$start_line" ] && [ -n "$end_line" ] && [ "$start_line" -le "$end_line" ]; then
                    sed -i "${start_line},${end_line}d" /etc/sysctl.conf 2>/dev/null || \
                    awk -v start="$start_line" -v end="$end_line" 'NR < start || NR > end' /etc/sysctl.conf > /tmp/sysctl.conf.tmp 2>/dev/null && mv /tmp/sysctl.conf.tmp /etc/sysctl.conf 2>/dev/null || true
                fi
            fi
            
            # حذف خطوط خالی اضافی در انتها
            sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' /etc/sysctl.conf 2>/dev/null || \
            sed -i '/^$/N;/^\n$/d' /etc/sysctl.conf 2>/dev/null || true
        fi
        
        # بهینه‌سازی‌های TCP برای ترافیک بالا و شبکه‌های با اختلال
        # این تنظیمات همچنین از خطای "No buffer space available" جلوگیری می‌کند
        if [ "$LANG_SELECTED" == "en" ]; then
            print_info "Applying sysctl optimizations..."
        else
            print_info "اعمال بهینه‌سازی‌های sysctl..."
        fi
        
        cat >> /etc/sysctl.conf <<'SYSCTL_EOF' 2>/dev/null || true

# Paqet Network Optimizations - بهینه‌سازی‌های شبکه Paqet
# TCP optimizations for high traffic and unstable networks
# این تنظیمات از خطای "No buffer space available" جلوگیری می‌کند
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 8192
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_syncookies = 1

# Buffer sizes for high traffic - جلوگیری از خطای "No buffer space available"
# این تنظیمات برای جلوگیری از پر شدن بافرها در ترافیک بالا ضروری است
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 134217728
net.core.wmem_default = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# Connection tracking optimizations
net.netfilter.nf_conntrack_max = 1000000
net.netfilter.nf_conntrack_tcp_timeout_established = 1200

# IP forwarding (if needed)
# net.ipv4.ip_forward = 1
SYSCTL_EOF
            
        # اعمال تنظیمات (با مدیریت خطا)
        if sysctl -p > /dev/null 2>&1; then
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Sysctl optimizations applied"
            else
                print_success "بهینه‌سازی‌های sysctl اعمال شد"
            fi
        else
            if [ "$LANG_SELECTED" == "en" ]; then
                print_warning "Some sysctl optimizations may not be applied (check sysctl.conf)"
            else
                print_warning "برخی از بهینه‌سازی‌های sysctl ممکن است اعمال نشده باشند (sysctl.conf را بررسی کنید)"
            fi
        fi
    else
        if [ "$LANG_SELECTED" == "en" ]; then
            print_info "Skipping sysctl optimizations (using existing settings)"
        else
            print_info "رد کردن بهینه‌سازی‌های sysctl (استفاده از تنظیمات موجود)"
        fi
    fi
    
    echo ""
    
    # فعال کردن مجدد set -e (اما فقط اگر در ابتدای اسکریپت فعال بود)
    # set -e
}

get_network_info() {
    # غیرفعال کردن set -e برای این تابع (دستورات read ممکن است fail شوند)
    set +e
    
    print_separator
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        print_info "Gathering network information..."
    else
        print_info "جمع‌آوری اطلاعات شبکه..."
    fi
    echo ""
    
    # پیدا کردن اینترفیس
    INTERFACES=($(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -v lo || true))
    if [ ${#INTERFACES[@]} -eq 0 ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_error "No network interface found"
            read -p "Enter interface name manually: " INTERFACE < /dev/tty
        else
            print_error "اینترفیس شبکه پیدا نشد"
            read -p "نام اینترفیس را دستی وارد کنید: " INTERFACE < /dev/tty
        fi
        if [ -z "$INTERFACE" ]; then
            if [ "$LANG_SELECTED" == "en" ]; then
                print_error "Interface name is required"
                return 1
            else
                print_error "نام اینترفیس الزامی است"
                return 1
            fi
        fi
    else
        INTERFACE="${INTERFACES[0]}"
        if [ ${#INTERFACES[@]} -gt 1 ]; then
            if [ "$LANG_SELECTED" == "en" ]; then
                echo "Available interfaces:"
            else
                echo "اینترفیس‌های موجود:"
            fi
            for i in "${!INTERFACES[@]}"; do
                echo -e "  ${CYAN}$((i+1))${NC}) ${INTERFACES[$i]}"
            done
            echo ""
            if [ "$LANG_SELECTED" == "en" ]; then
                read -p "Select interface [1]: " IFACE_CHOICE < /dev/tty
            else
                read -p "اینترفیس را انتخاب کنید [1]: " IFACE_CHOICE < /dev/tty
            fi
            IFACE_CHOICE=${IFACE_CHOICE:-1}
            if [ "$IFACE_CHOICE" -ge 1 ] && [ "$IFACE_CHOICE" -le ${#INTERFACES[@]} ]; then
                INTERFACE="${INTERFACES[$((IFACE_CHOICE-1))]}"
            fi
        fi
    fi
    
    if [ "$LANG_SELECTED" == "en" ]; then
        print_success "Interface: $INTERFACE"
    else
        print_success "اینترفیس: $INTERFACE"
    fi
    
    # پیدا کردن IP محلی
    LOCAL_IP=$(ip -4 addr show $INTERFACE 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1 || true)
    if [ -z "$LOCAL_IP" ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            read -p "Enter local IP: " LOCAL_IP < /dev/tty
        else
            read -p "IP محلی را وارد کنید: " LOCAL_IP < /dev/tty
        fi
    else
        if [ "$LANG_SELECTED" == "en" ]; then
            echo -e "${CHECK} Local IP found: ${BOLD}$LOCAL_IP${NC}"
            read -p "Is this correct? [Y/n]: " CONFIRM < /dev/tty
        else
            echo -e "${CHECK} IP محلی پیدا شد: ${BOLD}$LOCAL_IP${NC}"
            read -p "آیا درست است؟ [Y/n]: " CONFIRM < /dev/tty
        fi
        if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
            if [ "$LANG_SELECTED" == "en" ]; then
                read -p "Enter local IP: " LOCAL_IP < /dev/tty
            else
                read -p "IP محلی را وارد کنید: " LOCAL_IP < /dev/tty
            fi
        fi
    fi
    
    # پیدا کردن MAC روتر
    GATEWAY_IP=$(ip route 2>/dev/null | grep default | awk '{print $3}' | head -1 || true)
    if [ -n "$GATEWAY_IP" ]; then
        ping -c 1 -W 1 $GATEWAY_IP > /dev/null 2>&1 || true
        sleep 1
        ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1 || true)
        if [ -n "$ROUTER_MAC" ]; then
            if [ "$LANG_SELECTED" == "en" ]; then
                echo -e "${CHECK} Router MAC found: ${BOLD}$ROUTER_MAC${NC}"
                read -p "Is this correct? [Y/n]: " CONFIRM < /dev/tty
            else
                echo -e "${CHECK} MAC روتر پیدا شد: ${BOLD}$ROUTER_MAC${NC}"
                read -p "آیا درست است؟ [Y/n]: " CONFIRM < /dev/tty
            fi
            if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
                if [ "$LANG_SELECTED" == "en" ]; then
                    read -p "Enter router MAC address: " ROUTER_MAC < /dev/tty
                else
                    read -p "MAC آدرس روتر را وارد کنید: " ROUTER_MAC < /dev/tty
                fi
            fi
        else
            if [ "$LANG_SELECTED" == "en" ]; then
                read -p "Enter router MAC address: " ROUTER_MAC < /dev/tty
            else
                read -p "MAC آدرس روتر را وارد کنید: " ROUTER_MAC < /dev/tty
            fi
        fi
    else
        if [ "$LANG_SELECTED" == "en" ]; then
            read -p "Enter router MAC address: " ROUTER_MAC < /dev/tty
        else
            read -p "MAC آدرس روتر را وارد کنید: " ROUTER_MAC < /dev/tty
        fi
    fi
    
    echo ""
}

create_client_package() {
    local TUNNEL_NAME="$1"
    local SERVER_IP="$2"
    local SERVER_PORT="$3"
    local SECRET_KEY="$4"
    
    print_separator
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        print_info "Creating client package for Iran server..."
    else
        print_info "در حال ساخت پکیج برای کلاینت ایران..."
    fi
    echo ""
    
    mkdir -p "$PACKAGE_DIR"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    PACKAGE_NAME="paqet-client-${TUNNEL_NAME}-${TIMESTAMP}"
    PACKAGE_PATH="$PACKAGE_DIR/$PACKAGE_NAME"
    ARCHIVE_NAME="${PACKAGE_NAME}.tar.gz"
    
    rm -rf "$PACKAGE_PATH"
    mkdir -p "$PACKAGE_PATH"
    
    # کپی paqet binary
    if [ -f "$PAQET_BINARY" ]; then
        cp "$PAQET_BINARY" "$PACKAGE_PATH/paqet"
        chmod +x "$PACKAGE_PATH/paqet"
        if [ "$LANG_SELECTED" == "en" ]; then
            print_success "Paqet binary copied"
        else
            print_success "فایل paqet کپی شد"
        fi
    fi
    
    # ساخت فایل اطلاعات
    cat > "$PACKAGE_PATH/server_info.txt" <<EOF
# Server Information / اطلاعات سرور
SERVER_IP=$SERVER_IP
SERVER_PORT=$SERVER_PORT
TUNNEL_NAME=$TUNNEL_NAME
SECRET_KEY=$SECRET_KEY
LANG=$LANG_SELECTED
EOF
    chmod 600 "$PACKAGE_PATH/server_info.txt"
    
    # ساخت اسکریپت نصب خودکار (دو زبانه)
    cat > "$PACKAGE_PATH/install.sh" <<'INSTALL_EOF'
#!/bin/bash

# Auto-install script for Paqet Client / اسکریپت نصب خودکار کلاینت Paqet

# غیرفعال کردن set -e برای جلوگیری از خروج زودهنگام در دستورات تعاملی
# set -e

export LC_ALL=C.UTF-8 2>/dev/null || export LANG=C.UTF-8 2>/dev/null

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# تابع بهینه‌سازی بر اساس تعداد کاربران
optimize_for_users() {
    local USER_COUNT="$1"
    
    if [ "$USER_COUNT" -lt 50 ]; then
        # زیر 50 کاربر - تنظیمات پایه (با buffer های کافی برای جلوگیری از overflow)
        KCP_MODE="fast"
        KCP_CONN=1
        KCP_RCVWND=1024           # افزایش از 512 به 1024 برای جلوگیری از buffer overflow
        KCP_SNDWND=1024           # افزایش از 512 به 1024 برای جلوگیری از buffer overflow
        KCP_SMUXBUF=8388608       # 8MB - افزایش از 4MB برای جلوگیری از buffer overflow
        KCP_STREAMBUF=4194304     # 4MB - افزایش از 2MB برای جلوگیری از buffer overflow
        PCAP_SOCKBUF_CLIENT=8388608   # 8MB - افزایش از 4MB برای جلوگیری از buffer overflow
    elif [ "$USER_COUNT" -lt 100 ]; then
        # 50-100 کاربر - تنظیمات متوسط-پایین
        KCP_MODE="fast"
        KCP_CONN=1
        KCP_RCVWND=1536           # افزایش برای جلوگیری از buffer overflow
        KCP_SNDWND=1536           # افزایش برای جلوگیری از buffer overflow
        KCP_SMUXBUF=12582912      # 12MB - افزایش برای جلوگیری از buffer overflow
        KCP_STREAMBUF=6291456     # 6MB - افزایش برای جلوگیری از buffer overflow
        PCAP_SOCKBUF_CLIENT=12582912  # 12MB - افزایش برای جلوگیری از buffer overflow
    elif [ "$USER_COUNT" -lt 300 ]; then
        # 100-300 کاربر - تنظیمات متوسط
        # بافرهای متوسط برای جلوگیری از خطای "No buffer space available"
        KCP_MODE="fast2"
        KCP_CONN=2
        KCP_RCVWND=2048           # افزایش از 1024 به 2048 برای جلوگیری از خطای buffer space
        KCP_SNDWND=2048           # افزایش از 1024 به 2048 برای جلوگیری از خطای buffer space
        KCP_SMUXBUF=16777216      # 16MB - افزایش از 8MB برای جلوگیری از خطای buffer space
        KCP_STREAMBUF=8388608     # 8MB - افزایش از 4MB برای جلوگیری از خطای buffer space
        PCAP_SOCKBUF_CLIENT=16777216  # 16MB - افزایش از 8MB برای جلوگیری از خطای buffer space
    else
        # بالای 300 کاربر - تنظیمات پیشرفته (بهینه شده برای ترافیک بالا)
        # بافرهای بزرگ برای جلوگیری از خطای "No buffer space available"
        KCP_MODE="fast3"
        KCP_CONN=4
        KCP_RCVWND=8192           # افزایش از 4096 به 8192 برای جلوگیری از خطای buffer space
        KCP_SNDWND=8192           # افزایش از 4096 به 8192 برای جلوگیری از خطای buffer space
        KCP_SMUXBUF=67108864      # 64MB - افزایش از 32MB برای جلوگیری از خطای buffer space
        KCP_STREAMBUF=33554432    # 32MB - افزایش از 16MB برای جلوگیری از خطای buffer space
        PCAP_SOCKBUF_CLIENT=67108864  # 64MB - افزایش از 32MB برای جلوگیری از خطای buffer space
    fi
}

# بهینه‌سازی شبکه (BBR و TCP optimizations)
optimize_network() {
    # پارامتر اول: آیا sysctl اعمال شود؟ (1=yes, 0=no, empty=ask)
    local APPLY_SYSCTL="${1:-}"
    
    if [ "$LANG_SELECTED" == "en" ]; then
        echo -e "${BLUE}ℹ${NC} Optimizing network settings..."
    else
        echo -e "${BLUE}ℹ${NC} بهینه‌سازی تنظیمات شبکه..."
    fi
    
    # بررسی و فعال کردن BBR
    if [ -f /proc/sys/net/ipv4/tcp_congestion_control ]; then
        CURRENT_CC=$(cat /proc/sys/net/ipv4/tcp_congestion_control)
        if [ "$CURRENT_CC" != "bbr" ]; then
            # بررسی وجود BBR
            if lsmod | grep -q tcp_bbr || modprobe tcp_bbr 2>/dev/null; then
                echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
                echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
                sysctl -w net.core.default_qdisc=fq > /dev/null 2>&1
                sysctl -w net.ipv4.tcp_congestion_control=bbr > /dev/null 2>&1
                if [ "$LANG_SELECTED" == "en" ]; then
                    echo -e "${GREEN}✓${NC} BBR enabled"
                else
                    echo -e "${GREEN}✓${NC} BBR فعال شد"
                fi
            else
                if [ "$LANG_SELECTED" == "en" ]; then
                    echo -e "${YELLOW}⚠${NC} BBR module not available (kernel >= 4.9 required)"
                else
                    echo -e "${YELLOW}⚠${NC} ماژول BBR در دسترس نیست (نیاز به kernel >= 4.9)"
                fi
            fi
        else
            if [ "$LANG_SELECTED" == "en" ]; then
                echo -e "${BLUE}ℹ${NC} BBR already enabled"
            else
                echo -e "${BLUE}ℹ${NC} BBR قبلاً فعال است"
            fi
        fi
    fi
    
    # اگر APPLY_SYSCTL خالی است، از کاربر بپرس
    if [ -z "$APPLY_SYSCTL" ]; then
        echo ""
        if [ "$LANG_SELECTED" == "en" ]; then
            echo -e "${YELLOW}⚠ Note:${NC} You may already have sysctl settings configured."
            echo -e "Do you want to apply Paqet's sysctl optimizations?"
            echo -e "  ${CYAN}1${NC}) Yes - Apply sysctl optimizations (recommended for high traffic)"
            echo -e "  ${CYAN}2${NC}) No - Skip sysctl (use your existing settings)"
            read -p "Choose [1/2] (default: 2): " APPLY_SYSCTL < /dev/tty
        else
            echo -e "${YELLOW}⚠ توجه:${NC} ممکن است شما قبلاً تنظیمات sysctl داشته باشید."
            echo -e "آیا می‌خواهید بهینه‌سازی‌های sysctl Paqet اعمال شوند؟"
            echo -e "  ${CYAN}1${NC}) بله - اعمال بهینه‌سازی‌های sysctl (پیشنهاد برای ترافیک بالا)"
            echo -e "  ${CYAN}2${NC}) خیر - رد کردن sysctl (استفاده از تنظیمات موجود شما)"
            read -p "انتخاب [1/2] (پیش‌فرض: 2): " APPLY_SYSCTL < /dev/tty
        fi
        APPLY_SYSCTL="${APPLY_SYSCTL:-2}"
    fi
    
    # اعمال sysctl فقط اگر کاربر بخواهد
    if [ "$APPLY_SYSCTL" = "1" ]; then
        # حذف تنظیمات قبلی Paqet از sysctl.conf (اگر وجود داشته باشد)
        if grep -q "# Paqet Network Optimizations" /etc/sysctl.conf 2>/dev/null; then
            if [ "$LANG_SELECTED" == "en" ]; then
                echo -e "${BLUE}ℹ${NC} Removing previous Paqet sysctl settings..."
            else
                echo -e "${BLUE}ℹ${NC} حذف تنظیمات قبلی sysctl Paqet..."
            fi
            
            # حذف بخش Paqet از sysctl.conf
            sed -i '/# Paqet Network Optimizations/,/^# net\.ipv4\.ip_forward = 1$/d' /etc/sysctl.conf 2>/dev/null || \
            sed -i '/# Paqet Network Optimizations/,/^$/d' /etc/sysctl.conf 2>/dev/null || \
            awk '/# Paqet Network Optimizations/{flag=1} /^$/{if(flag){flag=0;next}} !flag' /etc/sysctl.conf > /tmp/sysctl.conf.tmp && mv /tmp/sysctl.conf.tmp /etc/sysctl.conf 2>/dev/null || true
            
            # حذف خط خالی اضافی در انتها (اگر وجود داشته باشد)
            sed -i ':a;N;$!ba;s/\n\n\n*/\n\n/g' /etc/sysctl.conf 2>/dev/null || true
        fi
        
        # بهینه‌سازی‌های TCP برای ترافیک بالا و شبکه‌های با اختلال
        if [ "$LANG_SELECTED" == "en" ]; then
            echo -e "${BLUE}ℹ${NC} Applying sysctl optimizations..."
        else
            echo -e "${BLUE}ℹ${NC} اعمال بهینه‌سازی‌های sysctl..."
        fi
        
        cat >> /etc/sysctl.conf <<'SYSCTL_EOF'

# Paqet Network Optimizations - بهینه‌سازی‌های شبکه Paqet
# TCP optimizations for high traffic and unstable networks
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 8192
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_syncookies = 1

# Buffer sizes for high traffic - جلوگیری از خطای "No buffer space available"
# این تنظیمات برای جلوگیری از پر شدن بافرها در ترافیک بالا ضروری است
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 134217728
net.core.wmem_default = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# Connection tracking optimizations
net.netfilter.nf_conntrack_max = 1000000
net.netfilter.nf_conntrack_tcp_timeout_established = 1200

# IP forwarding (if needed)
# net.ipv4.ip_forward = 1
SYSCTL_EOF
            
        # اعمال تنظیمات
        sysctl -p > /dev/null 2>&1
        
        if [ "$LANG_SELECTED" == "en" ]; then
            echo -e "${GREEN}✓${NC} Sysctl optimizations applied"
        else
            echo -e "${GREEN}✓${NC} بهینه‌سازی‌های sysctl اعمال شد"
        fi
    else
        if [ "$LANG_SELECTED" == "en" ]; then
            echo -e "${BLUE}ℹ${NC} Skipping sysctl optimizations (using existing settings)"
        else
            echo -e "${BLUE}ℹ${NC} رد کردن بهینه‌سازی‌های sysctl (استفاده از تنظیمات موجود)"
        fi
    fi
}

# خواندن زبان از server_info.txt
if [ -f "$SCRIPT_DIR/server_info.txt" ]; then
    source "$SCRIPT_DIR/server_info.txt"
fi
LANG_SELECTED=${LANG:-fa}

# انتخاب زبان
if [ -z "$LANG" ]; then
    clear
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║          Paqet Client Auto-Install                           ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Select Language / انتخاب زبان:"
    echo "  1) فارسی (Persian)"
    echo "  2) English"
    read -p "Choose / انتخاب [1/2]: " LANG_CHOICE
    case "$LANG_CHOICE" in
        2|en|english) LANG_SELECTED="en" ;;
        *) LANG_SELECTED="fa" ;;
    esac
fi

if [ "$LANG_SELECTED" == "en" ]; then
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║          Paqet Client Auto-Install                           ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
else
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║          نصب خودکار Paqet Client                            ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
fi
echo ""

# بررسی root
if [ "$EUID" -ne 0 ]; then
    if [ "$LANG_SELECTED" == "en" ]; then
        echo -e "${CROSS} This script must be run as root"
        echo "Usage: sudo $0"
    else
        echo -e "${CROSS} این اسکریپت باید با دسترسی root اجرا شود"
        echo "استفاده: sudo $0"
    fi
    exit 1
fi

# خواندن اطلاعات سرور
if [ ! -f "$SCRIPT_DIR/server_info.txt" ]; then
    if [ "$LANG_SELECTED" == "en" ]; then
        echo -e "${CROSS} server_info.txt not found"
    else
        echo -e "${CROSS} فایل server_info.txt پیدا نشد"
    fi
    exit 1
fi

source "$SCRIPT_DIR/server_info.txt"

# نصب prerequisites
if [ "$LANG_SELECTED" == "en" ]; then
    echo -e "${BLUE}ℹ${NC} Installing prerequisites..."
else
    echo -e "${BLUE}ℹ${NC} در حال نصب prerequisites..."
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    case "$OS" in
        ubuntu|debian)
            apt-get update -qq > /dev/null 2>&1
            apt-get install -y libpcap-dev iptables iproute2 net-tools > /dev/null 2>&1
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y libpcap-devel iptables iproute net-tools > /dev/null 2>&1
            else
                yum install -y libpcap-devel iptables iproute net-tools > /dev/null 2>&1
            fi
            ;;
    esac
fi

# نصب paqet
if [ -f "$SCRIPT_DIR/paqet" ]; then
    cp "$SCRIPT_DIR/paqet" /usr/local/bin/paqet
    chmod +x /usr/local/bin/paqet
    if [ "$LANG_SELECTED" == "en" ]; then
        echo -e "${CHECK} Paqet installed"
    else
        echo -e "${CHECK} Paqet نصب شد"
    fi
fi

# جمع‌آوری اطلاعات شبکه
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$LANG_SELECTED" == "en" ]; then
    echo "Gathering Network Information"
else
    echo "جمع‌آوری اطلاعات شبکه"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

INTERFACES=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))
if [ ${#INTERFACES[@]} -gt 1 ]; then
    if [ "$LANG_SELECTED" == "en" ]; then
        echo "Available interfaces:"
    else
        echo "اینترفیس‌های موجود:"
    fi
    for i in "${!INTERFACES[@]}"; do
        echo "  $((i+1))) ${INTERFACES[$i]}"
    done
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Select interface [1]: " IFACE_CHOICE
    else
        read -p "اینترفیس را انتخاب کنید [1]: " IFACE_CHOICE
    fi
    IFACE_CHOICE=${IFACE_CHOICE:-1}
    INTERFACE="${INTERFACES[$((IFACE_CHOICE-1))]}"
else
    INTERFACE="${INTERFACES[0]}"
fi

LOCAL_IP=$(ip -4 addr show $INTERFACE 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
if [ -z "$LOCAL_IP" ]; then
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Enter local IP: " LOCAL_IP
    else
        read -p "IP محلی را وارد کنید: " LOCAL_IP
    fi
fi

GATEWAY_IP=$(ip route | grep default | awk '{print $3}' | head -1)
if [ -n "$GATEWAY_IP" ]; then
    ping -c 1 -W 1 $GATEWAY_IP > /dev/null 2>&1
    sleep 1
    ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
fi

if [ -z "$ROUTER_MAC" ]; then
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Enter router MAC address: " ROUTER_MAC
    else
        read -p "MAC آدرس روتر را وارد کنید: " ROUTER_MAC
    fi
fi

# سوال تعداد کاربران همزمان
echo ""
if [ "$LANG_SELECTED" == "en" ]; then
    echo "Expected concurrent users:"
    echo "  1) Under 100 users (10-100 users, optimized buffers to prevent overflow)"
    echo "  2) 100-300 users (medium settings, high buffers)"
    echo "  3) Over 300 users (advanced settings, maximum buffers)"
    echo "  4) Custom settings (manual)"
    read -p "Select [1]: " USER_PROFILE
else
    echo "تعداد کاربران همزمان مورد انتظار:"
    echo "  1) زیر 100 کاربر (10-100 کاربر، بافرهای بهینه برای جلوگیری از overflow)"
    echo "  2) 100 تا 300 کاربر (تنظیمات متوسط، بافرهای بالا)"
    echo "  3) بالای 300 کاربر (تنظیمات پیشرفته، بافرهای حداکثری)"
    echo "  4) تنظیمات دستی"
    read -p "انتخاب [1]: " USER_PROFILE
fi
USER_PROFILE=${USER_PROFILE:-1}

# بهینه‌سازی خودکار بر اساس تعداد کاربران
case "$USER_PROFILE" in
    1)
        if [ "$LANG_SELECTED" == "en" ]; then
            echo -e "${BLUE}ℹ${NC} Optimizing for 10-100 users (buffers optimized to prevent overflow)..."
        else
            echo -e "${BLUE}ℹ${NC} بهینه‌سازی برای 10-100 کاربر (بافرهای بهینه برای جلوگیری از overflow)..."
        fi
        optimize_for_users 50
        ;;
    2)
        if [ "$LANG_SELECTED" == "en" ]; then
            echo -e "${BLUE}ℹ${NC} Optimizing for 100-300 users (high buffers)..."
        else
            echo -e "${BLUE}ℹ${NC} بهینه‌سازی برای 100-300 کاربر (بافرهای بالا)..."
        fi
        optimize_for_users 200
        ;;
    3)
        if [ "$LANG_SELECTED" == "en" ]; then
            echo -e "${BLUE}ℹ${NC} Optimizing for over 300 users (maximum buffers)..."
        else
            echo -e "${BLUE}ℹ${NC} بهینه‌سازی برای بالای 300 کاربر (بافرهای حداکثری)..."
        fi
        optimize_for_users 500
        ;;
    4)
        # تنظیمات دستی
        if [ "$LANG_SELECTED" == "en" ]; then
            echo "KCP Mode (speed vs latency):"
            echo "  1) normal  - Balanced, lower CPU usage"
            echo "  2) fast    - Faster (default)"
            echo "  3) fast2   - Very fast, low latency"
            echo "  4) fast3   - Fastest, lowest latency"
            read -p "Select KCP mode [2]: " KCP_MODE_CHOICE
        else
            echo "حالت KCP (سرعت در مقابل تأخیر):"
            echo "  1) normal  - متعادل، مصرف CPU کمتر"
            echo "  2) fast    - سریع‌تر (پیش‌فرض)"
            echo "  3) fast2   - خیلی سریع، تأخیر کم"
            echo "  4) fast3   - سریع‌ترین، کم‌ترین تأخیر"
            read -p "حالت KCP را انتخاب کنید [2]: " KCP_MODE_CHOICE
        fi
        KCP_MODE_CHOICE=${KCP_MODE_CHOICE:-2}
        case "$KCP_MODE_CHOICE" in
            1) KCP_MODE="normal" ;;
            2) KCP_MODE="fast" ;;
            3) KCP_MODE="fast2" ;;
            4) KCP_MODE="fast3" ;;
            *) KCP_MODE="fast" ;;
        esac
        
        if [ "$LANG_SELECTED" == "en" ]; then
            read -p "Number of connections (conn) [1]: " KCP_CONN
        else
            read -p "تعداد اتصالات (conn) [1]: " KCP_CONN
        fi
        KCP_CONN=${KCP_CONN:-1}
        KCP_RCVWND=512
        KCP_SNDWND=512
        KCP_SMUXBUF=4194304
        KCP_STREAMBUF=2097152
        PCAP_SOCKBUF_CLIENT=4194304
        ;;
    *)
        optimize_for_users 50
        ;;
esac

# نوع استفاده
echo ""
if [ "$LANG_SELECTED" == "en" ]; then
    echo "Usage type:"
    echo "  1) SOCKS5 Proxy"
    echo "  2) Port Forwarding"
    read -p "Select [1]: " USE_TYPE
else
    echo "نوع استفاده:"
    echo "  1) SOCKS5 Proxy"
    echo "  2) Port Forwarding"
    read -p "انتخاب [1]: " USE_TYPE
fi
USE_TYPE=${USE_TYPE:-1}

# آرایه برای ذخیره Port Forwarding ها
FORWARD_ENTRIES=()

if [ "$USE_TYPE" == "2" ]; then
    ADD_MORE="y"
    while [ "$ADD_MORE" != "n" ] && [ "$ADD_MORE" != "N" ]; do
        LISTEN_PORT_FWD=""
        TARGET_ADDR=""
        
        while [ -z "$LISTEN_PORT_FWD" ]; do
            if [ "$LANG_SELECTED" == "en" ]; then
                read -p "Listen port on Iran server: " LISTEN_PORT_FWD
            else
                read -p "پورت گوش دادن روی سرور ایران: " LISTEN_PORT_FWD
            fi
            if [ -z "$LISTEN_PORT_FWD" ]; then
                if [ "$LANG_SELECTED" == "en" ]; then
                    print_error "Port cannot be empty"
                else
                    print_error "پورت نمی‌تواند خالی باشد"
                fi
            fi
        done
        
        # تنظیم پیش‌فرض target address بر اساس listen port
        DEFAULT_TARGET="127.0.0.1:$LISTEN_PORT_FWD"
        
        while [ -z "$TARGET_ADDR" ] || ! echo "$TARGET_ADDR" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$'; do
            if [ "$LANG_SELECTED" == "en" ]; then
                read -p "Target address on foreign server [$DEFAULT_TARGET]: " TARGET_ADDR
            else
                read -p "آدرس مقصد روی سرور خارج [$DEFAULT_TARGET]: " TARGET_ADDR
            fi
            # اگر خالی بود، از پیش‌فرض استفاده کن
            if [ -z "$TARGET_ADDR" ]; then
                TARGET_ADDR="$DEFAULT_TARGET"
            elif ! echo "$TARGET_ADDR" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$'; then
                if [ "$LANG_SELECTED" == "en" ]; then
                    print_error "Invalid format. Use IP:PORT (e.g. 127.0.0.1:8080)"
                else
                    print_error "فرمت نامعتبر. از IP:PORT استفاده کنید (مثلا 127.0.0.1:8080)"
                fi
                TARGET_ADDR=""
            fi
        done
        
        # اضافه کردن به آرایه
        FORWARD_ENTRIES+=("$LISTEN_PORT_FWD|$TARGET_ADDR")
        
        if [ "$LANG_SELECTED" == "en" ]; then
            echo ""
            read -p "Add another port forwarding? [y/N]: " ADD_MORE
        else
            echo ""
            read -p "پورت forward دیگری اضافه کنید؟ [y/N]: " ADD_MORE
        fi
        ADD_MORE=${ADD_MORE:-n}
    done
fi

# ساخت کانفیگ
CONFIG_DIR="/etc/paqet"
mkdir -p "$CONFIG_DIR"
CONFIG_FILE="$CONFIG_DIR/${TUNNEL_NAME}_client.yaml"

cat > "$CONFIG_FILE" <<EOF
role: "client"
log:
  level: "info"
network:
  interface: "$INTERFACE"
  ipv4:
    addr: "$LOCAL_IP:0"
    router_mac: "$ROUTER_MAC"
  pcap:
    sockbuf: $PCAP_SOCKBUF_CLIENT
  tcp:
    local_flag: ["PA"]
    remote_flag: ["PA"]
server:
  addr: "$SERVER_IP:$SERVER_PORT"
transport:
  protocol: "kcp"
  conn: $KCP_CONN
  kcp:
    mode: "$KCP_MODE"
    mtu: 1480
    rcvwnd: $KCP_RCVWND
    sndwnd: $KCP_SNDWND
    block: "salsa20"
    key: "$SECRET_KEY"
    smuxbuf: $KCP_SMUXBUF
    streambuf: $KCP_STREAMBUF
EOF

if [ "$USE_TYPE" == "1" ]; then
    cat >> "$CONFIG_FILE" <<EOF
socks5:
  - listen: "127.0.0.1:1080"
    username: ""
    password: ""
EOF
else
    cat >> "$CONFIG_FILE" <<EOF
forward:
EOF
    for entry in "${FORWARD_ENTRIES[@]}"; do
        LISTEN_PORT=$(echo "$entry" | cut -d'|' -f1)
        TARGET_ADDR=$(echo "$entry" | cut -d'|' -f2)
        cat >> "$CONFIG_FILE" <<EOF
  - listen: "0.0.0.0:$LISTEN_PORT"
    target: "$TARGET_ADDR"
    protocol: "tcp"
EOF
    done
fi

# ساخت سرویس
SERVICE_NAME="udp-relay-${TUNNEL_NAME}"
cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=UDP Relay Service - $TUNNEL_NAME
After=network.target
[Service]
Type=simple
User=paqet
ExecStart=/usr/local/bin/paqet run -c $CONFIG_FILE
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$LANG_SELECTED" == "en" ]; then
    echo -e "${CHECK} Installation complete!"
    echo ""
    echo "Commands:"
    echo "  sudo systemctl start $SERVICE_NAME"
    echo "  sudo systemctl enable $SERVICE_NAME"
    echo ""
    read -p "Do you want to start the service? [Y/n]: " START
else
    echo -e "${CHECK} نصب کامل شد!"
    echo ""
    echo "دستورات:"
    echo "  sudo systemctl start $SERVICE_NAME"
    echo "  sudo systemctl enable $SERVICE_NAME"
    echo ""
    read -p "آیا می‌خواهید سرویس را شروع کنید؟ [Y/n]: " START
fi

if [[ ! "$START" =~ ^[Nn]$ ]]; then
    systemctl start "$SERVICE_NAME"
    systemctl enable "$SERVICE_NAME"
    sleep 2
    systemctl status "$SERVICE_NAME" --no-pager -l | head -15
fi
INSTALL_EOF

    chmod +x "$PACKAGE_PATH/install.sh"
    
    # ساخت README (دو زبانه)
    cat > "$PACKAGE_PATH/README.md" <<EOF
# Paqet Client Package / پکیج نصب Paqet Client

$(if [ "$LANG_SELECTED" == "en" ]; then
    echo "This package is ready for installing Paqet on Iran server."
else
    echo "این پکیج برای نصب Paqet روی سرور ایران آماده شده است."
fi)

## Tunnel Information / اطلاعات تونل:
- $(if [ "$LANG_SELECTED" == "en" ]; then echo "Tunnel Name"; else echo "نام تونل"; fi): $TUNNEL_NAME
- $(if [ "$LANG_SELECTED" == "en" ]; then echo "Foreign Server IP"; else echo "IP سرور خارج"; fi): $SERVER_IP
- $(if [ "$LANG_SELECTED" == "en" ]; then echo "Server Port"; else echo "پورت سرور"; fi): $SERVER_PORT

## Installation Steps / مراحل نصب:

### 1. $(if [ "$LANG_SELECTED" == "en" ]; then echo "Transfer package to Iran server"; else echo "انتقال پکیج به سرور ایران"; fi):

\`\`\`bash
scp $ARCHIVE_NAME user@iran-server:/tmp/
\`\`\`

### 2. $(if [ "$LANG_SELECTED" == "en" ]; then echo "Extract package"; else echo "استخراج پکیج"; fi):

\`\`\`bash
cd /tmp
tar -xzf $ARCHIVE_NAME
cd $PACKAGE_NAME
\`\`\`

### 3. $(if [ "$LANG_SELECTED" == "en" ]; then echo "Run install script"; else echo "اجرای اسکریپت نصب"; fi):

\`\`\`bash
sudo chmod +x install.sh
sudo ./install.sh
\`\`\`

$(if [ "$LANG_SELECTED" == "en" ]; then
    echo "The auto-install script will:"
    echo "- Install prerequisites"
    echo "- Install Paqet"
    echo "- Gather network information"
    echo "- Create configuration"
    echo "- Create systemd service"
else
    echo "اسکریپت نصب خودکار:"
    echo "- prerequisites را نصب می‌کند"
    echo "- Paqet را نصب می‌کند"
    echo "- اطلاعات شبکه را جمع می‌کند"
    echo "- کانفیگ را می‌سازد"
    echo "- سرویس systemd را ایجاد می‌کند"
fi)
EOF
    
    # ساخت فایل tar.gz
    cd "$PACKAGE_DIR"
    tar -czf "$ARCHIVE_NAME" "$PACKAGE_NAME"
    
    if [ "$LANG_SELECTED" == "en" ]; then
        print_success "Package created!"
        echo ""
        print_box "Package Information" "Path: ${BOLD}$PACKAGE_DIR/$ARCHIVE_NAME${NC}"
        echo ""
        echo "  ${CYAN}Size:${NC} $(du -h "$PACKAGE_DIR/$ARCHIVE_NAME" | cut -f1)"
        echo ""
        echo "To transfer to Iran server:"
        echo -e "  ${BOLD}scp $PACKAGE_DIR/$ARCHIVE_NAME user@iran-server:/tmp/${NC}"
    else
        print_success "پکیج ساخته شد!"
        echo ""
        print_box "اطلاعات پکیج" "مسیر: ${BOLD}$PACKAGE_DIR/$ARCHIVE_NAME${NC}"
        echo ""
        echo "  ${CYAN}حجم:${NC} $(du -h "$PACKAGE_DIR/$ARCHIVE_NAME" | cut -f1)"
        echo ""
        echo "برای انتقال به سرور ایران:"
        echo -e "  ${BOLD}scp $PACKAGE_DIR/$ARCHIVE_NAME user@iran-server:/tmp/${NC}"
    fi
    echo ""
}

setup_server() {
    print_header
    print_separator
    if [ "$LANG_SELECTED" == "en" ]; then
        echo -e "${BOLD}🌍 Setup Foreign Server (Kharej)${NC}"
    else
        echo -e "${BOLD}🌍 راه‌اندازی سرور خارج (Kharej)${NC}"
    fi
    print_separator
    echo ""
    
    # نصب خودکار
    if ! check_paqet_installed; then
        auto_install_prerequisites
        auto_install_paqet
    fi
    
    if ! check_paqet_installed; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_error "Failed to install Paqet"
            read -p "Press Enter to continue..."
        else
            print_error "نصب Paqet ناموفق بود"
            read -p "برای ادامه Enter را فشار دهید..."
        fi
        return 1
    fi
    
    if [ "$LANG_SELECTED" == "en" ]; then
        print_success "Paqet is installed"
    else
        print_success "Paqet نصب شده است"
    fi
    echo ""
    
    # ایجاد کاربر paqet
    if ! id -u paqet &>/dev/null; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_step "Creating paqet user..."
        else
            print_step "در حال ایجاد کاربر paqet..."
        fi
        useradd -r -s /bin/false paqet 2>/dev/null || true
        if id -u paqet &>/dev/null; then
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "User paqet created"
            else
                print_success "کاربر paqet ایجاد شد"
            fi
        fi
    fi
    echo ""
    
    # بهینه‌سازی شبکه
    optimize_network
    
    # بررسی اینکه آیا optimize_network با موفقیت انجام شد
    if [ $? -ne 0 ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_warning "Network optimization had some issues, but continuing..."
        else
            print_warning "بهینه‌سازی شبکه مشکلاتی داشت، اما ادامه می‌دهیم..."
        fi
    fi
    
    # اطلاعات شبکه
    get_network_info
    
    # اطلاعات تونل
    print_separator
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        print_info "Tunnel Settings"
    else
        print_info "تنظیمات تونل"
    fi
    echo ""
    
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Tunnel name [tunnel1]: " TUNNEL_NAME
        read -p "Listen port [9999]: " LISTEN_PORT
    else
        read -p "نام تونل [tunnel1]: " TUNNEL_NAME
        read -p "پورت گوش دادن [9999]: " LISTEN_PORT
    fi
    TUNNEL_NAME=${TUNNEL_NAME:-tunnel1}
    LISTEN_PORT=${LISTEN_PORT:-9999}
    
    # سوال تعداد کاربران همزمان
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        echo "Expected concurrent users:"
        echo "  1) Under 100 users (basic settings)"
        echo "  2) 100-300 users (medium settings)"
        echo "  3) Over 300 users (advanced settings)"
        echo "  4) Custom settings (manual)"
        read -p "Select [1]: " USER_PROFILE
    else
        echo "تعداد کاربران همزمان مورد انتظار:"
        echo "  1) زیر 100 کاربر (تنظیمات پایه)"
        echo "  2) 100 تا 300 کاربر (تنظیمات متوسط)"
        echo "  3) بالای 300 کاربر (تنظیمات پیشرفته)"
        echo "  4) تنظیمات دستی"
        read -p "انتخاب [1]: " USER_PROFILE
    fi
    USER_PROFILE=${USER_PROFILE:-1}
    
    # بهینه‌سازی خودکار بر اساس تعداد کاربران
    case "$USER_PROFILE" in
        1)
            if [ "$LANG_SELECTED" == "en" ]; then
                print_info "Optimizing for under 100 users..."
            else
                print_info "بهینه‌سازی برای زیر 100 کاربر..."
            fi
            optimize_for_users 50
            ;;
        2)
            if [ "$LANG_SELECTED" == "en" ]; then
                print_info "Optimizing for 100-300 users..."
            else
                print_info "بهینه‌سازی برای 100-300 کاربر..."
            fi
            optimize_for_users 200
            ;;
        3)
            if [ "$LANG_SELECTED" == "en" ]; then
                print_info "Optimizing for over 300 users..."
            else
                print_info "بهینه‌سازی برای بالای 300 کاربر..."
            fi
            optimize_for_users 500
            ;;
        4)
            # تنظیمات دستی
            if [ "$LANG_SELECTED" == "en" ]; then
                echo "KCP Mode (speed vs latency):"
                echo "  1) normal  - Balanced, lower CPU usage"
                echo "  2) fast    - Faster (default)"
                echo "  3) fast2   - Very fast, low latency"
                echo "  4) fast3   - Fastest, lowest latency"
                read -p "Select KCP mode [2]: " KCP_MODE_CHOICE
            else
                echo "حالت KCP (سرعت در مقابل تأخیر):"
                echo "  1) normal  - متعادل، مصرف CPU کمتر"
                echo "  2) fast    - سریع‌تر (پیش‌فرض)"
                echo "  3) fast2   - خیلی سریع، تأخیر کم"
                echo "  4) fast3   - سریع‌ترین، کم‌ترین تأخیر"
                read -p "حالت KCP را انتخاب کنید [2]: " KCP_MODE_CHOICE
            fi
            KCP_MODE_CHOICE=${KCP_MODE_CHOICE:-2}
            case "$KCP_MODE_CHOICE" in
                1) KCP_MODE="normal" ;;
                2) KCP_MODE="fast" ;;
                3) KCP_MODE="fast2" ;;
                4) KCP_MODE="fast3" ;;
                *) KCP_MODE="fast" ;;
            esac
            
            if [ "$LANG_SELECTED" == "en" ]; then
                read -p "Number of connections (conn) [1]: " KCP_CONN
            else
                read -p "تعداد اتصالات (conn) [1]: " KCP_CONN
            fi
            KCP_CONN=${KCP_CONN:-1}
            KCP_RCVWND=2048           # افزایش برای جلوگیری از خطای buffer space
            KCP_SNDWND=2048           # افزایش برای جلوگیری از خطای buffer space
            KCP_SMUXBUF=16777216      # 16MB - افزایش برای جلوگیری از خطای buffer space
            KCP_STREAMBUF=8388608     # 8MB - افزایش برای جلوگیری از خطای buffer space
            PCAP_SOCKBUF_SERVER=33554432  # 32MB - افزایش برای جلوگیری از خطای buffer space
            ;;
        *)
            optimize_for_users 50
            ;;
    esac
    
    # نمایش تنظیمات انتخاب شده
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        print_box "Optimized Settings" "Mode: ${BOLD}$KCP_MODE${NC} | Conn: ${BOLD}$KCP_CONN${NC} | Windows: ${BOLD}$KCP_RCVWND/$KCP_SNDWND${NC}"
    else
        print_box "تنظیمات بهینه شده" "Mode: ${BOLD}$KCP_MODE${NC} | Conn: ${BOLD}$KCP_CONN${NC} | Windows: ${BOLD}$KCP_RCVWND/$KCP_SNDWND${NC}"
    fi
    echo ""
    
    # تولید کلید
    SECRET_KEY=$(openssl rand -base64 32 2>/dev/null || echo "AY9Frl1VHWJB01lmKqLgE6dJllLhF3Sn4Lw/6BrcyYY=")
    
    # ساخت کانفیگ
    print_separator
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        print_step "Creating configuration..."
    else
        print_step "در حال ساخت کانفیگ..."
    fi
    
    mkdir -p "$CONFIG_DIR"
    CONFIG_FILE="$CONFIG_DIR/${TUNNEL_NAME}_server.yaml"
    
    cat > "$CONFIG_FILE" <<EOF
role: "server"
log:
  level: "info"
listen:
  addr: ":$LISTEN_PORT"
network:
  interface: "$INTERFACE"
  ipv4:
    addr: "$LOCAL_IP:$LISTEN_PORT"
    router_mac: "$ROUTER_MAC"
  pcap:
    sockbuf: $PCAP_SOCKBUF_SERVER
  tcp:
    local_flag: ["PA"]
transport:
  protocol: "kcp"
  conn: $KCP_CONN
  kcp:
    mode: "$KCP_MODE"
    mtu: 1480
    rcvwnd: $KCP_RCVWND
    sndwnd: $KCP_SNDWND
    block: "salsa20"
    key: "$SECRET_KEY"
    smuxbuf: $KCP_SMUXBUF
    streambuf: $KCP_STREAMBUF
EOF
    
    if [ "$LANG_SELECTED" == "en" ]; then
        print_success "Configuration created: $CONFIG_FILE"
    else
        print_success "کانفیگ ساخته شد: $CONFIG_FILE"
    fi
    
    # اعمال iptables
    if [ "$LANG_SELECTED" == "en" ]; then
        print_step "Applying iptables rules..."
    else
        print_step "در حال اعمال قوانین iptables..."
    fi
    iptables -t raw -A PREROUTING -p tcp --dport $LISTEN_PORT -j NOTRACK 2>/dev/null || true
    iptables -t raw -A OUTPUT -p tcp --sport $LISTEN_PORT -j NOTRACK 2>/dev/null || true
    iptables -t mangle -A OUTPUT -p tcp --sport $LISTEN_PORT --tcp-flags RST RST -j DROP 2>/dev/null || true
    if [ "$LANG_SELECTED" == "en" ]; then
        print_success "iptables rules applied"
    else
        print_success "قوانین iptables اعمال شد"
    fi
    
    # ساخت سرویس
    if [ "$LANG_SELECTED" == "en" ]; then
        print_step "Creating systemd service..."
    else
        print_step "در حال ساخت سرویس systemd..."
    fi
    SERVICE_NAME="udp-relay-${TUNNEL_NAME}"
    cat > "$SERVICE_DIR/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=UDP Relay Service - $TUNNEL_NAME
After=network.target
[Service]
Type=simple
User=paqet
ExecStart=$PAQET_BINARY run -c $CONFIG_FILE
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    if [ "$LANG_SELECTED" == "en" ]; then
        print_success "Service created: $SERVICE_NAME"
    else
        print_success "سرویس ساخته شد: $SERVICE_NAME"
    fi
    
    # نمایش اطلاعات
    print_separator
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        print_box "Tunnel Information" "Name: ${BOLD}$TUNNEL_NAME${NC} | Port: ${BOLD}$LISTEN_PORT${NC}"
        echo ""
        echo -e "  ${CYAN}Encryption Key:${NC}"
    else
        print_box "اطلاعات تونل" "نام: ${BOLD}$TUNNEL_NAME${NC} | پورت: ${BOLD}$LISTEN_PORT${NC}"
        echo ""
        echo -e "  ${CYAN}کلید رمزنگاری:${NC}"
    fi
    echo -e "  ${BOLD}$SECRET_KEY${NC}"
    echo ""
    
    # ساخت پکیج کلاینت
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Do you want to create client package for Iran server? [Y/n]: " CREATE_PACKAGE
    else
        read -p "آیا می‌خواهید پکیج برای کلاینت ایران بسازید؟ [Y/n]: " CREATE_PACKAGE
    fi
    if [[ ! "$CREATE_PACKAGE" =~ ^[Nn]$ ]]; then
        create_client_package "$TUNNEL_NAME" "$LOCAL_IP" "$LISTEN_PORT" "$SECRET_KEY"
    fi
    
    # شروع سرویس
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Do you want to start the service? [Y/n]: " START
    else
        read -p "آیا می‌خواهید سرویس را شروع کنید؟ [Y/n]: " START
    fi
    if [[ ! "$START" =~ ^[Nn]$ ]]; then
        systemctl start "$SERVICE_NAME"
        systemctl enable "$SERVICE_NAME"
        sleep 2
        echo ""
        systemctl status "$SERVICE_NAME" --no-pager -l | head -15
    fi
    
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Press Enter to continue..."
    else
        read -p "برای ادامه Enter را فشار دهید..."
    fi
}

setup_client() {
    print_header
    print_separator
    if [ "$LANG_SELECTED" == "en" ]; then
        echo -e "${BOLD}🇮🇷 Setup Iran Client${NC}"
    else
        echo -e "${BOLD}🇮🇷 راه‌اندازی کلاینت ایران${NC}"
    fi
    print_separator
    echo ""
    
    # نصب خودکار
    if ! check_paqet_installed; then
        auto_install_prerequisites
        auto_install_paqet
    fi
    
    if ! check_paqet_installed; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_error "Failed to install Paqet"
            read -p "Press Enter to continue..."
        else
            print_error "نصب Paqet ناموفق بود"
            read -p "برای ادامه Enter را فشار دهید..."
        fi
        return 1
    fi
    
    if [ "$LANG_SELECTED" == "en" ]; then
        print_success "Paqet is installed"
    else
        print_success "Paqet نصب شده است"
    fi
    echo ""
    
    # ایجاد کاربر paqet
    if ! id -u paqet &>/dev/null; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_step "Creating paqet user..."
        else
            print_step "در حال ایجاد کاربر paqet..."
        fi
        useradd -r -s /bin/false paqet 2>/dev/null || true
        if id -u paqet &>/dev/null; then
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "User paqet created"
            else
                print_success "کاربر paqet ایجاد شد"
            fi
        fi
    fi
    echo ""
    
    # بهینه‌سازی شبکه
    optimize_network
    
    # اطلاعات اتصال
    print_separator
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        print_info "Foreign Server Connection Information"
    else
        print_info "اطلاعات اتصال به سرور خارج"
    fi
    echo ""
    
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Foreign server IP: " SERVER_IP
        read -p "Server port [9999]: " SERVER_PORT
    else
        read -p "IP سرور خارج: " SERVER_IP
        read -p "پورت سرور [9999]: " SERVER_PORT
    fi
    SERVER_PORT=${SERVER_PORT:-9999}
    SERVER_ADDR="$SERVER_IP:$SERVER_PORT"
    
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Encryption key: " SECRET_KEY
    else
        read -p "کلید رمزنگاری: " SECRET_KEY
    fi
    
    # اطلاعات شبکه
    get_network_info
    
    # اطلاعات تونل
    print_separator
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Tunnel name [tunnel1]: " TUNNEL_NAME
    else
        read -p "نام تونل [tunnel1]: " TUNNEL_NAME
    fi
    TUNNEL_NAME=${TUNNEL_NAME:-tunnel1}
    
    # سوال تعداد کاربران همزمان
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        echo "Expected concurrent users:"
        echo "  1) Under 100 users (basic settings)"
        echo "  2) 100-300 users (medium settings)"
        echo "  3) Over 300 users (advanced settings)"
        echo "  4) Custom settings (manual)"
        read -p "Select [1]: " USER_PROFILE
    else
        echo "تعداد کاربران همزمان مورد انتظار:"
        echo "  1) زیر 100 کاربر (تنظیمات پایه)"
        echo "  2) 100 تا 300 کاربر (تنظیمات متوسط)"
        echo "  3) بالای 300 کاربر (تنظیمات پیشرفته)"
        echo "  4) تنظیمات دستی"
        read -p "انتخاب [1]: " USER_PROFILE
    fi
    USER_PROFILE=${USER_PROFILE:-1}
    
    # بهینه‌سازی خودکار بر اساس تعداد کاربران
    case "$USER_PROFILE" in
        1)
            if [ "$LANG_SELECTED" == "en" ]; then
                print_info "Optimizing for under 100 users..."
            else
                print_info "بهینه‌سازی برای زیر 100 کاربر..."
            fi
            optimize_for_users 50
            ;;
        2)
            if [ "$LANG_SELECTED" == "en" ]; then
                print_info "Optimizing for 100-300 users..."
            else
                print_info "بهینه‌سازی برای 100-300 کاربر..."
            fi
            optimize_for_users 200
            ;;
        3)
            if [ "$LANG_SELECTED" == "en" ]; then
                print_info "Optimizing for over 300 users..."
            else
                print_info "بهینه‌سازی برای بالای 300 کاربر..."
            fi
            optimize_for_users 500
            ;;
        4)
            # تنظیمات دستی
            if [ "$LANG_SELECTED" == "en" ]; then
                echo "KCP Mode (speed vs latency):"
                echo "  1) normal  - Balanced, lower CPU usage"
                echo "  2) fast    - Faster (default)"
                echo "  3) fast2   - Very fast, low latency"
                echo "  4) fast3   - Fastest, lowest latency"
                read -p "Select KCP mode [2]: " KCP_MODE_CHOICE
            else
                echo "حالت KCP (سرعت در مقابل تأخیر):"
                echo "  1) normal  - متعادل، مصرف CPU کمتر"
                echo "  2) fast    - سریع‌تر (پیش‌فرض)"
                echo "  3) fast2   - خیلی سریع، تأخیر کم"
                echo "  4) fast3   - سریع‌ترین، کم‌ترین تأخیر"
                read -p "حالت KCP را انتخاب کنید [2]: " KCP_MODE_CHOICE
            fi
            KCP_MODE_CHOICE=${KCP_MODE_CHOICE:-2}
            case "$KCP_MODE_CHOICE" in
                1) KCP_MODE="normal" ;;
                2) KCP_MODE="fast" ;;
                3) KCP_MODE="fast2" ;;
                4) KCP_MODE="fast3" ;;
                *) KCP_MODE="fast" ;;
            esac
            
            if [ "$LANG_SELECTED" == "en" ]; then
                read -p "Number of connections (conn) [1]: " KCP_CONN
            else
                read -p "تعداد اتصالات (conn) [1]: " KCP_CONN
            fi
            KCP_CONN=${KCP_CONN:-1}
            KCP_RCVWND=2048           # افزایش برای جلوگیری از خطای buffer space
            KCP_SNDWND=2048           # افزایش برای جلوگیری از خطای buffer space
            KCP_SMUXBUF=16777216      # 16MB - افزایش برای جلوگیری از خطای buffer space
            KCP_STREAMBUF=8388608     # 8MB - افزایش برای جلوگیری از خطای buffer space
            PCAP_SOCKBUF_CLIENT=16777216  # 16MB - افزایش برای جلوگیری از خطای buffer space
            ;;
        *)
            optimize_for_users 50
            ;;
    esac
    
    # نمایش تنظیمات انتخاب شده
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        print_box "Optimized Settings" "Mode: ${BOLD}$KCP_MODE${NC} | Conn: ${BOLD}$KCP_CONN${NC} | Windows: ${BOLD}$KCP_RCVWND/$KCP_SNDWND${NC}"
    else
        print_box "تنظیمات بهینه شده" "Mode: ${BOLD}$KCP_MODE${NC} | Conn: ${BOLD}$KCP_CONN${NC} | Windows: ${BOLD}$KCP_RCVWND/$KCP_SNDWND${NC}"
    fi
    echo ""
    
    # نوع استفاده
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        echo "Usage type:"
        echo -e "  ${CYAN}1${NC}) SOCKS5 Proxy (default)"
        echo -e "  ${CYAN}2${NC}) Port Forwarding"
        read -p "Select [1]: " USE_TYPE
    else
        echo "نوع استفاده:"
        echo -e "  ${CYAN}1${NC}) SOCKS5 Proxy (پیش‌فرض)"
        echo -e "  ${CYAN}2${NC}) Port Forwarding"
        read -p "انتخاب [1]: " USE_TYPE
    fi
    USE_TYPE=${USE_TYPE:-1}
    
    # آرایه برای ذخیره Port Forwarding ها
    FORWARD_ENTRIES=()
    
    if [ "$USE_TYPE" == "2" ]; then
        ADD_MORE="y"
        while [ "$ADD_MORE" != "n" ] && [ "$ADD_MORE" != "N" ]; do
            LISTEN_PORT_FWD=""
            TARGET_ADDR=""
            
            while [ -z "$LISTEN_PORT_FWD" ]; do
                if [ "$LANG_SELECTED" == "en" ]; then
                    read -p "Listen port on Iran server: " LISTEN_PORT_FWD
                else
                    read -p "پورت گوش دادن روی سرور ایران: " LISTEN_PORT_FWD
                fi
                if [ -z "$LISTEN_PORT_FWD" ]; then
                    if [ "$LANG_SELECTED" == "en" ]; then
                        echo -e "${CROSS} Port cannot be empty"
                    else
                        echo -e "${CROSS} پورت نمی‌تواند خالی باشد"
                    fi
                fi
            done
            
            # تنظیم پیش‌فرض target address بر اساس listen port
            DEFAULT_TARGET="127.0.0.1:$LISTEN_PORT_FWD"
            
            while [ -z "$TARGET_ADDR" ] || ! echo "$TARGET_ADDR" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$'; do
                if [ "$LANG_SELECTED" == "en" ]; then
                    read -p "Target address on foreign server [$DEFAULT_TARGET]: " TARGET_ADDR
                else
                    read -p "آدرس مقصد روی سرور خارج [$DEFAULT_TARGET]: " TARGET_ADDR
                fi
                # اگر خالی بود، از پیش‌فرض استفاده کن
                if [ -z "$TARGET_ADDR" ]; then
                    TARGET_ADDR="$DEFAULT_TARGET"
                elif ! echo "$TARGET_ADDR" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$'; then
                    if [ "$LANG_SELECTED" == "en" ]; then
                        echo -e "${CROSS} Invalid format. Use IP:PORT (e.g. 127.0.0.1:8080)"
                    else
                        echo -e "${CROSS} فرمت نامعتبر. از IP:PORT استفاده کنید (مثلا 127.0.0.1:8080)"
                    fi
                    TARGET_ADDR=""
                fi
            done
            
            # اضافه کردن به آرایه
            FORWARD_ENTRIES+=("$LISTEN_PORT_FWD|$TARGET_ADDR")
            
            if [ "$LANG_SELECTED" == "en" ]; then
                echo ""
                read -p "Add another port forwarding? [y/N]: " ADD_MORE
            else
                echo ""
                read -p "پورت forward دیگری اضافه کنید؟ [y/N]: " ADD_MORE
            fi
            ADD_MORE=${ADD_MORE:-n}
        done
    fi
    
    # ساخت کانفیگ
    print_separator
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        print_step "Creating configuration..."
    else
        print_step "در حال ساخت کانفیگ..."
    fi
    
    mkdir -p "$CONFIG_DIR"
    CONFIG_FILE="$CONFIG_DIR/${TUNNEL_NAME}_client.yaml"
    
    cat > "$CONFIG_FILE" <<EOF
role: "client"
log:
  level: "info"
network:
  interface: "$INTERFACE"
  ipv4:
    addr: "$LOCAL_IP:0"
    router_mac: "$ROUTER_MAC"
  pcap:
    sockbuf: 4194304
  tcp:
    local_flag: ["PA"]
    remote_flag: ["PA"]
server:
  addr: "$SERVER_ADDR"
transport:
  protocol: "kcp"
  conn: $KCP_CONN
  kcp:
    mode: "$KCP_MODE"
    mtu: 1480
    rcvwnd: $KCP_RCVWND
    sndwnd: $KCP_SNDWND
    block: "salsa20"
    key: "$SECRET_KEY"
    smuxbuf: $KCP_SMUXBUF
    streambuf: $KCP_STREAMBUF
EOF
    
    if [ "$USE_TYPE" == "1" ]; then
        cat >> "$CONFIG_FILE" <<EOF
socks5:
  - listen: "127.0.0.1:1080"
    username: ""
    password: ""
EOF
        PROXY_INFO="SOCKS5 Proxy: 127.0.0.1:1080"
    else
        cat >> "$CONFIG_FILE" <<EOF
forward:
EOF
        PROXY_INFO="Port Forwarding:"
        for entry in "${FORWARD_ENTRIES[@]}"; do
            LISTEN_PORT=$(echo "$entry" | cut -d'|' -f1)
            TARGET_ADDR=$(echo "$entry" | cut -d'|' -f2)
            cat >> "$CONFIG_FILE" <<EOF
  - listen: "0.0.0.0:$LISTEN_PORT"
    target: "$TARGET_ADDR"
    protocol: "tcp"
EOF
            if [ -z "$PROXY_INFO" ] || [ "$PROXY_INFO" == "Port Forwarding:" ]; then
                PROXY_INFO="Port Forwarding: 0.0.0.0:$LISTEN_PORT -> $TARGET_ADDR"
            else
                PROXY_INFO="$PROXY_INFO, 0.0.0.0:$LISTEN_PORT -> $TARGET_ADDR"
            fi
        done
    fi
    
    if [ "$LANG_SELECTED" == "en" ]; then
        print_success "Configuration created: $CONFIG_FILE"
    else
        print_success "کانفیگ ساخته شد: $CONFIG_FILE"
    fi
    
    # ساخت سرویس
    if [ "$LANG_SELECTED" == "en" ]; then
        print_step "Creating systemd service..."
    else
        print_step "در حال ساخت سرویس systemd..."
    fi
    SERVICE_NAME="udp-relay-${TUNNEL_NAME}"
    cat > "$SERVICE_DIR/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=UDP Relay Service - $TUNNEL_NAME
After=network.target
[Service]
Type=simple
User=paqet
ExecStart=$PAQET_BINARY run -c $CONFIG_FILE
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    if [ "$LANG_SELECTED" == "en" ]; then
        print_success "Service created: $SERVICE_NAME"
    else
        print_success "سرویس ساخته شد: $SERVICE_NAME"
    fi
    
    # نمایش اطلاعات
    print_separator
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        print_box "Tunnel Information" "Name: ${BOLD}$TUNNEL_NAME${NC} | $PROXY_INFO"
    else
        print_box "اطلاعات تونل" "نام: ${BOLD}$TUNNEL_NAME${NC} | $PROXY_INFO"
    fi
    echo ""
    
    # شروع سرویس
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Do you want to start the service? [Y/n]: " START
    else
        read -p "آیا می‌خواهید سرویس را شروع کنید؟ [Y/n]: " START
    fi
    if [[ ! "$START" =~ ^[Nn]$ ]]; then
        systemctl start "$SERVICE_NAME"
        systemctl enable "$SERVICE_NAME"
        sleep 2
        echo ""
        systemctl status "$SERVICE_NAME" --no-pager -l | head -15
    fi
    
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Press Enter to continue..."
    else
        read -p "برای ادامه Enter را فشار دهید..."
    fi
}

list_configs() {
    print_header
    print_separator
    if [ "$LANG_SELECTED" == "en" ]; then
        echo -e "${BOLD}📋 Config List${NC}"
    else
        echo -e "${BOLD}📋 لیست کانفیگ‌ها${NC}"
    fi
    print_separator
    echo ""
    
    if [ ! -d "$CONFIG_DIR" ] || [ -z "$(ls -A $CONFIG_DIR 2>/dev/null)" ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_warning "No configs found"
            read -p "Press Enter to continue..."
        else
            print_warning "هیچ کانفیگی پیدا نشد"
            read -p "برای ادامه Enter را فشار دهید..."
        fi
        return
    fi
    
    CONFIGS=$(ls -1 "$CONFIG_DIR"/*.yaml 2>/dev/null | xargs -n1 basename)
    
    if [ -z "$CONFIGS" ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_warning "No configs found"
            read -p "Press Enter to continue..."
        else
            print_warning "هیچ کانفیگی پیدا نشد"
            read -p "برای ادامه Enter را فشار دهید..."
        fi
        return
    fi
    
    if [ "$LANG_SELECTED" == "en" ]; then
        echo "Available configs:"
    else
        echo "کانفیگ‌های موجود:"
    fi
    echo ""
    INDEX=1
    declare -a CONFIG_ARRAY
    for CONFIG in $CONFIGS; do
        CONFIG_PATH="$CONFIG_DIR/$CONFIG"
        ROLE=$(grep "^role:" "$CONFIG_PATH" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "unknown")
        echo -e "  ${CYAN}$INDEX${NC}) ${BOLD}$CONFIG${NC} (${ROLE})"
        CONFIG_ARRAY[$INDEX]="$CONFIG"
        INDEX=$((INDEX + 1))
    done
    
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Select config: " CONFIG_CHOICE
    else
        read -p "کانفیگ را انتخاب کنید: " CONFIG_CHOICE
    fi
    
    if [ -z "${CONFIG_ARRAY[$CONFIG_CHOICE]}" ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_error "Invalid choice"
            read -p "Press Enter to continue..."
        else
            print_error "انتخاب نامعتبر"
            read -p "برای ادامه Enter را فشار دهید..."
        fi
        return
    fi
    
    SELECTED_CONFIG="${CONFIG_ARRAY[$CONFIG_CHOICE]}"
    SELECTED_CONFIG_PATH="$CONFIG_DIR/$SELECTED_CONFIG"
    
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        echo "Actions:"
        echo -e "  ${CYAN}1${NC}) View content"
        echo -e "  ${CYAN}2${NC}) Edit"
        echo -e "  ${CYAN}3${NC}) Delete"
        read -p "Select: " ACTION
    else
        echo "عملیات:"
        echo -e "  ${CYAN}1${NC}) نمایش محتوا"
        echo -e "  ${CYAN}2${NC}) ویرایش"
        echo -e "  ${CYAN}3${NC}) حذف"
        read -p "انتخاب: " ACTION
    fi
    
    case "$ACTION" in
        1)
            echo ""
            print_separator
            cat "$SELECTED_CONFIG_PATH"
            print_separator
            ;;
        2)
            ${EDITOR:-nano} "$SELECTED_CONFIG_PATH"
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Config edited"
            else
                print_success "کانفیگ ویرایش شد"
            fi
            ;;
        3)
            echo ""
            if [ "$LANG_SELECTED" == "en" ]; then
                print_warning "This will delete the config!"
                read -p "Are you sure? [y/N]: " CONFIRM
            else
                print_warning "این عملیات کانفیگ را حذف می‌کند!"
                read -p "آیا مطمئن هستید؟ [y/N]: " CONFIRM
            fi
            if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                rm -f "$SELECTED_CONFIG_PATH"
                if [ "$LANG_SELECTED" == "en" ]; then
                    print_success "Config deleted"
                else
                    print_success "کانفیگ حذف شد"
                fi
            fi
            ;;
        *)
            if [ "$LANG_SELECTED" == "en" ]; then
                print_error "Invalid choice"
            else
                print_error "انتخاب نامعتبر"
            fi
            ;;
    esac
    
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Press Enter to continue..."
    else
        read -p "برای ادامه Enter را فشار دهید..."
    fi
}

manage_services() {
    print_header
    print_separator
    if [ "$LANG_SELECTED" == "en" ]; then
        echo -e "${BOLD}⚙️  Service Management${NC}"
    else
        echo -e "${BOLD}⚙️  مدیریت سرویس‌ها${NC}"
    fi
    print_separator
    echo ""
    
    SERVICES=$(systemctl list-units --type=service --all | grep "udp-relay-" | awk '{print $1}' | sed 's/.service$//')
    
    if [ -z "$SERVICES" ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_warning "No UDP relay services found"
            read -p "Press Enter to continue..." < /dev/tty
        else
            print_warning "هیچ سرویس UDP relay پیدا نشد"
            read -p "برای ادامه Enter را فشار دهید..." < /dev/tty
        fi
        return
    fi
    
    if [ "$LANG_SELECTED" == "en" ]; then
        echo "Available services:"
    else
        echo "سرویس‌های موجود:"
    fi
    echo ""
    INDEX=1
    declare -a SERVICE_ARRAY
    for SERVICE in $SERVICES; do
        STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null || echo "inactive")
        if [ "$STATUS" == "active" ]; then
            STATUS_COLOR="${GREEN}●${NC}"
        else
            STATUS_COLOR="${RED}●${NC}"
        fi
        echo -e "  ${CYAN}$INDEX${NC}) ${BOLD}$SERVICE${NC} ${STATUS_COLOR} $STATUS"
        SERVICE_ARRAY[$INDEX]=$SERVICE
        INDEX=$((INDEX + 1))
    done
    
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Select service: " SERVICE_CHOICE
    else
        read -p "سرویس را انتخاب کنید: " SERVICE_CHOICE
    fi
    
    if [ -z "${SERVICE_ARRAY[$SERVICE_CHOICE]}" ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_error "Invalid choice"
            read -p "Press Enter to continue..."
        else
            print_error "انتخاب نامعتبر"
            read -p "برای ادامه Enter را فشار دهید..."
        fi
        return
    fi
    
    SELECTED_SERVICE="${SERVICE_ARRAY[$SERVICE_CHOICE]}"
    
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        echo "Actions:"
        echo -e "  ${CYAN}1${NC}) Start"
        echo -e "  ${CYAN}2${NC}) Stop"
        echo -e "  ${CYAN}3${NC}) Restart"
        echo -e "  ${CYAN}4${NC}) Enable"
        echo -e "  ${CYAN}5${NC}) Disable"
        echo -e "  ${CYAN}6${NC}) Status"
        echo -e "  ${CYAN}7${NC}) Logs"
        echo -e "  ${CYAN}8${NC}) Delete"
        read -p "Select: " ACTION
    else
        echo "عملیات:"
        echo -e "  ${CYAN}1${NC}) شروع"
        echo -e "  ${CYAN}2${NC}) توقف"
        echo -e "  ${CYAN}3${NC}) راه‌اندازی مجدد"
        echo -e "  ${CYAN}4${NC}) فعال‌سازی (enable)"
        echo -e "  ${CYAN}5${NC}) غیرفعال‌سازی (disable)"
        echo -e "  ${CYAN}6${NC}) نمایش وضعیت"
        echo -e "  ${CYAN}7${NC}) نمایش لاگ‌ها"
        echo -e "  ${CYAN}8${NC}) حذف سرویس"
        read -p "انتخاب: " ACTION
    fi
    
    case "$ACTION" in
        1)
            systemctl start "$SELECTED_SERVICE"
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Service started"
            else
                print_success "سرویس شروع شد"
            fi
            ;;
        2)
            systemctl stop "$SELECTED_SERVICE"
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Service stopped"
            else
                print_success "سرویس متوقف شد"
            fi
            ;;
        3)
            systemctl restart "$SELECTED_SERVICE"
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Service restarted"
            else
                print_success "سرویس راه‌اندازی مجدد شد"
            fi
            ;;
        4)
            systemctl enable "$SELECTED_SERVICE"
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Service enabled"
            else
                print_success "سرویس فعال شد"
            fi
            ;;
        5)
            systemctl disable "$SELECTED_SERVICE"
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Service disabled"
            else
                print_success "سرویس غیرفعال شد"
            fi
            ;;
        6)
            echo ""
            systemctl status "$SELECTED_SERVICE" --no-pager -l
            ;;
        7)
            echo ""
            journalctl -u "$SELECTED_SERVICE" -f --no-pager
            ;;
        8)
            echo ""
            if [ "$LANG_SELECTED" == "en" ]; then
                print_warning "This will delete the service and config file!"
                read -p "Are you sure? [y/N]: " CONFIRM
            else
                print_warning "این عملیات سرویس و فایل کانفیگ را حذف می‌کند!"
                read -p "آیا مطمئن هستید؟ [y/N]: " CONFIRM
            fi
            if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                systemctl stop "$SELECTED_SERVICE" 2>/dev/null || true
                systemctl disable "$SELECTED_SERVICE" 2>/dev/null || true
                
                SERVICE_FILE="$SERVICE_DIR/${SELECTED_SERVICE}.service"
                if [ -f "$SERVICE_FILE" ]; then
                    CONFIG_FILE=$(grep "ExecStart.*-c" "$SERVICE_FILE" | grep -oP '(?<=-c\s)[^\s]+' || echo "")
                    rm -f "$SERVICE_FILE"
                    systemctl daemon-reload
                    
                    if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
                        rm -f "$CONFIG_FILE"
                        if [ "$LANG_SELECTED" == "en" ]; then
                            print_success "Config deleted: $CONFIG_FILE"
                        else
                            print_success "کانفیگ حذف شد: $CONFIG_FILE"
                        fi
                    fi
                    
                    if [ "$LANG_SELECTED" == "en" ]; then
                        print_success "Service deleted"
                    else
                        print_success "سرویس حذف شد"
                    fi
                fi
            fi
            ;;
        *)
            if [ "$LANG_SELECTED" == "en" ]; then
                print_error "Invalid choice"
            else
                print_error "انتخاب نامعتبر"
            fi
            ;;
    esac
    
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Press Enter to continue..."
    else
        read -p "برای ادامه Enter را فشار دهید..."
    fi
}

manage_logs() {
    print_header
    print_separator
    if [ "$LANG_SELECTED" == "en" ]; then
        echo -e "${BOLD}📝 Log Management${NC}"
    else
        echo -e "${BOLD}📝 مدیریت لاگ‌ها${NC}"
    fi
    print_separator
    echo ""
    
    # Find all config files
    if [ ! -d "$CONFIG_DIR" ] || [ -z "$(ls -A $CONFIG_DIR/*.yaml 2>/dev/null)" ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_warning "No configs found"
            read -p "Press Enter to continue..." < /dev/tty
        else
            print_warning "هیچ کانفیگی پیدا نشد"
            read -p "برای ادامه Enter را فشار دهید..." < /dev/tty
        fi
        return
    fi
    
    CONFIGS=$(ls -1 "$CONFIG_DIR"/*.yaml 2>/dev/null)
    
    if [ -z "$CONFIGS" ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_warning "No configs found"
            read -p "Press Enter to continue..." < /dev/tty
        else
            print_warning "هیچ کانفیگی پیدا نشد"
            read -p "برای ادامه Enter را فشار دهید..." < /dev/tty
        fi
        return
    fi
    
    # Display configs with current log levels
    if [ "$LANG_SELECTED" == "en" ]; then
        echo "Available configs:"
    else
        echo "کانفیگ‌های موجود:"
    fi
    echo ""
    INDEX=1
    declare -a CONFIG_ARRAY
    for CONFIG in $CONFIGS; do
        CONFIG_PATH="$CONFIG"
        CONFIG_NAME=$(basename "$CONFIG")
        ROLE=$(grep "^role:" "$CONFIG_PATH" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "unknown")
        CURRENT_LOG=$(grep -A1 "^log:" "$CONFIG_PATH" 2>/dev/null | grep "level:" | awk '{print $2}' | tr -d '"' || echo "info")
        echo -e "  ${CYAN}$INDEX${NC}) ${BOLD}$CONFIG_NAME${NC} (${ROLE}) - Log: ${BOLD}$CURRENT_LOG${NC}"
        CONFIG_ARRAY[$INDEX]="$CONFIG_PATH"
        INDEX=$((INDEX + 1))
    done
    
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        echo "Options:"
        echo -e "  ${CYAN}0${NC}) Change all configs at once"
        read -p "Select config (0 for all) [1]: " CONFIG_CHOICE < /dev/tty
    else
        echo "گزینه‌ها:"
        echo -e "  ${CYAN}0${NC}) تغییر همه کانفیگ‌ها به یکباره"
        read -p "کانفیگ را انتخاب کنید (0 برای همه) [1]: " CONFIG_CHOICE < /dev/tty
    fi
    CONFIG_CHOICE=${CONFIG_CHOICE:-1}
    
    # Select log level
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        echo "Log levels:"
        echo -e "  ${CYAN}1${NC}) none   - No logging"
        echo -e "  ${CYAN}2${NC}) debug  - Detailed debugging information"
        echo -e "  ${CYAN}3${NC}) info   - General information (default)"
        echo -e "  ${CYAN}4${NC}) warn   - Warnings only"
        echo -e "  ${CYAN}5${NC}) error  - Errors only"
        echo -e "  ${CYAN}6${NC}) fatal  - Fatal errors only"
        read -p "Select log level [3]: " LOG_CHOICE < /dev/tty
    else
        echo "سطح لاگ:"
        echo -e "  ${CYAN}1${NC}) none   - بدون لاگ"
        echo -e "  ${CYAN}2${NC}) debug  - اطلاعات دیباگ تفصیلی"
        echo -e "  ${CYAN}3${NC}) info   - اطلاعات عمومی (پیش‌فرض)"
        echo -e "  ${CYAN}4${NC}) warn   - فقط هشدارها"
        echo -e "  ${CYAN}5${NC}) error  - فقط خطاها"
        echo -e "  ${CYAN}6${NC}) fatal  - فقط خطاهای مرگبار"
        read -p "سطح لاگ را انتخاب کنید [3]: " LOG_CHOICE < /dev/tty
    fi
    LOG_CHOICE=${LOG_CHOICE:-3}
    
    case "$LOG_CHOICE" in
        1) NEW_LOG_LEVEL="none" ;;
        2) NEW_LOG_LEVEL="debug" ;;
        3) NEW_LOG_LEVEL="info" ;;
        4) NEW_LOG_LEVEL="warn" ;;
        5) NEW_LOG_LEVEL="error" ;;
        6) NEW_LOG_LEVEL="fatal" ;;
        *) NEW_LOG_LEVEL="info" ;;
    esac
    
    # Apply changes
    if [ "$CONFIG_CHOICE" = "0" ]; then
        # Change all configs
        CHANGED=0
        for CONFIG_PATH in "${CONFIG_ARRAY[@]}"; do
            if [ -n "$CONFIG_PATH" ] && [ -f "$CONFIG_PATH" ]; then
                # Update log level - find line with "level:" under "log:" section
                # Method 1: sed with proper YAML indentation handling
                sed -i.tmp '/^log:/,/^[^ ]/ { /^[[:space:]]*level:/s/level:.*/level: "'"$NEW_LOG_LEVEL"'"/ }' "$CONFIG_PATH" 2>/dev/null || \
                # Method 2: awk fallback
                awk '/^log:/{flag=1} flag && /^[[:space:]]*level:/{sub(/level:.*/, "level: \"'"$NEW_LOG_LEVEL"'\"")} /^[^ ]/ && !/^log:/{flag=0}1' "$CONFIG_PATH" > "$CONFIG_PATH.tmp" 2>/dev/null && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH" 2>/dev/null || true
                rm -f "$CONFIG_PATH.tmp" "$CONFIG_PATH.tmp.tmp" 2>/dev/null || true
                CHANGED=$((CHANGED + 1))
            fi
        done
        
        if [ "$CHANGED" -gt 0 ]; then
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Log level changed to '$NEW_LOG_LEVEL' for $CHANGED config(s)"
            else
                print_success "سطح لاگ برای $CHANGED کانفیگ به '$NEW_LOG_LEVEL' تغییر یافت"
            fi
        fi
    else
        # Change single config
        if [ -n "${CONFIG_ARRAY[$CONFIG_CHOICE]}" ] && [ -f "${CONFIG_ARRAY[$CONFIG_CHOICE]}" ]; then
            CONFIG_PATH="${CONFIG_ARRAY[$CONFIG_CHOICE]}"
            CONFIG_NAME=$(basename "$CONFIG_PATH")
            
            # Update log level - find line with "level:" under "log:" section
            # Method 1: sed with proper YAML indentation handling
            sed -i.tmp '/^log:/,/^[^ ]/ { /^[[:space:]]*level:/s/level:.*/level: "'"$NEW_LOG_LEVEL"'"/ }' "$CONFIG_PATH" 2>/dev/null || \
            # Method 2: awk fallback
            awk '/^log:/{flag=1} flag && /^[[:space:]]*level:/{sub(/level:.*/, "level: \"'"$NEW_LOG_LEVEL"'\"")} /^[^ ]/ && !/^log:/{flag=0}1' "$CONFIG_PATH" > "$CONFIG_PATH.tmp" 2>/dev/null && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH" 2>/dev/null || true
            rm -f "$CONFIG_PATH.tmp" "$CONFIG_PATH.tmp.tmp" 2>/dev/null || true
            
            if [ "$LANG_SELECTED" == "en" ]; then
                print_success "Log level changed to '$NEW_LOG_LEVEL' for $CONFIG_NAME"
            else
                print_success "سطح لاگ برای $CONFIG_NAME به '$NEW_LOG_LEVEL' تغییر یافت"
            fi
        else
            if [ "$LANG_SELECTED" == "en" ]; then
                print_error "Invalid config selection"
            else
                print_error "انتخاب کانفیگ نامعتبر"
            fi
        fi
    fi
    
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        echo "Note: Restart the service for changes to take effect:"
        echo "  sudo systemctl restart <service-name>"
    else
        echo "توجه: برای اعمال تغییرات، سرویس را restart کنید:"
        echo "  sudo systemctl restart <service-name>"
    fi
    
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Press Enter to continue..." < /dev/tty
    else
        read -p "برای ادامه Enter را فشار دهید..." < /dev/tty
    fi
}

# MTU Discovery Functions - توابع یافتن MTU بهینه
detect_ping_flags_mtu() {
    # Try to detect ping implementation for MTU discovery
    local ping_path=$(command -v ping)
    local ping_version=$(ping -V 2>&1 || echo "")
    local ping_help=$(ping -h 2>&1 || ping --help 2>&1 || echo "")
    
    # Check for macOS ping (BSD-based)
    if [ "$(uname)" = "Darwin" ]; then
        if echo "$ping_help" | grep -qE "\-D\s"; then
            PING_DF_FLAG_MTU="-D"
            PING_SIZE_FLAG_MTU="-s"
            PING_TIMEOUT_FLAG_MTU="-W"
            print_info "Detected: macOS ping (using -D flag)"
            return 0
        else
            PING_DF_FLAG_MTU=""
            PING_SIZE_FLAG_MTU="-s"
            PING_TIMEOUT_FLAG_MTU="-W"
            print_warning "Detected: macOS ping (DF flag not available)"
            print_info "Will use alternative fragmentation detection method"
            return 0
        fi
    fi
    
    # Check for iputils-ping (Linux, supports -M)
    if echo "$ping_help" | grep -q "\-M"; then
        if ping -c 1 -Mdo 127.0.0.1 2>&1 | grep -qiE "invalid|bad|unrecognized|unknown"; then
            PING_DF_FLAG_MTU="-M do"
        else
            PING_DF_FLAG_MTU="-Mdo"
        fi
        PING_SIZE_FLAG_MTU="-s"
        if echo "$ping_help" | grep -qE "\-W\s"; then
            PING_TIMEOUT_FLAG_MTU="-W"
        elif echo "$ping_help" | grep -qE "\-w\s"; then
            PING_TIMEOUT_FLAG_MTU="-w"
        else
            PING_TIMEOUT_FLAG_MTU="-W"
        fi
        print_info "Detected: iputils-ping (Linux) - using ${PING_DF_FLAG_MTU} format"
        return 0
    fi
    
    # Check for busybox ping
    if echo "$ping_version" | grep -qi "busybox"; then
        PING_DF_FLAG_MTU=""
        PING_SIZE_FLAG_MTU="-s"
        PING_TIMEOUT_FLAG_MTU="-W"
        print_warning "Detected: Busybox ping (DF flag may not be supported)"
        print_info "Will use alternative fragmentation detection method"
        return 0
    fi
    
    # Check for inetutils-ping (GNU)
    if echo "$ping_version" | grep -qi "inetutils\|GNU"; then
        if echo "$ping_help" | grep -q "\-D"; then
            PING_DF_FLAG_MTU="-D"
            PING_SIZE_FLAG_MTU="-s"
            PING_TIMEOUT_FLAG_MTU="-W"
            print_info "Detected: inetutils-ping (using -D flag)"
            return 0
        fi
        PING_DF_FLAG_MTU=""
        PING_SIZE_FLAG_MTU="-s"
        PING_TIMEOUT_FLAG_MTU="-W"
        print_warning "Detected: inetutils-ping (DF flag not available)"
        print_info "Will use alternative fragmentation detection method"
        return 0
    fi
    
    # Fallback
    PING_DF_FLAG_MTU=""
    PING_SIZE_FLAG_MTU="-s"
    PING_TIMEOUT_FLAG_MTU="-W"
    print_warning "Could not detect ping implementation"
    print_info "Will attempt to use -s flag and detect fragmentation from output"
    return 0
}

# Global variables for MTU ping flags
PING_DF_FLAG_MTU=""
PING_SIZE_FLAG_MTU="-s"
PING_TIMEOUT_FLAG_MTU="-W"

test_basic_ping_mtu() {
    local target=$1
    
    print_step "Testing basic connectivity to $target..."
    local result
    result=$(ping -c 2 ${PING_TIMEOUT_FLAG_MTU} 2 "$target" 2>&1)
    local exit_code=$?
    
    local received=0
    local received_line=$(echo "$result" | grep -oE '[0-9]+\s+packets?\s+received' | head -1)
    if [ -n "$received_line" ]; then
        received=$(echo "$received_line" | grep -oE '[0-9]+' | head -1)
        received=${received:-0}
    fi
    
    local has_response=$(echo "$result" | grep -c "bytes from" || echo "0")
    
    if [ "$received" -gt 0 ] || [ "$has_response" -gt 0 ] || [ "$exit_code" -eq 0 ]; then
        print_success "Basic connectivity OK"
        return 0
    else
        print_error "Cannot reach $target"
        echo "$result" | head -5 | sed 's/^/  /'
        return 1
    fi
}

test_mtu_icmp() {
    local mtu=$1
    local target=$2
    local packet_size=$((mtu - 28))
    
    local ping_cmd="ping -c 3 ${PING_TIMEOUT_FLAG_MTU} 2"
    ping_cmd="${ping_cmd} ${PING_SIZE_FLAG_MTU} ${packet_size}"
    
    if [ -n "$PING_DF_FLAG_MTU" ]; then
        ping_cmd="${ping_cmd} ${PING_DF_FLAG_MTU}"
    fi
    
    ping_cmd="${ping_cmd} ${target}"
    
    local result=$(eval "$ping_cmd" 2>&1)
    local exit_code=$?
    
    if echo "$result" | grep -qiE "frag needed|Message too long|packet too big|Fragmentation required|fragmentation needed|needs to be fragmented"; then
        return 1
    fi
    
    if [ -z "$PING_DF_FLAG_MTU" ]; then
        local received=$(echo "$result" | grep -oE '[0-9]+\s+packets?\s+received' | grep -oE '[0-9]+' | head -1)
        if [ -z "$received" ] || [ "$received" -eq 0 ]; then
            return 1
        fi
        if echo "$result" | grep -qiE "packet too large|exceeds maximum|too large"; then
            return 1
        fi
    fi
    
    if [ $exit_code -eq 0 ]; then
        return 0
    fi
    
    local received=$(echo "$result" | grep -oE '[0-9]+\s+packets?\s+received' | grep -oE '[0-9]+' | head -1)
    if [ -n "$received" ] && [ "$received" -gt 0 ]; then
        return 0
    fi
    
    return 1
}

extract_packet_loss_mtu() {
    local ping_output="$1"
    
    local loss_line=$(echo "$ping_output" | grep -iE "packet loss|loss" | tail -1)
    
    if [ -n "$loss_line" ]; then
        local loss_percent=$(echo "$loss_line" | grep -oE '[0-9]+\.?[0-9]*%' | grep -oE '[0-9]+\.?[0-9]*' | head -1)
        if [ -n "$loss_percent" ]; then
            loss_percent=$(echo "$loss_percent" | cut -d. -f1)
            echo "${loss_percent:-0}"
            return 0
        fi
    fi
    
    local transmitted=$(echo "$ping_output" | grep -oE '[0-9]+\s+packets?\s+transmitted' | grep -oE '[0-9]+' | head -1)
    local received=$(echo "$ping_output" | grep -oE '[0-9]+\s+packets?\s+received' | grep -oE '[0-9]+' | head -1)
    
    if [ -n "$transmitted" ] && [ -n "$received" ]; then
        transmitted=$(echo "$transmitted" | grep -oE '[0-9]+' | head -1)
        received=$(echo "$received" | grep -oE '[0-9]+' | head -1)
        if [ -n "$transmitted" ] && [ -n "$received" ] && [ "$transmitted" -gt 0 ]; then
            local loss=$((100 - (received * 100 / transmitted)))
            echo "$loss"
            return 0
        fi
    fi
    
    if echo "$ping_output" | grep -qiE "100% packet loss|unreachable|timeout|no answer"; then
        echo "100"
        return 0
    fi
    
    echo "0"
}

validate_mtu_stability() {
    local mtu=$1
    local target=$2
    local duration=$3
    local packet_size=$((mtu - 28))
    local packet_count=$((duration * 2))
    
    print_step "Testing MTU $mtu for ${duration} seconds (${packet_count} packets @ 2 pps)..."
    
    local ping_args=("ping" "-c" "${packet_count}" "-i" "0.5" "${PING_TIMEOUT_FLAG_MTU}" "2" "${PING_SIZE_FLAG_MTU}" "${packet_size}")
    
    if [ -n "$PING_DF_FLAG_MTU" ]; then
        if [ "$PING_DF_FLAG_MTU" = "-M do" ]; then
            ping_args+=("-M" "do")
        else
            ping_args+=("${PING_DF_FLAG_MTU}")
        fi
    fi
    
    ping_args+=("${target}")
    
    local ping_cmd_str="${ping_args[*]}"
    echo -e "  ${CYAN}Command:${NC} ${BOLD}${ping_cmd_str}${NC}"
    echo -e "  ${CYAN}This may take a while. Please wait...${NC}"
    echo ""
    
    local ping_output
    ping_output=$(timeout $((duration + 10)) "${ping_args[@]}" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ] && [ $exit_code -ne 124 ]; then
        local output_lines=$(echo "$ping_output" | wc -l)
        if [ "$output_lines" -lt 10 ]; then
            print_warning "Ping command: ${ping_args[*]}"
            print_warning "Ping output (first 5 lines):"
            echo "$ping_output" | head -5 | sed 's/^/  /'
        fi
    fi
    
    if [ $exit_code -eq 124 ]; then
        print_error "MTU $mtu test timed out"
        return 1
    fi
    
    if echo "$ping_output" | grep -qiE "frag needed|Message too long|packet too big|Fragmentation required|fragmentation needed"; then
        print_error "MTU $mtu causes fragmentation"
        return 1
    fi
    
    if [ -z "$ping_output" ]; then
        print_error "MTU $mtu test failed: no output from ping"
        return 1
    fi
    
    local received=$(echo "$ping_output" | grep -oE '[0-9]+\s+packets?\s+received' | grep -oE '[0-9]+' | head -1)
    local transmitted=$(echo "$ping_output" | grep -oE '[0-9]+\s+packets?\s+transmitted' | grep -oE '[0-9]+' | head -1)
    local has_responses=$(echo "$ping_output" | grep -c "bytes from" || echo "0")
    
    if [ -n "$received" ] && [ "$received" != "0" ] && [ "$received" -gt 0 ]; then
        :
    elif [ "$has_responses" -gt 0 ]; then
        :
    else
        if echo "$ping_output" | grep -qiE "invalid|bad|unrecognized|unknown option"; then
            print_error "MTU $mtu test failed: ping command error (invalid arguments)"
            echo "$ping_output" | grep -iE "invalid|bad|unrecognized|unknown" | head -2 | sed 's/^/  /'
            return 1
        fi
        if echo "$ping_output" | grep -qiE "unknown host|Name or service not known|Network is unreachable|Permission denied|Operation not permitted"; then
            print_error "MTU $mtu test failed: network error"
            echo "$ping_output" | grep -iE "unknown host|Name or service|unreachable|Permission|Operation" | head -2 | sed 's/^/  /'
            return 1
        fi
        print_error "MTU $mtu test failed: no packets received"
        if [ -n "$ping_output" ]; then
            echo "$ping_output" | tail -10 | sed 's/^/  /'
        fi
        return 1
    fi
    
    local packet_loss=$(extract_packet_loss_mtu "$ping_output")
    packet_loss=$(echo "$packet_loss" | grep -oE '[0-9]+' | head -1)
    packet_loss=${packet_loss:-0}
    
    if [ "$packet_loss" -gt 0 ]; then
        print_warning "MTU $mtu has ${packet_loss}% packet loss (target: 0%)"
        return 1
    fi
    
    print_success "MTU $mtu passed stability test (0% packet loss)"
    return 0
}

discover_optimal_mtu() {
    local target=$1
    local test_duration=$2
    
    print_separator
    echo ""
    print_info "Phase 1: Rapid MTU Discovery"
    print_separator
    echo ""
    
    local max_mtu=0
    local tested_mtu=1500
    
    print_step "Scanning MTU range: 1500 → 1200"
    echo ""
    
    while [ $tested_mtu -ge 1200 ]; do
        printf "\r${ARROW} Testing MTU ${BOLD}$tested_mtu${NC}... "
        
        if test_mtu_icmp "$tested_mtu" "$target"; then
            max_mtu=$tested_mtu
            printf "\r${CHECK} MTU ${BOLD}$tested_mtu${NC} works (no fragmentation)\n"
            break
        else
            printf "\r${CROSS} MTU ${BOLD}$tested_mtu${NC} failed (fragmentation detected)\n"
        fi
        
        tested_mtu=$((tested_mtu - 10))
    done
    
    if [ $max_mtu -eq 0 ]; then
        print_error "No working MTU found in range 1200-1500"
        print_info "Trying lower values..."
        
        tested_mtu=1190
        while [ $tested_mtu -ge 1000 ]; do
            printf "\r${ARROW} Testing MTU ${BOLD}$tested_mtu${NC}... "
            
            if test_mtu_icmp "$tested_mtu" "$target"; then
                max_mtu=$tested_mtu
                printf "\r${CHECK} MTU ${BOLD}$tested_mtu${NC} works\n"
                break
            fi
            
            tested_mtu=$((tested_mtu - 10))
        done
    fi
    
    if [ $max_mtu -eq 0 ]; then
        print_error "Failed to find any working MTU"
        return 1
    fi
    
    echo ""
    print_success "Initial discovery complete: Maximum MTU = $max_mtu"
    echo ""
    
    print_separator
    echo ""
    print_info "Phase 2: Stability Validation (Zero-Tolerance Policy)"
    print_info "Target: 0% packet loss over ${test_duration} seconds"
    print_separator
    echo ""
    
    local current_mtu=$max_mtu
    local stable_mtu=0
    local attempts=0
    local max_attempts=20
    
    while [ $attempts -lt $max_attempts ] && [ $current_mtu -ge 1000 ]; do
        attempts=$((attempts + 1))
        
        echo ""
        print_info "Attempt $attempts: Testing MTU $current_mtu"
        
        if validate_mtu_stability "$current_mtu" "$target" "$test_duration"; then
            stable_mtu=$current_mtu
            break
        else
            current_mtu=$((current_mtu - 10))
            print_warning "Decreasing MTU to $current_mtu and retrying..."
        fi
    done
    
    if [ $stable_mtu -eq 0 ]; then
        print_error "Failed to find stable MTU after $attempts attempts"
        print_info "Last tested MTU: $current_mtu"
        return 1
    fi
    
    local mss=$((stable_mtu - 40))
    
    echo ""
    print_separator
    echo ""
    print_success "Optimal MTU Found!"
    print_separator
    echo ""
    echo -e "  ${BOLD}Recommended MTU:${NC}     ${GREEN}$stable_mtu${NC}"
    echo -e "  ${BOLD}Recommended MSS:${NC}     ${GREEN}$mss${NC} (MTU - 40)"
    echo -e "  ${BOLD}Test Duration:${NC}       ${CYAN}${test_duration} seconds${NC}"
    echo -e "  ${BOLD}Packet Loss:${NC}           ${GREEN}0%${NC}"
    echo ""
    print_separator
    echo ""
    
    print_info "Paqet Configuration Recommendation:"
    echo ""
    echo -e "  ${CYAN}kcp:${NC}"
    echo -e "    ${CYAN}mtu:${NC} $stable_mtu"
    echo ""
    echo -e "  ${CYAN}network:${NC}"
    echo -e "    ${CYAN}ipv4:${NC}"
    echo -e "      ${CYAN}addr:${NC} \"YOUR_IP:$stable_mtu\""
    echo ""
}

find_optimal_mtu() {
    print_header
    print_separator
    if [ "$LANG_SELECTED" == "en" ]; then
        echo -e "${BOLD}🔍 Find Optimal MTU${NC}"
    else
        echo -e "${BOLD}🔍 یافتن MTU بهینه${NC}"
    fi
    print_separator
    echo ""
    
    # Detect ping implementation
    detect_ping_flags_mtu
    echo ""
    
    # Get target IP
    echo ""
    print_separator
    echo ""
    if [ -c /dev/tty ] && [ -t 0 ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            read -p "Enter target server IP address: " TARGET_IP < /dev/tty
        else
            read -p "آدرس IP سرور مقصد را وارد کنید: " TARGET_IP < /dev/tty
        fi
    else
        if [ "$LANG_SELECTED" == "en" ]; then
            read -p "Enter target server IP address: " TARGET_IP
        else
            read -p "آدرس IP سرور مقصد را وارد کنید: " TARGET_IP
        fi
    fi
    
    if [ -z "$TARGET_IP" ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_error "Target IP is required"
        else
            print_error "آدرس IP الزامی است"
        fi
        echo ""
        if [ "$LANG_SELECTED" == "en" ]; then
            read -p "Press Enter to continue..." < /dev/tty
        else
            read -p "برای ادامه Enter را فشار دهید..." < /dev/tty
        fi
        return 1
    fi
    
    if ! echo "$TARGET_IP" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
        print_warning "IP format validation skipped (proceeding anyway)"
    fi
    
    # Test basic connectivity
    echo ""
    if ! test_basic_ping_mtu "$TARGET_IP"; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_error "Cannot establish basic connectivity. Please check:"
            echo "  - Network connection"
            echo "  - Target IP address: $TARGET_IP"
            echo "  - Firewall rules"
        else
            print_error "نمی‌توان اتصال پایه برقرار کرد. لطفاً بررسی کنید:"
            echo "  - اتصال شبکه"
            echo "  - آدرس IP: $TARGET_IP"
            echo "  - قوانین فایروال"
        fi
        echo ""
        if [ "$LANG_SELECTED" == "en" ]; then
            read -p "Press Enter to continue..." < /dev/tty
        else
            read -p "برای ادامه Enter را فشار دهید..." < /dev/tty
        fi
        return 1
    fi
    echo ""
    
    # Get test duration
    echo ""
    if [ -c /dev/tty ] && [ -t 0 ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            read -p "Enter test duration in seconds [300]: " TEST_DURATION < /dev/tty
        else
            read -p "مدت زمان تست را به ثانیه وارد کنید [300]: " TEST_DURATION < /dev/tty
        fi
    else
        if [ "$LANG_SELECTED" == "en" ]; then
            read -p "Enter test duration in seconds [300]: " TEST_DURATION
        else
            read -p "مدت زمان تست را به ثانیه وارد کنید [300]: " TEST_DURATION
        fi
    fi
    TEST_DURATION=${TEST_DURATION:-300}
    
    if ! [[ "$TEST_DURATION" =~ ^[0-9]+$ ]] || [ "$TEST_DURATION" -lt 60 ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_warning "Invalid duration, using default: 300 seconds"
        else
            print_warning "مدت زمان نامعتبر، استفاده از پیش‌فرض: 300 ثانیه"
        fi
        TEST_DURATION=300
    fi
    
    # Confirm before starting
    echo ""
    print_separator
    echo ""
    print_info "Configuration:"
    echo -e "  ${CYAN}Target:${NC}        $TARGET_IP"
    echo -e "  ${CYAN}Duration:${NC}      ${TEST_DURATION} seconds"
    echo ""
    if [ -c /dev/tty ] && [ -t 0 ]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            read -p "Start MTU discovery? [Y/n]: " CONFIRM < /dev/tty
        else
            read -p "شروع یافتن MTU؟ [Y/n]: " CONFIRM < /dev/tty
        fi
    else
        if [ "$LANG_SELECTED" == "en" ]; then
            read -p "Start MTU discovery? [Y/n]: " CONFIRM
        else
            read -p "شروع یافتن MTU؟ [Y/n]: " CONFIRM
        fi
    fi
    
    if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        if [ "$LANG_SELECTED" == "en" ]; then
            print_info "Cancelled by user"
        else
            print_info "لغو شد توسط کاربر"
        fi
        echo ""
        if [ "$LANG_SELECTED" == "en" ]; then
            read -p "Press Enter to continue..." < /dev/tty
        else
            read -p "برای ادامه Enter را فشار دهید..." < /dev/tty
        fi
        return 0
    fi
    
    echo ""
    
    # Run discovery
    if discover_optimal_mtu "$TARGET_IP" "$TEST_DURATION"; then
        echo ""
        if [ "$LANG_SELECTED" == "en" ]; then
            print_success "MTU discovery completed!"
            echo ""
            print_info "You can now use the recommended MTU value when setting up tunnels."
            print_info "The default MTU in this script is set to 1480."
        else
            print_success "یافتن MTU کامل شد!"
            echo ""
            print_info "اکنون می‌توانید از مقدار MTU پیشنهادی هنگام راه‌اندازی تونل‌ها استفاده کنید."
            print_info "MTU پیش‌فرض در این اسکریپت 1480 تنظیم شده است."
        fi
    else
        if [ "$LANG_SELECTED" == "en" ]; then
            print_warning "MTU discovery had some issues, but you can still use the default MTU (1480)"
        else
            print_warning "یافتن MTU مشکلاتی داشت، اما می‌توانید از MTU پیش‌فرض (1480) استفاده کنید"
        fi
    fi
    
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Press Enter to continue..." < /dev/tty
    else
        read -p "برای ادامه Enter را فشار دهید..." < /dev/tty
    fi
}

show_main_menu() {
    print_header
    
    # نمایش وضعیت
    if check_paqet_installed; then
        if [ "$LANG_SELECTED" == "en" ]; then
            echo -e "${CHECK} ${GREEN}Paqet is installed${NC}"
        else
            echo -e "${CHECK} ${GREEN}Paqet نصب شده است${NC}"
        fi
    else
        if [ "$LANG_SELECTED" == "en" ]; then
            echo -e "${WARN} ${YELLOW}Paqet is not installed (will auto-install)${NC}"
        else
            echo -e "${WARN} ${YELLOW}Paqet نصب نشده است (خودکار نصب می‌شود)${NC}"
        fi
    fi
    
    echo ""
    print_separator
    if [ "$LANG_SELECTED" == "en" ]; then
        echo -e "${BOLD}Main Menu${NC}"
    else
        echo -e "${BOLD}منوی اصلی${NC}"
    fi
    print_separator
    echo ""
    echo -e "  ${CYAN}1${NC}) ${BOLD}$(t setup_server)${NC}"
    echo -e "  ${CYAN}2${NC}) ${BOLD}$(t setup_client)${NC}"
    echo -e "  ${CYAN}3${NC}) ${BOLD}$(t manage_configs)${NC}"
    echo -e "  ${CYAN}4${NC}) ${BOLD}$(t manage_services)${NC}"
    echo -e "  ${CYAN}5${NC}) ${BOLD}$(t manage_logs)${NC}"
    echo -e "  ${CYAN}6${NC}) ${BOLD}$(t mtu_discovery)${NC}"
    echo -e "  ${CYAN}7${NC}) ${BOLD}$(t exit)${NC}"
    echo ""
    if [ "$LANG_SELECTED" == "en" ]; then
        read -p "Select [1-7]: " MENU_CHOICE
    else
        read -p "انتخاب کنید [1-7]: " MENU_CHOICE
    fi
    
    case "$MENU_CHOICE" in
        1)
            setup_server
            ;;
        2)
            setup_client
            ;;
        3)
            list_configs
            ;;
        4)
            manage_services
            ;;
        5)
            manage_logs
            ;;
        6)
            find_optimal_mtu
            ;;
        7)
            echo ""
            if [ "$LANG_SELECTED" == "en" ]; then
                echo "Goodbye! 👋"
            else
                echo "خداحافظ! 👋"
            fi
            exit 0
            ;;
        *)
            if [ "$LANG_SELECTED" == "en" ]; then
                print_error "Invalid choice"
            else
                print_error "انتخاب نامعتبر"
            fi
            sleep 2
            ;;
    esac
}

# شروع برنامه
main() {
    # اگر stdin یک pipe است، آن را به /dev/tty redirect کن
    if [ ! -t 0 ] && [ -c /dev/tty ]; then
        exec < /dev/tty
    fi
    
    # انتخاب زبان در ابتدا
    select_language
    
    check_root
    
    while true; do
        show_main_menu
    done
}

main
