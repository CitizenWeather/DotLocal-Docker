#!/bin/sh
# NetLocal host firewall rules — default-deny ingress with explicit allow-list.
# Applied once at container startup via NET_ADMIN capability.
# Customize ALLOW_TCP_PORTS and ALLOW_UDP_PORTS in .env or edit this file.

set -e

BACKBONE_CIDR="${NETLOCAL_SUBNET_BACKBONE:-169.254.0.0/16}"
DEFAULT_CIDR="${NETLOCAL_SUBNET_DEFAULT:-172.20.0.0/16}"
NAT_CIDR="${NETLOCAL_SUBNET_NAT:-10.20.0.0/16}"

# Space-separated TCP/UDP ports to allow on the host.
# Defaults cover SSH + HTTP/HTTPS gateway + DNS.
ALLOW_TCP="${FIREWALL_ALLOW_TCP:-22 53 80 443}"
ALLOW_UDP="${FIREWALL_ALLOW_UDP:-53 67 68 123}"

detect_tool() {
    if command -v nft >/dev/null 2>&1; then
        echo nftables
    elif command -v iptables >/dev/null 2>&1; then
        echo iptables
    else
        echo "ERROR: neither nft nor iptables found" >&2
        exit 1
    fi
}

apply_nftables() {
    # Build comma-separated port lists for nft set syntax
    tcp_set=$(echo "$ALLOW_TCP" | tr ' ' ',')
    udp_set=$(echo "$ALLOW_UDP" | tr ' ' ',')

    nft -f - <<EOF
table inet netlocal {
    chain input {
        type filter hook input priority 0; policy drop;

        # Always allow loopback
        iif lo accept

        # Allow established/related
        ct state established,related accept

        # Allow ICMP (ping, path MTU)
        ip  protocol icmp  accept
        ip6 nexthdr  icmpv6 accept

        # Allow inbound Docker network traffic (intra-stack)
        ip saddr $BACKBONE_CIDR accept
        ip saddr $DEFAULT_CIDR  accept
        ip saddr $NAT_CIDR      accept

        # Explicit allow-list — override via FIREWALL_ALLOW_TCP / FIREWALL_ALLOW_UDP in .env
        tcp dport { $tcp_set } accept
        udp dport { $udp_set } accept

        # Drop everything else (policy drop covers this, but log first if desired)
        drop
    }

    chain forward {
        type filter hook forward priority 0; policy drop;

        # Allow established/related
        ct state established,related accept

        # Allow intra-backbone traffic
        ip saddr $BACKBONE_CIDR ip daddr $BACKBONE_CIDR accept

        # Allow intra-default traffic
        ip saddr $DEFAULT_CIDR ip daddr $DEFAULT_CIDR accept

        # Allow NAT subnet egress
        ip saddr $NAT_CIDR accept

        # Allow gateway → backbone (service discovery)
        ip saddr $DEFAULT_CIDR ip daddr $BACKBONE_CIDR accept
        ip saddr $BACKBONE_CIDR ip daddr $DEFAULT_CIDR accept
    }

    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF
    echo "nftables rules applied (default-deny ingress)."
}

apply_iptables() {
    # ---- INPUT chain: default deny ----
    iptables -P INPUT DROP
    ip6tables -P INPUT DROP 2>/dev/null || true

    # Loopback
    iptables -A INPUT -i lo -j ACCEPT

    # Established / related
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # ICMP
    iptables -A INPUT -p icmp -j ACCEPT
    ip6tables -A INPUT -p icmpv6 -j ACCEPT 2>/dev/null || true

    # Docker network sources
    iptables -A INPUT -s "$BACKBONE_CIDR" -j ACCEPT
    iptables -A INPUT -s "$DEFAULT_CIDR"  -j ACCEPT
    iptables -A INPUT -s "$NAT_CIDR"      -j ACCEPT

    # Explicit TCP/UDP allow-list
    for port in $ALLOW_TCP; do
        iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
    done
    for port in $ALLOW_UDP; do
        iptables -A INPUT -p udp --dport "$port" -j ACCEPT
    done

    # ---- FORWARD chain: default deny ----
    iptables -P FORWARD DROP

    iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -s "$BACKBONE_CIDR" -d "$BACKBONE_CIDR" -j ACCEPT
    iptables -A FORWARD -s "$DEFAULT_CIDR"  -d "$DEFAULT_CIDR"  -j ACCEPT
    iptables -A FORWARD -s "$NAT_CIDR"      -j ACCEPT
    iptables -A FORWARD -s "$DEFAULT_CIDR"  -d "$BACKBONE_CIDR" -j ACCEPT
    iptables -A FORWARD -s "$BACKBONE_CIDR" -d "$DEFAULT_CIDR"  -j ACCEPT

    # ---- OUTPUT: permissive ----
    iptables -P OUTPUT ACCEPT

    echo "iptables rules applied (default-deny ingress)."
}

TOOL=$(detect_tool)
echo "Applying NetLocal firewall rules via $TOOL ..."

case "$TOOL" in
    nftables) apply_nftables ;;
    iptables) apply_iptables ;;
esac
