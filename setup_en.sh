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
    echo "🔹 Found Gateway IP: $GATEWAY_IP"
    ROUTER_MAC=$(arp -n $GATEWAY_IP 2>/dev/null | grep -oP '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
    if [ -n "$ROUTER_MAC" ]; then
        echo "🔹 Found router MAC address: $ROUTER_MAC"
        read -p "Is this MAC address correct? [Y/n]: " CONFIRM
        if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
            read -p "Enter router MAC address (e.g., aa:bb:cc:dd:ee:ff): " ROUTER_MAC
        fi
    else
        read -p "Enter router MAC address (e.g., aa:bb:cc:dd:ee:ff): " ROUTER_MAC
    fi
else
    read -p "Enter router MAC address (e.g., aa:bb:cc:dd:ee:ff): " ROUTER_MAC
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
            
            # List of possible filenames
            POSSIBLE_NAMES=(
                "paqet-linux-amd64"
                "paqet_linux_amd64"
                "paqet-linux_amd64"
                "paqet_linux-amd64"
            )
            
            DOWNLOAD_SUCCESS=false
            for FILENAME in "${POSSIBLE_NAMES[@]}"; do
                echo "   Trying: $FILENAME..."
                if wget -q --spider https://github.com/hanselime/paqet/releases/latest/download/$FILENAME 2>/dev/null; then
                    wget https://github.com/hanselime/paqet/releases/latest/download/$FILENAME -O paqet
                    if [ $? -eq 0 ] && [ -f "./paqet" ]; then
                        chmod +x paqet
                        PAQET_CMD="./paqet"
                        echo "✓ Paqet downloaded ($FILENAME)"
                        DOWNLOAD_SUCCESS=true
                        break
                    fi
                fi
            done
            
            if [ "$DOWNLOAD_SUCCESS" == false ]; then
                echo ""
                echo "❌ Automatic download failed!"
                echo ""
                echo "Please download manually from:"
                echo "   https://github.com/hanselime/paqet/releases/latest"
                echo ""
                echo "Or use this command:"
                echo "   wget https://github.com/hanselime/paqet/releases/download/v1.0.0-alpha.6/paqet_linux_amd64 -O paqet"
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
