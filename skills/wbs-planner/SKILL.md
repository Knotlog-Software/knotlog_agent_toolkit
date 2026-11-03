---
name: wbs-planner
description: >
  Plans a standards-based Work Breakdown Structure (WBS) from requirements,
  use cases, architecture, and the current codebase. Decomposes work into
  TDD-atomic work packages, identifies dependencies and iteration waves,
  and emits a WBS document plus PlantUML hierarchy and dependency diagrams.
  Runs a drafter → parallel red-team → questioner loop until zero blocking
  findings. Use when the user wants to plan a build, break a project into
  atomic iterations, or create/update a work breakdown structure. Skip for
  single-file changes, implementation work, or projects with no
  requirements/architecture inputs and no user approval to infer scope.
license: MIT
---

# WBS Planner

Transforms target scope and current codebase evidence into an atomic,
dependency-aware Work Breakdown Structure that feeds the `iteration`
skill. The orchestrator never writes the WBS itself — it discovers,
plans the boundary, delegates drafting, runs parallel red-team review,
and loops until the WBS is defensible.

```
requirements-gatherer → requirements.md
generate-usecases     → use-case specs + use-case diagrams
wbs-planner           → wbs.md + wbs.puml + wbs-dependencies.puml   (this skill)
iteration             → TDD build from a WP- work package
```

## Pre-flight

Pre-flight is read-only except for the output files created later. Ask the
user whenever a decision is explicitly marked **ASK EVERY RUN** — do not
silently pick a default.

### Step 1. Discover project configuration

Scan for the project configuration that defines architecture rules,
testing conventions, and gate commands:

| Config file | What it provides |
|---|---|
| `AGENTS.md` | Architecture rules, testing conventions, layer constraints, gate commands |
| `CLAUDE.md` | Same role, different naming convention |
| `*.md` in project root with architecture/testing sections | Fallback |

If no project config exists, warn the user and proceed with discovered
project markers. The WBS can still be planned, but the iteration handoff
will be weaker.

### Step 2. Discover source documents

Scan for planning inputs in this order:

| Input | Standard locations | Required? |
|---|---|---|
| Requirements | `docs/requirements/requirements.md`, `**/*requirements*.md` | Strongly recommended |
| Use cases | `docs/use-cases/*.md` | Optional |
| Architecture narrative | `docs/architecture*.md`, `README.md` architecture section | Strongly recommended |
| Architecture matrix | `ARCHITECTURE_MATRIX.yaml` | Optional |
| Component diagram | `docs/uml/**/component*.puml`, `docs/uml/**/*component*.puml` | Optional |
| Iteration history | `agents/iteration_history.md`, `docs/iterations*.md`, `agents/plans/*` | Optional |
| Existing WBS | `docs/wbs/wbs.md`, `**/*wbs*.md` | Revision input |

If a requirements or architecture document is missing or incomplete,
**ASK EVERY RUN**:

```
I could not find [requirements / architecture / both]. How should I proceed?

1. Abort — run requirements-gatherer first (recommended when scope is unclear)
2. Proceed with code-only inference — I will record every inference as an
   assumption or TBR, not as fact
3. Use paths I provide
4. Proceed with a named requirement/use-case subset only
```

Record the user's choice in the WBS document.

If multiple candidate documents exist, ask the user which is authoritative.

### Step 3. Inventory the current codebase (bounded)

Build a **Current State Inventory** sufficient to distinguish built work
from remaining work. Keep discovery bounded:

| Budget | Limit |
|---|---|
| Project docs read | 1 read per document |
| Directory listings | 3 (top level, source tree, tests tree) |
| Targeted searches | 10 (`grep`/`glob` for requirement terms, routes, models, migrations) |
| Source file reads | 5 (manifests, public interfaces, tests — not deep implementation) |

Discovery priorities:

1. Language/framework markers (`package.json`, `pubspec.yaml`, `Cargo.toml`, `pyproject.toml`, `go.mod`).
2. Top-level source, test, migration, and infrastructure directories.
3. Public interfaces: routes, controllers, handlers, domain entities, schemas, exported APIs.
4. Existing tests — they reveal implemented behavior and verification style.
5. CI/CD, environment, and deployment configuration.
6. Targeted search for requirement/use-case nouns and IDs.

