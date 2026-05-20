1# DotLocal-Docker — Master Capability Roadmap

This document synthesises every gap, missing capability, and planned feature identified across the full platform analysis. It is the canonical reference for what exists, what is planned, and what is entirely absent. Use it to prioritise work, evaluate contributions, and communicate the platform's scope.

---

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Implemented and operational |
| 🔄 | Partially implemented or formally planned |
| ❌ | Identified as needed; not yet started |

---

## 1. Architecture Principles

The platform is built on five invariants. Every gap below should be evaluated against them.

1. **Swappable slots** — each functional role is filled by one named implementation selected via an environment variable.
2. **Production parity** — the local environment must mirror real infrastructure closely enough that bugs found locally reproduce in production.
3. **Zero implicit trust** — no service should communicate with another without explicit network policy and mutual authentication.
4. **Observable by default** — logs, metrics, and traces are emitted and collected for every service without developer configuration.
5. **Composable extensions** — optional capabilities are activated by a tag, never baked in unconditionally.

---

## 2. Foundational Slots

These are non-optional. The platform does not claim production parity without all of them running.

| Slot variable | Role | Default impl | Status | Critical gaps |
|---|---|---|---|---|
| `DNS_APP` | Authoritative + recursive DNS | CoreDNS | ✅ | No DNSSEC, no DoH/DoT, no PTR automation |
| `CA_APP` | Certificate authority | step-ca | ✅ | No intermediate CA hierarchy, no OCSP stapling |
| `GATEWAY_APP` | Reverse proxy / ingress | Traefik / Caddy | ✅ | No full WAF (Coraza), no weighted canary routing |
| `IDENTITY_APP` | OIDC/SAML identity provider | Keycloak | 🔄 | Auto-realm bootstrap incomplete, no OIDC forward-auth wiring |
| `SECRETS_APP` | Secrets vault & dynamic credentials | Vault | 🔄 | Unseal automation missing, no rotation dry-run |
| `OBSERVABILITY_APP` | Logs + metrics + traces | Grafana stack | 🔄 | No continuous profiling, no synthetic monitoring, no error tracking |
| `BROKER_APP` | Async message broker | RabbitMQ / NATS | 🔄 | No event streaming (Kafka/Redpanda) formalised |
| `DB_APP` | Relational database | PostgreSQL | ✅ | No automated schema migration sidecar, no backup scheduling |
| `MESH_APP` | Service mesh / mTLS | (none) | ❌ | Entire slot missing |
| `POLICY_APP` | Network & API policy engine | OPA | 🔄 | Default-deny rules not enforced, no policy simulator |
| `GIT_APP` | Local source control + CI | Gitea + runner | 🔄 | No per-branch ephemeral environments, no pre-push hook integration |

### 2.1 Identity Provider — detailed gaps

- Auto-register realm, client, and test user via bootstrap script (❌)
- Wire gateway forward-auth so all management UIs require login (❌)
- Federation to platform OIDC from Supabase auth and developer portal (❌)
- MFA simulation (TOTP, WebAuthn) for app testing (❌)
- Token introspection endpoint exposed at `auth.localhost` (❌)

### 2.2 Secrets Vault — detailed gaps

- Automated unseal via a local software HSM container issued by the CA (❌)
- Policy simulator: show which secrets a given token can access (❌)
- Secret rotation dry-run: preview service restart impact before rotating (❌)
- `vault-init.sh` must enable KV, issue an AppRole for every service, and write first-run secrets without interactive input (🔄)
- File-based injection into containers via shared `tmpfs` volume (❌)

### 2.3 Observability — detailed gaps

- Continuous profiling (Pyroscope / Parca) — `PROFILING_APP` slot (❌)
- Synthetic monitoring / blackbox probing (Prometheus Blackbox Exporter) — `SYNTHETIC_MONITORING_APP` slot (❌)
- Error tracking (GlitchTip / local Sentry) — `ERROR_TRACKING_APP` slot (❌)
- Application Performance Index (Apdex) Grafana dashboard (❌)
- DNS query analytics sidecar (`dnscollector` + dashboard at `dns-stats.localhost`) (❌)
- Per-service profiling from the IDE debug panel via OTel + dotlocal CLI backend (❌)
- Distributed tracing enriched with tenant/user context from the IdP (❌)

---

## 3. Platform Lifecycle & Self-Management

### 3.1 In-Place Upgrades with Zero Downtime — `dotlocal apply`

A command that diffs desired state against running reality, restarts only affected containers, and preserves database volumes.

