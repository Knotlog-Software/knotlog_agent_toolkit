# Work Breakdown Structure: [Project / Release Name]

**Version:** 0.1 (DRAFT)
**Date:** [YYYY-MM-DD]
**Status:** Draft | Under Review | Baselined
**Scope baseline:** [Delta from current code | Full program | Release/phase | Requirement subset]
**Granularity:** TDD-atomic leaf work package
**Author:** [name or "AI-assisted, pending human review"]

---

## 1. Purpose & Scope

### 1.1 Objective

[What outcome does this WBS plan? One or two sentences.]

### 1.2 In Scope

- [Deliverable or capability included in this plan]
- [Deliverable or capability included in this plan]

### 1.3 Out of Scope

| Excluded Item | Horizon | Note |
|---|---|---|
| [What this plan does not cover] | Not V1 / Never | [why excluded] |

### 1.4 Baseline Decision

[State the confirmed scope baseline and why it was chosen. If delta from
current code, state what counts as "already built" and what evidence was
used. If full program, state that completed work is included and marked
Done.]

### 1.5 Atomicity Definition

A leaf work package is the smallest independently verifiable increment
that still delivers meaningful behavior. It must:

- have one clear deliverable or outcome,
- have one accountable owner role,
- have one test surface or verification method,
- fit one iteration subagent cycle,
- be estimated `XS` or `S` (a leaf estimated `M` needs justification; a
  leaf estimated `L` is invalid and must be decomposed).

A leaf is too small if it has no meaningful acceptance test. A leaf is
too large if it contains unrelated acceptance criteria or more than one
owner.

---

## 2. Inputs & Evidence

### 2.1 Source Documents

| Source | Path | Version / Status | Used For |
|---|---|---|---|
| Requirements | [path] | [version/status] | Functional and non-functional scope |
| Use cases | [path] | [version/status] | Actor-facing behavior and flows |
| Architecture | [path] | [version/status] | Components, constraints, interfaces |
| Architecture matrix | [path] | [version/status] | Call-graph / layer constraints |
| Component diagram | [path] | [version/status] | Component boundaries |
| Iteration history | [path] | [version/status] | Completed work baseline |
| Existing WBS | [path] | [version/status] | Revision baseline, if any |

### 2.2 Current Codebase Inventory

[Summarize the bounded inventory: language/framework, top-level modules,
tests, migrations, API routes, infrastructure, and any implemented
capabilities relevant to this plan. Record confidence per item.]

| Capability / Component | Evidence | Confidence | Notes |
|---|---|---|---|
| [name] | [path / search result] | Confirmed / Likely / Unknown | [note] |

### 2.3 Assumptions

| ID | Assumption | Status | Owner | Date |
|---|---|---|---|---|
| AS-001 | [assumption] | Confirmed / Unconfirmed | [who] | [date] |

### 2.4 Source Gaps

| ID | Gap | Impact | Resolution |
|---|---|---|---|
| GAP-001 | [missing or ambiguous input] | [impact on plan] | [TBR / user decision / accepted risk] |

---

## 3. WBS Conventions

### 3.1 Numbering Scheme

- Summary elements: `1`, `1.2`, `1.2.3`
- Work packages: `WP-1.2.3.1`
- Dependencies: `DEP-001`
- Iteration waves: `IT-01`
- IDs are assigned once and never reused. Deleted IDs are retired.

### 3.2 Levels

| Level | Meaning | Example |
|---|---|---|
| 1 | Project / release | `1` |
| 2 | Major deliverable, feature area, or enabling category | `1.2` |
| 3 | Sub-deliverable or component group | `1.2.3` |
| 4+ | Work package (leaf) | `WP-1.2.3.1` |

### 3.3 Work Package Types

| Type | Meaning |
|---|---|
| `Product` | User-facing or domain capability |
| `Test` | Test harness, fixtures, unit/integration/e2e verification |
| `Enabling` | Repo, CI/CD, environment, codegen, tooling, migration |
| `Quality` | Security, performance, reliability, observability, accessibility |
| `Docs` | User, operator, or developer documentation |
| `Release` | Deployment, release, handover, training |

### 3.4 Role Taxonomy & Execution Mode

