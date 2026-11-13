# Solution Proposal — Week NN: <Case title>

<!--
HOW TO USE THIS TEMPLATE
- This is the same template every week. Copy it to `proposal/PROPOSAL.md` in your team repo
  (the starter repo already contains a copy) and replace every <angle-bracket placeholder>.
- Delete these guidance comments when you are done, or leave them; they don't render on GitHub.
- Target length: 2–4 pages of prose plus tables. Short and specific beats long and generic.
- Graded with rubrics/written-proposal.md (30 points of the weekly case score). That rubric rewards
  REASONING over polish: a plain document with a justified RTO and honest test evidence beats a
  beautiful one with numbers nobody can explain.
- Anyone on the team can be cold-called on ANY section. If you can't explain it, rewrite it until you can.
- Numbers must agree with your Terraform, your dashboard screenshots and your slides.
-->

| | |
|---|---|
| **Consultancy (team name)** | <team name> |
| **Client / department** | Niner National Bank — <department from the case> |
| **Client contact** | <e.g., Marcus Bell, VP Branch Operations> |
| **Week / date** | Week <NN> — <Tue Mon DD> |
| **Repo / commit reviewed** | <github.com/resilience-in-the-cloud/...> @ `<short SHA>` |
| **Autograder result** | <score / total, link to the Actions run> |

**Roles this week** (see your team charter rotation):

| Role | Name |
|---|---|
| Lead Architect | <name> |
| Client Lead | <name> |
| Presenter | <name> |
| Ops/Observability Owner | <name> |

---

## 1. Recommendation (answer first)

<!--
Write this LAST, put it FIRST. 3–5 sentences a busy executive could read and stop.
Pattern: "We recommend <X>. It meets <target> at about $<N>/month. In testing, when <failure>
happened, we detected it in <T> and recovered in <T>. The main trade-off is <Y>. We need
<decision/approval> from <person>."
-->

<Your 3–5 sentence recommendation.>

## 2. The client's ask, restated

<!--
Restate the ask in YOUR words, as the client would recognize it. Not a copy of the case.
Include who is affected (tellers? customers? auditors?), what "working" means to them,
and any hard constraint (regulation, deadline, budget). If the case is ambiguous, say how you read it.
-->

- **What they asked for:** <one or two sentences>
- **Who depends on it and how:** <users, volume, time of day, business process>
- **What "broken" costs them:** <lost transactions, branch queues, regulatory exposure, reputation>
- **Constraints:** <AWS Academy limits, budget, compliance, deadline>
- **Out of scope:** <what you are deliberately not solving this week>

## 3. Assumptions

<!--
Every number you use that the case didn't give you is an assumption. Write it down so the client can
correct it. Mark how you'd validate it. Typical: traffic volume, business hours, cost of an outage
per hour, data change rate, number of branches affected.
-->

| # | Assumption | Why we think it's reasonable | How we'd validate it |
|---|---|---|---|
| A1 | <e.g., 40 branches × ~300 lookups/hour peak = ~3.3 req/s> | <case says "hundreds an hour"> | <ask Marcus Bell for teller-system logs> |
| A2 | <...> | <...> | <...> |
| A3 | <...> | <...> | <...> |

## 4. Architecture

<!--
One diagram, one paragraph per major component. Put the diagram in `proposal/` (PNG/SVG) or use
a Mermaid/ASCII block. Show: users, entry point, compute, data, monitoring, and where the
Availability Zone / Region boundaries are. Mark what is NEW this week vs. carried over.
-->

**Diagram:** [`proposal/architecture.png`](architecture.png) <!-- or a Mermaid / ASCII block below -->

```
<ASCII or Mermaid diagram>
```

**How it works (request path):** <one paragraph: a request enters at ..., is handled by ..., data lives in ..., we see it in ...>

| Component | AWS service / Terraform resource | Why this choice | Resilience feature used |
|---|---|---|---|
| <Entry point> | <e.g., Lambda Function URL / `aws_lambda_function_url`> | <...> | <e.g., managed, multi-AZ by default> |
| <Compute> | <...> | <...> | <timeout 3 s, reserved concurrency ...> |
| <Data> | <...> | <...> | <PITR, Multi-AZ, versioning ...> |
| <Monitoring> | <CloudWatch alarm + dashboard + SNS> | <...> | <alarm on Errors, p99 latency> |

