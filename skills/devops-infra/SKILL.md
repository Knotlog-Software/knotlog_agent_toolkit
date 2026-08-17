---
name: devops-infra
description: >
  DevOps and infrastructure workflows for small full-stack teams.
  Covers deployment, CI/CD pipeline setup, monitoring/alerting,
  infrastructure management (IaC), and incident response. Project-agnostic:
  discovers cloud provider, IaC tool, deployment target, and CI platform
  from the project automatically. Each workflow has pre-flight discovery,
  phased procedure with decision branches, structured output, and
  workflow-specific anti-patterns. Use when the user asks to deploy,
  set up CI/CD, add monitoring, review infrastructure, or responds to
  an incident. Skip for application code changes, local dev setup, or
  tasks outside the deployment/operations scope.
license: MIT
---

# DevOps & Infrastructure Skill

Operational workflows for a 2-person full-stack team. This skill covers
the five things a small team actually does with infrastructure: deploy
code, keep CI green, know when things break, manage cloud resources, and
respond when something goes wrong.

Every workflow follows the same structure: discover the environment first,
then act. No hardcoded providers, paths, or tool names. The skill adapts
by reading what the project already uses.

## Global Pre-flight

Run before any workflow. Builds an infrastructure profile of the project.

**Step 1. Discover cloud provider.**

| Scan target | What to look for |
|---|---|
| `**/terraform.tf` or `**/*.tf` | Terraform files → cloud resource blocks (`aws_*`, `azurerm_*`, `google_*`) |
| `**/serverless.yml` or `**/serverless.yaml` | Serverless Framework → `provider.name` field |
| `**/vercel.json`, `**/netlify.toml` | Vercel or Netlify |
| `**/Dockerfile`, `**/docker-compose*.yml` | Container target (check `FROM` base images, compose services) |
| `**/*.tfstate` or `**/.terraform/` | Terraform state exists → IaC in use |
| `**/Pulumi.*` | Pulumi (check language: `Pulumi.yaml`) |
| `**/cdk.json` | AWS CDK |
| `**/aws-*`, `**/azure-*`, `**/gcp-*` | Provider-specific config directories |
| `**/fly.toml` | Fly.io |
| `**/render.yaml` | Render |
| `**/railway.json` | Railway |
| `**/Caddyfile` or `**/nginx*.conf` | Self-hosted with reverse proxy |

Record: `{provider: aws|gcp|azure|fly|vercel|netlify|self-hosted|unknown, iac_tool: terraform|pulumi|cdk|serverless|none, deployment_target: ...}`

**Step 2. Discover CI/CD platform.**

| Scan target | What to look for |
|---|---|
| `.github/workflows/*.yml` | GitHub Actions |
| `.gitlab-ci.yml` | GitLab CI |
| `.circleci/config.yml` | CircleCI |
| `Jenkinsfile` | Jenkins |
| `.buildkite/pipeline.yml` | Buildkite |
| `bitbucket-pipelines.yml` | Bitbucket Pipelines |
| No CI files found | No CI configured — workflow may include setup |

Record: `{ci_platform: github_actions|gitlab_ci|circleci|jenkins|buildkite|none, pipeline_files: [...]}`

**Step 3. Discover deployment configuration.**

| Scan target | What to look for |
|---|---|
| `.github/workflows/deploy*.yml` or `release*.yml` | GitHub Actions deploy jobs |
| `Procfile` | Heroku-style process management |
| `**/Dockerfile` + `docker-compose*.yml` | Containerized deployment |
| `**/nginx*.conf` | Nginx config → reverse proxy to app |
| `**/systemd/*.service` | Systemd service files |
| `fly.toml`, `render.yaml`, `railway.json` | PaaS deployment |
| `appspec.yml`, `buildspec.yml` | AWS CodeDeploy / CodeBuild |
| Kubernetes manifests (`**/*.yaml` with `kind: Deployment`) | K8s deployment |

Record: `{deploy_method: docker|k8s|paas|systemd|serverless|ci_cd_pipeline|unknown, deploy_files: [...]}`

**Step 4. Discover monitoring signals.**

| Scan target | What to look for |
|---|---|
| `**/monitoring/**`, `**/alerts/**` | Existing monitoring configs |
| `**/*alert*rules*` or `**/*prometheus*` | Prometheus alerting rules |
| `**/*grafana*` | Grafana dashboards or provisioning |
| `**/*sentry*` | Sentry error tracking |
| `**/*datadog*`, `**/*newrelic*` | APM tools |
| `**/health` or `**/healthz` endpoints in code | Health check endpoints |
| `**/metrics` endpoints in code | Metrics endpoints |

Record: `{monitoring_stack: prometheus|datadog|sentry|none, health_checks: bool, metrics_endpoint: bool}`

**Step 5. Discover project structure.**

