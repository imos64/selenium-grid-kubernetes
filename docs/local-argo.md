# Local Argo qualification

This repository supplies the Helm chart to an explicitly pinned Argo Application. The local deployment values and exact multi-source references are reviewed in `teckixora/platform-infrastructure` PR #2. One Argo owner manages each release; do not install a second Helm/Terraform release.

`workloadNetworkPolicy.enabled=false` is permitted only with the separately rendered default-deny and service-specific policies in the infrastructure release. The shared `platform-access=true` namespace allowance is not used for the local deployment. Services remain ClusterIP, no Ingress is created, and authenticated NGINX endpoints are accessed by loopback-only port forwards. No public tunnel, Cloudflare or DNS configuration changes are made.

The local profile retains nonroot execution, read-only root filesystems, dropped capabilities, RuntimeDefault seccomp, no service-account token, immutable images and bounded resources. Grid uses one Chromium worker with one session; no Firefox/Edge/video/autoscaler. Sonar uses one Community instance and a dedicated PostgreSQL/PVC; analysis is serialized. Credentials are supplied separately and never committed.

Rendering uses only checksum-locked vendored dependencies. `scripts/render.py` never refreshes a mutable upstream chart during validation. Kubernetes 1.36.1 and Argo Helm 4.2.1 are the actual local target; rendering/admission and runtime results are separate evidence. No upstream Kubernetes support promise is inferred from local success. The infrastructure release must record real startup, authentication, analysis/browser sessions, persistence and capacity before acceptance.

Grid 0.59.1 lacks pod security-context and hub init-container values hooks. `patches/selenium-grid.patch` is the reviewed three-file extension (including the distinct version `0.59.1-techixora.1`); `patches/build_grid_chart.py` reproduces its archive from original upstream SHA-256 `df90a9300ed27e220ccde25beacf90f9b5d7b145595000ca195162315174ad78`. Disabled bundled dependencies are unchanged. Runtime qualification and patch maintenance remain our responsibility.

## Runtime image corrections

The latest official 4.49.0-20260909 hub and Chromium images still fail the HIGH/CRITICAL scan gate. The two Dockerfiles start from their exact digests and remove unused runtime tooling: pip (including its bundled vulnerable msgpack and setuptools metadata/code), plus Chromium's optional rclone uploader. Selenium, the browsers, drivers and their runtime packages are unchanged. No vulnerability suppression is used. Upload/video/build-package features are unsupported by this minimal local profile.

`python3 scripts/qualify_runtime.py hub --output evidence/hub` (and `chromium`) builds only committed Dockerfiles, checks source labels, tests restricted runtime imports without network, enforces the complete pinned Trivy image gate and generates an SBOM. Failures and receipts are retained. Public-repository CI does not publish images or deploy; after the reviewed merge and exact main CI succeed, the operator may publish these exact qualified images to the existing GHCR connection, independently rescan the published digests, and pin those digests in the infrastructure PR. This uses no subscription or purchased resource. It does not modify the Phase A operator verifier.
