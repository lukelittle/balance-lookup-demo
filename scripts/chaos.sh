#!/usr/bin/env bash
# Inject or remove a failure THROUGH TERRAFORM (a "bad config push").
# Usage:
#   scripts/chaos.sh errors [rate=0.5]   # make a fraction of requests fail
#   scripts/chaos.sh slow   [ms=4000]    # add latency (> 3000ms = Lambda timeouts)
#   scripts/chaos.sh fix                 # back to healthy
set -euo pipefail
TF="terraform -chdir=$(cd "$(dirname "$0")/.." && pwd)/terraform"
case "${1:-}" in
  errors) $TF apply -auto-approve -var="failure_rate=${2:-0.5}" -var="added_latency_ms=0" ;;
  slow)   $TF apply -auto-approve -var="failure_rate=0" -var="added_latency_ms=${2:-4000}" ;;
  fix)    $TF apply -auto-approve -var="failure_rate=0" -var="added_latency_ms=0" ;;
  *) echo "usage: $0 errors [rate] | slow [ms] | fix"; exit 2 ;;
esac
echo "Done. Watch: $($TF output -raw dashboard_url)"
