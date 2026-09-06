# Source provenance

Maintainer: [imos64](https://github.com/imos64). Integration package version: 1.0.0. Sources reviewed 2026-09-06.

[Upstream project](https://github.com/SeleniumHQ/docker-selenium) · [Official documentation](https://www.selenium.dev/documentation/grid/)

Upstream Helm chart `selenium-grid` is pinned to `0.59.1` from `https://www.selenium.dev/docker-selenium`. Chart dependencies are vendored and locked; `helm dependency build` reproduces the recorded version.

Kubernetes CRD validation schema is the transitive definition subset of the official [Kubernetes v1.34.0 OpenAPI specification](https://github.com/kubernetes/kubernetes/blob/v1.34.0/api/openapi-spec/swagger.json), Apache-2.0. Upstream chart archives include their source templates and original license files where supplied. Container image licensing remains upstream; this deployment license does not relicense those applications.

Image versions are explicit in values or locked upstream charts. Tags are version-pinned, not guaranteed immutable; mirror and pin approved image digests for your production supply chain. Review chart, image, plugin and operator updates as one compatible change.

| Chart archive | SHA-256 |
| --- | --- |
| `charts/selenium/charts/selenium-grid-0.59.1.tgz` | `df90a9300ed27e220ccde25beacf90f9b5d7b145595000ca195162315174ad78` |
