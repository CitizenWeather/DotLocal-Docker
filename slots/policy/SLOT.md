# Slot: policy

**Variable:** `POLICY_APP`
**Network:** `localnet_default`
**Label:** `netlocal.component=policy`

## Contract

An implementation must:
- Provide a policy evaluation mechanism for request or network authorization
- Be reachable from the gateway and other services on `localnet_default`

## Port conventions

| Implementation | Port | Protocol |
|---|---|---|
| `opa` | 8181 | HTTP REST (Rego policy evaluation) |
| `iptables` | — | Host-level rules, no port |

## Available implementations

| Name | Image | Notes |
|---|---|---|
| `opa` *(recommended)* | `openpolicyagent/opa:latest` | REST API for Rego policy evaluation |
| `iptables` | `alpine:latest` | Host iptables rules via NET_ADMIN capability |

## Adding a new implementation

1. Create `slots/policy/<impl-name>/docker-compose.yml`
2. Attach to `localnet_default`
3. Add label `netlocal.component=policy`
4. Set `POLICY_APP=<impl-name>` in `.env`
