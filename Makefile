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
# Infrastructure slots (swappable fixed services)
COMPOSE_FILES += $(call include_if,$(NTP_DIR)/$(NTP_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(DASHBOARD_DIR)/$(DASHBOARD_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(UPTIME_DIR)/$(UPTIME_APP)/docker-compose.yml)

# Optional architectural slots (blank by default — not required for basic stack)
COMPOSE_FILES += $(call include_if,$(IDENTITY_DIR)/$(IDENTITY_APP)/docker-compose.yml)
COMPOSE_FILES += $(call include_if,$(SECRETS_DIR)/$(SECRETS_APP)/docker-compose.yml)

# Fixed services — always included when their compose files exist
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/intranet_service_provider/base/domain_registry/core/dnsmasq/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/localnet_authority/dashboards/heimdall/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/intranet_service_provider/base/health/endpoint/docker-compose.yml)
COMPOSE_FILES += $(call include_if,build/layers/authority/net_time/slots/chrony/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/net_web/whois/whoisd/docker-compose.yml)
COMPOSE_FILES += $(call include_if,stacks/barebones/net_root/localnet_authority/dashboards/dotlocal/status/uptime-kuma/docker-compose.yml)
COMPOSE_FILES += $(call include_if,build/layers/architecture/internet_services_provider/gateways/nat_egress/docker-compose.yml)

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
    COMPOSE_FILES += $(call include_if,build/layers/architecture/supervisor/observability/docker-compose.yml)
    COMPOSE_FILES += $(call include_if,build/layers/architecture/supervisor/observability/slots/prometheus/docker-compose.yml)
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
        validate-slots switch switch-ca switch-cache switch-dns \
        plan apply rollback apply-status apply-history

## up — validate slots then start the full stack in detached mode
up: validate-slots
	docker compose --project-name $(NETLOCAL_PROJECT) $(COMPOSE_FILES) up -d

## validate-slots — check every non-blank *_APP variable resolves to an existing compose file
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

## down — stop and remove all stack containers
down:
	docker compose --project-name $(NETLOCAL_PROJECT) $(COMPOSE_FILES) down

## restart — stop then start the full stack
restart: down up

## status — show running container status
ps status:
	docker compose --project-name $(NETLOCAL_PROJECT) $(COMPOSE_FILES) ps

## logs — follow logs for all services
logs:
	docker compose --project-name $(NETLOCAL_PROJECT) $(COMPOSE_FILES) logs -f

## clean — stop stack, remove volumes, and wipe volumes/ directory
clean: down
	docker compose --project-name $(NETLOCAL_PROJECT) $(COMPOSE_FILES) down -v
	rm -rf volumes/*

## bootstrap — create Docker networks and runtime directories (first-time setup)
bootstrap:
	./scripts/bootstrap.sh

## network-lab — deploy the containerlab network topology (requires containerlab)
network-lab:
	containerlab deploy -t stacks/core/containerlab/topology.clab.yml

## health — run scripts/healthcheck.py to verify TCP/UDP reachability of core services
health:
	./scripts/healthcheck.py

## switch — change a slot implementation: make switch SLOT=<slot> IMPL=<impl>
switch:
	@./scripts/lib/switch.sh $(SLOT) $(IMPL)

## switch-ca — shorthand for: make switch SLOT=ca IMPL=<impl>
switch-ca:
	@./scripts/lib/switch.sh ca $(filter-out $@,$(MAKECMDGOALS))

## switch-cache — shorthand for: make switch SLOT=cache IMPL=<impl>
switch-cache:
	@./scripts/lib/switch.sh cache $(filter-out $@,$(MAKECMDGOALS))

## switch-dns — shorthand for: make switch SLOT=dns IMPL=<impl>
switch-dns:
	@./scripts/lib/switch.sh dns $(filter-out $@,$(MAKECMDGOALS))

# ---------------------------------------------------------------------------
# Zero-downtime lifecycle — see scripts/dotlocal_lib/ for implementation.
# `plan`/`apply`/`rollback` reconcile the running stack to the desired state
# tier-by-tier, with drain hooks and health gating, preserving named volumes.
# `up`/`down`/`restart` above are left intact for backwards compatibility.
# ---------------------------------------------------------------------------

## plan — show what `apply` would change without making any changes
plan:
	@./scripts/dotlocal plan

## apply — reconcile running stack to desired state, tier-by-tier with health gating
apply:
	@./scripts/dotlocal apply $(if $(AUTO_APPROVE),--auto-approve,)

## rollback — restore previous snapshot; use SNAPSHOT=<timestamp> to pick a specific one
rollback:
	@./scripts/dotlocal rollback $(SNAPSHOT)

## apply-status — show the result of the most recent apply
apply-status:
	@./scripts/dotlocal status

## apply-history — list all past apply operations
apply-history:
	@./scripts/dotlocal history
