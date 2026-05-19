include .env
export

# -------------------------------
# Base compose files (networks)
# -------------------------------
COMPOSE_BASE = -f core/networks.yml

# Helper to include an app if its directory exists
define include_app
$(if $(wildcard apps/localnet/barebones/$(1)/$(2)/docker-compose.yml),-f apps/localnet/barebones/$(1)/$(2)/docker-compose.yml)
endef

# Start with base networks
COMPOSE_FILES = $(COMPOSE_BASE)

# ----------------------------------------------------------------------
# Mandatory core services (discovery, secrets, policy) – always included
# ----------------------------------------------------------------------
COMPOSE_FILES += -f apps/localnet/barebones/discovery/consul/docker-compose.yml
COMPOSE_FILES += -f apps/localnet/barebones/secrets/openbao/docker-compose.yml
COMPOSE_FILES += -f apps/localnet/barebones/policy/opa/docker-compose.yml

# ----------------------------------------------------------------------
# Mandatory barebones apps – implementation chosen via .env variables
# ----------------------------------------------------------------------
COMPOSE_FILES += $(call include_app,dns,$(DNS_APP))
COMPOSE_FILES += $(call include_app,ca,$(CA_APP))
COMPOSE_FILES += $(call include_app,registry,$(REGISTRY_APP))
COMPOSE_FILES += $(call include_app,policy,$(POLICY_APP))
COMPOSE_FILES += $(call include_app,gateway,$(GATEWAY_APP))
COMPOSE_FILES += $(call include_app,database,$(DB_APP))
COMPOSE_FILES += $(call include_app,cache,$(CACHE_APP))
COMPOSE_FILES += $(call include_app,storage,$(STORAGE_APP))
COMPOSE_FILES += $(call include_app,messaging,$(MESSAGING_APP))

# Fixed barebones services (no alternative implementations)
COMPOSE_FILES += -f apps/localnet/barebones/dns-forwarder/dnsmasq/docker-compose.yml
COMPOSE_FILES += -f apps/localnet/barebones/dashboard/heimdall/docker-compose.yml
COMPOSE_FILES += -f apps/localnet/barebones/health/endpoint/docker-compose.yml
COMPOSE_FILES += -f apps/localnet/barebones/fabric/default-router/docker-compose.yml
COMPOSE_FILES += -f apps/localnet/barebones/fabric/squid/docker-compose.yml
COMPOSE_FILES += -f apps/localnet/barebones/ntp/chrony/docker-compose.yml
COMPOSE_FILES += -f apps/localnet/barebones/whois/whoisd/docker-compose.yml
COMPOSE_FILES += -f apps/localnet/barebones/status/uptime-kuma/docker-compose.yml

# ----------------------------------------------------------------------
# Email tier (1‑4)
# ----------------------------------------------------------------------
ifeq ($(EMAIL_TIER),1)
    COMPOSE_FILES += --profile tier1 -f apps/localnet/barebones/email/mailpit/docker-compose.yml
else
    # Tiers 2‑4 share stalwart + webmail
    COMPOSE_FILES += -f apps/localnet/barebones/email/stalwart/docker-compose.yml
    COMPOSE_FILES += -f apps/localnet/barebones/webmail/snappymail/docker-compose.yml
    ifeq ($(EMAIL_TIER),3)
        COMPOSE_FILES += -f apps/localnet/barebones/email/dovecot/docker-compose.yml
    endif
    ifeq ($(EMAIL_TIER),4)
        COMPOSE_FILES += -f apps/localnet/barebones/email/postfix-relay/docker-compose.yml
    endif
endif

# ----------------------------------------------------------------------
# Observability (optional, enabled by ENABLE_OBSERVABILITY=true)
# ----------------------------------------------------------------------
ifeq ($(ENABLE_OBSERVABILITY),true)
    COMPOSE_FILES += -f apps/localnet/barebones/observability/prometheus/docker-compose.yml
    COMPOSE_FILES += -f apps/localnet/barebones/observability/grafana/docker-compose.yml
    COMPOSE_FILES += -f apps/localnet/barebones/observability/loki/docker-compose.yml
    COMPOSE_FILES += -f apps/localnet/barebones/observability/promtail/docker-compose.yml
    COMPOSE_FILES += -f apps/localnet/barebones/observability/tempo/docker-compose.yml
endif

# ----------------------------------------------------------------------
# Extensions (tag‑based, each tag adds a compose file with its profile)
# ----------------------------------------------------------------------
ifdef EXTENSION_TAGS
    $(foreach tag,$(EXTENSION_TAGS),$(eval COMPOSE_FILES += --profile tag-$(tag) -f extensions/$(tag)/docker-compose.yml))
endif

# ======================================================================
# Targets
# ======================================================================
.PHONY: up down restart status logs clean bootstrap

up:
	docker compose $(COMPOSE_FILES) up -d

down:
	docker compose $(COMPOSE_FILES) down

restart: down up

status:
	docker compose $(COMPOSE_FILES) ps

logs:
	docker compose $(COMPOSE_FILES) logs -f

clean: down
	docker compose $(COMPOSE_FILES) down -v
	rm -rf volumes/*

bootstrap:
	./scripts/bootstrap.sh

# ----------------------------------------------------------------------
# Helper scripts
# ----------------------------------------------------------------------
.PHONY: health switch-ca switch-cache

health:
	./scripts/healthcheck.py

switch-ca:
	./scripts/switch-ca.sh

switch-cache:
	./scripts/switch-cache.sh

# ----------------------------------------------------------------------
# Faux providers (optional, can be started independently)
# ----------------------------------------------------------------------
.PHONY: up-mail-admin up-search up-cdn up-dns-hosting

up-mail-admin:
	docker compose -f apps/faux_provider/mail_admin/docker-compose.yml up -d

up-search:
	docker compose -f apps/faux_provider/search_local/docker-compose.yml up -d

up-cdn:
	docker compose -f apps/faux_provider/cdn_local/docker-compose.yml up -d

up-dns-hosting:
	docker compose -f apps/faux_provider/dns_hosting/docker-compose.yml up -d

# ----------------------------------------------------------------------
# Containerlab network simulations (optional)
# ----------------------------------------------------------------------
.PHONY: network-lab network-lab-lorawan network-lab-cellular network-lab-ics network-lab-clean

network-lab:
	containerlab deploy -t core/containerlab/topology.clab.yml

network-lab-lorawan:
	containerlab deploy -t core/containerlab/topology.lorawan.yml

network-lab-cellular:
	containerlab deploy -t core/containerlab/topology.cellular.yml

network-lab-ics:
	containerlab deploy -t core/containerlab/topology.ics.yml

network-lab-clean:
	containerlab destroy -t core/containerlab/topology.lorawan.yml || true
	containerlab destroy -t core/containerlab/topology.cellular.yml || true
	containerlab destroy -t core/containerlab/topology.ics.yml || true