**Missing pieces:**
- State differ: compare current `docker compose config` against desired, emit a plan (❌)
- Ordered rolling restart respecting dependency graph (❌)
- Automatic rollback when a post-restart healthcheck fails within a configurable window (❌)
- `dotlocal plan` dry-run that prints the diff without executing (❌)
- Smoke-test suite run automatically after apply (❌)

### 3.2 Immutable State Migration Between Slot Implementations

Switching `DNS_APP=coredns` to `DNS_APP=pihole` must carry over existing DNS records, zone files, and upstream forwarders.

**Missing pieces:**
- Per-slot export script: reads current state into a canonical JSON format (❌)
- Per-slot import script: seeds a new implementation from canonical JSON (❌)
- Migration planner: shows what will be lost or transformed before switching (❌)
- Post-migration validation: replays healthcheck queries against the new implementation (❌)

### 3.3 Platform Configuration Versioning & GitOps

The `.env` and Compose selection should be versioned with audit trail and rollback.

**Missing pieces:**
- A local reconciliation loop (Flux-lite) that watches a Git repo and applies changes to the running instance (❌)
- `dotlocal diff` comparing running state against HEAD (❌)
- Change audit log: which variable changed, when, by whom (❌)
- Branch-per-environment: run `staging` branch of platform config alongside `main` (❌)

### 3.4 Self-Diagnosis & Repair Bot

When a core service becomes unhealthy, the platform should act, not just log.

**Missing pieces:**
- Rule engine: symptom → root cause → remediation mapping (❌)
- Automatic container restart with backoff and alerting after N failures (❌)
- Config restore from backup when corruption detected (❌)
- "Service A cannot reach B" diagnosis with one-click suggested fix (❌)
- Integration with observability stack for symptom correlation (❌)

### 3.5 Dry-Run & Simulation Mode — `dotlocal plan`

Terraform-style plan output for any stack change.

**Missing pieces:**
- Full diff: containers to create/destroy/update, DNS records to add/remove, certs to issue (❌)
- Blast-radius analysis: lists every downstream service affected by a change (❌)
- Resource estimate: predicted CPU/memory delta (❌)

---

## 4. DNS — Deep Capability Map

### 4.1 Current

CoreDNS handles `.local` zone from static zone file. PowerDNS handles dynamic records. dnsmasq forwards from host. Registration via REST API script.

### 4.2 Missing Capabilities

| Capability | Status | Notes |
|---|---|---|
| DNSSEC zone signing & validation | ❌ | Knot DNS or Bind with signed zones; local root CA signs DNSKEY |
| DNS over HTTPS / DNS over TLS | ❌ | `doh-proxy` container; browsers can target it |
| Dynamic DNS updates (RFC 2136 / nsupdate) | ❌ | TSIG-scoped updates from containers to their own A records |
| DNS firewall / RPZ | ❌ | Bind RPZ or CoreDNS policy plugin; load threat feed from container |
| Split-horizon / views | ❌ | Different zone data per source subnet (internal vs. lab topology) |
| Reverse DNS (PTR) automation | ❌ | Auto-generate `in-addr.arpa` zones from backbone IP assignments |
| DNS query analytics & audit log | ❌ | `dnscollector` sidecar + Grafana dashboard at `dns-stats.localhost` |
| Zone transfer testing (AXFR/IXFR) | ❌ | Secondary DNS container; TSIG-restricted transfers |
| DNS Registrar API for CI/CD | ❌ | REST endpoint callable from pipelines to register preview domains |
| Self-service DNS Management UI | ❌ | Web UI + API for zone management; auto-issues cert on record creation |
| DoH/DoT for browser testing | ❌ | Configures system resolver to local encrypted endpoint |

---

## 5. Certificate Authority — Deep Capability Map

| Capability | Status | Notes |
|---|---|---|
| Root CA (step-ca) | ✅ | ACME endpoint at `ca.<ROOT_DOMAIN>` |
| Intermediate CA hierarchy | ❌ | Subordinate CA per environment or extension |
| OCSP stapling | ❌ | Reduces revocation latency for strict TLS tests |
| Per-device X.509 certs (IoT) | ❌ | Client cert provisioning for simulated devices |
| Key compromise simulation | ❌ | Deliberately expose a cert, trigger auto-rotation and revocation |
| Inspection CA (HTTPS interception) | ❌ | Subordinate CA for Squid HTTPS MITM; toggle per service |
| TOFU vs. strict validation toggle | ❌ | Platform-wide switch forces strict TLS validation everywhere |
| Cert lifecycle notification | ❌ | DNS registrar UI warns N days before expiry |