Record each inventory item with confidence:

| Confidence | Meaning |
|---|---|
| `Confirmed` | Code, test, schema, or config proves it exists |
| `Likely` | Related code exists but the exact capability is not proven |
| `Unknown` | No evidence found — do not assume it is missing |

If the repository is large, delegate the inventory to the built-in
`explore` subagent with the same budget and ask for a structured
Current State Inventory. Do not read the entire source tree.

### Step 4. Confirm the scope baseline — ASK EVERY RUN

Ask the user:

```
What is the planning boundary for this WBS?

1. Delta from current code — inventory what exists and plan only remaining work
2. Full program WBS — include all work, marking completed items Done
3. Release / phase / milestone — plan a named slice
4. Requirement or use-case subset — plan only named source IDs
```

Record the answer in Section 1.4 of the WBS document. For delta mode,
state what counts as "already built" and which evidence supports it.

### Step 5. Confirm delivery coverage

The default is a **full delivery WBS with roles**: product, tests,
CI/CD, docs, security, migration, deployment, observability, and release.
Ask which categories are in scope for this run. Record exclusions in
Section 1.3.

Confirm the role taxonomy and estimate scale if the project has special
roles. Default roles and estimates come from `template.md`.

### Step 6. Check for an existing WBS

If `docs/wbs/wbs.md` or another WBS exists, ask:

```
An existing WBS was found. Should I revise it in place (preserve IDs,
retire deleted IDs), overwrite it, or write a versioned copy?
```

Revision mode must preserve stable IDs. Never renumber surviving
elements.

### Step 7. Set output paths

| Artifact | Default |
|---|---|
| WBS document | `docs/wbs/wbs.md` |
| WBS hierarchy diagram | `docs/uml/wbs/wbs.puml` |
| Dependency DAG | `docs/uml/wbs/wbs-dependencies.puml` |
| Per-branch splits | `docs/wbs/<branch-slug>.md`, `docs/uml/wbs/wbs-<branch-slug>.puml` |

Create directories if needed. For large plans, split by level-2 branch:
the top-level `wbs.md` becomes an index and each branch gets its own
document and diagram.

### Step 8. Configure red-team

| Setting | Default | Options |
|---|---|---|
| Number of red-teamers | 4 | 1–6 |
| Focus areas | `coverage`, `decomposition`, `dependencies`, `verifiability` | Add `consistency`, `traceability` |
| Convergence mode | Zero blocking findings | User may override at any point |
| Iteration loop limit | 3 loops on the same blocking issue | Escalate after 3 |

If the user provides no preference, use the defaults.

### Step 9. Build the Project Context / Evidence Pack

Assemble a compact block that every subagent receives. Subagents must not
re-discover the project.

```
## Project Context (extracted by orchestrator)

- **Framework**: [language/framework]
- **Test command**: [exact command]
- **Lint command**: [exact command]
- **Codegen command**: [if any]
- **Architecture rules**: [3-5 lines]
- **Code conventions**: [3-5 lines]
- **Test conventions**: [3-5 lines]
- **Scope baseline**: [delta / full / release / subset]
- **Delivery coverage**: [categories in scope; exclusions]
- **Atomicity policy**: [TDD-atomic definition]
- **Role taxonomy**: [default or project-specific]
- **Estimate scale**: [default or project-specific]
- **Source documents**: [paths + versions/status]
- **Current State Inventory**: [confirmed/likely/unknown capabilities]
- **Known gaps**: [missing inputs, draft requirements, conflicting docs]
- **Output paths**: [wbs.md, wbs.puml, wbs-dependencies.puml]
```

---

## Phase 1 — Scope & Decomposition Q&A

Ask 3–5 additional questions after the pre-flight decisions. The goal is
enough context to partition the WBS, not an exhaustive interview —
red-teamers and the questioner will find gaps. Do not exceed 7 total
scope questions in this phase.

