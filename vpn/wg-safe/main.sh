#!/bin/bash

# Kill switch status file to track if kill switch is active
KILL_SWITCH_STATUS_FILE="/tmp/wg-safe-killswitch.status"

setup_kill_switch(){
    local wg_interface="$1"
    echo "🔒 Setting up kill switch firewall rules..."
    
    # Save current iptables rules
    sudo iptables-save > /tmp/wg-safe-iptables-backup.rules
    
    # Flush existing rules in FORWARD and OUTPUT chains for clean setup
    sudo iptables -P INPUT ACCEPT
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT DROP
    
    # Allow loopback traffic
    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established and related connections
    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    
    # Allow traffic through VPN interface when it exists
    if ip link show "$wg_interface" >/dev/null 2>&1; then
        sudo iptables -A INPUT -i "$wg_interface" -j ACCEPT
        sudo iptables -A OUTPUT -o "$wg_interface" -j ACCEPT
    fi
    
    # Allow local network communication (optional, comment out for strict mode)
    sudo iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT
    sudo iptables -A OUTPUT -d 192.168.0.0/16 -j ACCEPT
    sudo iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT
    sudo iptables -A OUTPUT -d 10.0.0.0/8 -j ACCEPT
    
    # Block all other traffic (kill switch active)
    # INPUT/OUTPUT default policies are already set to DROP above
    
    # Mark kill switch as active
    echo "active" > "$KILL_SWITCH_STATUS_FILE"
    echo "✅ Kill switch activated - all traffic blocked except through VPN"
}

restore_firewall(){
    echo "🔓 Restoring original firewall rules..."
    
    # Restore original iptables rules if backup exists
    if [ -f "/tmp/wg-safe-iptables-backup.rules" ]; then
        sudo iptables-restore < /tmp/wg-safe-iptables-backup.rules
        rm -f /tmp/wg-safe-iptables-backup.rules
    else
        # Fallback: reset to default permissive rules
        sudo iptables -P INPUT ACCEPT
        sudo iptables -P FORWARD ACCEPT
        sudo iptables -P OUTPUT ACCEPT
        sudo iptables -F
    fi
    
    # Remove kill switch status
    rm -f "$KILL_SWITCH_STATUS_FILE"
    echo "✅ Firewall rules restored"
}

monitor_vpn_connection(){
    local wg_profile="$1"
    local check_interval=5
    
    echo "👁️  Starting VPN connection monitor for $wg_profile..."
    echo "📝 Kill switch will activate if VPN connection is lost"
    echo "🛑 Press Ctrl+C to stop monitoring and restore firewall"
    
    # Set up signal handlers for clean exit
    trap 'echo ""; echo "🛑 Stopping monitor and restoring firewall..."; restore_firewall; exit 0' INT TERM
    
    while true; do
        # Check if WireGuard interface exists and is up
        if sudo wg show "$wg_profile" >/dev/null 2>&1; then
            local interface=$(sudo wg show "$wg_profile" | head -1 | awk '{print $2}' | tr -d ':')
            if [ -n "$interface" ] && ip link show "$interface" >/dev/null 2>&1; then
                local status=$(ip link show "$interface" | grep -o "state [A-Z]*" | awk '{print $2}')
                if [ "$status" = "UP" ]; then
                    # VPN is up - ensure kill switch allows VPN traffic
                    if [ -f "$KILL_SWITCH_STATUS_FILE" ]; then
                        # Update rules to allow traffic through current VPN interface
                        sudo iptables -D OUTPUT -o "$interface" -j ACCEPT >/dev/null 2>&1
                        sudo iptables -D INPUT -i "$interface" -j ACCEPT >/dev/null 2>&1
                        sudo iptables -A OUTPUT -o "$interface" -j ACCEPT
                        sudo iptables -A INPUT -i "$interface" -j ACCEPT
                    fi
                    echo "$(date '+%H:%M:%S') ✅ VPN connection active ($interface)"
                else
                    echo "$(date '+%H:%M:%S') ⚠️  VPN interface $interface is DOWN - traffic blocked by kill switch"
                fi
            else
                echo "$(date '+%H:%M:%S') ❌ VPN interface not found - traffic blocked by kill switch"
            fi
        else
            echo "$(date '+%H:%M:%S') ❌ VPN connection lost - traffic blocked by kill switch"
        fi
        
        sleep $check_interval
    done
}

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
if [ $# -lt 1 ]; then
    echo "❌ Error: Action required."
    echo "Usage: sudo $(basename "$0") {up|down|monitor} <profile>"
    echo "       sudo $(basename "$0") {restore-firewall}"
    echo "Example: sudo $(basename "$0") up nl"
    echo "         sudo $(basename "$0") down nl"
    echo "         sudo $(basename "$0") monitor nl"
    echo "         sudo $(basename "$0") restore-firewall"
    exit 1
fi

ACTION="$1"
WG_PROFILE="$2"

case "$ACTION" in
    up)
        if [ -z "$WG_PROFILE" ]; then
            echo "❌ Error: WireGuard profile required for 'up' action."
            echo "Usage: sudo $(basename "$0") up <profile>"
            exit 1
        fi
        
        disable_ipv6
        echo "Connecting to Proton VPN ($WG_PROFILE) via WireGuard..."
        sudo wg-quick up "$WG_PROFILE"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully connected to Proton VPN ($WG_PROFILE)."
            
            # Set up kill switch
            setup_kill_switch "$WG_PROFILE"
            
            echo "💡 Use 'sudo $(basename "$0") monitor $WG_PROFILE' to start connection monitoring"
            echo "💡 Use 'sudo $(basename "$0") down $WG_PROFILE' to disconnect and restore firewall"
        else
            echo "❌ Failed to connect to Proton VPN ($WG_PROFILE)."
            exit 1
        fi
        ;;
    down)
        if [ -z "$WG_PROFILE" ]; then
            echo "❌ Error: WireGuard profile required for 'down' action."
            echo "Usage: sudo $(basename "$0") down <profile>"
            exit 1
        fi
        
        echo "Disconnecting from Proton VPN ($WG_PROFILE) via WireGuard..."
        
        # Restore firewall before disconnecting
        restore_firewall
        
        sudo wg-quick down "$WG_PROFILE"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully disconnected from Proton VPN ($WG_PROFILE)."
            enable_ipv6
        else
            echo "❌ Failed to disconnect from Proton VPN ($WG_PROFILE)."
            # Still try to restore firewall even if wg-quick failed
            restore_firewall
            exit 1
        fi
        ;;
    monitor)
        if [ -z "$WG_PROFILE" ]; then
            echo "❌ Error: WireGuard profile required for 'monitor' action."
            echo "Usage: sudo $(basename "$0") monitor <profile>"
            exit 1
        fi
        
        # Check if VPN is connected
        if ! sudo wg show "$WG_PROFILE" >/dev/null 2>&1; then
            echo "❌ Error: VPN profile '$WG_PROFILE' is not connected."
            echo "💡 Connect first using: sudo $(basename "$0") up $WG_PROFILE"
            exit 1
        fi
        
        monitor_vpn_connection "$WG_PROFILE"
        ;;
    restore-firewall)
        restore_firewall
        ;;
    *)
        echo "❌ Error: Invalid action '$ACTION'. Use 'up', 'down', 'monitor', or 'restore-firewall'."
        echo "Usage: sudo $(basename "$0") {up|down|monitor} <profile>"
        echo "       sudo $(basename "$0") restore-firewall"
        exit 1
        ;;
esac
