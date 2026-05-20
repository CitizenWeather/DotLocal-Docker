include .env
export

# Base compose files (networks)
COMPOSE_BASE = -f core/networks.yml

# Helper to include an app if its directory exists
define include_app
$(if $(wildcard apps/$(1)/$(2)/docker-compose.yml),-f apps/$(1)/$(2)/docker-compose.yml)
endef

# Mandatory apps – always included
COMPOSE_FILES = $(COMPOSE_BASE)
COMPOSE_FILES += $(call include_app,dns,$(DNS_APP))
COMPOSE_FILES += $(call include_app,ca,$(CA_APP))
COMPOSE_FILES += $(call include_app,registry,$(REGISTRY_APP))
COMPOSE_FILES += $(call include_app,policy,$(POLICY_APP))
COMPOSE_FILES += $(call include_app,gateway,$(GATEWAY_APP))
COMPOSE_FILES += $(call include_app,database,$(DB_APP))
COMPOSE_FILES += $(call include_app,cache,$(CACHE_APP))
COMPOSE_FILES += $(call include_app,storage,$(STORAGE_APP))
COMPOSE_FILES += $(call include_app,messaging,$(MESSAGING_APP))
COMPOSE_FILES += -f apps/dns-forwarder/dnsmasq/docker-compose.yml
COMPOSE_FILES += -f apps/dashboard/heimdall/docker-compose.yml
COMPOSE_FILES += -f apps/health/health-endpoint/docker-compose.yml
COMPOSE_FILES += -f apps/fabric/default-router/docker-compose.yml
COMPOSE_FILES += -f apps/fabric/squid/docker-compose.yml
COMPOSE_FILES += -f apps/ntp/chrony/docker-compose.yml
COMPOSE_FILES += -f apps/whois/whoisd/docker-compose.yml
COMPOSE_FILES += -f apps/status/uptime-kuma/docker-compose.yml

# Email tier selection
ifeq ($(EMAIL_TIER),1)
    COMPOSE_FILES += --profile tier1 -f apps/email/mailpit/docker-compose.yml
else
    COMPOSE_FILES += -f apps/email/stalwart/docker-compose.yml
    COMPOSE_FILES += -f apps/webmail/snappymail/docker-compose.yml
    ifeq ($(EMAIL_TIER),3)
        COMPOSE_FILES += -f apps/email/dovecot/docker-compose.yml
    endif
    ifeq ($(EMAIL_TIER),4)
        COMPOSE_FILES += -f apps/email/postfix-relay/docker-compose.yml
    endif
endif

# Observability
ifeq ($(ENABLE_OBSERVABILITY),true)
    COMPOSE_FILES += -f apps/observability/prometheus/docker-compose.yml
    COMPOSE_FILES += -f apps/observability/grafana/docker-compose.yml
    COMPOSE_FILES += -f apps/observability/loki/docker-compose.yml
    COMPOSE_FILES += -f apps/observability/promtail/docker-compose.yml
    COMPOSE_FILES += -f apps/observability/tempo/docker-compose.yml
endif

# Extensions – each tag adds its own compose file
ifdef EXTENSION_TAGS
    $(foreach tag,$(EXTENSION_TAGS),$(eval COMPOSE_FILES += --profile tag-$(tag) -f extensions/$(tag)/docker-compose.yml))
endif

# Targets
.PHONY: up down restart ps status logs clean bootstrap network-lab health switch-ca switch-cache

up:
	docker compose up -d
	docker compose $(COMPOSE_FILES) up -d

down:
	docker compose down
	docker compose $(COMPOSE_FILES) down

restart:
	docker compose restart
restart: down up

ps:
	docker compose ps
status:
	docker compose $(COMPOSE_FILES) ps

logs:
	docker compose logs -f
	docker compose $(COMPOSE_FILES) logs -f

clean: down
	docker compose $(COMPOSE_FILES) down -v
	rm -rf volumes/*

bootstrap:
	./scripts/bootstrap.sh

network-lab:
	containerlab deploy -t core/containerlab/topology.clab.yml


health:
	./scripts/healthcheck.py

switch-ca:
	./scripts/switch-ca.sh

switch-cache:
	./scripts/switch-cache.sh