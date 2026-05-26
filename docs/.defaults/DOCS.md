# Documentation Defaults & Templates

## TODO

- [ ] Create a DOCS.md template file that new directories can copy as a starting point
- [ ] Document the DOCS.md format standard (H1 title, TODO, Outline sections)
- [ ] Add a `make docs-check` target that validates all DOCS.md files have required sections
- [ ] Collect default variable definitions and glossary terms used across all docs

## Outline

The docs defaults directory holds shared templates, style guides, and default content snippets used consistently across all NetLocal DOCS.md files.

- Defines the standard DOCS.md format: `# Title`, `## TODO` checklist, `## Outline` with bullet points
- Provides a glossary of NetLocal-specific terms (backbone network, slot, swappable, extension tag, etc.)
- Template files can be copied into new component directories as a starting scaffold
- Default variable descriptions (e.g., `NETLOCAL_ROOT_DOMAIN`, `CA_APP`) are defined here to avoid duplication
- Integrates with future documentation generation tooling that reads DOCS.md files across the repo
- Status: foundational — this directory should be populated before the documentation grows further
