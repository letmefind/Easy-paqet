#!/bin/bash

# Paqet Interactive Setup Script - English
# This script guides you step by step and does everything automatically

export LC_ALL=C.UTF-8 2>/dev/null || export LANG=C.UTF-8 2>/dev/null

clear
echo "╔════════════════════════════════════════════════════════╗"
echo "║          Paqet - Interactive Setup                     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Paqet Interactive Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Server type detection
read -p "🔹 Is this server Client (A) or Server (B)? [A/B]: " SERVER_TYPE

if [[ "$SERVER_TYPE" == "A" || "$SERVER_TYPE" == "a" ]]; then
    ROLE="client"
    CONFIG_FILE="config_client.yaml"
    SERVER_NAME="Client"
    echo "✓ Client mode selected"
elif [[ "$SERVER_TYPE" == "B" || "$SERVER_TYPE" == "b" ]]; then
    ROLE="server"
    CONFIG_FILE="config_server.yaml"
    SERVER_NAME="Server"
    echo "✓ Server mode selected"
else
    echo "❌ Invalid selection!"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Network Information Collection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Finding network interfaces
echo "🔹 Available network interfaces:"
echo ""

# Build array of interfaces
INTERFACES=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))
INTERFACE_COUNT=${#INTERFACES[@]}

echo "Available interfaces list:"
for i in "${!INTERFACES[@]}"; do
    echo "  $((i+1))) ${INTERFACES[$i]}"
done
echo ""

read -p "Which interface do you want? (number or name) [1-$INTERFACE_COUNT]: " interface_choice

# Check if number or name entered
if [[ "$interface_choice" =~ ^[0-9]+$ ]]; then
    if [ "$interface_choice" -ge 1 ] && [ "$interface_choice" -le "$INTERFACE_COUNT" ]; then
        INTERFACE="${INTERFACES[$((interface_choice-1))]}"
        echo "✓ Selected interface: $INTERFACE"
    else
        echo "❌ Invalid number! Please select from the list above."
        exit 1
    fi
else
    if [[ " ${INTERFACES[@]} " =~ " ${interface_choice} " ]]; then
        INTERFACE="$interface_choice"
        echo "✓ Selected interface: $INTERFACE"
    else
        echo "❌ Interface not found! Please select from the list above."
        exit 1
    fi
fi
echo ""

# Finding local IP
LOCAL_IP=$(ip -4 addr show $INTERFACE 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
if [ -z "$LOCAL_IP" ]; then
    read -p "Enter local IP address of this server: " LOCAL_IP
else
    echo "🔹 Found local IP: $LOCAL_IP"
    read -p "Is this IP correct? [Y/n]: " CONFIRM
    if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
        read -p "Enter local IP address: " LOCAL_IP
    fi
fi

# Finding router MAC
GATEWAY_IP=$(ip route | grep default | awk '{print $3}' | head -1)
if [ -n "$GATEWAY_IP" ]; then
    echo "🔹 Gateway IP from routing table: $GATEWAY_IP"
    
    # Check if Gateway IP is a private/internal IP
    if [[ "$GATEWAY_IP" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]+\.[0-9]+$ ]] || \
       [[ "$GATEWAY_IP" =~ ^10\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
       [[ "$GATEWAY_IP" =~ ^192\.168\.[0-9]+\.[0-9]+$ ]]; then
        echo "   ⚠️  This is a private/internal IP (usually correct for cloud servers)"
        echo "   This IP is used to find MAC address, not for routing"
    fi
    
    # Find MAC address from ARP table
    ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
    
    # If MAC not found, try pinging to populate ARP
    if [ -z "$ROUTER_MAC" ]; then
        echo "   Pinging Gateway to find MAC..."
        ping -c 1 -W 1 $GATEWAY_IP > /dev/null 2>&1
        sleep 1
        ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
    fi
    
    if [ -n "$ROUTER_MAC" ]; then
        echo "🔹 Found router MAC address: $ROUTER_MAC"
        echo ""
        echo "   📝 Note: This MAC address is used for sending packets."
        echo "   On cloud servers, Gateway IP may be an internal IP which is correct."
        echo ""
        read -p "Is this MAC address correct? [Y/n]: " CONFIRM
        if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
            read -p "Enter router MAC address (e.g., aa:bb:cc:dd:ee:ff): " ROUTER_MAC
        fi
    else
        echo "⚠️  Router MAC address not found"
        echo ""
        echo "   To find MAC address, you can use:"
        echo "   arp -n $GATEWAY_IP"
        echo "   or"
        echo "   ip neigh show $GATEWAY_IP"
        echo ""
        read -p "Enter router MAC address (e.g., aa:bb:cc:dd:ee:ff): " ROUTER_MAC
    fi
else
    echo "⚠️  Gateway IP not found"
    echo ""
    echo "   To find Gateway IP, you can use:"
    echo "   ip route | grep default"
    echo ""
    read -p "Enter Gateway IP (or press Enter to skip): " GATEWAY_IP
    if [ -n "$GATEWAY_IP" ]; then
        ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
        if [ -z "$ROUTER_MAC" ]; then
            ping -c 1 -W 1 $GATEWAY_IP > /dev/null 2>&1
            sleep 1
            ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
        fi
        if [ -n "$ROUTER_MAC" ]; then
            echo "✓ MAC address found: $ROUTER_MAC"
        else
            read -p "Enter router MAC address (e.g., aa:bb:cc:dd:ee:ff): " ROUTER_MAC
        fi
    else
        read -p "Enter router MAC address directly (e.g., aa:bb:cc:dd:ee:ff): " ROUTER_MAC
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Connection and Encryption Settings"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$ROLE" == "client" ]; then
    read -p "Enter Server B IP address: " SERVER_IP
    read -p "Connection port to Server B (default: 9999): " SERVER_PORT
    SERVER_PORT=${SERVER_PORT:-9999}
    SERVER_ADDR="$SERVER_IP:$SERVER_PORT"
    LOCAL_PORT=0
else
    read -p "Server listen port (default: 9999): " LISTEN_PORT
    LISTEN_PORT=${LISTEN_PORT:-9999}
    LOCAL_PORT=$LISTEN_PORT
fi

# Generate or use existing key
echo ""
echo "🔹 For encryption key:"
echo "   1) Generate new key (recommended)"
echo "   2) Use existing key"
read -p "   Select [1/2]: " KEY_CHOICE

if [ "$KEY_CHOICE" == "1" ]; then
    if command -v openssl &> /dev/null; then
        SECRET_KEY=$(openssl rand -base64 32)
        echo "✓ New key generated"
    else
        echo "⚠️  openssl not found, using default key"
        SECRET_KEY="AY9Frl1VHWJB01lmKqLgE6dJllLhF3Sn4Lw/6BrcyYY="
    fi
else
    read -p "Enter encryption key: " SECRET_KEY
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Configuration Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Server Type: $SERVER_NAME"
echo "Interface: $INTERFACE"
echo "Local IP: $LOCAL_IP"
echo "Router MAC: $ROUTER_MAC"
if [ "$ROLE" == "client" ]; then
    echo "Server Address: $SERVER_ADDR"
else
    echo "Listen Port: $LISTEN_PORT"
fi
echo "Encryption Key: ${SECRET_KEY:0:20}..."
echo ""
read -p "Are these settings correct? [Y/n]: " CONFIRM

if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
    echo "❌ Setup cancelled"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  Creating Configuration File"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Creating client config
if [ "$ROLE" == "client" ]; then
    cat > $CONFIG_FILE <<EOF
# Client config (Server A)
# Created by interactive setup script

role: "client"

log:
  level: "info"

socks5:
  - listen: "127.0.0.1:1080"
    username: ""
    password: ""

network:
  interface: "$INTERFACE"
  local_addr: "$LOCAL_IP:$LOCAL_PORT"
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
  conn: 1
  
  kcp:
    mode: "fast3"
    mtu: 1350
    rcvwnd: 512
    sndwnd: 512
    
    block: "aes"
    key: "$SECRET_KEY"
    
    smuxbuf: 4194304
    streambuf: 2097152
EOF
else
    # Creating server config
    cat > $CONFIG_FILE <<EOF
# Server config (Server B)
# Created by interactive setup script

role: "server"

log:
  level: "info"

listen:
  addr: ":$LISTEN_PORT"

network:
  interface: "$INTERFACE"
  local_addr: "$LOCAL_IP:$LOCAL_PORT"
  router_mac: "$ROUTER_MAC"
  
  pcap:
    sockbuf: 8388608
  
  tcp:
    local_flag: ["PA"]

transport:
  protocol: "kcp"
  conn: 1
  
  kcp:
    mode: "fast3"
    mtu: 1350
    rcvwnd: 1024
    sndwnd: 1024
    
    block: "aes"
    key: "$SECRET_KEY"
    
    smuxbuf: 4194304
    streambuf: 2097152
EOF
fi

echo "✓ Configuration file $CONFIG_FILE created"

# Apply iptables if server
if [ "$ROLE" == "server" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔥 Applying iptables Rules"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    read -p "Do you want to apply iptables rules? [Y/n]: " APPLY
    
    if [[ "$APPLY" != "n" && "$APPLY" != "N" ]]; then
        echo "Applying iptables rules..."
        
        PORT=$LISTEN_PORT
        
        sudo iptables -t raw -A PREROUTING -p tcp --dport $PORT -j NOTRACK 2>/dev/null
        sudo iptables -t raw -A OUTPUT -p tcp --sport $PORT -j NOTRACK 2>/dev/null
        sudo iptables -t mangle -A OUTPUT -p tcp --sport $PORT --tcp-flags RST RST -j DROP 2>/dev/null
        sudo iptables -t filter -A INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null
        sudo iptables -t filter -A OUTPUT -p tcp --sport $PORT -j ACCEPT 2>/dev/null
        
        if command -v iptables-save &> /dev/null; then
            sudo mkdir -p /etc/iptables
            sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
        fi
        
        if [ -f /etc/redhat-release ]; then
            sudo service iptables save 2>/dev/null || sudo iptables-save > /etc/sysconfig/iptables
        fi
        
        echo "✓ iptables rules applied"
    fi
fi

# Check paqet installation
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📥 Checking Paqet Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v paqet &> /dev/null; then
    echo "✓ Paqet found"
    PAQET_CMD="paqet"
else
    if [ -f "./paqet" ]; then
        echo "✓ Paqet file found in current directory"
        PAQET_CMD="./paqet"
    else
        echo "⚠️  Paqet not found"
        read -p "Do you want to download it now? [Y/n]: " DOWNLOAD
        
        if [[ "$DOWNLOAD" != "n" && "$DOWNLOAD" != "N" ]]; then
            echo "Downloading paqet..."
            
            # Detect operating system and architecture
            OS=""
            ARCH=""
            
            # Detect OS
            case "$(uname -s)" in
                Linux*)     OS="linux" ;;
                Darwin*)    OS="darwin" ;;
                CYGWIN*)    OS="windows" ;;
                MINGW*)     OS="windows" ;;
                MSYS*)      OS="windows" ;;
                *)          OS="linux" ;;  # Default
            esac
            
            # Detect architecture
            case "$(uname -m)" in
                x86_64|amd64)   ARCH="amd64" ;;
                aarch64|arm64)  ARCH="arm64" ;;
                armv7l|armv6l)  ARCH="arm" ;;
                *)              ARCH="amd64" ;;  # Default
            esac
            
            echo "   Operating System: $OS"
            echo "   Architecture: $ARCH"
            
            # Use GitHub API to find latest release and available files
            if command -v curl &> /dev/null; then
                echo "   Checking latest release..."
                RELEASE_INFO=$(curl -s https://api.github.com/repos/hanselime/paqet/releases/latest)
                LATEST_RELEASE=$(echo "$RELEASE_INFO" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
                
                if [ -n "$LATEST_RELEASE" ]; then
                    echo "   Latest version found: $LATEST_RELEASE"
                    
                    # Determine file extension based on OS
                    if [ "$OS" == "windows" ]; then
                        FILE_EXT=".zip"
                    else
                        FILE_EXT=".tar.gz"
                    fi
                    
                    # Build correct filename: paqet-OS-ARCH-VERSION.EXT
                    CORRECT_FILENAME="paqet-${OS}-${ARCH}-${LATEST_RELEASE}${FILE_EXT}"
                    DOWNLOAD_URL="https://github.com/hanselime/paqet/releases/download/${LATEST_RELEASE}/${CORRECT_FILENAME}"
                    echo "   Trying correct format: $CORRECT_FILENAME..."
                    
                    DOWNLOAD_SUCCESS=false
                    
                    if wget -q --spider "$DOWNLOAD_URL" 2>/dev/null; then
                        TEMP_FILE=$(mktemp)
                        wget "$DOWNLOAD_URL" -O "$TEMP_FILE" 2>/dev/null
                        
                        if [ $? -eq 0 ] && [ -f "$TEMP_FILE" ]; then
                            echo "   Extracting from tar.gz..."
                            tar -xzf "$TEMP_FILE" -C . 2>/dev/null
                            rm "$TEMP_FILE"
                            # Find extracted paqet file (might be in a subdirectory)
                            if [ -f "./paqet" ]; then
                                chmod +x paqet
                                PAQET_CMD="./paqet"
                                echo "✓ Paqet downloaded and extracted ($CORRECT_FILENAME)"
                                DOWNLOAD_SUCCESS=true
                            else
                                # Look for paqet in subdirectories
                                PAQET_FILE=$(find . -name "paqet" -type f 2>/dev/null | head -1)
                                if [ -n "$PAQET_FILE" ]; then
                                    mv "$PAQET_FILE" ./paqet
                                    chmod +x paqet
                                    PAQET_CMD="./paqet"
                                    echo "✓ Paqet downloaded and extracted ($CORRECT_FILENAME)"
                                    DOWNLOAD_SUCCESS=true
                                fi
                            fi
                        fi
                    fi
                    
                    # If not found, try actual files from release
                    if [ "$DOWNLOAD_SUCCESS" == false ]; then
                        # Extract asset names from API that match OS and ARCH
                        ASSET_NAMES=$(echo "$RELEASE_INFO" | python3 -c "import sys, json; data=json.load(sys.stdin); print('\n'.join([a['name'] for a in data.get('assets', []) if '$OS' in a['name'].lower() and '$ARCH' in a['name'].lower()]))" 2>/dev/null || echo "$RELEASE_INFO" | grep '"name":' | grep -i "$OS.*$ARCH\|$ARCH.*$OS" | sed -E 's/.*"name":\s*"([^"]+)".*/\1/')
                        
                        if [ -n "$ASSET_NAMES" ]; then
                            for ASSET_NAME in $ASSET_NAMES; do
                                DOWNLOAD_URL="https://github.com/hanselime/paqet/releases/download/${LATEST_RELEASE}/${ASSET_NAME}"
                                echo "   Trying actual file: $ASSET_NAME..."
                            
                            # Download file
                            if wget -q --spider "$DOWNLOAD_URL" 2>/dev/null; then
                                TEMP_FILE=$(mktemp)
                                wget "$DOWNLOAD_URL" -O "$TEMP_FILE" 2>/dev/null
                                
                                if [ $? -eq 0 ] && [ -f "$TEMP_FILE" ]; then
                                    # If tar.gz or tar, extract it
                                    if [[ "$ASSET_NAME" == *.tar.gz ]] || [[ "$ASSET_NAME" == *.tgz ]]; then
                                        echo "   Extracting from tar.gz..."
                                        tar -xzf "$TEMP_FILE" -C . 2>/dev/null
                                        rm "$TEMP_FILE"
                                        # Find extracted paqet file (might be in a subdirectory)
                                        if [ -f "./paqet" ]; then
                                            chmod +x paqet
                                            PAQET_CMD="./paqet"
                                            echo "✓ Paqet downloaded and extracted ($ASSET_NAME)"
                                            DOWNLOAD_SUCCESS=true
                                            break
                                        else
                                            # Look for paqet in subdirectories
                                            PAQET_FILE=$(find . -name "paqet" -type f 2>/dev/null | head -1)
                                            if [ -n "$PAQET_FILE" ]; then
                                                mv "$PAQET_FILE" ./paqet
                                                chmod +x paqet
                                                PAQET_CMD="./paqet"
                                                echo "✓ Paqet downloaded and extracted ($ASSET_NAME)"
                                                DOWNLOAD_SUCCESS=true
                                                break
                                            fi
                                        fi
                                    elif [[ "$ASSET_NAME" == *.zip ]]; then
                                        echo "   Extracting from zip..."
                                        unzip -q "$TEMP_FILE" -d . 2>/dev/null
                                        rm "$TEMP_FILE"
                                        if [ -f "./paqet" ]; then
                                            chmod +x paqet
                                            PAQET_CMD="./paqet"
                                            echo "✓ Paqet downloaded and extracted ($ASSET_NAME)"
                                            DOWNLOAD_SUCCESS=true
                                            break
                                        else
                                            # Look for paqet in subdirectories
                                            PAQET_FILE=$(find . -name "paqet" -type f 2>/dev/null | head -1)
                                            if [ -n "$PAQET_FILE" ]; then
                                                mv "$PAQET_FILE" ./paqet
                                                chmod +x paqet
                                                PAQET_CMD="./paqet"
                                                echo "✓ Paqet downloaded and extracted ($ASSET_NAME)"
                                                DOWNLOAD_SUCCESS=true
                                                break
                                            fi
                                        fi
                                    else
                                        # Direct binary file
                                        mv "$TEMP_FILE" paqet
                                        chmod +x paqet
                                        PAQET_CMD="./paqet"
                                        echo "✓ Paqet downloaded ($ASSET_NAME)"
                                        DOWNLOAD_SUCCESS=true
                                        break
                                    fi
                                fi
                            fi
                        done
                    fi
                    
                    if [ "$DOWNLOAD_SUCCESS" == false ]; then
                        echo ""
                        echo "⚠️  Automatic download failed!"
                        echo ""
                        echo "Please download manually from:"
                        echo "   https://github.com/hanselime/paqet/releases/tag/${LATEST_RELEASE}"
                        echo ""
                        echo "Or use this command (find the filename on the release page):"
                        echo "   wget https://github.com/hanselime/paqet/releases/download/${LATEST_RELEASE}/[filename] -O paqet"
                        echo ""
                        read -p "Did you download the file manually and is it in this directory? [Y/n]: " MANUAL_DOWNLOAD
                        if [[ "$MANUAL_DOWNLOAD" != "n" && "$MANUAL_DOWNLOAD" != "N" ]]; then
                            if [ -f "./paqet" ]; then
                                chmod +x paqet
                                PAQET_CMD="./paqet"
                                echo "✓ Paqet file found"
                            else
                                PAQET_CMD="paqet"
                            fi
                        else
                            PAQET_CMD="paqet"
                        fi
                    fi
                else
                    echo "⚠️  Could not find latest release"
                    echo "Please download manually: https://github.com/hanselime/paqet/releases"
                    PAQET_CMD="paqet"
                fi
            else
                # If curl not available, use simple method
                echo "⚠️  curl not found, using simple method..."
                wget https://github.com/hanselime/paqet/releases/latest/download/paqet-linux-amd64 -O paqet 2>&1
                if [ $? -eq 0 ] && [ -f "./paqet" ]; then
                    chmod +x paqet
                    PAQET_CMD="./paqet"
                    echo "✓ Paqet downloaded"
                else
                    echo ""
                    echo "❌ Download failed!"
                    echo "Please download manually from:"
                    echo "   https://github.com/hanselime/paqet/releases/latest"
                    PAQET_CMD="paqet"
                fi
            fi
        else
            PAQET_CMD="paqet"
        fi
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📄 Configuration file: $CONFIG_FILE"
echo "🔑 Encryption key: ${SECRET_KEY:0:30}..."
echo ""
echo "🚀 To run, use the following command:"
echo ""
echo "   sudo $PAQET_CMD run -c $CONFIG_FILE"
echo ""
if [ "$ROLE" == "client" ]; then
    echo "🧪 To test the connection:"
    echo ""
    echo "   curl -x socks5://127.0.0.1:1080 http://httpbin.org/ip"
    echo ""
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Save key to separate file
echo "$SECRET_KEY" > .paqet_secret_key.txt
chmod 600 .paqet_secret_key.txt
echo "💾 Encryption key saved to .paqet_secret_key.txt"
echo "   ⚠️  Share this file with the other server!"