| Role | Scope | Typical Work Packages |
|---|---|---|
| Product/Requirements Analyst | Scope clarification, acceptance criteria | Product, docs |
| Architect | Boundaries, interfaces, constraints | Product, enabling |
| Backend Engineer | Domain, application, infrastructure | Product, test |
| Frontend Engineer | Presentation, interaction | Product, test |
| Data Engineer | Schema, migration, pipelines | Product, enabling |
| DevOps/Platform Engineer | CI/CD, environments, deployment | Enabling, release |
| QA/Test Engineer | Test strategy, fixtures, verification | Test, quality |
| Security Engineer | Threat model, security controls | Quality |
| Technical Writer | Documentation, handover | Docs |
| Release Manager | Release, deployment, rollback | Release |
| AI Agent (iteration pipeline) | TDD-atomic implementation and verification | Product, test |
| Human Reviewer | Approval, architecture/security review | Quality, release |

**Execution mode values:** `Agent`, `Human`, `Hybrid`.

### 3.5 Estimate Scale

| Estimate | Meaning |
|---|---|
| `XS` | Under 1 hour |
| `S` | 1–4 hours |
| `M` | 0.5–1 day; leaf requires justification |
| `L` | Over 1 day; not allowed as a leaf |

### 3.6 Dependency Types

| Type | Meaning |
|---|---|
| `FS` | Finish-to-start: predecessor must finish before successor starts |
| `SS` | Start-to-start: successor may start when predecessor starts |
| `FF` | Finish-to-finish: successor may finish when predecessor finishes |
| `SF` | Start-to-finish: successor may finish when predecessor starts |
| `External` | Prerequisite outside the WBS (vendor, approval, credential, environment) |

Dependencies are recorded in the dependency matrix and dependency
diagram. They are **not** encoded in the WBS tree.

### 3.7 Status Values

| Status | Meaning |
|---|---|
| `Not started` | Work package is planned but not ready or not begun |
| `Ready` | All dependencies satisfied; eligible for an iteration |
| `In progress` | An iteration is actively building it |
| `Blocked` | Cannot proceed; blocker recorded in Risks/TBRs |
| `Done` | Acceptance criteria verified and gate passed |
| `Retired` | Removed from scope; ID is not reused |

---

## 4. WBS Hierarchy

<!-- Deliverable-oriented outline. Node labels are nouns/results, not
activities. Do not put dependencies, dates, or durations here. -->

```
1 [Project / Release]
  1.1 [Major deliverable]
    1.1.1 [Sub-deliverable]
      WP-1.1.1.1 [Work package]
      WP-1.1.1.2 [Work package]
  1.2 [Major deliverable]
    1.2.1 [Sub-deliverable]
      WP-1.2.1.1 [Work package]
  1.3 [Enabling / quality / release category, if in scope]
```

---

## 5. WBS Dictionary

<!-- One row per element. Summary elements need a description and
child roll-up; work packages need the full entry. Split this table by
level-2 branch if it becomes large. -->

### 5.1 Summary Elements

| WBS ID | Element | Type | Description | Children | Trace To |
|---|---|---|---|---|---|
| 1.1 | [element] | [type] | [what this element delivers] | [IDs] | [source IDs] |

### 5.2 Work Packages

<!-- Two tables are used for readability; the WBS ID links them. -->

| WBS ID | Work Package | Type | Description | Deliverable / Outputs | Acceptance Criteria | Verification Method |
|---|---|---|---|---|---|---|
| WP-1.1.1.1 | [name] | Product | [what it delivers] | [output] | [measurable criteria] | [unit/integration/inspection/analysis/manual] |

| WBS ID | Depends On | Owner Role | Execution Mode | Inputs | Estimate | Status | Trace To |
|---|---|---|---|---|---|---|---|
| WP-1.1.1.1 | [WP IDs or external] | [role] | Agent / Human / Hybrid | [inputs] | XS / S / M | Not started | [FR/UC/ARCH IDs] |

### 5.3 Work Package Definition of Ready / Done

**Definition of Ready (per work package):**

- Dependencies satisfied or explicitly waived.
- Inputs available.
- Acceptance criteria unambiguous.
- Owner role assigned.
- Test surface identified.

**Definition of Done (per work package):**

- Deliverable produced.
- Acceptance criteria verified by the stated method.
- Tests written and passing (where applicable).
- Lint/gate command passes (where applicable).
- Documentation updated (where applicable).
- WBS status updated.

---

## 6. Dependency Matrix

<!-- Every dependency names predecessor, successor, type, and rationale.
The graph must be acyclic. External dependencies are marked. -->

| ID | Predecessor | Successor | Type | Hard / Soft | Rationale | Notes |
|---|---|---|---|---|---|---|
| DEP-001 | [WBS ID] | [WBS ID] | FS / SS / FF / SF / External | Hard / Soft | [technical reason] | [note] |

