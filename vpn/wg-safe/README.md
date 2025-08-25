# VPN Kill Switch (wg-safe)

A secure WireGuard VPN manager with built-in kill switch functionality to prevent IP leaks when VPN connections drop.

## Features

- **Kill Switch Protection**: Automatically blocks all internet traffic when VPN connection is lost
- **IPv6 Leak Prevention**: Disables IPv6 during VPN connection to prevent leaks
- **Connection Monitoring**: Continuously monitors VPN status and maintains firewall rules
- **Clean Disconnection**: Safely restores network access when disconnecting
- **Emergency Recovery**: Manual firewall restore function

## Usage

### Connect to VPN with Kill Switch
```bash
sudo ./main.sh up <profile>
```
This will:
- Disable IPv6 to prevent leaks
- Connect to the VPN using the specified WireGuard profile
- Set up iptables firewall rules to block all traffic except through VPN
- Display instructions for monitoring and disconnecting

### Monitor VPN Connection
```bash
sudo ./main.sh monitor <profile>
```
This will:
- Continuously check VPN connection status
- Update firewall rules to allow traffic through active VPN interface
- Block all traffic if VPN connection is lost
- Display real-time connection status
- Press Ctrl+C to stop monitoring and restore firewall

### Disconnect VPN
```bash
sudo ./main.sh down <profile>
```
This will:
- Restore original firewall rules
- Disconnect from the VPN
- Re-enable IPv6

### Emergency Firewall Restore
```bash
sudo ./main.sh restore-firewall
```
Use this if you need to manually restore network access (e.g., if the script was interrupted).

## How Kill Switch Works

1. **Firewall Setup**: When connecting, the script:
   - Backs up current iptables rules
   - Sets restrictive firewall policies (DROP by default)
   - Allows only loopback and VPN interface traffic
   - Allows local network communication (configurable)

2. **Connection Monitoring**: The monitor function:
   - Checks VPN interface status every 5 seconds
   - Updates firewall rules to match current VPN interface
   - Blocks all traffic if VPN interface goes down

3. **Traffic Flow**:
   - ✅ **Allowed**: Traffic through VPN interface, loopback, local network
   - ❌ **Blocked**: All other internet traffic (when VPN is down)

## Security Features

- **No DNS Leaks**: All traffic forced through VPN tunnel
- **No IPv6 Leaks**: IPv6 disabled during VPN session
- **Fail-Safe**: Traffic blocked by default if VPN fails
- **Clean Restoration**: Original firewall rules restored on disconnect

## Requirements

- WireGuard (`wg-quick` command)
- iptables
- Root/sudo privileges
- Properly configured WireGuard profiles

## Example Workflow

```bash
# Connect with kill switch
sudo ./main.sh up nl

# In another terminal, start monitoring
sudo ./main.sh monitor nl

# When done, disconnect safely
sudo ./main.sh down nl
```

## Troubleshooting

- **No internet after script**: Run `sudo ./main.sh restore-firewall`
- **Can't connect to VPN**: Check WireGuard profile exists and is valid
- **Monitor shows connection lost**: Check VPN server status and network connectivity

## Configuration

To modify kill switch behavior, edit the `setup_kill_switch()` function:
- Comment out local network rules (lines 33-36) for stricter blocking
- Adjust monitoring interval in `monitor_vpn_connection()` (line 68)
- Modify firewall rules as needed for your network setup