| Scan target | What to look for |
|---|---|
| `package.json` | Node.js project, check scripts section for build/test/lint commands |
| `Cargo.toml` | Rust project |
| `go.mod` | Go project |
| `pyproject.toml`, `setup.py`, `requirements.txt` | Python project |
| `Gemfile` | Ruby project |
| `pubspec.yaml` | Dart/Flutter |
| `Makefile` | Build targets |

Record the build/test/lint commands for use in workflow phases.

**Step 6. Abort if nothing to work with.**

If the project has no CI, no IaC, no deployment config, and no
monitoring, the skill cannot perform any workflow. Report what was found
and offer to set up each from scratch — but only if the user asks.

## Workflow 1 — Deployment

Safe deployment: pre-flight checks → build → deploy → verify → monitor.

**Trigger phrases:** "deploy this", "push to production", "ship it",
"release", "go live", "deploy the changes"

### Pre-flight

1. **Check deployment readiness.** Run the project's gate commands:
   - Lint/analyze: pass
   - Tests: pass
   - Type check (if applicable): pass
   If any gate fails, abort and report which gate failed with the
   specific error. Do not deploy with failing gates.

2. **Check git state.**
   - Branch: confirm which branch is being deployed (main/master/staging)
   - Clean working tree: no uncommitted changes
   - Recent commit: confirm what changed since last deploy
   - Diff summary: `git log --oneline` last 5 commits on branch

3. **Check deployment target health.** If a health endpoint exists:
   - `curl <health_url>` — confirm target is responding
   - If target is unreachable, ABORT — the deploy target may be down

4. **Check for lock files or deploy freezes.** Look for:
   - `DEPLOY_FREEZE` file or env var
   - `.github/workflows` with deploy conditions
   - Any `freeze` or `lock` markers in deploy scripts

### Phase 1 — Build

1. Run the project's build command (discovered in pre-flight Step 5).
2. Verify build artifacts exist at expected paths.
3. If Docker-based: build the image, tag with commit SHA and `latest`.
   Verify image builds without errors.
4. Record: `{build_command, build_duration, artifact_path, image_tag}`

### Phase 2 — Deploy

Branch based on deployment method:

| Method | Steps |
|---|---|
| **CI/CD pipeline** | Push to trigger branch → wait for pipeline → verify pipeline passes |
| **Docker** | `docker compose up -d` → verify containers healthy → `docker compose ps` |
| **Kubernetes** | `kubectl apply -f` → `kubectl rollout status` → verify pods ready |
| **PaaS (Fly/Render/Railway)** | `<provider> deploy` → wait for build → verify status |
| **Serverless** | `serverless deploy` → verify function versions → `serverless info` |
| **Terraform** | `terraform plan` (review) → `terraform apply` → verify state |
| **Systemd** | Copy binary → `systemctl restart <service>` → `systemctl status` |

Decision points during deploy:
- **Terraform apply shows destruction?** Stop. Show the plan. Require
  explicit approval before destroying resources.
- **Docker build cache miss?** Flag as slower than expected. Proceed.
- **K8s rollout stuck?** After 5 minutes, abort and report pod status.
- **Pipeline fails?** Read the failure log, report the specific step
  that failed, and ABORT.

### Phase 3 — Verify

1. **Health check:** Hit the health endpoint. Expect 200 OK within
   timeout (default 30s). If health check fails 3 times, ABORT and
   initiate rollback considerations.

2. **Smoke test:** Run the project's smoke tests or manual verification
   checklist. At minimum:
   - Application starts without errors
   - Key endpoint responds
   - Database connection works (if applicable)
   - Auth flow works (if applicable)

3. **Error rate check:** If monitoring is available, check error rate
   for the last 5 minutes post-deploy. If error rate > baseline, flag
   as potential rollback candidate.

4. **Performance check:** If APM is available, check p95 latency for
   the last 5 minutes. If p95 > 2x baseline, flag.

### Phase 4 — Monitor (window)

Set a monitoring window. For a 2-person team:
- **Minor change:** 15-minute window, check error rate once
- **Major change:** 30-minute window, check error rate twice
- **Database migration:** 60-minute window, check for slow queries

After the window:
- If stable: report deployment success with commit SHA, timestamp, and
  any flags raised during verify.
- If unstable: recommend rollback with rationale.

### Output

