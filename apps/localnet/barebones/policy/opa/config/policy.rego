package envoy.authz

default allow = false

# Allow internal DNS queries
allow {
    input.parsed_path == "/dns-query"
}

# Allow external relay (Tier 4) to reach Gmail SMTP
allow {
    input.service_name == "netlocal_external_relay"
    input.destination_host == "smtp.gmail.com"
    input.destination_port == 587
}

# Allow health checks from uptime-kuma to anywhere inside NetLocal
allow {
    input.service_name == "netlocal_uptime_kuma"
    cidr_contains("172.20.0.0/16", input.destination_ip)
}

# Allow all traffic to the local Docker subnet (localnet_default)
allow {
    cidr_contains("172.20.0.0/16", input.destination_ip)
}

# Deny everything else