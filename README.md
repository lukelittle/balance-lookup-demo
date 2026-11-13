# Week 1 — Niner National Bank: Balance-Lookup API

**Department:** Branch Operations · **Building blocks:** Lambda, CloudWatch, Terraform, Git · **Focus:** What is resilience? RTO, RPO, SLIs

Tellers at Niner National Bank's 40 branches look up customer balances hundreds of times an hour. Branch Ops wants a tiny API for it, and wants to *know* when it breaks before a branch manager calls. Read the full brief in [CASE.md](CASE.md).

```
 teller (curl) ──HTTPS──▶ Lambda Function URL ──▶ Lambda (python3.12)
                                                     │  logs + metrics
                                                     ▼
                                   CloudWatch: dashboard, Errors alarm, p99 alarm ──▶ SNS (email)
```

---

## Your task this week

This is the exact repo your instructor demoed on the first night. It already works, so your job is to run it, break it, and measure it. The full brief is in [CASE.md](CASE.md). There is one code change:

- **Add a Throttles alarm.** It is marked `TODO(week 1 assignment)` in `terraform/monitoring.tf`. Until you add it, the autograder fails 2 checks: `06_throttle_alarm_exists` and one observability policy.

## 0. One-time setup (≈10 min)

| Tool | Check | Install |
|---|---|---|
| Git | `git --version` | https://git-scm.com/downloads |
| Terraform ≥ 1.7 | `terraform version` | https://developer.hashicorp.com/terraform/install |
| AWS CLI v2 | `aws --version` | https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html |
| Python 3.12 (for tests) | `python3 --version` | https://www.python.org/downloads/ |
| Optional: the grader's check tools | `tflint --version`, `conftest --version`, `checkov --version` | macOS: `brew install tflint conftest` and `pip install checkov==3.4.3`. Others: [tflint](https://github.com/terraform-linters/tflint#installation), [conftest](https://www.conftest.dev/install/). You can skip them: the **Actions** report runs every check on each push. |

**AWS Academy credentials** (repeat every lab session — they expire when the lab session ends, about 4 hours):

1. Canvas → AWS Academy Learner Lab → **Start Lab**; wait for the dot to turn green.
2. **AWS Details** → AWS CLI → **Show** → copy the block.
3. Paste it into `~/.aws/credentials` (replace the whole `[default]` section).
4. `aws sts get-caller-identity` should print an ARN containing `voclabs`.
5. Set the region for the `aws` CLI — the Learner Lab block fills only `~/.aws/credentials`: `export AWS_DEFAULT_REGION=us-east-1` (run it in every new terminal, or add it to your shell profile). `scripts/preflight.sh` fails without it.

## 1. Deploy (≈5 min)

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars   # set team_name
scripts/preflight.sh
terraform -chdir=terraform init
terraform -chdir=terraform apply
curl "$(terraform -chdir=terraform output -raw api_url)?account_id=1001"
```

Open the dashboard: `terraform -chdir=terraform output -raw dashboard_url` (paste into the browser where the Academy console is open).

## 2. Break it on purpose (≈10 min)

Run these in three terminal windows side by side:

```bash
scripts/traffic.sh 300 5          # window 1: steady teller traffic
scripts/alarm-status.sh           # window 2: alarm states every 10 s
scripts/chaos.sh errors 0.5       # window 3: push a "bad config": 50% of lookups fail
```

CloudWatch metrics arrive in 1-minute buckets, so **expect the alarm to flip to `ALARM` 1–3 minutes after the failure starts**. That delay is your *time to detect* — write it down; it's part of your answer.

Then try latency: `scripts/chaos.sh slow 4000` (the function times out at 3 s). Restore with `scripts/chaos.sh fix`.

## 3. Test without AWS

```bash
python3 -m venv .venv                 # once (a venv avoids pip's "externally-managed-environment" error)
source .venv/bin/activate             # in every new terminal
python3 -m pip install -r requirements-dev.txt && python3 -m pytest -q tests
terraform -chdir=terraform test        # mocked provider, no credentials needed
```

The autograder runs these plus formatting, linting, security and resilience-policy checks on every push. See the **Actions** tab for your score report.

## 4. Clean up (every time!)

```bash
scripts/teardown.sh
```

## When the alarm fires (runbook)

1. Open the dashboard. Errors, latency, or both?
2. Check what changed: `git log -3 --oneline` and `terraform -chdir=terraform show | grep -A3 environment`.
3. If failure injection is on, roll back: `scripts/chaos.sh fix`.
4. Confirm recovery: alarm returns to `OK`, `traffic.sh` shows only `.`.
5. Write the timeline into your proposal: failure start, alarm time, fix time, recovery time.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `ExpiredToken` / `InvalidClientTokenId` | Academy session ended — re-copy AWS Details credentials. |
| `AccessDenied ... iam:CreateRole` | You set `use_lab_role = false` in Academy. Set it back to `true`. |
| `403 Forbidden` from the URL | Both `aws_lambda_permission` resources must exist; re-run `apply`. |
| Alarm stays `INSUFFICIENT_DATA` | No traffic yet. Run `scripts/traffic.sh`. |
| Alarm never fires | Wait 3 min; check `failure_rate` actually changed (`terraform -chdir=terraform output failure_rate`), and that traffic includes `account_id`. |

## What to submit

Push to your team repo by the deadline in Canvas:

- [ ] Working Terraform (autograder green or explained)
- [ ] `proposal/PROPOSAL.md` filled in (the solution-proposal template)
- [ ] Your presentation slides (PDF) in `proposal/`