```
Deployment Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Commit:     <sha> — <commit message>
Branch:     <branch>
Deployed:   <timestamp>
Target:     <deployment target>
Duration:   <total time>

Pre-flight:
  Lint:      ✓ Pass
  Tests:     ✓ Pass
  Git state: Clean

Build:
  Command:   <build command>
  Duration:  <time>
  Artifacts: <path or image tag>

Deploy:
  Method:    <docker|k8s|paas|...>
  Status:    ✓ Success

Verify:
  Health:    ✓ 200 OK (response: <time>ms)
  Smoke:     ✓ Pass
  Errors:    ✓ No spike
  Latency:   ✓ p95 <baseline

Monitoring window: <duration> — stable
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Deploying without passing gates** | Pushes broken code to production. Gates exist for a reason. |
| **Skipping health check** | A deployed but broken service looks like a success until users hit it. |
| **No monitoring window** | You do not know if the deploy broke something until a user reports it. |
| **Deploying on Friday afternoon** | Small team = no weekend coverage. Deploy risk scales with time-to-rollback. |
| **Rolling forward through a bad deploy** | If verify fails, rollback is almost always faster than fixing forward under pressure. |
| **Deploying multiple changes at once** | If something breaks, you cannot isolate which change caused it. |
| **Forgetting database migrations** | App code expects new schema, old schema is live. Silent data corruption. |

## Workflow 2 — CI/CD Pipeline

Pipeline setup or fix: audit → design → implement → test → deploy.

**Trigger phrases:** "set up CI", "fix the pipeline", "CI is broken",
"add a deploy step", "pipeline keeps failing", "set up CD", "automate
deploys"

### Pre-flight

1. **Audit existing CI.** Read all CI config files discovered in global
   pre-flight Step 2. For each pipeline file, extract:
   - Triggers (push, PR, schedule, manual)
   - Jobs and their dependencies
   - Steps within each job
   - Environment variables and secrets referenced
   - Runner/environment specs

2. **Check pipeline health.** If the CI platform has an API or status
   page, check recent run history:
   - Last 10 runs: pass rate
   - Flaky tests (tests that pass/fail intermittently)
   - Average pipeline duration
   - Common failure points

3. **Identify gaps.** Compare current pipeline against a baseline
   checklist:

   | Capability | Present? | Priority |
   |---|---|---|
   | Lint/analyze on PR | ? | High |
   | Test suite on PR | ? | High |
   | Type check on PR | ? | Medium |
   | Build verification | ? | High |
   | Deploy on merge to main | ? | High |
   | Environment-specific deploys (staging → prod) | ? | Medium |
   | Rollback mechanism | ? | High |
   | Secret management | ? | High |
   | Caching (deps, build artifacts) | ? | Medium |
   | Notifications (Slack/email on failure) | ? | Low |

### Phase 1 — Design

Present a pipeline design as a directed acyclic graph (DAG):

```
PR opened/updated
  └─→ Lint & Analyze
  └─→ Type Check
  └─→ Unit Tests
  └─→ Build
       └─→ Integration Tests (if applicable)
            └─→ All checks pass → Ready to merge

Merge to main
  └─→ Build (reuse from PR if cached)
  └─→ Deploy to Staging
       └─→ Smoke Tests (staging)
            └─→ Manual approval gate (optional)
                 └─→ Deploy to Production
                      └─→ Health Check
                           └─→ Notify
```

Decision points:
- **Separate staging and production?** For a 2-person team, usually
  yes if deploying customer-facing services. No if it is an internal
  tool.
- **Manual approval gate?** Recommended for production even on a small
  team. At minimum, require a manual trigger on the production deploy
  job.
- **Parallel vs. sequential jobs?** Lint, type check, and tests should
  run in parallel on PR. Build and deploy are sequential.

### Phase 2 — Implement

For each missing capability from the audit, implement it:

1. **Write the CI config file.** Use the discovered CI platform's syntax.
   Conventions:
   - Keep pipeline files in the standard location (`.github/workflows/`,
     `.gitlab-ci.yml`, etc.)
   - Name jobs descriptively, not `job1`, `job2`
   - Pin action/tool versions (do not use `@latest`)
   - Cache dependency directories between runs
   - Set timeouts on every job (prevent runaway builds)

2. **Implement secrets management.** For each environment variable the
   pipeline needs:
   - Check if it is already configured as a CI secret
   - If not, document what needs to be added and where (do not write
     secrets into config files)
   - If the pipeline references secrets that do not exist, flag and
     abort — the pipeline will fail silently or noisily

3. **Implement deploy jobs.** Branch on deploy method:

   | Method | CI implementation |
   |---|---|
   | Docker | Build image → push to registry → pull on target → restart |
   | K8s | Build image → push → `kubectl set image` or ArgoCD sync |
   | PaaS | `git push` or provider CLI deploy command |
   | Serverless | `serverless deploy` in CI |
   | Terraform | `terraform plan` (PR) → `terraform apply` (merge) |

### Phase 3 — Test

1. **Dry run.** Trigger the pipeline on a test branch or PR. Watch the
   full run.
2. **Verify each stage passes.** Read logs for each job. Confirm expected
   behavior.
3. **Check duration.** If total pipeline time > 10 minutes for a 2-person
   team, identify bottlenecks and optimize:
   - Parallelize independent jobs
   - Add caching
   - Skip unchanged jobs (e.g., skip docs build if only code changed)

4. **Verify deploy.** If the pipeline includes deployment, confirm the
   deploy succeeds and the target environment is healthy post-deploy.

### Phase 4 — Document

Write a brief `CI.md` or add a section to `AGENTS.md` documenting:
- Pipeline structure (which jobs run when)
- How to trigger each job
- Where secrets are configured
- How to add a new job
- How to roll back a bad deploy

### Output

```
CI/CD Pipeline Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Platform:       <github_actions|gitlab_ci|...>
Pipeline files: <list>
PR pipeline:
  Jobs:         <count> parallel → <count> sequential
  Duration:     <time>
