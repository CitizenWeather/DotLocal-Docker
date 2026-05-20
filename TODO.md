# DotLocal-Docker — Prioritised TODO

Extracted from [`docs/ROADMAP.md`](ROADMAP.md) (branch `alpha/alt`). Every ❌ (not started) and 🔄 (partial) item has been assigned a priority and ordered within each tier by dependency and impact.

**Priority legend**

| Tag | Meaning |
|-----|---------|
| **P0** | Blocking — project cannot be used or contributed to without these |
| **P1** | Security & stability — must land before foundational slots |
| **P2** | Foundational slots — ordered by dependency graph; unlock all downstream work |
| **P3** | Advanced features, extensions, and meta-capabilities |

Checkbox state tracks completion. Link each item to its ROADMAP section for full detail.

---

## P0 — Immediate / Project Hygiene

> Source: [ROADMAP §19 Phase 0](ROADMAP.md#19-implementation-phases)
> These are gating items: CI, env validation, and contributor tooling must exist before any other work is mergeable.

- [ ] Complete `.env.example` with every variable, sensible defaults, and inline comments
- [ ] Write `scripts/validate-env.sh` — checks required vars, valid `EMAIL_TIER` (1–4), no port conflicts
- [ ] Add `.editorconfig` and `.gitattributes`
- [ ] Add `pre-commit` hooks: shellcheck, yamllint, dotenv-linter
- [ ] GitHub Actions CI skeleton: lint + validate on every PR
- [ ] Add inline docstrings to Makefile targets and `bootstrap.sh`

---

## P1 — Core Platform Hardening

> Source: [ROADMAP §19 Phase 1](ROADMAP.md#19-implementation-phases)
> Security and operational gaps that make the running platform unsafe or fragile. Must be resolved before Phase 2 slots are wired.

- [ ] Run all containers as non-root; add `read_only: true` with `tmpfs` mounts where needed
- [ ] Add `deploy.resources` CPU/memory limits to every Compose service
- [ ] Migrate sensitive values to Docker secrets (remove plain-text env vars for credentials)
- [ ] Assign static backbone IPs to all infrastructure containers (fill in any unassigned `169.254.x.x` slots)
- [ ] Extend `healthcheck.py` to cover all swappable components via `netlocal.component` labels
- [ ] Make `bootstrap.sh` fully idempotent; add `--force` flag for clean re-runs
- [ ] Add `stop_grace_period` to every service and implement post-restart smoke tests

---

## P2 — Foundational Slots

> Source: [ROADMAP §19 Phase 2](ROADMAP.md#19-implementation-phases), §2.1–2.3
> Ordered by dependency: Identity Provider must exist before Secrets can use OIDC; both must exist before Observability can enrich traces with user context.

### Identity Provider — Keycloak (`IDENTITY_APP`)

> Source: [ROADMAP §2.1](ROADMAP.md#21-identity-provider--detailed-gaps)

- [ ] Auto-register realm, client, and test user via bootstrap script — no interactive input
- [ ] Wire gateway forward-auth so all management UIs (`*.localhost`) require login
- [ ] Federate Supabase auth and developer portal to platform OIDC
- [ ] MFA simulation: TOTP and WebAuthn test flows
- [ ] Expose token introspection endpoint at `auth.localhost`

### Secrets Vault — Vault (`SECRETS_APP`)

> Source: [ROADMAP §2.2](ROADMAP.md#22-secrets-vault--detailed-gaps)

- [ ] Automated unseal via a local software HSM container issued by the platform CA
- [ ] `vault-init.sh`: enable KV engine, issue AppRole for every service, write first-run secrets — no interactive input
- [ ] File-based secret injection into containers via shared `tmpfs` volume
- [ ] Policy simulator: show which secrets a given token can access
- [ ] Secret rotation dry-run: preview which services restart before committing

### Observability Stack (`OBSERVABILITY_APP`)

> Source: [ROADMAP §2.3](ROADMAP.md#23-observability--detailed-gaps), §8

- [ ] Pre-configured Grafana dashboards for all core services; add scrape labels to every service
- [ ] `PROFILING_APP` slot — Pyroscope continuous profiling
- [ ] `SYNTHETIC_MONITORING_APP` slot — Prometheus Blackbox Exporter (HTTP/DNS/TCP/TLS expiry checks)
- [ ] `ERROR_TRACKING_APP` slot — GlitchTip (Sentry-compatible SDK)
- [ ] DNS query analytics sidecar: `dnscollector` + Grafana dashboard at `dns-stats.localhost`
- [ ] Business-context trace enrichment: OTel collector adds tenant/user context from IdP
- [ ] Apdex scoring Grafana panel computed from Prometheus metrics

### Message Broker — RabbitMQ (`BROKER_APP`)

> Source: [ROADMAP §19 Phase 2](ROADMAP.md#19-implementation-phases)

- [ ] Configure virtual host, test user, and startup verification
- [ ] Formalise NATS / NATS JetStream as a named slot alternative

### Database + Migration Sidecar (`DB_APP`)

> Source: [ROADMAP §10](ROADMAP.md#10-data--analytics)

- [ ] Schema migration sidecar (Flyway) that runs `migrations/` on container startup
- [ ] `make db-backup` target with configurable retention

### Service Mesh (`MESH_APP`)

> Source: [ROADMAP §2](ROADMAP.md#2-foundational-slots), §6

- [ ] Add `MESH_APP` slot — Linkerd sidecars; short-lived mTLS certs issued by the platform CA
- [ ] Enforce default-deny network baseline via service mesh policy

### Local Git + CI (`GIT_APP`)

> Source: [ROADMAP §11](ROADMAP.md#11-developer-experience)

- [ ] Complete Gitea inner-loop setup; expose at `git.localhost`
- [ ] Wire Gitea Actions runner with a sample pipeline (lint → build → smoke-test)
- [ ] Per-branch ephemeral environments: isolated stack per Git branch, unique DNS, auto-destroy on merge

---

## P3 — Advanced Features & Extensions

> Source: [ROADMAP §§3–18](ROADMAP.md)
> High-value capabilities that can proceed in parallel once P2 is underway. Grouped by domain.

### Platform Lifecycle — `dotlocal` CLI

> Source: [ROADMAP §3](ROADMAP.md#3-platform-lifecycle--self-management), §20

- [ ] `dotlocal plan` — Terraform-style dry-run diff (containers to create/destroy/update, DNS changes, certs to issue, blast-radius analysis)
- [ ] `dotlocal apply` — state differ → ordered rolling restart respecting dependency graph → automatic rollback on failed healthcheck
- [ ] Per-slot export/import scripts for state migration between implementations (canonical JSON format)
- [ ] Migration planner: shows what will be lost or transformed before switching slot
- [ ] GitOps reconciliation loop: watches a Git repo, applies changes to running instance
- [ ] `dotlocal diff` — compare running state against HEAD
- [ ] Self-diagnosis rule engine: symptom → root cause → remediation; auto-restart with backoff
- [ ] `dotlocal snapshot` + `dotlocal restore` — portable archive of container images, volumes, DB, DNS records

### DNS Advanced

> Source: [ROADMAP §4](ROADMAP.md#4-dns--deep-capability-map)

- [ ] DNSSEC zone signing & validation (Knot DNS or BIND with signed zones; local root CA signs DNSKEY)
- [ ] DNS over HTTPS / DNS over TLS (`doh-proxy` container; browsers target it)
- [ ] Dynamic DNS updates: RFC 2136 / nsupdate with TSIG-scoped per-container records
- [ ] DNS firewall / RPZ (CoreDNS policy plugin; load threat feed from container)
- [ ] Reverse DNS (PTR) automation: auto-generate `in-addr.arpa` zones from backbone IP assignments
- [ ] Self-service DNS Management UI: web UI + API; auto-issues cert on record creation
- [ ] Zone transfer testing (AXFR/IXFR) with secondary DNS container
- [ ] DNS Registrar API callable from CI/CD pipelines to register preview domains

### Certificate Authority Advanced

> Source: [ROADMAP §5](ROADMAP.md#5-certificate-authority--deep-capability-map)

- [ ] Intermediate CA hierarchy: subordinate CA per environment or extension
- [ ] OCSP stapling to reduce revocation latency for strict TLS tests
- [ ] Per-device X.509 cert provisioning from local CA (IoT use case)
- [ ] Key compromise simulation: deliberately expose a cert, trigger auto-rotation and revocation
- [ ] Inspection CA: subordinate CA for Squid HTTPS MITM; toggle per service
- [ ] Platform-wide TOFU vs. strict TLS validation toggle
- [ ] Cert lifecycle notifications: warn N days before expiry

### Networking

> Source: [ROADMAP §6](ROADMAP.md#6-networking)

- [ ] Load balancer L4 slot (not currently modelled)
- [ ] DHCP & IPAM slot (Kea or dnsmasq-DHCP with dynamic DNS updates)
- [ ] Software router slot `ROUTER_APP` (FRRouting or VyOS with web management UI)
- [ ] VPN slot `VPN_APP` (WireGuard; auto-generates client configs; site-to-site to cloud VPC)
- [ ] CDN emulation slot `CDN_APP` (Varnish/ATS; cache rules, purge API, surrogate keys)
- [ ] WAN emulator (`tc netem` or WANem container; configurable per link)
- [ ] Visual live topology web UI showing link state and health
- [ ] Per-service network policy / micro-segmentation: enforce OPA default-deny

### Security Advanced

> Source: [ROADMAP §7](ROADMAP.md#7-security)

- [ ] Code signing & attestation: local Sigstore stack (Fulcio + Rekor + CT log); `cosign` enforces signed-only policy in registry
- [ ] Compliance as code: InSpec / OpenSCAP container + Grafana compliance dashboard
- [ ] API security gateway / WAF: Coraza/ModSecurity sidecar on gateway with OWASP CRS rules
- [ ] Runtime container security slot `RUNTIME_SEC_APP` (Falco): syscall anomaly alerts to Alertmanager
- [ ] Network intrusion detection slot `IDS_APP` (Suricata): mirrored traffic port
- [ ] Secret rotation engine: coordinates Vault + service restarts without downtime
- [ ] Air-gap audit mode: monitor all outbound traffic, flag unexpected connections
- [ ] GDPR/CCPA deletion simulation: `COMPLIANCE_TEST` extension + synthetic deletion commands + compliance report
- [ ] Data residency assurance: verify no data leaves local machine under any configuration

### Messaging & Events

> Source: [ROADMAP §9](ROADMAP.md#9-messaging--events)

- [ ] Event streaming slot `STREAM_APP` — Redpanda (Kafka-compatible) + Apicurio schema registry + Kowl UI
- [ ] Event store slot `EVENTSTORE_APP` — EventStoreDB + projection management
- [ ] Webhook relay slot `WEBHOOK_APP` — captures, displays, and replays outbound webhooks
- [ ] FaaS event gateway — bridges RabbitMQ/Kafka/HTTP to function invocations
- [ ] Message transformation slot `INTEGRATION_BUS_APP` (Camel-K) — YAML DSL, content-based routing

### Data & Analytics

> Source: [ROADMAP §10](ROADMAP.md#10-data--analytics)

- [ ] Graph database slot `GRAPH_DB_APP` (Neo4j extension)
- [ ] Time-series database slot `TSDB_APP` (InfluxDB / TimescaleDB extension)
- [ ] Full-text search slot `SEARCH_APP` (Meilisearch / Typesense / Elasticsearch)
- [ ] Object storage auto-provisioning: S3 event notifications and fake STS for MinIO
- [ ] Federated query engine slot `QUERY_ENGINE_APP` (Trino; connectors to PostgreSQL, MinIO, Elasticsearch)
- [ ] Stream processor slot `STREAM_PROCESSOR_APP` (Flink / Kafka Streams; windowed aggregation)
- [ ] Data catalog slot `DATA_CATALOG_APP` (DataHub / Amundsen; crawls PostgreSQL, Trino, dbt metadata)
- [ ] Automated backup scheduling and retention policy (`BACKUP_MANAGER`)

### Developer Experience

> Source: [ROADMAP §11](ROADMAP.md#11-developer-experience)

- [ ] `dotlocal` developer CLI binary — `up`, `create service`, `env create`, `cert issue`, `dns register --branch` (see full command reference in ROADMAP §20)
- [ ] Contract testing slot `CONTRACT_TEST_APP` (Pact Broker + Pactflow mock)
- [ ] Sandbox preview URLs via gateway weighted routing by cookie/header
- [ ] API development proxy slot `DEV_PROXY_APP` — intercepts API calls, redirects to mocks, modifies responses on the fly
- [ ] Pre-push infrastructure validation hook — validates DNS, cert issue, port conflicts, spins temp environment, runs smoke tests
- [ ] Interactive troubleshooting playbooks — correlates symptoms to root causes; one-click remediation
- [ ] Session recording & replay — records HTTP/gRPC traffic; replay against different code versions
- [ ] Developer portal (Backstage) — auto-populates catalogue from `netlocal.component` labels; scaffolder

### Simulation & Chaos

> Source: [ROADMAP §12](ROADMAP.md#12-simulation--testing), §17.1

- [ ] CPU/memory/disk stress injection slot `STRESS_APP` (attaches to target container)
- [ ] Chaos experiment as code: YAML-defined experiments with dry-run → blast-radius check → apply → auto-rollback
- [ ] Hypothesis-driven chaos: blocks experiment if PromQL steady-state metric violated
- [ ] Chaos scheduling: recurring experiments with UI configuration
- [ ] Clock skew per container (`libfaketime`): shift system clock for TZ differences, cert expiry, leap second testing
- [ ] Gradual traffic shifting / A/B routing via gateway weighted routing by cookie/header
- [ ] Load-testing recipes: pre-configured k6 / Locust scenarios; 50-container stability tests
- [ ] Data corruption / bit-flip injection: `CORRUPTION_AGENT` proxy intercepts DB traffic
- [ ] Outbox pattern fault injection: crash DB or broker at transaction commit to test idempotent delivery
- [ ] CQRS / event-sourcing view rebuild harness
- [ ] Long-running saga compensation harness
- [ ] BDD for infrastructure: Cucumber-like DSL ("Given a new service, when I deploy it, then it resolves via HTTPS")

### Application Services / Faux Providers

> Source: [ROADMAP §15](ROADMAP.md#15-application-services-faux-providers)

- [ ] SMS / telephony gateway slot `SMS_APP` (fakesms / smpp-simulator; Twilio-compatible API + web UI)
- [ ] Payment gateway simulator slot `PAYMENT_APP` (Stripe-mock / PayPal-mock; configurable responses + webhooks)
- [ ] Map & geolocation server slot `GEO_APP` (OpenMapTiles + Pelias/Nominatim; offline geocoding)
- [ ] Vector database slot `VECTOR_DB_APP` (Qdrant / Weaviate; for RAG pipelines)
- [ ] Prompt registry — manages and versions LLM prompts
- [ ] Video streaming / WebRTC slot `MEDIA_APP` (LiveKit / Jitsi; auto-provisions rooms and test tokens)
- [ ] AWS emulation improvements: IAM policy simulation, cost calculator, state snapshot/restore
- [ ] Azure emulation slot `CLOUD_EMULATOR_APP` (Azurite)
- [ ] GCP emulation slot `CLOUD_EMULATOR_APP`
- [ ] Cross-service event recipes for LocalStack (S3 → Lambda → SQS)

### Integration & Middleware

> Source: [ROADMAP §16](ROADMAP.md#16-integration--middleware)

- [ ] gRPC toolkit slot `GRPC_TOOLKIT_APP` (gRPCui + gRPCurl + reflection proxy; auto-discovers gRPC services)
- [ ] WebSocket gateway slot `WS_GATEWAY_APP` (central WS proxy; multiplexes connections to backend services)
- [ ] Rate limiter / quota manager slot `QUOTA_APP` (Redis-backed; gRPC API callable from gateway)
- [ ] Config server slot `CONFIG_SERVER_APP` (Consul KV / Spring Cloud Config; services source config over HTTP)
- [ ] BPMN engine slot `BPMN_ENGINE_APP` (Camunda Zeebe)

### IoT Extension

> Source: [ROADMAP §17.2](ROADMAP.md#172-iot-extension)

- [ ] Device simulation framework: virtual sensors and actuators
- [ ] Per-device X.509 cert provisioning from local CA
- [ ] Digital twin state sync with configurable drift
- [ ] Multi-protocol gateway: CoAP, LwM2M, Modbus
- [ ] Full sensor data pipeline: MQTT → stream processor → TSDB
- [ ] Battery / sleep cycle simulation
- [ ] OT security simulation: Modbus/TCP + local IDS
- [ ] LoRaWAN / NB-IoT network emulation
- [ ] Firmware OTA update simulation

### Labs Extension

> Source: [ROADMAP §17.3](ROADMAP.md#173-labs-extension)

- [ ] Structured lab catalogue and curriculum
- [ ] Declarative lab definition DSL (YAML: nodes, links, objectives, checker)
- [ ] Automated lab completion validation and grading
- [ ] `dotlocal lab start <repo>` — spin up a published lab
- [ ] Time-limited lab scenarios with `libfaketime` speed-up
- [ ] Performance scoring: time-to-resolve, commands used, best-practice adherence
- [ ] Dynamic topology changes mid-lab
- [ ] Kernel feature pre-flight check (e.g., MPLS modules)

### Legacy Extension

> Source: [ROADMAP §17.4](ROADMAP.md#174-legacy-extension)

- [ ] API compatibility layer: gRPC/REST adapter over legacy protocol
- [ ] Deliberate CVE seeding for vulnerability scanner testing
- [ ] Migration path simulation: traffic split between legacy and modern stack
- [ ] Non-x86 binary emulation via QEMU user-mode

### Containerlab Topology Engine

> Source: [ROADMAP §17.5](ROADMAP.md#175-containerlab-topology-engine)

- [ ] Lab nodes auto-register in `*.lab.localhost` DNS zone
- [ ] Persistent config storage: reverse-diff lab changes back to YAML
- [ ] Traffic injection tooling: iperf, synthetic traffic generators
- [ ] WAN emulator integration: satellite / trans-continental link simulation
- [ ] Visual live topology web UI with link state

### Internet Access Control

> Source: [ROADMAP §17.6](ROADMAP.md#176-internet-access-control)

- [ ] Application-layer filtering for WebSocket / gRPC / HTTP3
- [ ] HTTPS interception: CA-signed inspection cert; toggle per service
- [ ] Time-based access policies
- [ ] Per-service allowlist based on declared service dependencies
- [ ] DPI content modification via ICAP (inject ads / throttle video for testing)
- [ ] Seamless network profile switching without container restart

### Supabase (BaaS)

> Source: [ROADMAP §17.8](ROADMAP.md#178-supabase-baas)

- [ ] Multi-project workspace: isolated by DNS subdomain
- [ ] Schema branching: Git branch → new isolated Supabase project
- [ ] Edge functions (Deno) local testing with cold-start latency simulation
- [ ] Real-time WebSocket stress testing
- [ ] Auth federation to platform IdP (Keycloak)
- [ ] PII data masking for safe environment sharing

### Meta — Slot Marketplace & SDK

> Source: [ROADMAP §18](ROADMAP.md#18-meta-capabilities--extensibility)

- [ ] Slot marketplace / registry: `dotlocal install <slot-name>` with version constraints and compatibility metadata
- [ ] Dependency solver: checks slot interfaces and warns about conflicts before applying
- [ ] `dotlocal create slot` wizard: scaffolds Compose, healthcheck, migration, README with correct label conventions
- [ ] Slot interface specification document (required labels, ports, healthcheck contract)
- [ ] Extension dependency manifest: e.g., `iot` requires `BROKER_APP>=rabbitmq-3.12`
- [ ] Conflict detection: two extensions claiming the same port
- [ ] Supported combination matrix: tested combinations documented or enforced
- [ ] Behaviour-driven infrastructure test suite: runs automatically after `dotlocal apply`

### Multi-User & Collaboration

> Source: [ROADMAP §13](ROADMAP.md#13-multi-user--collaboration)

- [ ] `dotlocal snapshot` — freeze container images, volumes, DB contents, and DNS records into portable archive
- [ ] `dotlocal restore <archive>` — recipient gets identical copy
- [ ] Conflict resolution / lock manager: prevents two users claiming the same subdomain or port
- [ ] Multi-tenant isolation manager slot `TENANT_MANAGER_APP` — API creates isolated namespaces with dedicated DB, DNS subzones, network policies
- [ ] Virtual pair programming (WebRTC tunnel): streams dashboards, logs, terminal to remote peer

### Operational Realities

> Source: [ROADMAP §14](ROADMAP.md#14-operational-realities)

- [ ] Log rotation and retention policy (`MAINTENANCE_APP` cron; warns on low disk space)
- [ ] Automated volume cleanup as part of maintenance app
- [ ] Security patch notifications: cross-references running image digests with CVE databases; suggests pulls
- [ ] Electricity-loss / host-crash recovery test: SIGKILLs Docker daemon in sub-test env; verifies consistent restart
- [ ] Graceful degradation testing: Vault unreachable → services fall back to cached secrets → clear error shown
- [ ] Resource-aware scheduling warnings: warn when topology exceeds host capacity; offer "simulate slow" mode

---

*Sourced from `docs/ROADMAP.md` on branch `alpha/alt`. Last prioritised: 2026-05-20.*
