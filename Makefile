include .env
export

# External networks declaration
COMPOSE_BASE = -f stacks/core/networks.yml

# Helper to include a compose file only if it exists
define include_if
$(if $(wildcard $(1)),-f $(1))
endef

# ---------------------------------------------------------------------------
# ROLE SLOTS — mandatory roles; exactly one implementation runs per slot.
# Each *_DIR points to slots/<role>/; *_APP selects the implementation.
# Set *_APP in .env to switch. Leave blank to skip (identity, secrets).
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
NTP_DIR       = slots/ntp
DASHBOARD_DIR = slots/dashboard
UPTIME_DIR    = slots/uptime
IDENTITY_DIR  = slots/identity
SECRETS_DIR   = slots/secrets

# ---------------------------------------------------------------------------
# Compose file list
# ---------------------------------------------------------------------------
COMPOSE_FILES = $(COMPOSE_BASE)

# Core role slots
COMPOSE_FILES += $(call include_if,$(DNS_DIR)/$(DNS_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(CA_DIR)/$(CA_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(REGISTRY_DIR)/$(REGISTRY_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(GATEWAY_DIR)/$(GATEWAY_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(DB_DIR)/$(DB_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(CACHE_DIR)/$(CACHE_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(STORAGE_DIR)/$(STORAGE_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(MESSAGING_DIR)/$(MESSAGING_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(POLICY_DIR)/$(POLICY_APP)/docker-compose.yml)

# Infrastructure slots (swappable fixed services)
COMPOSE_FILES += $(call include_if,$(NTP_DIR)/$(NTP_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(DASHBOARD_DIR)/$(DASHBOARD_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(UPTIME_DIR)/$(UPTIME_APP)/docker-compose.yml)

# Optional architectural slots (blank by default — not required for basic stack)
COMPOSE_FILES += $(call include_if,$(IDENTITY_DIR)/$(IDENTITY_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(SECRETS_DIR)/$(SECRETS_APP)/docker-compose.yml)

# Fixed services — always included when their compose files exist
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/intranet_service_provider/base/domain_registry/core/dnsmasq/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/intranet_service_provider/base/health/endpoint/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/net_web/whois/whoisd/docker-compose.yml)

# ---------------------------------------------------------------------------
# Email tiers (additive/layered — not a slot)
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
# Observability — opt-in feature flag (ENABLE_OBSERVABILITY=true)
# Grafana + Promtail are always included when enabled.
# LOG_APP and TRACE_APP select the backend implementations.
# ---------------------------------------------------------------------------
ifeq ($(ENABLE_OBSERVABILITY),true)
    LOG_DIR   = slots/log
    TRACE_DIR = slots/trace
    COMPOSE_FILES += $(call include_if,build/docker/layers/architecture/.supervisor/maintenance/observability/docker-compose.yml)
    COMPOSE_FILES += $(call include_if,build/docker/layers/architecture/.supervisor/maintenance/observability/slots/prometheus/docker-compose.yml)
    COMPOSE_FILES += $(call include_if,$(LOG_DIR)/$(LOG_APP)/docker-compose.yml)
    COMPOSE_FILES += $(call include_if,$(TRACE_DIR)/$(TRACE_APP)/docker-compose.yml)
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

# Validates that every non-blank *_APP variable resolves to an existing
# compose file. Blank values (IDENTITY_APP, SECRETS_APP) are intentionally
# skipped — they are optional slots.
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
	  "POLICY_APP:$(POLICY_DIR)/$(POLICY_APP)" \
	  "NTP_APP:$(NTP_DIR)/$(NTP_APP)" \
	  "DASHBOARD_APP:$(DASHBOARD_DIR)/$(DASHBOARD_APP)" \
	  "UPTIME_APP:$(UPTIME_DIR)/$(UPTIME_APP)" \
	  "IDENTITY_APP:$(IDENTITY_DIR)/$(IDENTITY_APP)" \
	  "SECRETS_APP:$(SECRETS_DIR)/$(SECRETS_APP)"; do \
	  name=$$(echo "$$entry" | cut -d: -f1); \
	  impl=$$(echo "$$entry" | cut -d: -f2 | rev | cut -d/ -f1 | rev); \
	  path=$$(echo "$$entry" | cut -d: -f2)/docker-compose.yml; \
	  if [ -z "$$impl" ]; then continue; fi; \
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
	docker compose $(COMPOSE_FILES) down

restart: down up

ps status:
	docker compose $(COMPOSE_FILES) ps

logs:
	docker compose $(COMPOSE_FILES) logs -f

clean: down
	docker compose $(COMPOSE_FILES) down -v
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
