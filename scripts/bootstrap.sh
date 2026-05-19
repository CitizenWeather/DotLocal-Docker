#!/bin/bash
set -e

# Bootstrap NetLocal: generate configs from templates, create networks, set up CA trust

# Load .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "No .env file found; creating from .env.example"
    cp .env.example .env
    export $(grep -v '^#' .env | xargs)
fi

# Create directories
mkdir -p config/dns/{coredns,bind} config/ca/smallstep config/registry/powerdns config/policy/opa config/gateway/traefik config/email/stalwart config/fabric/squid
mkdir -p volumes

# Generate CoreDNS config from template
if [ ! -f config/dns/coredns/Corefile ]; then
    cat > config/dns/coredns/Corefile.template <<EOF
.:53 {
    forward . ${POWERDNS_HOST:-169.254.0.3}
    log
    errors
}
${NETLOCAL_ROOT_DOMAIN:-net.local}:53 {
    file /etc/coredns/zones/${NETLOCAL_ROOT_DOMAIN:-net.local}.zone
    log
}
EOF
    envsubst < config/dns/coredns/Corefile.template > config/dns/coredns/Corefile
fi

# Generate zone file
if [ ! -f config/dns/coredns/zones/${NETLOCAL_ROOT_DOMAIN:-net.local}.zone ]; then
    mkdir -p config/dns/coredns/zones
    cat > config/dns/coredns/zones/${NETLOCAL_ROOT_DOMAIN:-net.local}.zone <<EOF
\$ORIGIN ${NETLOCAL_ROOT_DOMAIN:-net.local}.
\$TTL 3600
@               IN SOA  ns1.${NETLOCAL_ROOT_DOMAIN:-net.local}. admin.${NETLOCAL_ROOT_DOMAIN:-net.local}. ( 2025051901 7200 3600 1209600 3600 )
                IN NS   ns1.${NETLOCAL_ROOT_DOMAIN:-net.local}.
ns1             IN A    169.254.0.2
ca              IN A    169.254.0.4
registrar       IN A    169.254.0.3
dashboard       IN A    172.20.0.254
health          IN A    172.20.0.254
minio           IN A    172.20.0.254
traefik         IN A    172.20.0.254
smtp            IN A    172.20.0.254
imap            IN A    172.20.0.254
mail            IN A    172.20.0.254
whois           IN A    172.20.0.254
status          IN A    172.20.0.254
EOF
fi

# Generate Stalwart config
if [ ! -f config/email/stalwart/stalwart.toml ]; then
    cat > config/email/stalwart/stalwart.toml.template <<EOF
[server]
hostname = "mail.${NETLOCAL_ROOT_DOMAIN}"

[storage]
data = "/opt/stalwart-mail/data"

[smtp]
listen = ["0.0.0.0:25"]
submission = ["0.0.0.0:587"]
disable-tls = true

[imap]
listen = ["0.0.0.0:143"]
disable-tls = true

[domains]
"${NETLOCAL_ROOT_DOMAIN}" = { type = "local", catchall = "admin@${NETLOCAL_ROOT_DOMAIN}" }
EOF
    envsubst < config/email/stalwart/stalwart.toml.template > config/email/stalwart/stalwart.toml
fi

# Generate Squid config (pass-through)
if [ ! -f config/fabric/squid/squid.conf ]; then
    cat > config/fabric/squid/squid.conf <<EOF
http_port 3128 transparent
http_access allow all
cache deny all
EOF
fi

# Create Docker networks if missing
docker network inspect localnet_backbone >/dev/null 2>&1 || docker network create --driver bridge --subnet ${NETLOCAL_SUBNET_BACKBONE:-169.254.0.0/16} --internal localnet_backbone
docker network inspect localnet_default >/dev/null 2>&1 || docker network create --driver bridge --subnet ${NETLOCAL_SUBNET_DEFAULT:-172.20.0.0/16} localnet_default

# CA trust (optional)
if [ -d volumes/smallstep/certs ]; then
    echo "To trust the NetLocal CA, run: sudo cp volumes/smallstep/certs/root_ca.crt /usr/local/share/ca-certificates/netlocal-ca.crt && sudo update-ca-certificates"
fi

echo "Bootstrap complete. Run 'make up' to start NetLocal."