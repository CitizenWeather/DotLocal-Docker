# Developer Build Profiles

## TODO

- [ ] Define named build profiles (e.g., `minimal`, `full-stack`, `ci-only`) and their slot selections
- [ ] Document how to activate a profile via `.env` variable or Makefile target
- [ ] Create a profile validation script that checks all required slots are configured
- [ ] Add profile selection to the `make bootstrap` interactive setup wizard

## Outline

Developer build profiles provide pre-configured slot selections and extension combinations tailored to common development workflow scenarios.

- A profile is a named set of `*_APP` variable values and `EXTENSION_TAGS` that activate a specific developer toolchain
- Example profiles: `minimal` (DNS + CA + gateway only), `full-stack` (all slots), `backend-dev` (DB + cache + messaging + git + CI/CD)
- Profiles are stored as `.env.profile.<name>` files that can be symlinked or sourced as `.env`
- Profile documentation lists which services are activated, their URLs, and resource requirements
- The developer lab slots (git, CI/CD, registry, pkg-mirrors) are typically included in `full-stack` and `backend-dev` profiles
- Status: concept stage — profiles are manually configured via `.env` today; automated profile switching is planned