---

## 6. Networking

| Capability | Status | Notes |
|---|---|---|
| Dual Docker networks (backbone / default) | ✅ | Core architecture |
| Static backbone IPs for infra containers | ✅ | `169.254.x.x` range |
| Load balancer L7 | ✅ | Gateway slot |
| Load balancer L4 | ❌ | Not explicitly modelled |
| DHCP & IPAM | ❌ | Kea or dnsmasq-DHCP; updates DNS dynamically |
| Software router slot (`ROUTER_APP`) | ❌ | FRRouting or VyOS with web management UI |
| VPN slot (`VPN_APP`) | ❌ | WireGuard; auto-generates client configs; site-to-site to cloud VPC |
| CDN emulation (`CDN_APP`) | ❌ | Varnish / ATS; cache rules, purge API, surrogate keys |
| NAT / egress gateway (`EGRESS_APP`) | ❌ | Squid + iptables NAT; logs all outbound; domain whitelist policy |
| SD-WAN simulation | ❌ | Dynamic path selection + failover over emulated WAN links |
| WAN emulator (latency/loss) | ❌ | `tc netem` or WANem container; configurable per link |
| Containerlab topology engine | 🔄 | Multi-vendor router topologies; missing DNS auto-registration for lab nodes |
| Visual topology map | ❌ | Live web UI showing link state and health |
| Per-service network policy (micro-segmentation) | 🔄 | OPA/iptables; default-deny not enforced |

---

## 7. Security

| Capability | Status | Notes |
|---|---|---|
| PKI (CA slot) | ✅ | See §5 |
| Identity provider (IdP slot) | 🔄 | See §2.1 |
| Secrets vault | 🔄 | See §2.2 |
| Policy as code (OPA) | 🔄 | Planned; not enforced by default |
| Service mesh / mTLS | ❌ | `MESH_APP` slot entirely missing |
| Image vulnerability scanner | 🔄 | Mentioned with local registry; no dedicated slot |
| Code signing & attestation (Sigstore) | ❌ | Local Fulcio + Rekor + CT log; `cosign` verifies images; registry enforces signed-only |
| Compliance as code (CIS benchmarks) | ❌ | InSpec / OpenSCAP container; Grafana compliance dashboard |
| API security gateway / WAF | ❌ | Coraza/ModSecurity sidecar on gateway; OWASP CRS rules |
| Runtime container security (Falco) | ❌ | `RUNTIME_SEC_APP` slot; syscall anomaly alerts to Alertmanager |
| Network intrusion detection (Suricata) | ❌ | `IDS_APP` slot; mirrored traffic port |
| Secret rotation engine | ❌ | Coordinates Vault + service restarts without downtime |
| Air-gap audit mode | ❌ | Monitors all outbound traffic; flags unexpected connections including NTP/package mirrors |
| GDPR/CCPA deletion simulation | ❌ | `COMPLIANCE_TEST` extension; synthetic deletion commands + compliance report |
| Key compromise simulation | ❌ | Deliberate cert exposure → auto rotation → revocation validation |
| TOFU vs. strict TLS toggle | ❌ | Platform-wide switch; catches cert validation bugs |
| Data residency assurance | ❌ | Verify no data leaves local machine under any configuration |

---

## 8. Observability — Full Map

| Capability | Status | Notes |
|---|---|---|
| Metrics (Prometheus) | 🔄 | Core stack; not all services emit metrics yet |
| Alerting (Alertmanager) | 🔄 | Core stack |
| Log aggregation (Loki/Promtail) | 🔄 | Core stack; not all services have scrape labels |
| Distributed tracing (Tempo/Jaeger) | 🔄 | Core stack |
| Continuous profiling (Pyroscope) | ❌ | `PROFILING_APP` slot |
| Synthetic monitoring (Blackbox Exporter) | ❌ | `SYNTHETIC_MONITORING_APP`; checks HTTP/DNS/TCP, TLS expiry |
| Error tracking (GlitchTip) | ❌ | `ERROR_TRACKING_APP`; Sentry-compatible SDK |
| Apdex scoring dashboard | ❌ | Grafana panel computed from Prometheus metrics |
| DNS query analytics | ❌ | `dnscollector` + `dns-stats.localhost` dashboard |
| Business-context trace enrichment | ❌ | OTel collector enriches spans with tenant/user from IdP |
| IDE-integrated per-service observability | ❌ | VS Code / JetBrains extension showing latency, logs, live traffic |