| Category | Example Questions |
|---|---|
| **Boundary** | "Is this a delta from the current code, a full program, or a named release/phase?" |
| **Exclusions** | "What is definitely not part of this WBS?" |
| **Coverage** | "Should the plan include tests, CI/CD, docs, security, migration, deployment, observability, and release?" |
| **Atomicity** | "Should leaves be TDD-atomic (one testable behavior) or larger task-sized units?" |
| **Ownership** | "Who owns each type of work — human roles, agents, or a mix?" |
| **Dependencies** | "Are there external APIs, credentials, approvals, vendors, or environments the plan must assume?" |
| **Current state** | "What is already built, and what evidence should I treat as authoritative?" |
| **Constraints** | "Are there architecture, compliance, timeline, or technology constraints?" |

Before moving on, paraphrase the answers:

> "Let me confirm the planning boundary: [2-3 sentence summary]. Is that right?"

Wait for confirmation.

---

## Phase 2 — Partition & Draft

### Step 2.1 — Propose level-2 branches

Derive 2–8 level-2 branches from the source documents and scope baseline.
Typical branches:

- Product/feature areas from requirements or use-case domains
- Enabling infrastructure (repo, CI/CD, environments, codegen)
- Quality engineering (test harness, fixtures, e2e, security, performance)
- Data migration
- Documentation and training
- Deployment and release

Present the proposed branch list with the source IDs mapped to each.
Confirm the list and order with the user before drafting — branch order
fixes WBS numbering, and reordering later invalidates IDs.

### Step 2.2 — Spawn the drafter

Pass the `wbs-drafter` subagent:

- The Project Context / Evidence Pack
- The complete Q&A transcript
- The confirmed level-2 branch list and order
- `skills/wbs-planner/template.md`
- `skills/wbs-planner/wbs-checklist.md`
- Output paths
- Existing WBS (if revision mode)
- Any user-provided constraints or source excerpts

### Step 2.3 — Drafter duties

The drafter:

1. Builds a deliverable-oriented WBS hierarchy — nouns/results, not activities.
2. Decomposes leaves to TDD-atomic work packages using the atomicity definition.
3. Writes a complete WBS dictionary entry for every element and work package.
4. Records dependencies in the companion matrix, never in the hierarchy.
5. Builds the dependency DAG, verifies acyclicity, and identifies the critical path.
6. Groups work packages into iteration waves and a Next Ready Queue.
7. Traces every in-scope source requirement/use case/architecture element to at least one WBS element.
8. Includes enabling, quality, docs, and release work according to the confirmed coverage.
9. Assigns owner role, execution mode, and estimate to every work package.
10. Writes measurable acceptance criteria and a verification method per leaf.
11. Self-checks against `wbs-checklist.md` before writing.
12. Writes `wbs.md`, `wbs.puml`, and `wbs-dependencies.puml`.
13. Returns a structured summary and flags anything the red team should attack.

Do not wait for user approval before red-team review. The red team
provides the first quality gate; the user is asked questions after
findings are aggregated.

---

## Phase 3 — Red Team (Parallel Subagents)

Spawn all configured red-teamers in parallel. Each is isolated and sees
only the WBS document, the checklist sections for its focus area, the
Project Context, and the source documents it needs to verify coverage.

### Step 3.1 — Prepare red-teamer prompts

For each focus area, pass:

- WBS document path
- Diagram paths
- Assigned focus area
- Relevant checklist sections from `wbs-checklist.md`
- Project Context / Evidence Pack
- Document version
- The specific source documents needed for trace checks
- Any prior findings that must be re-checked (revision rounds)

### Step 3.2 — Default focus areas

| Focus | Attacks |
|---|---|
| `coverage` | 100% rule, scope completeness, traceability, exclusions, orphan/invented work |
| `decomposition` | Deliverable orientation, atomicity, balance, mutual exclusivity, work package dictionary quality |
| `dependencies` | DAG integrity, dependency rationale, external dependencies, shared state, architecture constraints, critical path, waves |
| `verifiability` | Acceptance criteria, verification method, test surface, Definition of Ready/Done, unverifiable terms |

Optional focus areas:

