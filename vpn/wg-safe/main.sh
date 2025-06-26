#!/bin/bash

# get the script directory even if the script is symlinked
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

disable_ipv6(){
    IPV6_STATUS=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)
    if [ "$IPV6_STATUS" -eq 1 ]; then
        echo "✅ IPv6 is already disabled."
    else
        echo "⚠️ IPv6 is enabled. Disabling it now..."
        sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
        sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
        sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
        echo "✅ IPv6 is now disabled."
    fi
}

enable_ipv6(){
    IPV6_STATUS=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)
    if [ "$IPV6_STATUS" -eq 0 ]; then
        echo "✅ IPv6 is already enabled."
    else
        echo "🔄 Re-enabling IPv6..."
        sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
        sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0
        sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=0
        echo "✅ IPv6 is now enabled."
    fi
}

# parse arguments
KILLSWITCH_ENABLED=0
POSITIONAL=()
for arg in "$@"; do
    case $arg in
        -k|--killswitch)
            KILLSWITCH_ENABLED=1
            shift # remove --killswitch from positional parameters
            ;;
        *)
            POSITIONAL+=("$arg") # save other arguments
            ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# check if the number of arguments are valid
if [ $# -lt 2 ]; then
    echo "❌ Error: Action and WireGuard profile required."
    echo "Usage: sudo $(basename "$0") up|down <profile>"
    echo "Example: sudo $(basename "$0") up nl"
    echo "         sudo $(basename "$0") down nl"
    exit 1
fi

ACTION="$1"
WG_PROFILE="$2"
WG_INTERFACE="$WG_PROFILE" # assuming the WireGuard profile name is the same as the interface name
WG_CONF_PATH="/etc/wireguard/${WG_PROFILE}.conf"

IPTABLES_BACKUP_FILE="$HOME/.wg-safe/iptables-backup"

backup_iptables() {
    mkdir -p "$HOME/.wg-safe"
    sudo iptables-save > "$IPTABLES_BACKUP_FILE"
}

restore_iptables() {
    if [ -f "$IPTABLES_BACKUP_FILE" ]; then
        sudo iptables-restore < "$IPTABLES_BACKUP_FILE"
        rm -f "$IPTABLES_BACKUP_FILE"
    else
        echo "⚠️ No iptables backup file found to restore."
    fi
}

enable_killswitch() {
    read ENDPOINT_IP ENDPOINT_PORT < <(sudo "$SCRIPT_DIR/parse-wg-endpoint.sh" "$WG_CONF_PATH")
    echo $ENDPOINT_IP $ENDPOINT_PORT
    if [ -z "$ENDPOINT_IP" ] || [ -z "$ENDPOINT_PORT" ]; then
        echo "❌ Error: Could not parse endpoint IP and port from WireGuard configuration."
        exit 1
    fi
    echo "🔒 Allowing VPN handshake to $ENDPOINT_IP:$ENDPOINT_PORT"
    sudo iptables -A OUTPUT -d "$ENDPOINT_IP" -p udp --dport "$ENDPOINT_PORT" -j ACCEPT
    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A OUTPUT -o lo -j ACCEPT
    sudo iptables -A INPUT -i "$WG_INTERFACE" -j ACCEPT
    sudo iptables -A OUTPUT -o "$WG_INTERFACE" -j ACCEPT
    sudo iptables -A OUTPUT ! -o "$WG_INTERFACE" -j DROP
    sudo iptables -A INPUT ! -i "$WG_INTERFACE" -j DROP
}


case "$ACTION" in
    up)
        disable_ipv6
        if [ "$KILLSWITCH_ENABLED" -eq 1 ]; then
            echo "🔒 Enabling kill switch and backing up iptables rules..."
            backup_iptables
            enable_killswitch
        fi
        echo "Connecting to Proton VPN ($WG_PROFILE) via WireGuard..."
        sudo wg-quick up "$WG_PROFILE"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully connected to Proton VPN ($WG_PROFILE)."
        else
            echo "❌ Failed to connect to Proton VPN ($WG_PROFILE)."
            if [ "$KILLSWITCH_ENABLED" -eq 1 ]; then
                restore_iptables
            fi
            exit 1
        fi
        ;;
    down)
        echo "Disconnecting from Proton VPN ($WG_PROFILE) via WireGuard..."
        sudo wg-quick down "$WG_PROFILE"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully disconnected from Proton VPN ($WG_PROFILE)."
            if [ "$KILLSWITCH_ENABLED" -eq 1 ]; then
                echo "🔓 Restoring iptables rules..."
                restore_iptables
            fi
            enable_ipv6
        else
            echo "❌ Failed to disconnect from Proton VPN ($WG_PROFILE)."
            exit 1
        fi
        ;;
    *)
        echo "❌ Error: Invalid action '$ACTION'. Use 'up' or 'down'."
        "Usage: sudo $(basename "$0") up|down <profile> [-k|--killswitch]"
        exit 1
        ;;
esac
