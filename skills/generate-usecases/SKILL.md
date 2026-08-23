---
name: generate-usecases
description: >
  Generates use case specifications and use case diagrams from a
  finalized requirements document. Partitions requirements into domains,
  drafts one spec document per domain plus one PlantUML use case diagram
  per domain, then runs a drafter/reviewer loop until zero blocking
  findings. Output is formatted for downstream consumption by the
  generate-sequence skill (UC-X.Y identifiers, actors, goal,
  preconditions, flows, postconditions, inter-UC relationships). Use when
  the user wants to create use cases from requirements. Skip for:
  activity diagram generation (separate skill), sequence diagram
  generation (use generate-sequence), or systems with no requirements
  document.
license: MIT
---

# Generate Use Cases

Transforms a finalized requirements document into a complete use case
model: one specification document per domain and one PlantUML use case
diagram per domain. Fills the pipeline gap between `requirements-gatherer`
and `generate-sequence`:

```
requirements-gatherer → requirements.md
        ↓
generate-usecases      → docs/use-cases/<domain>.md + docs/uml/use-cases/<domain>.puml   (this skill)
        ↓
[future skill]         → activity diagrams per UC
        ↓
generate-sequence      → sequence diagrams (also needs a component diagram)
```

This skill does NOT generate activity diagrams or sequence diagrams.

## Pre-flight

**Step 1. Locate the requirements document.**

| Priority | Source |
|---|---|
| User-specified path | Use it |
| Standard location | `docs/requirements/requirements.md` |
| Discovery | Scan `**/*requirements*.md` — confirm with user if multiple hits |
| None found | **Abort.** Report: no requirements document. Do not invent requirements from code or conversation. |

**Step 2. Verify prerequisite quality.**

The drafter needs ID'd requirement tables to trace against:

| Check | If missing |
|---|---|
| Functional Requirements table with FR-NNN IDs | **Abort** — report that requirements must be re-drafted via requirements-gatherer first |
| Business Rules section with BR-NNN IDs | Warn — proceed without BR traceability |
| Non-Functional Requirements with NF-NNN IDs | Warn — proceed without NF traceability |
| Definition of Done with DoD-NNN IDs | Optional — used as coverage target when present |
| Capability Matrix | Used as the source of actor-role permissions when present |

**Step 3. Partition into domains.**

Derive candidate domains from the requirements document:

- Grouping of functional requirements by subsystem/feature area
- ConOps scenarios (Section 3)
- Capability matrix role clusters (if present)

Propose 2-8 domains to the user with the requirement IDs that map to
each. Example partition for an admin system: Authentication &
Authorization, Channel Management, Monitoring, Audit.

Confirm the domain list and ordering with the user before drafting.
Domain order fixes the UC major number: domain 1 → UC-1.x, domain 2 →
UC-2.x, and so on. Reordering later invalidates all identifiers, so get
explicit confirmation.

**Step 4. Set output paths.**

| Artifact | Default |
|---|---|
| Spec documents | `docs/use-cases/<domain-slug>.md` (one per domain) |
| Use case diagrams | `docs/uml/use-cases/<domain-slug>.puml` (one per domain) |

Create directories if they do not exist. If a target file exists, ask
the user: overwrite, skip, or version suffix (`_v2`).

## Phase 1 — Draft

Spawn the `usecase-drafter` sub-agent once with the full context.

**Step 1.1 — Build the drafter's context.**

Pass the drafter:
- The requirements document path
- The confirmed domain list with mapped requirement IDs (from pre-flight Step 3)
- The output paths for each domain
- The capability matrix content, if present

**Step 1.2 — Drafter duties.**

For each domain, the drafter produces:

1. A spec document containing one use case per actor-facing goal
2. A PlantUML use case diagram showing actors, use cases, and their
   relationships

Each use case follows this exact format (it matches what
`generate-sequence` extracts downstream):