---

## 9. Messaging & Events

| Capability | Status | Notes |
|---|---|---|
| Message broker AMQP (RabbitMQ) | 🔄 | Core `BROKER_APP` |
| Message broker (NATS / NATS JetStream) | 🔄 | Compose files exist; not formalised as slot |
| Event streaming (`STREAM_APP`) | ❌ | Redpanda (Kafka-compatible) + Apicurio schema registry + Kowl UI |
| Event store (`EVENTSTORE_APP`) | ❌ | EventStoreDB + projection management |
| Webhook relay (`WEBHOOK_APP`) | ❌ | Captures outbound webhooks, displays, replays; bridges Stripe/GitHub to local services |
| MQTT broker IoT extension | 🔄 | EMQX in IoT extension |
| Message transformation (`INTEGRATION_BUS_APP`) | 🔄 | Camel-K; YAML DSL; content-based routing |
| FaaS event gateway | ❌ | Bridges RabbitMQ/Kafka/HTTP to function invocations |

---

## 10. Data & Analytics

| Capability | Status | Notes |
|---|---|---|
| Relational DB (PostgreSQL) | ✅ | Core `DB_APP` |
| Schema migration sidecar (Flyway) | ❌ | Runs `migrations/` on startup |
| NoSQL document store (MongoDB) | 🔄 | Extension candidate |
| Graph database (`GRAPH_DB_APP`) | ❌ | Neo4j extension |
| Time-series database (`TSDB_APP`) | ❌ | InfluxDB / TimescaleDB extension |
| Full-text search (`SEARCH_APP`) | ❌ | Meilisearch / Typesense / Elasticsearch |
| Object storage (`OBJECT_STORE_APP`) | 🔄 | MinIO; needs auto-bucket provisioning, S3 event notifications, fake STS |
| Distributed file system (`SHARED_STORAGE_APP`) | ❌ | GlusterFS / NFS for shared volumes across containers |
| ETL / data pipeline orchestrator | 🔄 | Airflow / Dagster; not yet a named slot |
| Federated query engine (`QUERY_ENGINE_APP`) | ❌ | Trino; connectors to PostgreSQL, MinIO, Elasticsearch |
| Stream processor (`STREAM_PROCESSOR_APP`) | ❌ | Flink / Kafka Streams; windowed aggregation jobs |
| Business intelligence (`BI_APP`) | 🔄 | Metabase; Grafana covers ops dashboards |
| Data catalog (`DATA_CATALOG_APP`) | ❌ | DataHub / Amundsen; crawls PostgreSQL, Trino, dbt metadata |
| Backup & snapshot orchestration (`BACKUP_MANAGER`) | 🔄 | Scripts planned; no automated scheduling or retention policy |

---

## 11. Developer Experience

| Capability | Status | Notes |
|---|---|---|
| Local Git server (Gitea) | 🔄 | `GIT_APP`; inner loop not fully configured |
| CI runner (Gitea Actions) | 🔄 | Runner exists; no sample pipeline |
| Container / artifact registry | 🔄 | Harbor / Zot; not yet a named slot |
| Code editor (code-server) | 🔄 | Planned |
| Feature flags (Unleash) | 🔄 | Planned |
| API docs & mocking (WireMock) | 🔄 | Developer portal; mocking tools mentioned |
| Developer portal (Backstage) | 🔄 | Planned; auto-populates catalogue from service labels |
| Contract testing (`CONTRACT_TEST_APP`) | ❌ | Pact Broker + Pactflow mock; publish/verify consumer-driver contracts |
| Per-branch ephemeral environments | ❌ | Auto-provision isolated stack per Git branch; unique DNS, ephemeral DB; auto-destroy on merge |
| `dotlocal` developer CLI | ❌ | Single binary: `up`, `create service`, `env create`, `cert issue`, `dns register --branch` |
| Sandbox preview URLs | ❌ | Gateway weighted routing by cookie/header; CLI sets up routing |
| Code quality (`CODE_QUALITY_APP`) | 🔄 | SonarQube in CI/CD extension |
| API development proxy (`DEV_PROXY_APP`) | ❌ | Intercepts API calls, redirects to mocks, modifies responses on the fly |
| Pre-push infrastructure validation hook | ❌ | Validates DNS, cert auto-issue, port conflicts, spins temp environment, runs smoke tests |
| Interactive troubleshooting playbooks | ❌ | Correlates symptoms to root causes; one-click remediation |
| Session recording & replay | ❌ | Records HTTP/gRPC traffic; replay against different code versions |

