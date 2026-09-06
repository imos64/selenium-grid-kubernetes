# Configuration

Allocate browser memory and `/dev/shm` for realistic tests. Grid is an internal remote-code execution surface; restrict ingress to trusted test runners and use TLS at the approved ingress. Basic authentication is enabled and credentials must be supplied in an external secret.

## Credential contract

| Existing secret | Required keys |
| --- | --- |
| `selenium-secrets` | `SE_VNC_PASSWORD` |
| `selenium-basic-auth` | `SE_ROUTER_USERNAME`, `SE_ROUTER_PASSWORD` |

The disposable bootstrap script creates random 48-character values using Python's cryptographic secrets module. It creates new Secrets through stdin with an explicit context, refuses existing names and does not overwrite or rotate production credentials. It does not initialize database schemas or replace an organizational secret manager. Secrets must be created in `selenium` before the workload.

Kubernetes Secret base64 encoding is not encryption. Enable API datastore encryption, least-privilege RBAC and secret-manager integration. Rotate credentials using each application's supported procedure, then update the Kubernetes Secret and confirm all clients reconnect.

## Values

`charts/selenium/values.yaml` supplies the smaller base profile; `values-production.yaml` overlays production requests/storage. Upstream wrappers nest options under `app`; operator-managed databases expose `clusterSpec`; custom Nexus/Fabric charts expose their fields directly. Review the values files and upstream documentation before adding an option—Helm can silently ignore unknown values.

Set a CSI storage class that meets your failure-domain, expansion and encryption requirements. Never shrink an existing claim by changing a value. Before changing image major versions, validate the supported application and operator upgrade path and restore a backup in isolation.

## Access

`selenium-hub.selenium.svc.cluster.local:4444`

Services are private ClusterIP endpoints. Label only trusted client namespaces `platform-access=true`, or replace the ingress rule with explicit workload selectors. Add an approved TLS ingress and SSO/authentication where applicable. Egress filtering, external certificates, DNS and monitoring integration remain environment configuration.