Deploy pipeline:
  Targets:      <staging|production>
  Trigger:      <merge to main|manual>
  Duration:     <time>

Capabilities:
  Lint/analyze:     ✓
  Tests:            ✓
  Type check:       ✓
  Build:            ✓
  Deploy staging:   ✓
  Deploy prod:      ✓
  Rollback:         ✓ (manual: <command>)
  Caching:          ✓
  Notifications:    ✓

Gaps addressed:
  1. <gap> → <what was done>
  2. <gap> → <what was done>

Secrets needed:
  - <SECRET_NAME>: <purpose> — configure in <platform> settings
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Pinning to `@latest`** | A breaking change in an action/tool silently breaks all future runs. Pin to exact versions. |
| **No timeouts** | A stuck job burns runner minutes indefinitely. Always set `timeout-minutes`. |
| **Secrets in plaintext** | Leaked secrets in logs. Use CI secret stores exclusively. |
| **No caching** | Every run reinstalls all dependencies. Pipelines get slower over time. |
| **Deploy on every push** | Every commit to main goes straight to production. Add a staging environment or manual gate. |
| **Ignoring flaky tests** | Flaky tests train the team to ignore failures. Fix or quarantine them. |
| **Pipeline too long** | >15 minute pipelines discourage iteration. Parallelize and cache aggressively. |
| **No rollback path** | If the deploy fails, the team has no quick way back. Always have a rollback mechanism. |

## Workflow 3 — Monitoring & Alerting

Observability setup: identify signals → instrument → alert → dashboard.

**Trigger phrases:** "add monitoring", "set up alerts", "we need
observability", "add logging", "how do we know when things break",
"set up dashboards", "instrument the app"

### Pre-flight

1. **Assess current observability.** Check what exists:
   - Log output: structured or unstructured? Where do logs go?
   - Health endpoints: do they exist? What do they check?
   - Metrics: any metrics being collected?
   - Errors: how are errors currently reported?
   - Uptime: any external monitoring?

2. **Identify the application surface.** What needs to be monitored:

   | Surface | What to check |
   |---|---|
   | HTTP endpoints | Response codes, latency, throughput |
   | Background jobs | Success rate, duration, queue depth |
   | Database | Connection pool, query latency, slow queries |
   | External API calls | Success rate, latency, error codes |
   | Auth system | Login failures, token refresh failures |
   | File storage | Upload/download failures, storage usage |

3. **Determine alert budget.** For a 2-person team, you cannot monitor
   everything. Prioritize by impact:

   | Priority | What | Alert? | Why |
   |---|---|---|---|
   | P0 | Service down / health check fails | Yes — immediate page | Users cannot access anything |
   | P1 | Error rate spike (>5% of requests) | Yes — urgent notify | Significant user impact |
   | P1 | p95 latency > 2x baseline | Yes — urgent notify | Degraded experience |
   | P2 | Disk space < 20% | Yes — warning | Will cause outage eventually |
   | P2 | Certificate expiry < 14 days | Yes — warning | Will cause outage |
   | P3 | Unusual traffic pattern | No — dashboard only | Investigate when seen |
   | P3 | Dependency version outdated | No — dashboard only | Maintenance task |

### Phase 1 — Instrument

For each signal surface, implement the minimum viable instrumentation:

1. **Structured logging.** Convert unstructured logs to structured format:
   ```
   {"level": "info", "ts": "2026-08-17T10:30:00Z", "msg": "request completed", "method": "GET", "path": "/api/v1/plans", "status": 200, "duration_ms": 45}
   ```
   If the app already has structured logging, verify it includes:
   - Request ID / correlation ID
   - User ID (where applicable)
   - Duration for all operations

2. **Health endpoint.** Implement `/health` (or `/healthz`) if missing:
   - **Liveness:** returns 200 if the process is running
   - **Readiness:** returns 200 only if all dependencies (database, cache,
     external APIs) are reachable
   - Keep it lightweight — do not call external services in liveness

3. **Error tracking.** Set up error reporting to the chosen tool (Sentry,
   Datadog, or equivalent). If no tool is available:
   - Ensure errors are logged at `error` level with stack traces
   - Add a `/errors` endpoint that returns recent error counts (for
     dashboard polling)

4. **Key metrics.** Expose the four golden signals (if a metrics endpoint
   exists or can be added):

   | Signal | What to measure | How |
   |---|---|---|
   | Latency | Time to serve a request | Histogram of response times |
   | Traffic | Requests per second | Counter |
   | Errors | Errors per second / ratio | Counter with error status codes |
   | Saturation | Resource utilization | CPU, memory, disk, connection pool |

### Phase 2 — Alert