---

## 12. Simulation & Testing

### 12.1 Chaos Engineering

| Capability | Status | Notes |
|---|---|---|
| Network fault injection (latency, loss) | 🔄 | `tc netem` / Pumba; CLI only |
| CPU / memory / disk stress injection | ❌ | `STRESS_APP` slot attaches to target container |
| Chaos experiment as code (YAML) | ❌ | Versioned experiments with plan → dry-run → blast-radius check → apply → rollback |
| Blast-radius analysis | ❌ | Static analyser maps dependencies from service labels; warns before inject |
| Hypothesis-driven chaos (PromQL steady-state) | ❌ | Blocks experiment if steady-state metric violated |
| Non-destructive dry-run | ❌ | Inject for 2 s, measure, report without harming the environment |
| Rollback simulation | ❌ | Auto-injects, heals, verifies recovery |
| Chaos agent security hardening | ❌ | Restrict `NET_ADMIN` / `SYS_ADMIN` to chaos-enabled flag only |
| Process kill simulation (SIGKILL Docker daemon) | ❌ | Sub-test environment verifies full restart with consistent state |

### 12.2 Time & Clock Testing

| Capability | Status | Notes |
|---|---|---|
| Clock skew per container (`libfaketime`) | ❌ | Shift system clock for one or all services; test TZ differences, cert expiry, leap seconds |
| Time-travel / speed-up for long-running scenarios | ❌ | Required for lab time-limited scenarios |

### 12.3 Traffic & Load Simulation

| Capability | Status | Notes |
|---|---|---|
| Gradual traffic shifting / A/B routing | ❌ | Gateway plugin; weighted routing by cookie/header; no full mesh needed |
| Load-testing recipes | ❌ | Pre-configured k6 / Locust scenarios; 50-container stability tests |
| User-experience simulation (slow typing, abandonment) | ❌ | Browser-automation extension; realistic user behaviour |

### 12.4 Data & Storage Fault Injection

| Capability | Status | Notes |
|---|---|---|
| Data corruption / bit-flip injection | ❌ | `CORRUPTION_AGENT` proxy intercepts DB traffic; configurable bit-flip probability |
| Resource starvation / noisy neighbour | ❌ | `STRESS_APP` consumes CPU/memory/IO against a target container |
| Outbox pattern fault injection | ❌ | Crash DB or broker exactly at transaction commit; test idempotent delivery |

### 12.5 Architectural Pattern Testing

| Capability | Status | Notes |
|---|---|---|
| CQRS / event-sourcing view rebuild | ❌ | `VIEW_REBUILDER` tool; triggers rebuild, measures time, verifies consistency |
| Long-running saga compensation harness | ❌ | Steps through distributed transaction; injects failure; validates compensating actions |
| CDC (Debezium) simulation | ❌ | Generates realistic DB changes; verifies stream for schema evolution and exactly-once |
| BDD for infrastructure (Cucumber-like) | ❌ | Plain-English infrastructure behaviour tests run against live platform |

### 12.6 Infrastructure Validation

| Capability | Status | Notes |
|---|---|---|
| `dotlocal plan` dry-run | ❌ | Full diff without execution (see §3.5) |
| `dotlocal apply` rolling upgrade | ❌ | See §3.1 |
| Pre-push CI-style hook | ❌ | See §11 |
| Cross-platform CI (Ubuntu, macOS, WSL2) | ❌ | GitHub Actions matrix |
| Graceful degradation testing | ❌ | Force core service into failure; verify rest of platform handles it |

---

## 13. Multi-User & Collaboration

| Capability | Status | Notes |
|---|---|---|
| Virtual pair programming (WebRTC tunnel) | ❌ | Streams dashboards, logs, terminal to remote peer; co-editing |
| Environment snapshots (`dotlocal snapshot`) | ❌ | Freezes container images, volumes, DB contents, DNS records into portable archive |
| `dotlocal restore` from archive | ❌ | Recipient gets identical copy |
| Conflict resolution / lock manager | ❌ | Prevents two users claiming same subdomain or port; suggests alternatives |
| Multi-tenant isolation manager (`TENANT_MANAGER_APP`) | ❌ | API creates isolated namespaces with dedicated DB, DNS subzones, network policies |

---

## 14. Operational Realities