**Architecture decisions:** <link the ADRs you wrote this week, e.g. [ADR-003](adr/ADR-003-retry-policy.md); at least one ADR per week from week 3 on>

## 5. Resilience targets

<!--
Targets must be JUSTIFIED from the business, not picked because "99.99% sounds good".
- SLI = what you measure (e.g., % of lookups that return 2xx in < 500 ms).
- SLO = the target for the SLI over a window (e.g., 99.5% over 30 days).
- Error budget = 100% − SLO, expressed in minutes or requests per window.
- RTO = how long the business can tolerate the service being down.
- RPO = how much data (measured in time) the business can tolerate losing.
Say what happens if you're wrong in either direction (too strict = cost; too loose = client pain).
Read-only services may have RPO "n/a — no data written"; say so and why.
-->

| Target | Value | Measured by (SLI / evidence) | Justification (business reason) |
|---|---|---|---|
| **Availability SLO** | <e.g., 99.5% of requests succeed, per 30 days, during branch hours> | <CloudWatch: 1 − Errors/Invocations> | <...> |
| **Latency SLO** | <e.g., p99 < 500 ms> | <CloudWatch Duration p99> | <teller waits with customer at counter> |
| **Error budget** | <e.g., 0.5% ≈ 1.6 h/month of branch hours> | <calculation shown> | <...> |
| **RTO** | <e.g., 15 minutes> | <measured recovery time in §7> | <...> |
| **RPO** | <e.g., 0 / 5 minutes / n/a> | <backup/PITR setting> | <...> |

**Is our design able to meet these?** <Yes / No / Partly — compare to your test evidence in §7. If the measured recovery time is longer than the RTO, say so and say what would close the gap.>

## 6. Failure modes

<!--
List at least 5 realistic failures for THIS architecture, including at least one of each:
a dependency failure, a bad deploy/config change, a capacity/throttling problem, a human/process
failure, and one Availability Zone or Region-level event.
Blast radius = who/what is affected and how much (one branch? all customers? one feature?).
Detection = the alarm/metric/log that tells you, and roughly how fast.
Mark which ones you actually TESTED (✔) vs. reasoned about.
-->

| # | Component | Failure | Detection (signal + time to detect) | Mitigation (design + operational) | Blast radius | Tested? |
|---|---|---|---|---|---|---|
| F1 | <Lambda> | <bad config → 50% errors> | <Errors alarm, 1–3 min> | <roll back via Terraform; runbook> | <all branches, lookups only> | ✔ |
| F2 | <...> | <...> | <...> | <...> | <...> | |
| F3 | <...> | <...> | <...> | <...> | <...> | |
| F4 | <...> | <...> | <...> | <...> | <...> | |
| F5 | <...> | <...> | <...> | <...> | <...> | |

**Biggest single point of failure remaining:** <name it, and say why you accept it (cost? Academy limit? out of scope?)>

## 7. Test evidence — what we broke

<!--
This is the heart of the proposal. Describe at least ONE deliberate failure you injected and what
happened. Use the lab's chaos script or your own method. Times should come from timestamps (alarm
history, logs, terminal output), not memory. Screenshots go in `proposal/evidence/`.
If something didn't work, say so: honest partial evidence scores better than a vague claim.
-->

**Experiment:** <hypothesis: "If <failure>, then <alarm X> fires within <N> min and <mitigation> restores service within <M> min.">

| Event | Time (ET) | Source |
|---|---|---|
| Steady state confirmed | <hh:mm:ss> | <traffic.sh output / dashboard> |
| Failure injected | <hh:mm:ss> | <`scripts/chaos.sh errors 0.5`> |
| First customer-visible error | <hh:mm:ss> | <traffic.sh> |
| Alarm → ALARM | <hh:mm:ss> | <alarm history> |
| Mitigation started | <hh:mm:ss> | <...> |
| Service healthy again | <hh:mm:ss> | <...> |
| Alarm → OK | <hh:mm:ss> | <alarm history> |

