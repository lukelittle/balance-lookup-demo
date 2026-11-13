#!/usr/bin/env bash
# Poll alarm state every 10s until Ctrl-C. Handy on the projector next to traffic.sh.
set -uo pipefail
TF="terraform -chdir=$(cd "$(dirname "$0")/.." && pwd)/terraform"
# aws CLI calls use the stack's region, even if none is configured on this laptop.
export AWS_REGION="$($TF output -raw region 2>/dev/null || echo "${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}")"
NAMES=$($TF output -json alarm_names | python3 -c 'import json,sys; print(" ".join(json.load(sys.stdin)))')
while true; do
  printf '%s  ' "$(date +%H:%M:%S)"
  aws cloudwatch describe-alarms --alarm-names $NAMES --query 'MetricAlarms[].[AlarmName,StateValue]' --output text | awk '{printf "%s=%s  ", $1, $2}'
  echo; sleep 10
done