| Capability | Status | Notes |
|---|---|---|
| Log rotation & retention policies | ❌ | `MAINTENANCE_APP` cron; warns on low disk space |
| Automated volume cleanup | ❌ | Part of maintenance app |
| Security patch notifications for running images | ❌ | Dashboard cross-references image digests with CVE databases; suggests pulls |
| Electricity-loss / host-crash recovery test | ❌ | SIGKILLs Docker daemon in sub-test env; verifies containers restart with consistent state |
| Graceful degradation (Vault unreachable) | ❌ | Services fall back to cached secrets; show clear error; tested explicitly |
| Resource-aware scheduling warnings | ❌ | Warn when topology or stack exceeds host capacity; offer "simulate slow" mode |

---

## 15. Application Services (Faux Providers)

| Service | Slot | Status | Notes |
|---|---|---|---|
| Email catcher | `MAIL_PROVIDER` | ✅ | Mailpit |
| Full mail server | `MAIL_PROVIDER` | 🔄 | Stalwart + Dovecot + Postfix relay |
| SMS / telephony gateway | `SMS_APP` | ❌ | fakesms / smpp-simulator; Twilio-compatible API; web UI |
| Payment gateway simulator | `PAYMENT_APP` | ❌ | Stripe-mock / PayPal-mock; configurable responses; webhooks |
| Map & geolocation server | `GEO_APP` | ❌ | OpenMapTiles + Pelias/Nominatim; offline geocoding |
| AI / LLM inference | `AI_APP` | 🔄 | Ollama + Open WebUI |
| Vector database | `VECTOR_DB_APP` | ❌ | Qdrant / Weaviate; for RAG pipelines |
| Prompt registry | — | ❌ | Manages and versions LLM prompts |
| Video streaming / WebRTC | `MEDIA_APP` | ❌ | LiveKit / Jitsi; auto-provision rooms and test tokens |
| Cloud emulator AWS | `CLOUD_EMULATOR_APP` | 🔄 | LocalStack; needs IAM simulation, cost calculator, state snapshot |
| Cloud emulator Azure | `CLOUD_EMULATOR_APP` | ❌ | Azurite |
| Cloud emulator GCP | `CLOUD_EMULATOR_APP` | ❌ | GCP emulator containers |
| Container registry | `REGISTRY_APP` | 🔄 | Harbor / Zot; signed image enforcement via Sigstore |

---

## 16. Integration & Middleware

| Capability | Status | Notes |
|---|---|---|
| gRPC reflection & testing (`GRPC_TOOLKIT_APP`) | ❌ | gRPCui + gRPCurl + reflection proxy; auto-discovers gRPC services |
| WebSocket gateway (`WS_GATEWAY_APP`) | ❌ | Central WS proxy; multiplexes connections to backend services |
| GraphQL federation (`GRAPHQL_GATEWAY_APP`) | 🔄 | Apollo Router |
| Integration bus (`INTEGRATION_BUS_APP`) | 🔄 | Camel-K; YAML DSL; content-based routing |
| ESB | 🔄 | Mentioned |
| Rate limiter / quota manager (`QUOTA_APP`) | ❌ | Redis-backed; gRPC API callable from gateway |
| Config server (`CONFIG_SERVER_APP`) | ❌ | Consul KV / Spring Cloud Config; services source config over HTTP |
| Workflow engine (`WORKFLOW_APP`) | 🔄 | Temporal; multi-cluster failover, record-and-replay missing |
| BPMN engine (`BPMN_ENGINE_APP`) | ❌ | Camunda Zeebe |
| Service discovery | ✅ | DNS + labels |

---

## 17. Extensions — Deep Gap Analysis

### 17.1 Chaos Extension

Beyond the core chaos capabilities in §12.1:

- No UI for configuring experiments; currently CLI/script only (❌)
- No scheduling or recurring chaos experiments (❌)
- Integration with observability to validate steady-state hypothesis (❌)
- Security hardening: agents run with `NET_ADMIN`; must be restricted to a chaos-enabled flag and audited (❌)

### 17.2 IoT Extension

| Capability | Status |
|---|---|
| MQTT broker (Mosquitto / EMQX) | 🔄 |
| Device simulation framework (virtual sensors/actuators) | ❌ |
| Per-device X.509 cert provisioning from local CA | ❌ |
| Digital twin state sync with configurable drift | ❌ |
| Multi-protocol gateway (CoAP, LwM2M, Modbus) | ❌ |
| Sensor data pipeline (MQTT → stream processor → TSDB) | ❌ |
| Battery / sleep cycle simulation | ❌ |
| OT security simulation (Modbus/TCP + local IDS) | ❌ |
| LoRaWAN / NB-IoT network emulation | ❌ |
| Firmware OTA update simulation | ❌ |
| ChirpStack LoRa server | 🔄 |

