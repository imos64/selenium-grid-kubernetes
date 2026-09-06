#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
helm lint charts/selenium --strict
helm lint charts/selenium --strict -f charts/selenium/values-production.yaml
python3 scripts/check_manifests.py
python3 scripts/check_topology.py
terraform -chdir=terraform fmt -check
terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
tofu -chdir=opentofu fmt -check
tofu -chdir=opentofu init -backend=false -input=false
tofu -chdir=opentofu validate
gitleaks dir . --redact --no-banner
