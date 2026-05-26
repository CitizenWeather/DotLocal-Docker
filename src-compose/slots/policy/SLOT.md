# Slot: policy

**Variable:** `POLICY_APP`
**Network:** `localnet_default`
**Label:** `netlocal.component=policy`

## Contract

An implementation must:

- Provide a policy evaluation mechanism for request or network authorization
- Be reachable from the gateway and other services on `localnet_default`

## Port conventions

| Implementation | Port | Protocol                           |
|----------------|------|------------------------------------|
| `opa`          | 8181 | HTTP REST (Rego policy evaluation) |
| `iptables`     | —    | Host-level rules, no port          |

## OPA contract (REST policy evaluation)

OPA receives a JSON input document and returns `{"result": true}` or `{"result": false}`:

```
POST /v1/data/<package>/<rule>
Content-Type: application/json

{"input": {"user": "alice", "action": "read", "resource": "/api/secrets"}}
```

## Available implementations

| Name                  | Image                        | Notes                                                  |
|-----------------------|------------------------------|--------------------------------------------------------|
| `opa` *(recommended)* | `openpolicyagent/opa:latest` | REST API for Rego policy evaluation                    |
| `iptables`            | `alpine:latest`              | Host iptables rules; **requires `cap_add: NET_ADMIN`** |

## Adding a new implementation

1. Create `slots/policy/<impl-name>/docker-compose.yml`
2. Attach to `localnet_default`
3. Add label `netlocal.component=policy`
4. Set `POLICY_APP=<impl-name>` in `.env`