| Focus | Attacks |
|---|---|
| `consistency` | Terminology drift, contradictions, ID/reference integrity, versioning/change control |
| `traceability` | Source → WBS and WBS → source map completeness and validity |

### Step 3.3 — Collect reports

Wait for all red-teamers. Each report contains blocking, risky, and
trivial findings with rule IDs and WBS IDs, passed checks, a summary,
and an overall verdict.

---

## Phase 4 — Evaluate Convergence

Aggregate the reports:

| Metric | Value |
|---|---|
| Total blocking issues | N |
| Total risky issues | N |
| Total trivial issues | N |
| Elements reviewed | N |
| Passed checks | N |

Convergence rules:

| Condition | Result |
|---|---|
| Zero blocking issues | **CONVERGED** — proceed to Phase 6 |
| Blocking issues exist, user says "done enough" | **CONVERGED BY USER OVERRIDE** — proceed to Phase 6 |
| Blocking issues exist | **NOT CONVERGED** — proceed to Phase 5 |

Present a concise summary:

```
WBS Review — Iteration [N]

Found: [X] blocking, [Y] risky, [Z] trivial issues.

Blocking:
- [WP-1.2.1.1]: [one-line description]
- Coverage gap: [FR-009] has no WBS element
- Dependency cycle: [WP-1.1.1.1] → [WP-1.2.1.1] → [WP-1.1.1.1]
...
```

---

## Phase 5 — Questions and Revision Loop

### Step 5.1 — Spawn the questioner

Pass the `wbs-questioner`:

- WBS document path
- All red-team reports
- The full Q&A history
- Current document version
- Prior question sets and answers

The questioner deduplicates findings, filters already-answered
questions, frames questions in WBS terminology (100% rule, atomicity,
dependency direction, owner, acceptance criteria), prioritizes blocking
first, and adds a catch-all question.

### Step 5.2 — Present questions to the user

Group by priority:

```
I found [N] issues that need your input:

**Must resolve:**
1. [Question about coverage/atomicity/dependency] — [why it matters]
   - Suggested options: ...

**Should resolve:**
2. [Question] — ...

**Anything else?**
3. Is there anything else about this plan we haven't covered?
```

### Step 5.3 — Collect answers and revise

Go back to Phase 2. The drafter receives:

- The full Q&A history
- The existing WBS document and diagrams (revise in place, do not regenerate from scratch)
- All prior red-team reports
- The questioner's question set with the user's new answers

The drafter updates the document in place. Preserve surviving IDs; retire
deleted IDs; add new elements with the next unused number. Increment the
version (`0.1 → 0.2 → 0.3`). Re-run Phases 3–5.

### Step 5.4 — Stop condition

If the same blocking issue survives 3 revision loops, stop and surface it
to the user with full context. Do not burn more cycles.

---

## Phase 6 — Finalize

When converged:

### Step 6.1 — Final consistency sweep

Verify:

- Every WBS ID in the hierarchy, dictionary, dependency matrix, traceability matrix, and diagrams resolves.
- Every dependency predecessor exists or is marked external.
- The dependency graph is acyclic.
- PlantUML node sets match the WBS dictionary.
- Every level-2 branch in the document appears in the hierarchy diagram.
- Every source requirement/use case/architecture element is covered or explicitly excluded.
- Every TBR has an owner, target date, and best estimate.
- Version, status, and change log are current.

If a validation script is useful, write a throwaway script in a temp
directory and delete it after use. Do not add validation tooling to the
target project unless the user asks.

### Step 6.2 — Present the final report

```
WBS Plan Complete

**File:** docs/wbs/wbs.md
**Version:** 0.N
**Review loops:** [count]

**Structure:**
- Level-2 branches: [count]
- Summary elements: [count]
- Work packages: [count]
- Work package types: [counts by type]

**Coverage:**
- Requirements covered: [N]/[M] ([X]%)
- Use cases covered: [N]/[M]
- Architecture elements covered: [N]/[M]
- Explicit exclusions: [count]

**Dependencies:**
- Dependency edges: [count]
- External dependencies: [count]
- Cycles: 0
- Critical path: [WP IDs]
- Iteration waves: [count]
- Next ready work packages: [WP IDs]

**Role load:**
- [Role]: [N] work packages
- [Role]: [N] work packages

**Quality:**
- Blocking issues: 0
- Risky issues: [N] (not blocking)
- Trivial issues: [N]

**Diagrams:**
- docs/uml/wbs/wbs.puml
- docs/uml/wbs/wbs-dependencies.puml

Next step: pass a WP- ID from the Next Ready Queue to the iteration skill.
```