```
### UC-X.Y [Name]

- **Primary actor:** [role from capability matrix / Section 2]
- **Secondary actors:** [if any]
- **Goal:** [one sentence]
- **Precondition:** [state before the use case starts]
- **Main flow:**
  1. [step]
  2. [step]
- **Alternate flow:** [if any — numbered continuation]
- **Postcondition:** [state after the use case completes]
- **Traces to:** FR-NNN, FR-NNN, BR-NNN
```

Drafting rules:
- One use case per user-facing goal. Internal system steps are main-flow
  steps, not standalone use cases.
- `<<include>>` only for behavior reused by two or more use cases.
  `<<extend>>` only for optional/conditional behavior. When in doubt,
  keep the behavior inline in the main flow.
- Every use case traces to at least one requirement ID.
- Main-flow steps alternate actor/system responsibility visibly.
- Alternate flows reference outcome classes already defined in the
  requirements (error taxonomies) — never invent new error semantics.

## Phase 2 — Review

Spawn the `usecase-reviewer` sub-agent.

**Step 2.1 — Build the reviewer's context.**

Pass the reviewer:
- The requirements document path
- All generated spec document paths
- All generated diagram paths
- The confirmed domain list with mapped requirement IDs

**Step 2.2 — Reviewer checks.**

The reviewer validates:

| Check | Severity rule |
|---|---|
| **Requirement coverage**: every actor-facing FR appears in at least one main flow; every BR referenced by a UC is enforced in that UC's flow | Blocking |
| **Trace validity**: every "Traces to" ID exists in the requirements document | Blocking |
| **Spec completeness**: all eight fields present per UC (actors, goal, precondition, main flow, alternate flow or explicit N/A, postcondition, traces) | Blocking |
| **Diagram↔spec consistency**: every UC oval in the diagram has a spec; every spec has an oval; include/extend arrows match declared relationships both ways | Blocking |
| **Actor consistency**: diagram actors match requirements' roles; permissions implied by flows do not contradict the capability matrix | Risky |
| **Granularity**: no use case bundles two distinct actor goals; no main-flow step hides a second actor's goal | Risky |
| **Relationship discipline**: includes/extends are justified (reuse or optionality), not decorative | Risky |
| **Style uniformity**: naming, step phrasing, field order consistent across domains | Trivial |

Findings are classified blocking/risky/trivial exactly as in the
requirements-gatherer red team.

## Phase 3 — Evaluate convergence

| Condition | Result |
|---|---|
| Zero blocking issues | **CONVERGED** — proceed to Phase 5 |
| Blocking issues exist | Present summary, go to Phase 4 |
| User says done | **CONVERGED BY USER OVERRIDE** — proceed to Phase 5 |

Present a concise summary per iteration:

```
Use Case Review — Iteration [N]

Found: [X] blocking, [Y] risky, [Z] trivial issues.

Blocking:
- [UC-2.4]: main flow missing outcome class "quota error" required by FR-014
- Coverage gap: FR-009 not covered by any use case
...
```

## Phase 4 — Fix loop

Send the reviewer's findings back to the drafter with:
- The full finding list
- The existing draft files (revise in place, do not regenerate from scratch)
- UC numbering must remain stable across iterations — never renumber
  surviving use cases

Loop: Phase 2 → Phase 3 until converged or the user overrides.
Escalate to the user after 3 iterations without convergence on the same
blocking issue.

## Phase 5 — Finalize

**Step 5.1 — Consistency sweep.** Verify every domain pair: shared actors
rendered identically, cross-domain `<<include>>` targets exist, UC IDs
unique across ALL domains.

**Step 5.2 — Final report.**

```
Use Case Model Complete

**Domains:** [count]
**Use cases:** [total] ([per-domain counts])
**Diagrams:** docs/uml/use-cases/<slug>.puml × [count]

**Coverage:**
- Actor-facing FRs covered: [N]/[M] ([X]%)
- Uncovered FRs: [list IDs, or "none"]
- BRs referenced: [count]
- DoD items covered: [N]/[M] (if DoD exists)

**Downstream readiness:**
- generate-sequence requires: use case specs ✓, activity diagrams ✗,
  component diagram ✗
- Next steps: generate activity diagrams (separate skill), then
  generate-sequence
```

