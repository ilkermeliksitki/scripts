#!/bin/bash

check_ipv6_disabled() {
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

# ensure a wireguard profile is provided as an argument
if [ $# -eq 0 ]; then
    echo "❌ Error: No WireGuard profile specified."
    echo "Usage: sudo $(basename "$0") <profile>"
    echo "Example: sudo $(basename "$0") nl"
    exit 1
fi

WG_PROFILE="$1"  # get the first argument as the WireGuard profile

check_ipv6_disabled

# Connect to the specified WireGuard profile
echo "Connecting to Proton VPN ($WG_PROFILE) via WireGuard..."
sudo wg-quick up "$WG_PROFILE"

echo "✅ Connected to $WG_PROFILE!"