### 6.1 External Dependencies

| ID | External Prerequisite | Owner | Needed By | Risk if Unavailable |
|---|---|---|---|---|
| EXT-001 | [vendor/API/credential/approval] | [who] | [WBS ID / date] | [impact] |

### 6.2 Dependency Integrity

- [ ] Graph is acyclic.
- [ ] Every predecessor exists in the WBS or is marked external.
- [ ] Every shared schema/state dependency is serialized.
- [ ] Architecture matrix constraints are respected.
- [ ] Dependency diagram matches this matrix.

---

## 7. Sequencing & Iteration Batches

<!-- Derived from the dependency graph. A wave contains only work
packages whose hard dependencies are satisfied by earlier waves. -->

### 7.1 Critical Path

[Longest dependency chain by estimated effort, with WBS IDs.]

### 7.2 Iteration Waves

| Wave | WBS IDs | Goal | Preconditions | Exit Criteria | Parallelizable | Agent / Human Mix |
|---|---|---|---|---|---|---|
| IT-01 | [WP IDs] | [goal] | [none / prior wave] | [criteria] | Yes / No | [mix] |

### 7.3 Next Ready Queue

| Priority | WBS ID | Reason Ready | Owner Role | Estimate |
|---|---|---|---|---|
| 1 | WP-1.1.1.1 | No unmet dependencies | [role] | [XS/S/M] |

### 7.4 Sequencing Risks

| Risk | Affected Waves | Mitigation |
|---|---|---|
| [risk] | [IT-xx] | [mitigation] |

---

## 8. Traceability Matrix

### 8.1 Source → WBS

| Source ID | Source Type | WBS ID(s) | Coverage Status | Notes |
|---|---|---|---|---|
| FR-001 | Requirement | WP-1.1.1.1 | Covered / Partial / Not covered | [note] |
| UC-1.2 | Use case | WP-1.2.1.1 | Covered / Partial / Not covered | [note] |
| ARCH-01 | Architecture element | 1.3 | Covered / Partial / Not covered | [note] |

### 8.2 WBS → Source

| WBS ID | Traces To | Justification |
|---|---|---|
| WP-1.1.1.1 | [FR/UC/ARCH IDs] | [why this work is needed] |
| WP-1.3.1.1 | Enabling | [why this enabling work is necessary] |

---

## 9. Coverage & Exclusions

### 9.1 100% Rule Statement

[State that the WBS contains 100% of the approved in-scope work and no
out-of-scope work. State how the boundary was confirmed.]

### 9.2 Coverage Summary

| Area | Source Count | Covered | Partial | Not Covered |
|---|---|---|---|---|
| Functional requirements | [N] | [N] | [N] | [list] |
| Use cases | [N] | [N] | [N] | [list] |
| Architecture elements | [N] | [N] | [N] | [list] |
| Non-functional / quality | [N] | [N] | [N] | [list] |
| Enabling / release | [N] | [N] | [N] | [list] |

### 9.3 Explicit Exclusions

| Item | Reason | Horizon |
|---|---|---|
| [item] | [reason] | Not V1 / Never |

---

## 10. Risks, Assumptions & Open Questions

### 10.1 Risks

| ID | Risk | Probability | Impact | Affected WBS IDs | Mitigation |
|---|---|---|---|---|---|
| RISK-001 | [risk] | High/Medium/Low | High/Medium/Low | [IDs] | [mitigation] |

### 10.2 Open Questions (TBR)

| ID | Question | Owner | Target Date | Best Estimate |
|---|---|---|---|---|
| TBR-001 | [question] | [who] | [date] | [current best guess] |

### 10.3 Change Log

| Version | Date | Author | Changes |
|---|---|---|---|
| 0.1 | [date] | [author] | Initial draft |

---

## 11. Handoff to Iteration

This WBS is the planning source for the `iteration` skill. To start an
iteration:

1. Pick a work package from the **Next Ready Queue** or a wave in
   Section 7.2.
2. Pass its `WP-` ID, description, acceptance criteria, verification
   method, and dependencies to `iteration`.
3. The iteration skill plans the file-level TDD units and runs the
   tester → writer → verifier pipeline.
4. After the iteration completes, update the work package `Status` and
   the change log, then re-evaluate the Next Ready Queue.

Example invocation:

```
Run an iteration for WP-1.2.1.1.
```

The WBS planner does not modify the iteration skill. The WBS is the
planning artifact; iteration is the execution pipeline.
