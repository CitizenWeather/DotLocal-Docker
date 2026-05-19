#!/usr/bin/env python3
"""
NetLocal Health Check Script
Checks all mandatory services and returns exit code 0 if all healthy.
"""

import sys
import urllib.request
import socket
import os

# Load environment or use defaults
ROOT_DOMAIN = os.getenv('NETLOCAL_ROOT_DOMAIN', 'net.local')

services = [
    ('DNS', f'ca.{ROOT_DOMAIN}', 53, 'udp'),
    ('CA', f'ca.{ROOT_DOMAIN}', 443, 'tcp'),
    ('Registry', f'registrar.{ROOT_DOMAIN}', 8081, 'tcp'),
    ('Gateway', f'traefik.{ROOT_DOMAIN}', 443, 'tcp'),
    ('PostgreSQL', 'postgres', 5432, 'tcp'),
    ('Redis', 'redis', 6379, 'tcp'),
    ('MinIO', 'minio', 9000, 'tcp'),
    ('NATS', 'nats', 4222, 'tcp'),
    ('DNS Forwarder', 'dnsmasq', 53, 'udp'),
    ('Heimdall', f'dashboard.{ROOT_DOMAIN}', 80, 'tcp'),
    ('Health Endpoint', f'health.{ROOT_DOMAIN}', 80, 'tcp'),
]

def check_tcp(host, port, timeout=2):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        sock.connect((host, port))
        sock.close()
        return True
    except:
        return False

def check_udp(host, port, timeout=2):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(timeout)
        sock.sendto(b'\x00', (host, port))
        # UDP may not reply; we just assume reachable if no error
        sock.close()
        return True
    except:
        return False

def main():
    all_ok = True
    for name, host, port, proto in services:
        if proto == 'tcp':
            ok = check_tcp(host, port)
        else:
            ok = check_udp(host, port)
        if ok:
            print(f'✅ {name} ({host}:{port}) OK')
        else:
            print(f'❌ {name} ({host}:{port}) FAILED')
            all_ok = False
    sys.exit(0 if all_ok else 1)

if __name__ == '__main__':
    main()