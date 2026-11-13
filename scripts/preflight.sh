#!/usr/bin/env bash
# Run this FIRST. Checks your laptop + AWS Academy session are ready.
set -uo pipefail
ok(){ printf '  \033[32m✔\033[0m %s\n' "$1"; }
bad(){ printf '  \033[31m✘\033[0m %s\n' "$1"; FAIL=1; }
FAIL=0
echo "Preflight for NNB balance-lookup"
command -v git >/dev/null && ok "git $(git --version | awk '{print $3}')" || bad "git not installed"
command -v terraform >/dev/null && ok "$(terraform version | head -1)" || bad "terraform not installed (https://developer.hashicorp.com/terraform/install)"
command -v aws >/dev/null && ok "$(aws --version 2>&1 | awk '{print $1}')" || bad "aws CLI not installed"
command -v curl >/dev/null && ok "curl present" || bad "curl not installed"
if ID=$(aws sts get-caller-identity --output text --query Arn 2>/dev/null); then
  ok "AWS credentials work: $ID"
  case "$ID" in *voclabs*|*LabRole*) ok "Looks like an AWS Academy session";; *) echo "  ! not an Academy identity - set use_lab_role = false in terraform.tfvars";; esac
else
  bad "AWS credentials missing/expired. In Learner Lab: Start Lab -> AWS Details -> AWS CLI 'Show' -> paste into ~/.aws/credentials"
fi
R=$(aws configure get region 2>/dev/null || true); R="${AWS_REGION:-${AWS_DEFAULT_REGION:-$R}}"; [ -n "$R" ] && ok "region $R" || bad "no AWS region set. Run: export AWS_DEFAULT_REGION=us-east-1 (Learner Lab's AWS CLI block fills only ~/.aws/credentials)"
aws iam get-role --role-name LabRole >/dev/null 2>&1 && ok "LabRole found" || echo "  ! LabRole not visible (fine outside Academy)"
[ -f "$(dirname "$0")/../terraform/terraform.tfvars" ] && ok "terraform.tfvars present" || bad "copy terraform/terraform.tfvars.example to terraform/terraform.tfvars and set team_name"
[ $FAIL -eq 0 ] && echo "Ready." || { echo "Fix the ✘ items above."; exit 1; }
