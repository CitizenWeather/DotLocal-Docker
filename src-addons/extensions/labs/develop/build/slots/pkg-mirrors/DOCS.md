# Package Mirror Slot

## TODO

- [ ] Deploy Verdaccio (npm), devpi (pip/PyPI), and apt-cacher-ng (apt) as mirror implementations
- [ ] Configure CI/CD pipelines to use local mirror endpoints instead of public registries
- [ ] Add mirror cache hit/miss metrics to Grafana for bandwidth savings tracking
- [ ] Document how to pre-populate mirrors with commonly used packages for offline operation

## Outline

The package mirror slot provides local caching mirrors for public package registries, accelerating builds and enabling offline development.

- Covers npm (Verdaccio), Python pip/PyPI (devpi), Debian/Ubuntu apt (apt-cacher-ng), and Docker Hub (Registry mirror)
- All mirrors cache upstream packages on first request, subsequent requests are served locally without internet access
- Mirror endpoints are configured via environment variables or `.npmrc`/`pip.conf` settings distributed to developer containers
- Proxy URLs follow the pattern `<pkg-type>-mirror.<ROOT_DOMAIN>` (e.g., `npm-mirror.localnet`)
- Significantly reduces CI build times and eliminates rate limiting issues with public registries
- Status: optional developer slot — high value for teams with slow internet or strict network policies
