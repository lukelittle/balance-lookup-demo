#!/usr/bin/env bash
# Simulate branch tellers looking up balances. Prints one character per request:
#   .  = 200 OK     4 = 4xx     X = 5xx/error     T = client timeout
# Usage: scripts/traffic.sh [seconds=120] [requests_per_second=5]
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
URL="${API_URL:-$(terraform -chdir="$DIR/terraform" output -raw api_url)}"
DURATION="${1:-120}"; RPS="${2:-5}"
ACCOUNTS=(1001 1002 1003 1004)
end=$(( $(date +%s) + DURATION )); ok=0; err=0; n=0
echo "Sending ~${RPS} req/s to ${URL} for ${DURATION}s (Ctrl-C to stop)"
trap 'echo; echo "requests=$n ok=$ok errors=$err"; exit 0' INT
while [ "$(date +%s)" -lt "$end" ]; do
  for _ in $(seq "$RPS"); do
    acct=${ACCOUNTS[$((RANDOM % 4))]}
    code=$(curl -s -o /dev/null -m 5 -w '%{http_code}' "${URL}?account_id=${acct}")
    n=$((n+1))
    case "$code" in 2*) printf '.'; ok=$((ok+1));; 4*) printf '4'; ok=$((ok+1));; 000) printf 'T'; err=$((err+1));; *) printf 'X'; err=$((err+1));; esac
  done
  sleep 1
done
echo; echo "requests=$n ok=$ok errors=$err"
