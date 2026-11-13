# Week 01 — Balance-Lookup API

**Niner National Bank · Branch Operations · Tue Jan 12, 2027 · Building blocks: Lambda, CloudWatch, Terraform, Git · Focus: What is resilience; RTO/RPO; SLIs · Starter repo: [`balance-lookup-demo`](https://github.com/resilience-in-the-cloud/balance-lookup-demo)**

---

## Memo

```
TO:    Consulting teams, ITCS 5010 engagement
FROM:  Marcus Bell, VP Branch Operations
CC:    Dana Whitfield, CIO
DATE:  Tue Jan 12, 2027
RE:    Teller balance lookups: we need to know before the branches do
```

Welcome aboard. I'll keep this short because my tellers don't have time for long memos and neither do I.

Every teller at our 40 branches checks a customer's balance before cashing a check, approving a withdrawal over $500, or answering "did my paycheck clear?" Today that lookup goes through an aging screen-scraper that talks to the core banking system. When it fails, nobody in IT knows. I find out when a branch manager in Gastonia calls my cell phone, usually 20 to 40 minutes after the problem started, and usually on a Friday at lunch with a line out the door.

Dana has approved a small replacement: a cloud API that tellers' workstations call for a balance. I don't need it to be fancy. I need three things:

1. It answers fast enough that tellers don't notice it.
2. When it breaks, *your monitoring* tells us, not my branch managers.
3. Someone can tell me, in plain English, how long it can be down before I have a real problem, and how you'd know.

Please bring me a recommendation I can take to Dana. She will ask what it costs and what the risk is. So will I.

— Marcus

## Business context

- **Branches and staff:** 40 branches across North Carolina and upstate South Carolina; about 420 tellers.
- **Customers:** about 600,000. Roughly 35% still visit a branch at least once a month.
- **Branch hours:** Mon–Fri 9 a.m.–5 p.m., Sat 9 a.m.–noon. Outside those hours teller traffic is near zero.
- **Volume:** each branch does about 300 balance lookups per hour. That's about 12,000 lookups an hour, or 3.3 requests per second (rps) on average. Peak is about **5 rps** (Friday lunch, the 1st and 15th of the month).
- **The data:** balances live in the core banking system ("the core"), our system of record in the Charlotte data center. The new API reads balances. It never changes them.
- **When lookups fail:** tellers phone the core operations desk for balances. That desk can handle about 1 call a minute. Lines grow, customers leave, managers waive fees to calm people down. Finance puts the cost of a lookup outage at about **$14,000 per hour** in lost teller time, waived fees and complaint handling. That figure doesn't count the reputational damage when a customer posts a photo of the line.
- **Regulatory exposure (low this week):** there is no specific regulation for a teller tool being down. But examiners expect us to know about operational problems and respond to them. "We heard about it from a branch manager" is not a good answer in an exam.

## The ask

Deploy the balance-lookup API from the starter repo, make it observable, break it on purpose, and recommend a resilience target for it with a justification Marcus and Dana can accept.

Specifically:

1. Define **how you measure "working"** (your SLI) and a **target** (your SLO) for branch hours.
2. Propose an **RTO** and say whether an **RPO** even applies here. Justify both.
3. Show, with real numbers from your own failure test, **how long it takes to detect** a failure.

## Constraints

- **Budget:** Marcus has approved "a few dollars a month" for this service. Your design must run at teller volume for under **$10/month** (excluding staff time).
- **AWS Academy Learner Lab:** use the pre-made `LabRole` (set `use_lab_role = true`); you cannot create IAM roles or users. Region us-east-1. Your lab session lasts about 4 hours, and credentials expire when it ends.
- **Security note:** the Function URL uses `authorization_type = "NONE"` so the demo works with `curl`. A real bank API would never do this. Say so in your proposal and say what you would use instead.
- **Time:** about 60 minutes in class; outside class, most of your 4–6 hours for the week (see the syllabus).

## What you'll build

```
 teller (curl) ──HTTPS──▶ Lambda Function URL ──▶ Lambda (python3.12, 3 s timeout)
                                                     │  logs + metrics
                                                     ▼
                     CloudWatch: dashboard, Errors + p99 latency (+ Throttles: yours) ──▶ SNS
```

### In class (~60 min)

1. Form your consultancy (team of 3) and start `TEAM-CHARTER.md` from the [team charter template](https://resilience-in-the-cloud.github.io/templates/team-charter.html) (signed by Fri Jan 15). Assign this week's roles (see [cases/README.md](https://resilience-in-the-cloud.github.io/cases/index.html)).
2. Clone the team repo, copy `terraform/terraform.tfvars.example` to `terraform.tfvars`, set `team_name`, run `scripts/preflight.sh`, then `terraform init` and `apply`.
3. Call the API: `curl "$(terraform -chdir=terraform output -raw api_url)?account_id=1001"`.
4. Make one small code change as a team (for example, add a field to the response or a new test account), push it, and watch the autograder run in the **Actions** tab.
5. Break it: in three terminals run `scripts/traffic.sh 300 5`, `scripts/alarm-status.sh`, and `scripts/chaos.sh errors 0.5`. Write down the clock time the failure started and the clock time the `errors` alarm went to `ALARM`.
6. Restore with `scripts/chaos.sh fix`. Note when the alarm returns to `OK`.

### Outside class

1. Repeat the experiment with latency: `scripts/chaos.sh slow 4000` (above the 3 s timeout) and `scripts/chaos.sh slow 1500` (slow but not timing out). Which alarm fires for each? How long does each take?
2. Write your SLI as a formula and compute it from the dashboard for one of your test runs (good requests ÷ total requests, where "good" means a 2xx/4xx response in under 1 second).
3. Add the missing **Throttles** alarm (marked `TODO(week 1 assignment)` in `terraform/monitoring.tf`): wire it to the SNS topic and add it to the dashboard and the `alarm_names` output. Prove it fires with `aws lambda put-function-concurrency --function-name <name> --reserved-concurrent-executions 0` while `traffic.sh` runs, then remove the limit with `aws lambda delete-function-concurrency --function-name <name>`. The autograder checks this alarm.
4. Tune **one** alarm setting (period, evaluation periods, threshold, or `treat_missing_data`) in `terraform/monitoring.tf` and record the effect on time-to-detect and false alarms. Keep the autograder green.
5. Fill in `proposal/PROPOSAL.md` from the [solution-proposal template](https://resilience-in-the-cloud.github.io/templates/solution-proposal.html), including a monthly cost estimate from the AWS Pricing Calculator.
6. Build a 5-minute deck (PDF in `proposal/`).
7. Run `scripts/teardown.sh` when you're done. Every time.

## Parameters

Your instructor may issue a different parameter set; always use the one in your repo's case file.

```yaml
form: A
service: balance-lookup
business_hours: "Mon-Fri 09:00-17:00, Sat 09:00-12:00 ET"
avg_rps: 3.3
peak_rps: 5
lookups_per_branch_per_hour: 300
branches: 40
latency_good_threshold_ms: 1000   # a "good" lookup answers in under this
lambda_timeout_s: 3
target_availability_business_hours: 99.5   # percent, measured over a 30-day month
rto_minutes: 30
rpo_minutes: null                 # you decide whether RPO applies, and justify it
outage_cost_per_hour_usd: 14000
monthly_budget_usd: 10
```

## Resilience questions

Answer these in your proposal. Short, direct answers with numbers beat long essays.

1. **Define it.** Write the SLI for this service as a formula. What counts as a "good" lookup? Why does a 404 for an unknown account count as good (or not)?
2. **Detect it.** From your own test, what was your time to detect (failure start → alarm `ALARM`)? Break it into parts: metric delay, alarm period, evaluation periods. What is the fastest you could make it, and what would that cost you in false alarms?
3. **RTO and RPO.** Is a 30-minute RTO reasonable for this service? Does RPO apply to a read-only API whose system of record is the core? Explain what *would* have an RPO in this picture.
4. **SLO math.** A 99.5% target over branch hours in a 30-day month allows how many minutes of bad service? Compare with the same target measured 24×7. Which one should Marcus sign up for, and why?
5. **Cost.** What does this service cost per month at peak volume (5 rps during branch hours)? Compare that with one hour of outage at $14,000. What does that comparison tell you about where to spend the next dollar?
6. **Latency vs. errors.** When you injected 4,000 ms of latency, tellers saw failures, but did the `errors` alarm or the latency alarm tell you first? What does that say about relying on one alarm?
7. **What would make it worse?** Name one realistic change (to code, config, or the core) that would make this service fail in a way your current alarms would *not* catch. How would you catch it?

## Deliverables checklist

Due **Mon Jan 18, 11:59 p.m.** (push to your team repo + submit the repo link in Canvas). Client readout at 5:30 p.m., Tue Jan 19.

- [ ] Team charter `TEAM-CHARTER.md` (names, team name, how you'll communicate, how you'll resolve disagreements), signed by **Fri Jan 15**
- [ ] Terraform applied and torn down; autograder green, or each failing check explained in the proposal
- [ ] One code change made through a commit and push (not edited in the console)
- [ ] `proposal/PROPOSAL.md` from the [solution-proposal template](https://resilience-in-the-cloud.github.io/templates/solution-proposal.html): SLI, SLO, RTO, RPO position, failure-test timeline, cost estimate
- [ ] Failure-test timeline table (Exhibit B format) for at least one error test and one latency test
- [ ] 5-minute presentation (PDF in `proposal/`); every team member ready for cold-call questions
- [ ] Roles for this week recorded at the top of the proposal

## Exhibits

### Exhibit A — The last three "the system is down" calls (from Marcus's phone log)

| Date | Day / time | First reported by | Time to IT awareness | Duration | Cause (found later) |
|---|---|---|---|---|---|
| Oct 2, 2026 | Fri 12:10 p.m. | Gastonia branch manager | 34 min | 1 h 05 min | Screen-scraper session pool exhausted |
| Nov 13, 2026 | Fri 11:45 a.m. | Rock Hill branch manager | 22 min | 41 min | Core maintenance job ran long |
| Dec 1, 2026 | Tue 9:05 a.m. | Three branches at once | 40 min | 1 h 20 min | Expired TLS certificate |

### Exhibit B — Failure-test timeline (fill this in from your own run)

| Event | Clock time | Minutes since failure start |
|---|---|---|
| Failure injected (`chaos.sh errors 0.5` apply finished) | | 0 |
| First `X` in `traffic.sh` output | | |
| `errors` alarm → `ALARM` | | |
| Email notification received (if subscribed) | | |
| Fix applied (`chaos.sh fix` finished) | | |
| `errors` alarm → `OK` | | |

### Exhibit C — Service map (Marcus's sketch)

```
Teller workstation ──▶ [ new balance API ] ──▶ (later weeks) data store ◀── nightly + intraday feed ◀── THE CORE
                                │
                                └── today: in-function sample accounts 1001–1004
```