### 17.3 Labs Extension

| Capability | Status |
|---|---|
| Structured lab catalogue / curriculum | ❌ |
| Declarative lab definition DSL (YAML: nodes, links, objectives, checker) | ❌ |
| Automated lab completion validation | ❌ |
| Snapshot and grade a learner's work | ❌ |
| `dotlocal lab start <repo>` from published lab repository | ❌ |
| Time-limited lab scenarios with time-travel / speed-up | ❌ |
| Performance scoring (time-to-resolve, commands used, best-practice adherence) | ❌ |
| Dynamic topology changes mid-lab | ❌ |
| Kernel feature pre-flight check (e.g., MPLS modules) | ❌ |

### 17.4 Legacy Extension

| Capability | Status |
|---|---|
| API compatibility layer (gRPC/REST adapter over legacy protocol) | ❌ |
| Deliberate CVE seeding for vulnerability scanner testing | ❌ |
| Migration path simulation (traffic split: legacy ↔ modern) | ❌ |
| Non-x86 binary emulation via QEMU user-mode | ❌ |

### 17.5 Containerlab Topology Engine

| Capability | Status |
|---|---|
| Multi-vendor router topologies | 🔄 |
| Lab nodes auto-register in `*.lab.localhost` zone | ❌ |
| Persistent config storage (reverse-diff lab changes back to YAML) | ❌ |
| Traffic injection tooling (iperf, synthetic traffic generators) | ❌ |
| WAN emulator integration (satellite / trans-continental links) | ❌ |
| Visual live topology web UI with link state | ❌ |
| Resource-aware scheduling warnings | ❌ |

### 17.6 Internet Access Control

| Capability | Status |
|---|---|
| HTTP/HTTPS forward proxy (Squid) | ✅ |
| Network profiles (offline / restricted / full) | 🔄 |
| Application-layer filtering for WebSocket / gRPC / HTTP3 | ❌ |
| HTTPS interception (CA-signed inspection cert; toggle per service) | ❌ |
| Time-based access policies | ❌ |
| Per-service allow-list based on declared dependencies | ❌ |
| DPI content modification (ICAP; inject ads / throttle video) | ❌ |
| Seamless profile switching without container restart | ❌ |

### 17.7 LocalStack / Cloud Emulator

| Capability | Status |
|---|---|
| AWS emulation (LocalStack) | 🔄 |
| Azure emulation (Azurite) | ❌ |
| GCP emulation | ❌ |
| Cross-service event recipes (S3 → Lambda → SQS) | ❌ |
| IAM policy simulation / debugger | ❌ |
| Cost simulation calculator | ❌ |
| Hybrid cloud/local API gateway routing | ❌ |
| State snapshot and restore (`dotlocal localstack snapshot`) | ❌ |

### 17.8 Supabase (BaaS)

| Capability | Status |
|---|---|
| Supabase core stack | 🔄 |
| Multi-project workspace (isolated by DNS subdomain) | ❌ |
| Schema branching (Git branch → new Supabase project) | ❌ |
| Edge functions (Deno) local testing with cold-start latency | ❌ |
| Real-time WebSocket stress testing | ❌ |
| Auth federation to platform IdP (Keycloak) | ❌ |
| PII data masking for safe sharing | ❌ |

---

## 18. Meta-Capabilities & Extensibility

### 18.1 Slot Discovery & Marketplace

- Repository / registry of slot implementations (Compose + healthcheck + migration scripts) (❌)
- `dotlocal install <slot-name>` with version constraints and compatibility metadata (❌)
- Dependency solver: checks slot interfaces and warns about conflicts before applying (❌)

### 18.2 Platform SDK for Creating New Slots

- `dotlocal create slot` wizard: scaffolds Compose, healthcheck, migration, README with correct label conventions (❌)
- Slot interface specification document defining required labels, ports, and healthcheck contract (❌)

### 18.3 Extension Interoperability

The deepest structural gap. Extensions do not currently declare dependencies on each other or on specific slot versions.

**Required:**
- Extension dependency manifest (e.g., `iot` requires `BROKER_APP>=rabbitmq-3.12`) (❌)
- Conflict detection (e.g., two extensions claiming the same port) (❌)
- Supported combination matrix (tested combinations documented or enforced) (❌)
- Shared extension services (e.g., one MQTT broker shared by `iot` and `chaos`) (❌)

### 18.4 Behaviour-Driven Infrastructure Testing

