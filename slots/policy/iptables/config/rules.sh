#!/bin/sh
# Default network policy rules for NetLocal.
# Applied at container startup via NET_ADMIN capability.
# Edit to tighten or relax rules for your environment.

set -e

# Allow established/related connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow intra-network traffic on backbone
iptables -A FORWARD -s 169.254.0.0/16 -d 169.254.0.0/16 -j ACCEPT

# Allow intra-network traffic on default network
iptables -A FORWARD -s 172.20.0.0/16 -d 172.20.0.0/16 -j ACCEPT

# Default deny forward (comment out if you want permissive mode)
# iptables -P FORWARD DROP

echo "iptables policy rules applied."