## Ground rules

- **Requirements are the sole source of truth.** Behavior not stated in
  requirements is proposed to the user as a question, never invented
  silently.
- **Context injection over discovery.** Sub-agents receive the domain
  list, requirement mappings, and paths in the task prompt. They do not
  scan the project.
- **Stable identifiers.** UC-X.Y numbers are assigned once at Phase 1
  and never change across review iterations.
- **One use case per actor goal.** System-internal steps stay inside
  main flows. This mirrors the sample guidance: "Resolve Channel ID" is
  an `<<include>>` of "Add Channel", not a standalone goal.
- **Minimal relationship vocabulary.** Only `<<include>>`, `<<extend>>`,
  and plain associations. No generalizations between actors unless the
  requirements state a role hierarchy explicitly.
- **Each sub-agent returns one report or one revision set.** The
  orchestrator routes results forward.
- **Thinking budgets.** Drafter: 5 reads. Reviewer: 4 reads (task
  context, requirements doc, specs+diagrams). Stop and report blockers
  beyond budget.

## Configuration

| Setting | Source | Default |
|---|---|---|
| Domain partition + order | User confirms proposal | Derived from FR groupings |
| Spec/diagram output dirs | User preference | `docs/use-cases/`, `docs/uml/use-cases/` |
| Convergence mode | User preference | Zero blocking issues |
| Include/extend strictness | User preference | Minimal (inline unless reuse/optionality) |

## Calibration

**Small system (~10-20 FRs):** 2-3 domains, ~8-15 use cases. One review
iteration typical. Estimated time: 5-10 minutes.

**Medium system (~50 FRs):** 3-6 domains, ~25-40 use cases. One or two
review iterations. Estimated time: 10-20 minutes.

**Large system (100+ FRs):** 6-8 domains, ~50+ use cases. Multiple
iterations; consider running domain-by-domain to keep review reports
digestible. Estimated time: 20-40 minutes.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Inventing behavior absent from requirements** | Use cases would silently amend the spec — propose questions instead |
| **System steps as use cases** | Inflates the model; internal steps belong in main flows or `<<include>>` |
| **Decorative include/extend arrows** | Relationship noise misleads sequence generation later — justify every arrow |
| **Renumbering UCs mid-loop** | Breaks cross-references in specs, diagrams, and prior review reports |
| **Skipping the coverage check** | An uncovered actor-facing FR means either a missing use case or a non-functional misclassification — always surface it |
| **Generating activity or sequence diagrams here** | Out of scope — this skill stops at use case specs + use case diagrams |
| **Duplicating requirements text into specs** | Specs summarize goals and flows; verbatim copies drift when requirements change — trace instead |

## Edge Cases

| Scenario | Handling |
|---|---|
| **No requirements document found** | Abort with a structured message; suggest running requirements-gatherer first |
| **Requirements lack FR IDs** | Abort; direct user to re-run requirements-gatherer (ID'd tables are mandatory input) |
| **FR has no actor** (pure system constraint) | Not a use case. Verify it is enforced somewhere in the relevant domain's flows; note in the report |
| **User wants a single flat domain** | Accept. One domain, UC-1.x numbering, one spec file, one diagram |
| **Two domains claim the same FR** | Ask the user which domain owns it; the other may trace to it but ownership is single |
| **Existing use case files found on disk** | Ask: revise (load as baseline, preserve stable IDs) or overwrite |
| **Capability matrix contradicts drafted flows** | Blocking finding; the matrix is normative — fix the flow or raise a question |
| **Requirements still in Draft status** | Warn the user and proceed only on explicit confirmation — use cases inherit requirement stability |

## Invocation

Recognized patterns:

```
# Direct requests
generate use cases from requirements
create use cases for [project]
turn the requirements into use cases
build the use case model

# Scoped requests
generate use cases for the channel management domain
draft use case specs for [domain]

# Pipeline requests
continue after requirements — generate use cases
```

When intent is ambiguous, ask:
- "Which requirements document should I use?"
- "All domains, or a specific one?"