- Cucumber-like DSL: "Given a new service, when I deploy it, then it resolves via HTTPS" (❌)
- Test suite runs automatically after `dotlocal apply` (❌)

---

## 19. Implementation Phases

### Phase 0 — Project Hygiene (Immediate)

1. Complete `.env.example` with every variable, sensible defaults, and comments
2. Write `scripts/validate-env.sh` (required vars, valid `EMAIL_TIER`, no port conflicts)
3. Add `.editorconfig`, `.gitattributes`, `pre-commit` hooks (shellcheck, yamllint, dotenv-linter)
4. GitHub Actions CI skeleton: lint + validate on PR
5. Inline docstrings in Makefile and `bootstrap.sh`

### Phase 1 — Core Platform Hardening

1. Run all containers as non-root; add `read_only: true` with `tmpfs` where needed
2. Add `deploy.resources` limits to all Compose services
3. Migrate sensitive data to Docker secrets
4. Assign static IPs to all infrastructure containers on backbone
5. Extend `healthcheck.py` to cover all swappable components via `netlocal.component` labels
6. Make `bootstrap.sh` idempotent with `--force` flag
7. Implement `stop_grace_period` and restart smoke tests

### Phase 2 — Foundational Slots

Priority order based on dependency graph:

1. **Identity Provider** (Keycloak) — auto-realm bootstrap, OIDC forward-auth on gateway
2. **Secrets Vault** (Vault) — automated unseal, AppRole per service, file-based injection
3. **Observability stack** — Prometheus, Loki, Promtail, Grafana; pre-configured dashboards; scrape labels on all services
4. **Message broker** (RabbitMQ) — virtual host, test user, startup verification
5. **DB + migration sidecar** (PostgreSQL + Flyway) — runs `migrations/` on startup; `make db-backup`
6. **Service mesh** (Linkerd sidecars) — short-lived certs from internal CA; default-deny baseline
7. **Local Git + CI** (Gitea + Actions runner) — sample pipeline; `git.localhost`

### Phase 3 — Advanced Extensions

1. Network topology lab (Containerlab) — DNS auto-registration, visual UI
2. Internet access control (Squid profiles, seamless switching)
3. BaaS (Supabase) — multi-project, schema branching, IdP federation
4. Developer portal (Backstage) — catalogue from service labels, scaffolder
5. Alternative slot implementations (Pi-hole, Kong, MongoDB, Vault alternatives)
6. Domain-specific stacks: IoT, AI/LLM, CI/CD, virtual desktop

### Phase 4 — Production-Grade Quality

1. Integration tests: full platform spin-up, DNS resolution, TLS, reachability
2. Cross-platform CI: Ubuntu, macOS, Windows/WSL2
3. `dotlocal apply` rolling upgrade with rollback
4. `dotlocal plan` dry-run
5. Backup, restore, and disaster recovery automation
6. Documentation portal (MkDocs) with search, ADRs, video walkthroughs
7. Extension dependency solver and compatibility matrix
8. Community templates directory and 5-minute getting-started guide

---

## 20. `dotlocal` CLI — Command Reference (Target State)

```
dotlocal up                          Start the full platform
dotlocal down                        Stop the platform
dotlocal plan                        Show what apply would change (dry-run)
dotlocal apply                       Apply desired state; rolling restart; rollback on failure
dotlocal status                      Summarise running containers and health
dotlocal logs [service]              Tail logs
dotlocal shell <service>             Open interactive shell in a container

dotlocal cert issue <domain>         Issue TLS cert from local CA
dotlocal cert renew <domain>         Renew an existing cert
dotlocal cert revoke <domain>        Revoke and trigger rotation

dotlocal dns register <name> <ip>    Register A record; auto-issue cert
dotlocal dns register --branch <b>   Register preview domain for branch

dotlocal env create <name>           Provision ephemeral isolated environment
dotlocal env destroy <name>          Tear down ephemeral environment
dotlocal env list                    List active environments

dotlocal snapshot                    Freeze platform state to portable archive
dotlocal restore <archive>           Restore from archive

dotlocal switch <SLOT_VAR> <impl>    Switch slot implementation with state migration
dotlocal create slot <name>          Scaffold new slot implementation

dotlocal lab start <repo>            Start a lab from a published repository
dotlocal lab validate                Validate lab completion against success checker

dotlocal localstack snapshot         Save LocalStack state
dotlocal localstack restore          Restore LocalStack state
```

---

*Last updated: 2026-05-20. This document is the single source of truth for platform capability status. Update it alongside any implementation work.*