Configure alerts based on the priority table from pre-flight Step 3:

1. **P0 — Service down.** Health check fails 3 consecutive times over 60s.
   Action: Page immediately. For a 2-person team, this is typically
   a phone call or SMS, not just Slack.

2. **P1 — Error spike.** Error rate > 5% of requests over a 5-minute
   window. Action: Slack notification + optional page if during business
   hours.

3. **P1 — Latency spike.** p95 latency > 2x rolling 7-day baseline over
   a 5-minute window. Action: Slack notification.

4. **P2 — Resource warning.** Disk < 20%, certificate < 14 days, memory
   > 80%. Action: Slack notification, non-urgent.

Rules for alerting on a small team:
- **Every alert must be actionable.** If there is nothing to do when the
  alert fires, do not create it.
- **Suppress noise.** Use evaluation windows (5-minute minimum) to avoid
  alerting on transient blips.
- **Group related alerts.** One notification for "service X is degraded",
  not five separate alerts for each symptom.
- **Include runbook links.** Every alert should link to a document (or
  a one-line instruction) telling the responder what to check.

### Phase 3 — Dashboard

Build dashboards for the signals that matter:

| Dashboard | Purpose | Key panels |
|---|---|---|
| **Service Health** | Is the service working? | Request rate, error rate, p50/p95/p99 latency, active connections |
| **Deployment** | Did the last deploy break anything? | Error rate over time (with deploy markers), latency over time |
| **Resources** | Are we going to run out of something? | CPU, memory, disk, DB connections, queue depth |

Dashboard conventions for a small team:
- Keep it to 3 dashboards maximum. More than that and nobody looks at
  them.
- Each panel should answer a yes/no question: "Is error rate normal?"
  not "Show me all error details."
- Include time-series graphs, not just current values. Context matters.
- Add annotations for deploys so you can visually correlate changes.

### Output

```
Monitoring & Alerting Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Observability stack:
  Logging:    <structured|unstructured> → <destination>
  Errors:     <sentry|datadog|none>
  Metrics:    <prometheus|datadog|none>
  Dashboards: <grafana|datadog|none>

Signals instrumented:
  HTTP endpoints:     ✓ request rate, latency, error rate
  Background jobs:    ✓ success rate, duration
  Database:           ✓ connection pool, query latency
  External APIs:      ✗ not implemented

Alerts configured:
  P0 — Service down:         ✓ (health check, 3 failures, 60s window)
  P1 — Error rate spike:     ✓ (>5%, 5min window, Slack)
  P1 — Latency spike:        ✓ (>2x baseline, 5min window, Slack)
  P2 — Disk space:           ✓ (<20%, Slack)
  P2 — Certificate expiry:   ✓ (<14 days, Slack)

Dashboards:
  Service Health:  <url> — request rate, errors, latency
  Deployment:      <url> — error rate with deploy markers
  Resources:       <url> — CPU, memory, disk, DB

Health endpoint:
  Liveness:  <GET /healthz> → 200
  Readiness: <GET /health> → 200 (checks DB, cache)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Alerting on everything** | Alert fatigue. The team starts ignoring alerts, including the critical ones. |
| **Alerts without runbooks** | The on-call person gets paged but does not know what to check. Every alert needs a next step. |
| **No evaluation window** | A single 500 error triggers an alert at 3am. Use time-based evaluation (5-min window). |
| **Dashboard sprawl** | 15 dashboards, nobody checks any of them. Keep it to 3 focused dashboards. |
| **Monitoring after the incident** | You discover you have no logs when you need them. Instrument before things break. |
| **Ignoring log retention** | Logs fill up disk or cost a fortune. Set retention policies from day one. |
| **Only monitoring the happy path** | Dashboards show 200s but not 4xx/5xx breakdown. Always separate error signals. |

## Workflow 4 — Infrastructure Management

IaC: audit current state → plan changes → implement → verify.

**Trigger phrases:** "review infrastructure", "what resources do we have",
"add a database", "scale up", "infrastructure as code", "Terraform is
messy", "audit our cloud costs", "clean up infrastructure"

### Pre-flight

1. **Audit current state.** Based on the IaC tool discovered in global
   pre-flight Step 1:

   | Tool | Audit command | What to check |
   |---|---|---|
   | Terraform | `terraform plan -detailed-exitcode` | Resources to add/change/destroy |
   | Pulumi | `pulumi preview` | Same as Terraform |
   | CDK | `cdk diff` | Same as Terraform |
   | AWS Console | Manual review via CLI or browser | Resource inventory |
   | Manual (no IaC) | Scan cloud provider dashboard | Everything is manual — flag this |

2. **Check state health.**
   - Terraform: `terraform state list` — are there orphaned resources?
   - Pulumi: `pulumi stack export` — any failed resources?
   - Is the state file backed up? (S3 with versioning, Pulumi cloud, etc.)
   - Are there resources in the cloud that are NOT in IaC? (drift detection)

3. **Check costs.** If the cloud provider has a cost API or dashboard:
   - Current month spend
   - Top 5 resources by cost
   - Any resources that appear unused (running 24/7 but never accessed)

4. **Check security posture.** Quick scan:
   - Are any database ports open to the internet?
   - Are IAM policies overly permissive (wildcard actions)?
   - Are encryption settings correct?
   - Are security groups/firewalls locked down?

### Phase 1 — Plan

1. **Define the change.** Write the requested change as a description:
   - What resource(s) are being added, modified, or removed?
   - Why? (performance, cost, feature requirement, security)
   - What is the blast radius? (affects one service vs. all services)

2. **Check for conflicts.** Review existing IaC for:
   - Naming collisions (resource with same name already exists)
   - Port conflicts (service using same port)
   - CIDR overlaps (VPC/subnet ranges)
   - Dependency chains (new resource depends on something being created)

3. **Generate the plan.** For IaC-managed resources:
   - Terraform: write the `.tf` changes, run `terraform plan`
   - Pulumi: write the code, run `pulumi preview`
   - CDK: write the constructs, run `cdk diff`

4. **Present the plan for approval.** Show:
   - Resources to add
   - Resources to modify
   - Resources to destroy (ALWAYS require explicit approval for destroys)
   - Estimated cost change (if available)

   **STOP.** Wait for approval before implementing.

### Phase 2 — Implement

1. **Create a backup.** Before any infrastructure change:
   - Terraform: ensure state backup exists
   - Database: trigger a snapshot if database is being modified
   - Config: snapshot current config (`git stash` or branch)

2. **Apply changes.** Run the IaC apply/destroy command:
   - Terraform: `terraform apply`
   - Pulumi: `pulumi up`
   - CDK: `cdk deploy`
   - Manual: execute the cloud provider CLI commands

3. **Handle failures.** If the apply fails partway:
   - Check what succeeded vs. failed
   - For Terraform: check state — some resources may have been created
   - Do NOT re-run blindly — assess the partial state first
   - If state is corrupted: `terraform state pull` → review → fix manually

### Phase 3 — Verify

1. **State consistency.** Verify IaC state matches cloud reality:
   - Terraform: `terraform plan` should show "No changes"
   - Pulumi: `pulumi preview` should show no changes
   - If drift detected, investigate before proceeding

2. **Functional verification.** Verify the changed resources work:
   - New database: can the app connect? Can it read/write?
   - New service: is it reachable? Does it respond correctly?
   - Modified scaling: does the load balancer route correctly?
   - Changed networking: can services communicate?

3. **Cost verification.** If cost was a factor in the change:
   - Check the billing dashboard after 24 hours
   - Confirm the expected cost change materialized

4. **Clean up.** If manual changes were made outside IaC:
   - Import them into IaC (`terraform import`, `pulumi import`)
   - Document the manual change in `INFRA.md` or equivalent

### Output

```
Infrastructure Change Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IaC tool:        <terraform|pulumi|cdk|manual>
State backend:   <s3|pulumi_cloud|local|none>

