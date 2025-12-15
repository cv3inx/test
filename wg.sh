#!/bin/bash
set -e

# WireGuard NAT Proxy Auto Setup
# Usage: Run on VPS first, then on Proxmox host

COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_RED='\033[0;31m'
COLOR_NC='\033[0m'

log() { echo -e "${COLOR_GREEN}[INFO]${COLOR_NC} $1"; }
error() { echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1"; exit 1; }

# Detect if running on VPS or Proxmox
detect_environment() {
    if pveversion &>/dev/null; then
        echo "proxmox"
    else
        echo "vps"
    fi
}

# VPS Setup - WireGuard Server with NAT
setup_vps() {
    log "Setting up VPS as WireGuard NAT proxy..."
    
    # Install WireGuard
    apt update
    apt install -y wireguard iptables resolvconf
    
    # Generate server keys
    wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
    chmod 600 /etc/wireguard/server_private.key
    
    SERVER_PRIVATE_KEY=$(cat /etc/wireguard/server_private.key)
    SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
    
    # Generate client keys for Proxmox
    wg genkey | tee /etc/wireguard/client_private.key | wg pubkey > /etc/wireguard/client_public.key
    chmod 600 /etc/wireguard/client_private.key
    
    CLIENT_PRIVATE_KEY=$(cat /etc/wireguard/client_private.key)
    CLIENT_PUBLIC_KEY=$(cat /etc/wireguard/client_public.key)
    
    # Get primary network interface
    PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    log "Primary interface: $PRIMARY_INTERFACE"
    
    # Create WireGuard config
    cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = 10.200.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $PRIMARY_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $PRIMARY_INTERFACE -j MASQUERADE

# Proxmox host peer
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.200.0.2/32
EOF
    
    # Enable IP forwarding
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
    
    # Start WireGuard
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    
    # Get VPS public IP
    VPS_IP=$(curl -s ifconfig.me)
    
    log "VPS setup complete!"
    echo ""
    echo -e "${COLOR_BLUE}=== Configuration for Proxmox ===${COLOR_NC}"
    echo "VPS_IP=$VPS_IP"
    echo "VPS_PUBLIC_KEY=$SERVER_PUBLIC_KEY"
    echo "CLIENT_PRIVATE_KEY=$CLIENT_PRIVATE_KEY"
    echo ""
    echo "Save these values and run this script on your Proxmox host with:"
    echo "SETUP_MODE=proxmox VPS_IP=$VPS_IP VPS_PUBLIC_KEY=$SERVER_PUBLIC_KEY CLIENT_PRIVATE_KEY=$CLIENT_PRIVATE_KEY bash $0"
}

# Proxmox Setup - WireGuard Client with VM NAT
setup_proxmox() {
    log "Setting up Proxmox as WireGuard client..."
    
    # Check required variables
    [ -z "$VPS_IP" ] && error "VPS_IP not set"
    [ -z "$VPS_PUBLIC_KEY" ] && error "VPS_PUBLIC_KEY not set"
    [ -z "$CLIENT_PRIVATE_KEY" ] && error "CLIENT_PRIVATE_KEY not set"
    
    # Install WireGuard
    apt update
    apt install -y wireguard iptables
    
    # Create WireGuard config
    cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.200.0.2/24
PostUp = iptables -A FORWARD -i vmbr0 -o wg0 -j ACCEPT; iptables -A FORWARD -i wg0 -o vmbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
PostDown = iptables -D FORWARD -i vmbr0 -o wg0 -j ACCEPT; iptables -D FORWARD -i wg0 -o vmbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -D POSTROUTING -o wg0 -j MASQUERADE

[Peer]
PublicKey = $VPS_PUBLIC_KEY
Endpoint = $VPS_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
    
    chmod 600 /etc/wireguard/wg0.conf
    
    # Enable IP forwarding
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
    
    # Start WireGuard
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    
    log "Proxmox setup complete!"
    echo ""
    echo -e "${COLOR_BLUE}=== VM Configuration ===${COLOR_NC}"
    echo "For VMs to use the WireGuard tunnel:"
    echo "1. Set VM gateway to: 10.200.0.2 (this Proxmox host)"
    echo "2. Or configure individual VMs with routing through wg0"
    echo ""
    echo "To route specific VM traffic through tunnel:"
    echo "ip route add default via 10.200.0.1 dev wg0 table 100"
    echo "ip rule add from <VM_IP> table 100"
}

# Main execution
ENV=$(detect_environment)
SETUP_MODE=${SETUP_MODE:-$ENV}

log "Detected environment: $ENV"
log "Setup mode: $SETUP_MODE"

case $SETUP_MODE in
    vps)
        setup_vps
        ;;
    proxmox)
        setup_proxmox
        ;;
    *)
        error "Unknown setup mode: $SETUP_MODE. Must be 'vps' or 'proxmox'"
        ;;
esac

log "Setup complete! Check WireGuard status with: wg show"
