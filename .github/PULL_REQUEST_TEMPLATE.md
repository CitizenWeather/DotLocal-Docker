## Summary

<!-- What does this PR do and why? One paragraph is enough. -->

## Type of change

- [ ] New slot implementation
- [ ] Extension pack
- [ ] Bug fix
- [ ] Documentation
- [ ] Refactor / tooling
- [ ] Other

## Checklist

- [ ] `make bootstrap && make up && make health` passes against the changed compose files
- [ ] New or changed `.env` variables are added to `.env.example` with comments
- [ ] New services carry the `netlocal.component=<role>` Docker label
- [ ] Static backbone IPs are in the `169.254.x.x` range and do not clash with existing services
- [ ] Documentation updated (`docs/`, `README.md`, or `CHANGELOG.md`) where applicable
- [ ] `CHANGELOG.md` entry added under `[Unreleased]`

## Testing

<!-- How did you verify this? `make health` output, manual steps, etc. -->
