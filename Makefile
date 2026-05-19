# Makefile for NetLocal
include .env
export

# Base compose files
COMPOSE_FILES = -f docker-compose.base.yml

# Add backbone DNS based on implementation
ifeq ($(DNS_IMPLEMENTATION),coredns)
    COMPOSE_FILES += -f docker-compose.dns.coredns.yml
else ifeq ($(DNS_IMPLEMENTATION),bind)
    COMPOSE_FILES += -f docker-compose.dns.bind.yml
else ifeq ($(DNS_IMPLEMENTATION),knot)
    COMPOSE_FILES += -f docker-compose.dns.knot.yml
else
    $(error Unsupported DNS_IMPLEMENTATION: $(DNS_IMPLEMENTATION))
endif

# Add CA based on implementation
ifeq ($(CA_IMPLEMENTATION),smallstep)
    COMPOSE_FILES += -f docker-compose.ca.smallstep.yml
else ifeq ($(CA_IMPLEMENTATION),openxpki)
    COMPOSE_FILES += -f docker-compose.ca.openxpki.yml
else ifeq ($(CA_IMPLEMENTATION),vault)
    COMPOSE_FILES += -f docker-compose.ca.vault.yml
else
    $(error Unsupported CA_IMPLEMENTATION: $(CA_IMPLEMENTATION))
endif

# Add registry (PowerDNS is default)
ifeq ($(REGISTRY_IMPLEMENTATION),powerdns)
    COMPOSE_FILES += -f docker-compose.registry.powerdns.yml
else ifeq ($(REGISTRY_IMPLEMENTATION),knot)
    COMPOSE_FILES += -f docker-compose.registry.knot.yml
endif

# Add authorities (policy, dashboard, health)
COMPOSE_FILES += -f docker-compose.authorities.yml

# Add essentials (gateway, data, messaging, dns forwarder)
COMPOSE_FILES += -f docker-compose.essentials.yml

# Add fabric
COMPOSE_FILES += -f docker-compose.fabric.yml

# Add email tier (based on EMAIL_TIER)
ifeq ($(EMAIL_TIER),1)
    COMPOSE_FILES += --profile tier1 -f docker-compose.email.yml
else ifeq ($(EMAIL_TIER),2)
    COMPOSE_FILES += --profile tier2 -f docker-compose.email.yml
else ifeq ($(EMAIL_TIER),3)
    COMPOSE_FILES += --profile tier3 -f docker-compose.email.yml
else ifeq ($(EMAIL_TIER),4)
    COMPOSE_FILES += --profile tier4 -f docker-compose.email.yml
endif

# Add variants (lite/heavy) based on CACHE_IMPLEMENTATION etc.
ifneq ($(CACHE_IMPLEMENTATION),redis)
    ifeq ($(CACHE_IMPLEMENTATION),redis-stack)
        COMPOSE_FILES += -f docker-compose.variants.yml --profile heavy-redis
    endif
endif

# Add observability if enabled
ifeq ($(ENABLE_OBSERVABILITY),true)
    COMPOSE_FILES += -f docker-compose.observability.yml
endif

# Add sibling mirror if enabled
ifeq ($(ENABLE_SIBLING),true)
    COMPOSE_FILES += -f docker-compose.sibling.yml
endif

# Add extensions by tag (optional, passed as EXTENSION_TAGS environment variable)
ifdef EXTENSION_TAGS
    $(foreach tag,$(EXTENSION_TAGS),$(eval COMPOSE_FILES += --profile tag-$(tag)))
    COMPOSE_FILES += -f docker-compose.extensions.yml
endif

# Targets
.PHONY: up down restart status logs clean bootstrap switch-dns switch-ca switch-cache

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

switch-dns:
	@echo "Switching DNS from $(DNS_IMPLEMENTATION) to $(NEW_DNS)"
	sed -i 's/^DNS_IMPLEMENTATION=.*/DNS_IMPLEMENTATION=$(NEW_DNS)/' .env
	make down
	make up

switch-ca:
	@echo "Switching CA from $(CA_IMPLEMENTATION) to $(NEW_CA)"
	sed -i 's/^CA_IMPLEMENTATION=.*/CA_IMPLEMENTATION=$(NEW_CA)/' .env
	make down
	make up

switch-cache:
	@echo "Switching cache from $(CACHE_IMPLEMENTATION) to $(NEW_CACHE)"
	sed -i 's/^CACHE_IMPLEMENTATION=.*/CACHE_IMPLEMENTATION=$(NEW_CACHE)/' .env
	make down
	make up