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
# ROLE SLOTS — mandatory roles; exactly one implementation runs per slot.
# Each *_DIR points to the slot's home under slots/<role>/; *_APP selects
# the implementation subdirectory. Set *_APP in .env to switch.
# ---------------------------------------------------------------------------
DNS_DIR       = slots/dns
CA_DIR        = slots/ca
REGISTRY_DIR  = slots/registry
GATEWAY_DIR   = slots/gateway
DB_DIR        = slots/db
CACHE_DIR     = slots/cache
STORAGE_DIR   = slots/storage
MESSAGING_DIR = slots/messaging
POLICY_DIR    = slots/policy

# ---------------------------------------------------------------------------
# Compose file list
# ---------------------------------------------------------------------------
COMPOSE_FILES = $(COMPOSE_BASE)

# Role slots — silently skipped if the implementation compose file is absent
COMPOSE_FILES += $(call include_if,$(DNS_DIR)/$(DNS_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(CA_DIR)/$(CA_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(REGISTRY_DIR)/$(REGISTRY_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(GATEWAY_DIR)/$(GATEWAY_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(DB_DIR)/$(DB_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(CACHE_DIR)/$(CACHE_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(STORAGE_DIR)/$(STORAGE_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(MESSAGING_DIR)/$(MESSAGING_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(POLICY_DIR)/$(POLICY_APP)/docker-compose.yml)

# Fixed services (always included; skipped silently if not yet created)
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/intranet_service_provider/base/domain_registry/core/dnsmasq/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/localnet_authority/dashboards/heimdall/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/intranet_service_provider/base/health/endpoint/docker-compose.yml)
COMPOSE_FILES += $(call include_if,build/layers/authority/net_time/slots/chrony/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/net_web/whois/whoisd/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/localnet_authority/dashboards/dotlocal/status/uptime-kuma/docker-compose.yml)
COMPOSE_FILES += $(call include_if,build/docker/layers/architecture/internet_services_provider/gateways/nat_egress/docker-compose.yml)

# ---------------------------------------------------------------------------
# Email tier — additive/layered, not a slot (see docs/slots.md#email-tiers)
# EMAIL_TIER=1: Mailpit only (dev trap)
# EMAIL_TIER=2: Stalwart + SnappyMail webmail
# EMAIL_TIER=3: tier 2 + Dovecot IMAP
# EMAIL_TIER=4: tier 3 + Postfix relay (real outbound delivery)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Observability — opt-in feature flag, not a slot
# ENABLE_OBSERVABILITY=true starts Prometheus, Grafana, Loki, Promtail, Tempo
# ---------------------------------------------------------------------------
ifeq ($(ENABLE_OBSERVABILITY),true)
    COMPOSE_FILES += $(call include_if,build/docker/layers/architecture/.supervisor/maintenance/observability/slots/prometheus/docker-compose.yml)
    COMPOSE_FILES += $(call include_if,build/docker/layers/architecture/.supervisor/maintenance/observability/docker-compose.yml)
endif

# ---------------------------------------------------------------------------
# EXTENSION PACKS — optional, additive bundles activated by tag.
# Unlike slots, extensions are not mutually exclusive and may add many
# services at once. Set EXTENSION_TAGS in .env (space-separated).
# ---------------------------------------------------------------------------
ifdef EXTENSION_TAGS
    $(foreach tag,$(EXTENSION_TAGS),$(eval COMPOSE_FILES += $(call include_if,extensions/$(tag)/docker-compose.yml)))
endif

# ---------------------------------------------------------------------------
# Targets
# ---------------------------------------------------------------------------
.PHONY: up down restart ps status logs clean bootstrap network-lab health \
        validate-slots switch switch-ca switch-cache switch-dns

up:
	docker compose --project-name $(NETLOCAL_PROJECT) $(COMPOSE_FILES) up -d
validate-slots:
	@errors=0; \
	for entry in \
	  "DNS_APP:$(DNS_DIR)/$(DNS_APP)" \
	  "CA_APP:$(CA_DIR)/$(CA_APP)" \
	  "REGISTRY_APP:$(REGISTRY_DIR)/$(REGISTRY_APP)" \
	  "GATEWAY_APP:$(GATEWAY_DIR)/$(GATEWAY_APP)" \
	  "DB_APP:$(DB_DIR)/$(DB_APP)" \
	  "CACHE_APP:$(CACHE_DIR)/$(CACHE_APP)" \
	  "STORAGE_APP:$(STORAGE_DIR)/$(STORAGE_APP)" \
	  "MESSAGING_APP:$(MESSAGING_DIR)/$(MESSAGING_APP)" \
	  "POLICY_APP:$(POLICY_DIR)/$(POLICY_APP)"; do \
	  name=$$(echo "$$entry" | cut -d: -f1); \
	  path=$$(echo "$$entry" | cut -d: -f2)/docker-compose.yml; \
	  if [ ! -f "$$path" ]; then \
	    echo "  MISSING $$name → $$path" >&2; \
	    errors=$$((errors+1)); \
	  fi; \
	done; \
	if [ "$$errors" -gt 0 ]; then \
	  echo ""; \
	  echo "$$errors slot(s) have no compose file. Create them or update .env." >&2; \
	  exit 1; \
	fi; \
	echo "All configured slots have compose files."

up: validate-slots
	docker compose $(COMPOSE_FILES) up -d

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

# Generic slot switcher: make switch SLOT=<slot> IMPL=<impl>
switch:
	@./scripts/lib/switch.sh $(SLOT) $(IMPL)

# Convenience wrappers (delegate to the generic switch target)
switch-ca:
	@./scripts/lib/switch.sh ca $(filter-out $@,$(MAKECMDGOALS))

switch-cache:
	@./scripts/lib/switch.sh cache $(filter-out $@,$(MAKECMDGOALS))

switch-dns:
	@./scripts/lib/switch.sh dns $(filter-out $@,$(MAKECMDGOALS))
