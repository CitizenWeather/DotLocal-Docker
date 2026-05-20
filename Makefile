-include .env
export

# ─── Path helpers ────────────────────────────────────────────────────────────

# Include a swappable barebones component if the compose file exists
define barebones_app
$(if $(wildcard apps/localnet/barebones/$(1)/$(2)/docker-compose.yml),-f apps/localnet/barebones/$(1)/$(2)/docker-compose.yml)
endef

# Include a fixed barebones service if the compose file exists
define barebones_svc
$(if $(wildcard apps/localnet/barebones/$(1)/docker-compose.yml),-f apps/localnet/barebones/$(1)/docker-compose.yml)
endef

# Include a fixed enhancement service if the compose file exists
define enhancement_svc
$(if $(wildcard apps/localnet/enhancements/$(1)/docker-compose.yml),-f apps/localnet/enhancements/$(1)/docker-compose.yml)
endef

# ─── Compose file assembly ───────────────────────────────────────────────────

COMPOSE_FILES  = -f core/networks.yml

# Swappable barebones components (selected via .env)
COMPOSE_FILES += $(call barebones_app,dns,$(DNS_APP))
COMPOSE_FILES += $(call barebones_app,ca,$(CA_APP))
COMPOSE_FILES += $(call barebones_app,registry,$(REGISTRY_APP))
COMPOSE_FILES += $(call barebones_app,policy,$(POLICY_APP))
COMPOSE_FILES += $(call barebones_app,gateway,$(GATEWAY_APP))
COMPOSE_FILES += $(call barebones_app,database,$(DB_APP))
COMPOSE_FILES += $(call barebones_app,cache,$(CACHE_APP))
COMPOSE_FILES += $(call barebones_app,storage,$(STORAGE_APP))
COMPOSE_FILES += $(call barebones_app,messages,$(MESSAGING_APP))

# Fixed barebones services (always included)
COMPOSE_FILES += $(call barebones_svc,health/endpoint)
COMPOSE_FILES += $(call barebones_svc,fabric/default-router)
COMPOSE_FILES += $(call barebones_svc,fabric/squid)
COMPOSE_FILES += $(call barebones_svc,ntp/chrony)
COMPOSE_FILES += $(call barebones_svc,status/uptime-kuma)

# Fixed enhancements (always included)
COMPOSE_FILES += $(call enhancement_svc,dot_dashboard/heimdall)
COMPOSE_FILES += $(call enhancement_svc,whois/whoisd)

# Email tier selection (EMAIL_TIER=1..4)
ifeq ($(EMAIL_TIER),1)
    COMPOSE_FILES += $(if $(wildcard apps/localnet/barebones/mail/mailpit/docker-compose.yml),--profile tier1 -f apps/localnet/barebones/mail/mailpit/docker-compose.yml)
else ifneq ($(EMAIL_TIER),)
    COMPOSE_FILES += $(if $(wildcard apps/localnet/barebones/mail/stalwart/docker-compose.yml),-f apps/localnet/barebones/mail/stalwart/docker-compose.yml)
    COMPOSE_FILES += $(if $(wildcard apps/faux_provider/mail_local/webmail/snappymail/docker-compose.yml),-f apps/faux_provider/mail_local/webmail/snappymail/docker-compose.yml)
    ifeq ($(EMAIL_TIER),3)
        COMPOSE_FILES += $(if $(wildcard apps/localnet/barebones/mail/dovecot/docker-compose.yml),-f apps/localnet/barebones/mail/dovecot/docker-compose.yml)
    endif
    ifeq ($(EMAIL_TIER),4)
        COMPOSE_FILES += $(if $(wildcard apps/localnet/barebones/mail/dovecot/docker-compose.yml),-f apps/localnet/barebones/mail/dovecot/docker-compose.yml)
        COMPOSE_FILES += $(if $(wildcard apps/localnet/barebones/mail/postfix/relay/docker-compose.yml),-f apps/localnet/barebones/mail/postfix/relay/docker-compose.yml)
    endif
endif

# Observability stack (ENABLE_OBSERVABILITY=true)
ifeq ($(ENABLE_OBSERVABILITY),true)
    COMPOSE_FILES += $(if $(wildcard apps/localnet/enhancements/observability/prometheus/docker-compose.yml),-f apps/localnet/enhancements/observability/prometheus/docker-compose.yml)
    COMPOSE_FILES += $(if $(wildcard apps/localnet/enhancements/observability/docker-compose.yml),-f apps/localnet/enhancements/observability/docker-compose.yml)
endif

# Extensions — EXTENSION_TAGS is a space-separated list of tags (e.g. "iot chaos")
ifdef EXTENSION_TAGS
    $(foreach tag,$(subst $(comma), ,$(EXTENSION_TAGS)),\
        $(eval COMPOSE_FILES += $(if $(wildcard apps/extensions/$(tag)/docker-compose.yml),--profile tag-$(tag) -f apps/extensions/$(tag)/docker-compose.yml)))
endif

comma := ,

# ─── Targets ─────────────────────────────────────────────────────────────────

.PHONY: up down restart status logs clean bootstrap network-lab health \
        switch-ca switch-cache switch-dns validate-env validate-compose \
        lint backup restore help

up: ## Start all services
	docker compose $(COMPOSE_FILES) up -d

down: ## Stop all services
	docker compose $(COMPOSE_FILES) down

restart: down up ## Stop then start

status: ## Show running service status
	docker compose $(COMPOSE_FILES) ps

logs: ## Follow service logs (Ctrl-C to exit)
	docker compose $(COMPOSE_FILES) logs -f

clean: down ## Stop services, remove volumes, wipe data
	docker compose $(COMPOSE_FILES) down -v
	rm -rf volumes/*

bootstrap: ## First-time setup: create networks, directories, config templates
	@bash scripts/bootstrap.sh

network-lab: ## Deploy ContainerLab network topology
	containerlab deploy -t core/containerlab/topology.clab.yml

health: ## Check reachability of all core services
	@python3 scripts/healthcheck.py

validate-env: ## Validate .env configuration
	@bash scripts/validate-env.sh

validate-compose: ## Validate assembled Docker Compose configuration
	@docker compose $(COMPOSE_FILES) config --quiet && echo "✓ Compose config valid"

lint: ## Run shellcheck + yamllint locally
	@command -v shellcheck >/dev/null 2>&1 && shellcheck scripts/*.sh scripts/lib/*.sh || echo "shellcheck not installed; skipping"
	@command -v yamllint >/dev/null 2>&1 && yamllint . || echo "yamllint not installed; skipping"

backup: ## Backup volumes and config to backups/
	@bash scripts/backup.sh

restore: ## Restore from backup: make restore BACKUP=<path>
	@bash scripts/restore.sh "$(BACKUP)"

switch-ca: ## Change CA provider: make switch-ca APP=smallstep
	@bash scripts/lib/switch-ca.sh "$(APP)"

switch-cache: ## Change cache provider: make switch-cache APP=redis
	@bash scripts/lib/switch-cache "$(APP)"

switch-dns: ## Change DNS provider: make switch-dns APP=coredns
	@bash scripts/lib/switch-dns.sh "$(APP)"

help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