Change summary:
  Added:    <resource list>
  Modified: <resource list>
  Removed:  <resource list>

Cost impact:
  Before:   $<current_monthly>/month
  After:    $<new_monthly>/month
  Delta:    +/-$<delta>/month

Verification:
  State consistent:  ✓ No drift
  Functional:        ✓ Resources responding correctly
  Cost confirmed:    ✓ (or "pending — check in 24h")

Actions taken:
  1. <action>
  2. <action>

Outstanding:
  - <any manual steps or follow-ups>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Manual changes outside IaC** | State drifts. Next `terraform apply` destroys your manual work. |
| **No state backup** | State file corruption = you cannot manage or destroy anything. Back up state. |
| **Destroying without approval** | `terraform destroy` in CI can wipe production. Always require manual approval for destroys. |
| **Ignoring cost** | A new RDS instance "for testing" runs for 3 months at $200/month. Check costs. |
| **No plan review** | Running `apply` without `plan` first is flying blind. Always preview. |
| **Over-provisioning "just in case"** | db.r5.4xlarge for a side project. Right-size from the start. |
| **No security review** | Opening port 3306 to 0.0.0.0/0 "temporarily." Security changes need review. |
| **Skipping state lock** | Concurrent applies corrupt state. Use remote state with locking. |

## Workflow 5 — Incident Response

Structured response: detect → triage → mitigate → root cause → remediate.

**Trigger phrases:** "we have an incident", "the site is down", "users
are reporting errors", "something is broken", "help me debug this",
"production issue", "alert fired"

### Pre-flight

1. **Confirm the incident.** Before starting a full response, verify:
   - Is the alert/报告 based on real signals or noise?
   - Check the health endpoint directly
   - Check recent deploys (did something just change?)
   - Check if it is affecting all users or a subset

   If it is noise: acknowledge the alert, document why it was noise,
   and adjust alerting rules to reduce false positives.