### Step 6.3 — Offer optional next actions

Offer, but do not start unprompted:

- Split the WBS by branch if it exceeds 100 work packages.
- Add a sample WBS to `examples/`.
- Re-plan after an iteration completes (update statuses and Next Ready Queue).
- Later integration with the iteration skill (not done by this skill).

---

## Ground rules

- **Standards-compliant separation.** The WBS hierarchy is
  deliverable-oriented and contains no schedule/dependency content.
  Dependencies live in the companion matrix and DAG. This is required by
  AACE 33R-15, ISO 21511, PMI, and MIL-STD-881F.
- **Atomicity is testability, not trivia.** A leaf must be the smallest
  independently verifiable increment that still delivers meaningful
  behavior. Do not split into file-level or import-level tasks that have
  no independent acceptance test.
- **Context injection over discovery.** Subagents receive the Project
  Context / Evidence Pack. They do not re-discover the project or read
  `AGENTS.md` themselves.
- **Requirements and architecture are normative; code is evidence.** If
  code contradicts the planned architecture, record it as a risk/TBR —
  do not silently plan to preserve the contradiction.
- **No invented scope.** Missing information becomes a TBR with owner,
  target date, and best estimate. Never a bare TBD.
- **Stable identifiers.** WBS and work-package IDs are assigned once and
  never renumbered. Deleted IDs are retired, not reused.
- **Each subagent returns one report or one revision set.** The
  orchestrator routes results forward.
- **Parallel red-teamers are isolated.** No cross-contamination between
  focus areas.
- **User controls convergence.** Zero blocking findings is the default,
  but the user can force convergence.
- **No commits, pushes, or PRs unless explicitly asked.**

## Thinking budgets

| Subagent | Budget | Notes |
|---|---|---|
| `wbs-drafter` | 6 file reads | Context, template, checklist, requirements, architecture, existing WBS |
| `wbs-red-teamer` | 4 file reads | Context, WBS doc, checklist sections, source doc(s) |
| `wbs-questioner` | 3 file reads | Context, WBS doc, red-team reports |

If a subagent needs more reads, it stops and reports what is blocking it.

---

## Calibration

| Project size | Expected WBS | Review loops | Estimated time |
|---|---|---|---|
| Small (1–20 requirements) | 2–4 branches, 15–40 work packages | 1 | 10–20 minutes |
| Medium (20–70 requirements) | 3–6 branches, 40–100 work packages | 1–2 | 20–40 minutes |
| Large (70+ requirements) | 6–8 branches, 100+ work packages | 2–3; split by branch | 40–90 minutes |

For large plans, split by level-2 branch and run branch-by-branch. Keep
the top-level document as an index with roll-up counts and cross-branch
dependencies.

---

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Activity-oriented WBS** | "Implement login", "Write tests", "Deploy" are activities, not deliverables. Use "Authentication API", "Authentication test suite", "Production deployment". |
| **Dependencies inside the tree** | Violates WBS standards and makes the hierarchy a schedule. Use the companion matrix/DAG. |
| **WBS as a to-do list** | Excessive decomposition creates management overhead and hides real deliverables. Stop at independently verifiable work packages. |
| **Leaves too large to verify** | A leaf with multiple unrelated acceptance criteria cannot be tested atomically. Split it. |
| **Leaves too small to matter** | A leaf with no meaningful acceptance test is trivia. Merge it. |
| **Missing enabling work** | CI/CD, environments, migrations, docs, security, and release work are real scope. Include them when in scope. |
| **Orphan work** | Every WBS element must trace to a source or be justified as enabling work. |
| **Dependency cycles** | A cycle makes the plan unbuildable. Topologically sort and break cycles before finalizing. |
| **Unowned work packages** | Every leaf needs one accountable role, even if several roles contribute. |
| **Unverifiable acceptance criteria** | "Works well", "robust", "user-friendly" cannot gate an iteration. Use measurable criteria. |
| **Renumbering IDs mid-loop** | Breaks iteration plans, trace links, and prior review reports. |
| **Inventing scope** | Requirements and architecture are normative. Ask or record a TBR. |
| **Running red-teamers sequentially** | Slower with no quality benefit. Parallelize. |
| **Ignoring risky findings** | Risky issues become blocking issues later. Address them early. |
| **Letting the loop run forever** | Diminishing returns after 3–4 loops. Escalate to the user. |

