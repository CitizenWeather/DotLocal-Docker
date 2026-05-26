# Legacy Technology Support

## TODO

- [ ] Inventory all legacy services and document their deprecation timeline
- [ ] Add migration guides for each legacy service pointing to the recommended replacement
- [ ] Ensure legacy services are isolated in a separate Docker network to limit blast radius
- [ ] Remove or archive legacy services that have not been used in the past 12 months

## Outline

The legacy technology extension provides support for older or deprecated services that are still needed in some deployment scenarios but have been superseded by newer implementations.

- Activated via the `legacy` extension tag in `EXTENSION_TAGS`; compose file is at `apps/extensions/legacy/docker-compose.yml`
- Contains services that predate the current swappable slot architecture but are maintained for backward compatibility
- Each legacy service is documented with its replacement recommendation and migration path
- Legacy services run with the `profiles: ["tag-legacy"]` Docker Compose profile to ensure they are opt-in only
- Regular review process ensures deprecated services are eventually removed when no longer needed
- Status: maintained for compatibility — do not add new services here; use the slot architecture instead