- **Time to detect (TTD):** <failure → alarm = N min>
- **Time to recover (TTR):** <failure → healthy = N min> — vs. RTO of <N min>: <met / missed>
- **Data lost:** <none / N records / n/a> — vs. RPO of <...>
- **Result vs. hypothesis:** <confirmed / refuted, and what surprised you>
- **Evidence:** embed your screenshots, e.g. `![dashboard during failure](evidence/<file>.png)` · `![alarm history](evidence/<file>.png)` (without the backticks)

**What we'd change after this test:** <one or two concrete improvements>

## 8. Cost

<!--
Use the AWS Pricing Calculator (https://calculator.aws/) and paste the SHARE LINK. Estimate for
the client's realistic production volume (from your assumptions), not the Academy lab.
Then compare cost of the resilience level against the cost of downtime. This comparison is how
Dana Whitfield (CIO) decides; she will ask "what does it cost and what's the risk?"
-->

- **AWS Pricing Calculator link:** <https://calculator.aws/#/estimate?id=...>
- **Estimated monthly cost (production volume):** $<N>/month
- **Main cost drivers:** <e.g., Lambda requests, CloudWatch alarms/dashboards, data transfer>

| Option | What you get | Monthly cost | Expected downtime / data loss per year | Notes |
|---|---|---|---|---|
| Baseline (minimum viable) | <...> | $<N> | <...> | |
| **Recommended** | <...> | $<N> | <...> | |
| Higher resilience (next level up) | <e.g., multi-Region> | $<N> | <...> | |

**Cost of downtime:** <$ per hour of outage, with reasoning, e.g., "~1,200 teller lookups/hour fail; each forces a 3-minute workaround at ~$30/hour loaded teller cost ≈ $1,800/hour, plus customer goodwill and complaint handling.">

**Is the resilience worth it?** <one paragraph: incremental cost of the recommended option vs. expected downtime cost it avoids. Show the arithmetic.>

## 9. Trade-offs and recommendation

<!--
Name at least two alternatives you considered and why you didn't choose them. Every real
recommendation gives something up: cost, complexity, latency, consistency, time to build,
operational burden. Say what you gave up and why that's the right call for THIS client.
-->

| Alternative | Pros | Cons | Why not (now) |
|---|---|---|---|
| <Alternative A> | <...> | <...> | <...> |
| <Alternative B> | <...> | <...> | <...> |

**We recommend:** <restate the recommendation with the main trade-off in one sentence.>

**What would change our mind:** <e.g., "if Branch Ops says lookups must work during a regional outage, we'd move to ... at +$N/month.">

## 10. Risks

<!--
Top 3–5 risks of the RECOMMENDED design (not of doing nothing). Use the 1–5 scales from
templates/risk-register.md. Keep the team's running register in `proposal/risk-register.md`;
copy the top items here.
-->

| ID | Risk (cause → event → impact) | Likelihood (1–5) | Impact (1–5) | Owner (role) | Mitigation |
|---|---|---|---|---|---|
| R1 | <...> | <n> | <n> | <Ops/Observability Owner> | <...> |
| R2 | <...> | <n> | <n> | <...> | <...> |
| R3 | <...> | <n> | <n> | <...> | <...> |

## 11. AI-use disclosure

<!--
Required. AI tools are allowed for building and preparing slides; they must not do the whole
project, and every team member must be able to explain everything submitted (cold-call checks this).
Be specific. "We used ChatGPT" is not a disclosure; "Claude drafted the first version of
monitoring.tf; Ana rewrote the alarm thresholds after reading the CloudWatch docs" is.
-->

| Tool | What we used it for | What we changed / verified ourselves |
|---|---|---|
| <tool or "None"> | <...> | <...> |

## 12. Who did what

<!--
Honest, specific, and consistent with your Git history. This is cross-checked against commits and
peer evaluations. Everyone should appear in more than one row over the semester.
-->

| Team member | Role this week | Contributions (be specific: files, sections, tests, slides) |
|---|---|---|
| <name> | <role> | <...> |
| <name> | <role> | <...> |
| <name> | <role> | <...> |

---

<!-- Optional appendix: extra screenshots, calculations, raw logs. Not graded for length. -->
