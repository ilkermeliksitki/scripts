#!/bin/bash

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

case "$ACTION" in
    up)
        disable_ipv6
        echo "Connecting to Proton VPN ($WG_PROFILE) via WireGuard..."
        sudo wg-quick up "$WG_PROFILE"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully connected to Proton VPN ($WG_PROFILE)."
        else
            echo "❌ Failed to connect to Proton VPN ($WG_PROFILE)."
            exit 1
        fi
        ;;
    down)
        echo "Disconnecting from Proton VPN ($WG_PROFILE) via WireGuard..."
        sudo wg-quick down "$WG_PROFILE"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully disconnected from Proton VPN ($WG_PROFILE)."
            enable_ipv6
        else
            echo "❌ Failed to disconnect from Proton VPN ($WG_PROFILE)."
            exit 1
        fi
        ;;
    *)
        echo "❌ Error: Invalid action '$ACTION'. Use 'up' or 'down'."
        echo "Usage: sudo $(basename "$0") up|down <profile>"
        exit 1
        ;;
esac