2. **Classify severity.**

   | Severity | Definition | Response time | Example |
   |---|---|---|---|
   | **SEV-1** | Complete service outage or data loss | Immediate (< 5 min) | Health check fails, database unreachable |
   | **SEV-2** | Major feature broken, significant user impact | < 15 min | Auth broken, core API returning 500s |
   | **SEV-3** | Minor feature broken, limited user impact | < 1 hour | One endpoint broken, search not working |
   | **SEV-4** | Cosmetic or non-user-facing issue | Next business day | Dashboard typo, slow admin panel |

3. **Declare the incident.** For a 2-person team, this means:
   - Both people are aware
   - A dedicated channel/thread is created (or a shared doc)
   - The incident timeline starts now

### Phase 1 — Triage

1. **Gather signals.** In parallel, collect:
   - Error logs from the last 30 minutes
   - Metrics dashboards: error rate, latency, traffic
   - Recent changes: deploys, config changes, infrastructure changes
   - User reports: what are users experiencing?

2. **Identify the blast radius.**
   - Which features are affected?
   - Which user segments? (all, specific region, specific plan tier)
   - Is data at risk? (writes failing, reads failing, both)
   - Is it getting worse or stable?

3. **Correlate with changes.** The most common root cause is a recent
   change. Check:
   - Last deploy: when, what changed, did verify pass?
   - Last infrastructure change: when, what changed?
   - Last config change: any feature flags, env vars, or secrets updated?
   - External: is the cloud provider reporting an outage?

4. **Assign a lead.** Even with 2 people, one person drives the response.
   The other gathers information and prepares mitigations.

### Phase 2 — Mitigate

Mitigate first, investigate later. The goal is to restore service, not
to find the root cause.

| Scenario | Mitigation |
|---|---|
| **Bad deploy** | Rollback: `git revert` → deploy previous version. Or rollback Docker image tag. |
| **Database issue** | Restore from latest snapshot. Or failover to read replica if available. |
| **Infrastructure issue** | Scale up the affected resource. Or restart the service. |
| **External dependency down** | Enable circuit breaker. Switch to fallback. Or add retry with backoff. |
| **Configuration issue** | Revert the config change. Or apply a fix-forward config. |
| **Traffic spike** | Scale horizontally. Or enable rate limiting. |
| **DDoS / abuse** | Enable WAF rules. Block IPs. Enable Cloudflare under attack mode. |

Decision points:
- **Rollback vs. fix-forward?** If the root cause is clear and the fix
  is simple (< 10 lines, low risk), fix-forward. Otherwise, rollback.
  When in doubt, rollback.
- **Can we mitigate without deploying?** If it is a config change, a
  restart, or a scaling action, do that first. Deploying takes time.
- **Is the fix safe?** If you are not confident the fix works, do not
  apply it under pressure. Roll back to known-good state.

### Phase 3 — Root Cause

After service is restored, investigate:

1. **Timeline reconstruction.** Build a timeline from signals:
   ```
   14:32  Deploy v2.3.1 merged to main
   14:33  Deploy pipeline passes
   14:34  Deploy to production complete
   14:35  Health check passes
   14:38  Error rate starts climbing
   14:40  P1 alert fires (error rate > 5%)
   14:41  Incident declared
   14:45  Root cause identified: database migration broke query
   14:47  Rollback initiated
   14:49  Rollback complete, error rate normalizing
   14:55  Incident resolved
   ```

2. **Root cause identification.** For each suspected cause:
   - What evidence supports it?
   - What evidence contradicts it?
   - Can it be reproduced in a non-production environment?

3. **Verify the root cause.** Reproduce the issue in a safe environment
   if possible. Confirm the fix addresses the actual cause, not just a
   symptom.

### Phase 4 — Remediate

1. **Fix the root cause.** If the mitigation was a rollback, now implement
   the proper fix:
   - Write a fix for the bug
   - Write a test that would have caught it
   - If it was a migration issue, fix the migration

2. **Prevent recurrence.** Add guardrails:
   - If a deploy caused it: add a gate test
   - If a migration caused it: add migration testing to CI
   - If a config change caused it: add config validation
   - If it was a dependency issue: pin versions, add dependency testing

3. **Write the incident postmortem.** Keep it short and blameless:

   ```
   Incident: <title>
   Date: <date>
   Duration: <time from detection to resolution>
   Severity: <SEV-X>

   Summary:
   <1-2 sentence description>

   Impact:
   <what users experienced, how many users, how long>

   Timeline:
   <timestamped events>

   Root cause:
   <what actually broke and why>

   Mitigation:
   <what restored service>

   Resolution:
   <what was done to fix the root cause>

   Prevention:
   <what was added to prevent recurrence>
   ```

4. **Share the postmortem.** Even with a 2-person team, write it down.
   Future-you will forget the details.

### Output

