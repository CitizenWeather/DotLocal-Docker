include .env
export

# Fallback defaults — overridden by values in .env when present
NETLOCAL_PROJECT ?= netlocal
NETLOCAL_NETWORK_PREFIX ?=

# External networks declaration
COMPOSE_BASE = -f stacks/core/networks.yml

# Helper to include a compose file only if it exists
define include_if
$(if $(wildcard $(1)),-f $(1))
endef

# ---------------------------------------------------------------------------
# Swappable slot base paths
# Add a new row here when a slot gains a new location in stacks/
# ---------------------------------------------------------------------------
GATEWAY_DIR   = stacks/barebones/net_root/intranet_service_provider/base/gateway
REGISTRY_DIR  = stacks/barebones/net_root/intranet_service_provider/base/domain_registry/core
POLICY_DIR    = stacks/barebones/net_root/localnet_authority/policy
CACHE_DIR     = stacks/net_providers/cache_provider
MESSAGING_DIR = build/layers/barebones/infrastructure/messages

# Slots not yet populated (compose files will be found once created under these dirs)
DNS_DIR      = stacks/barebones/net_root/intranet_service_provider/base/dns
CA_DIR       = stacks/barebones/net_root/intranet_service_provider/base/cert_authority
DB_DIR       = stacks/net_providers/database
STORAGE_DIR  = stacks/net_providers/storage

# ---------------------------------------------------------------------------
# Compose file list
# ---------------------------------------------------------------------------
COMPOSE_FILES = $(COMPOSE_BASE)

# Swappable slots
COMPOSE_FILES += $(call include_if,$(GATEWAY_DIR)/$(GATEWAY_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(REGISTRY_DIR)/$(REGISTRY_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(POLICY_DIR)/$(POLICY_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(CACHE_DIR)/$(CACHE_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(MESSAGING_DIR)/$(MESSAGING_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(DNS_DIR)/$(DNS_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(CA_DIR)/$(CA_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(DB_DIR)/$(DB_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(STORAGE_DIR)/$(STORAGE_APP)/docker-compose.yml)

# Fixed services (always included; skipped silently if not yet created)
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/intranet_service_provider/base/domain_registry/core/dnsmasq/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/localnet_authority/dashboards/heimdall/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/intranet_service_provider/base/health/endpoint/docker-compose.yml)
COMPOSE_FILES += $(call include_if,build/layers/authority/net_time/slots/chrony/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/net_web/whois/whoisd/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/localnet_authority/dashboards/dotlocal/status/uptime-kuma/docker-compose.yml)
COMPOSE_FILES += $(call include_if,build/docker/layers/architecture/internet_services_provider/gateways/nat_egress/docker-compose.yml)

# Email tier
ifeq ($(EMAIL_TIER),1)
    COMPOSE_FILES += $(call include_if,stacks/net_providers/mail_provider/mailpit/docker-compose.yml)
else
    COMPOSE_FILES += $(call include_if,stacks/net_providers/mail_provider/stalwart/docker-compose.yml)
    ifeq ($(EMAIL_TIER),3)
        COMPOSE_FILES += $(call include_if,stacks/net_providers/mail_provider/dovecot/docker-compose.yml)
    endif
    ifeq ($(EMAIL_TIER),4)
        COMPOSE_FILES += $(call include_if,stacks/net_providers/mail_provider/dovecot/docker-compose.yml)
        COMPOSE_FILES += $(call include_if,stacks/net_providers/mail_provider/postfix/relay/docker-compose.yml)
    endif
endif

# Observability
ifeq ($(ENABLE_OBSERVABILITY),true)
    COMPOSE_FILES += $(call include_if,build/layers/architecture/.supervisor/maintenance/observability/slots/prometheus/docker-compose.yml)
    COMPOSE_FILES += $(call include_if,build/layers/architecture/.supervisor/maintenance/observability/docker-compose.yml)
endif

# Extensions – each tag adds its own compose file under extensions/<tag>/
ifdef EXTENSION_TAGS
    $(foreach tag,$(EXTENSION_TAGS),$(eval COMPOSE_FILES += $(call include_if,extensions/$(tag)/docker-compose.yml)))
endif

# ---------------------------------------------------------------------------
# Targets
# ---------------------------------------------------------------------------
.PHONY: up down restart ps status logs clean bootstrap network-lab health \
        switch-ca switch-cache switch-dns

up:
	docker compose --project-name $(NETLOCAL_PROJECT) $(COMPOSE_FILES) up -d

down:
	docker compose --project-name $(NETLOCAL_PROJECT) $(COMPOSE_FILES) down

restart: down up

ps status:
	docker compose --project-name $(NETLOCAL_PROJECT) $(COMPOSE_FILES) ps

logs:
	docker compose --project-name $(NETLOCAL_PROJECT) $(COMPOSE_FILES) logs -f

clean: down
	docker compose --project-name $(NETLOCAL_PROJECT) $(COMPOSE_FILES) down -v
	rm -rf volumes/*

bootstrap:
	./scripts/bootstrap.sh

network-lab:
	containerlab deploy -t stacks/core/containerlab/topology.clab.yml

health:
	./scripts/healthcheck.py

switch-ca:
	./scripts/lib/switch-ca.sh $(filter-out $@,$(MAKECMDGOALS))

switch-cache:
	./scripts/lib/switch-cache $(filter-out $@,$(MAKECMDGOALS))

switch-dns:
	./scripts/lib/switch-dns.sh $(filter-out $@,$(MAKECMDGOALS))