---

## Edge Cases

| Scenario | Handling |
|---|---|
| **No requirements document** | Ask the user: abort, code-only inference with TBRs, provide paths, or plan a named subset. |
| **No architecture document** | Ask the user: abort, infer from code with TBRs, or provide paths. |
| **Requirements are still Draft** | Warn the user; proceed only on explicit confirmation. The WBS inherits requirement instability. |
| **Use cases do not exist** | Proceed from requirements alone. Note the gap in the final report. |
| **Code contradicts architecture** | Requirements/architecture win. Record the contradiction as a risk/TBR; do not silently plan around it. |
| **Existing WBS found** | Ask revise/overwrite/version. Preserve stable IDs in revision mode. |
| **User wants product-only WBS** | Honor it. Exclude enabling/quality/release categories explicitly in Section 1.3. |
| **User wants full-program WBS** | Include completed work, mark it `Done`, and keep it in the traceability and coverage counts. |
| **WBS exceeds 100 work packages** | Split by level-2 branch; keep an index document with roll-up counts. |
| **A branch has a single child** | Merge it upward unless there is a documented reason to keep the layer. |
| **No dependencies exist** | Valid if work is truly independent. State that the DAG is intentionally flat. |
| **Shared schema or state** | Serialize the affected work packages; never mark them parallel. |
| **External dependency unavailable** | Record it as an external dependency with owner, needed-by date, and risk. |
| **User changes scope mid-loop** | Accept it. Update the baseline decision and re-run affected red-team checks. |
| **Same blocking issue persists 3+ loops** | Stop. Surface the issue with full context and ask for a decision. |
| **User asks for cost estimates** | Optional. The default is t-shirt sizing and role load, not dollars. Add a cost column only if the user supplies rates or asks for it. |
| **User asks for a hiring plan** | Use the Role Load summary. Map roles to headcount only if the user provides staffing assumptions. |

---

## Configuration

| Setting | Source | Default |
|---|---|---|
| Scope baseline | User, every run | Ask each run |
| Missing-input handling | User, every run | Ask each run |
| Delivery coverage | User | Full delivery WBS with roles |
| Work package granularity | User | TDD-atomic |
| Role taxonomy | Template or user | Template defaults |
| Estimate scale | Template or user | `XS`/`S`/`M` (`L` invalid) |
| Red-team count | User | 4 |
| Red-team focus | User | `coverage`, `decomposition`, `dependencies`, `verifiability` |
| Convergence | User | Zero blocking findings |
| Output directory | User | `docs/wbs/` and `docs/uml/wbs/` |
| Existing WBS behavior | User | Revise in place with stable IDs |
| Split threshold | User or default | 100 work packages |

---

## Invocation

Recognized patterns:

```
# Direct requests
plan the WBS
create a work breakdown structure
build a work breakdown structure for this project
break the project into atomic iterations
plan the build from requirements and architecture

# Scoped requests
plan the WBS for the authentication domain
create a WBS for release 2
break UC-2.0 into work packages

# Update requests
update the WBS after iteration 4
mark WP-1.2.1.1 done and re-plan the next ready queue
re-plan the remaining WBS

# Pipeline requests
continue after use cases — plan the WBS
turn the requirements and architecture into an iteration plan
```

When intent is ambiguous, ask:

- "What is the planning boundary — delta from current code, full program, release, or requirement subset?"
- "Which requirements/architecture document should I use?"
- "Should the plan include enabling, quality, documentation, and release work?"
