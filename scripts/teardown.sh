#!/usr/bin/env bash
# Destroy everything this lab created. Run at the end of every session to save Academy credits.
set -euo pipefail
terraform -chdir="$(cd "$(dirname "$0")/.." && pwd)/terraform" destroy -auto-approve