```
Incident Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Severity:    <SEV-X>
Duration:    <detection → resolution>
Impact:      <user experience, scope>

Detection:
  Source:     <alert|user report|manual check>
  Signal:     <what was observed>
  Time:       <timestamp>

Triage:
  Blast radius:    <features affected>
  Correlation:     <linked to deploy/config/external>
  Lead:            <person>

Mitigation:
  Action:          <rollback|restart|scale|config revert>
  Time to mitigate: <detection → service restored>

Root cause:
  <what broke and why>

Resolution:
  <what fixed the root cause>

Prevention:
  1. <action item>
  2. <action item>

Postmortem: <link to written postmortem>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Skipping mitigation to investigate** | Users are still experiencing the outage. Mitigate first, investigate second. |
| **No incident timeline** | Without a timeline, root cause analysis becomes guessing. Log timestamps from the start. |
| **Blame-oriented postmortem** | "Bob deployed the breaking change" is not useful. "The migration lacked a backward-compatible step" is. |
| **No prevention items** | If the postmortem has no action items, the same incident will happen again. |
| **Rollback without verifying** | Rolling back to a version that has its own bug just creates a new incident. Verify the rollback target is healthy. |
| **Incident response via DMs** | Information gets lost. Use a shared channel, doc, or thread. Single source of truth. |
| **No severity classification** | Everything feels like SEV-1 when you are stressed. Classify calmly before acting. |
| **Skipping the postmortem for "small" incidents** | Small incidents have small root causes that become big incidents. Write it down. |

## Global Anti-patterns

These apply across all workflows.

| Anti-pattern | Why it fails |
|---|---|
| **Hardcoding provider-specific paths** | The skill must discover the environment, not assume it. |
| **Acting without pre-flight** | Every workflow starts with discovery. Skipping it produces wrong assumptions. |
| **No output report** | If you did not write it down, the next person (including future-you) cannot learn from it. |
| **Skipping verification** | Every action needs a verification step. "I applied the change" is not the same as "the change works." |
| **Doing everything manually** | If you do it twice, automate it. If you do it once and it matters, document it. |
| **Ignoring the 2-person constraint** | Complex multi-stage pipelines with 5 approval gates are for large teams. Keep it proportional. |

## Calibration

**Quick task (< 5 min):** Single workflow, minimal output. Example: "deploy
this" → pre-flight → build → deploy → verify. Skip dashboard creation,
skip detailed reports.

**Standard task (5–30 min):** Full workflow with all phases. Example:
"set up CI" → audit → design → implement → test → document. Full output
report.

**Major task (30+ min):** Multiple workflows or complex infrastructure.
Example: "we need full observability" → monitoring workflow + CI/CD
workflow (add alerting to pipeline). Stage the work into clear phases
with checkpoints between them.

**Incident:** Skip all non-essential phases. Detect → triage → mitigate.
Report after service is restored. Do not try to set up monitoring during
an incident.

## Edge Cases

| Scenario | Handling |
|---|---|
| **No CI/CD configured** | Workflow 2 (CI/CD) can set it up from scratch. Workflows 1 (Deploy) and 5 (Incident) fall back to manual commands. |
| **No IaC tool** | Workflow 4 (Infrastructure) flags all resources as manual-managed and recommends adopting IaC. Provide the Terraform/Pulumi starter. |
| **Multiple cloud providers** | Discover and profile each. Workflows operate per-provider. Report which provider each resource lives on. |
| **Shared infrastructure** | If infrastructure is shared with other teams, flag any change that could affect other services. Require coordination. |
| **Staging environment does not exist** | Recommend creating one. In the meantime, deploy to production with extra caution and a shorter monitoring window. |
| **No monitoring stack** | Workflows 1 and 5 degrade gracefully — they use health checks and log output as fallback signals. Workflow 3 (Monitoring) sets up the stack. |
| **Deploy freeze active** | All deploy workflows abort. Report the freeze. Do not bypass it. |
| **Cloud provider is down** | Not a deployment issue. Report the provider status page. If mitigation is possible (failover, cached responses), suggest it. |
| **State file locked (Terraform)** | Another process or CI run holds the lock. Check for stuck runs. Do not force-unlock without confirming no active apply. |
| **Database migration breaks backward compatibility** | The deploy will succeed but the app will break. Recommend backward-compatible migration strategy: expand, migrate, contract. |

## Portability

This skill works with any project that has some form of deployment
target. It adapts by discovery, not by configuration.

**What it needs:**
- A project with some deployable artifact (code, container, binary)
- Some form of CI configuration (or willingness to add one)
- Access to the deployment target (cloud provider, server, PaaS)

**What it does NOT need:**
- Hardcoded provider names
- Project-specific configuration files
- Specific IaC tools
- Specific CI platforms

**Adaptation rules:**
- If no CI exists, the skill can set it up or fall back to manual commands
- If no IaC exists, the skill flags resources as manually managed
- If no monitoring exists, the skill uses health checks and logs as
  minimum viable observability
- If the deployment target is unknown, the skill probes common endpoints
  and config files to discover it
