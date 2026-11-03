# Work Breakdown Structure Quality Checklist

A source-backed checklist for validating Work Breakdown Structure (WBS)
documents. This file is the WBS equivalent of the NASA Appendix C
requirements checklist used by `requirements-gatherer`.

## Sources

| Source | What this checklist takes from it |
|---|---|
| [DoD MIL-STD-881F](https://quicksearch.dla.mil/qsDocDetails.aspx?ident_number=36026) (13 May 2022) | Product-oriented WBS, 100% rule, WBS dictionary, common-element discipline, and documented WBS construction pitfalls |
| [NASA/SP-3404 WBS Handbook](https://www.nasa.gov/wp-content/uploads/2023/08/nasa-work-breakdown-structure-handbook.pdf) | WBS development checklist, work-package characteristics, WBS dictionary examples, and non-product-element pitfalls |
| [ISO 21511:2018](https://www.iso.org/standard/69702.html) | 100% rule, hierarchical decomposition, unique identifiers, parent-child integrity, progressive elaboration |
| [PMI Practice Standard for Work Breakdown Structures, 3rd ed.](https://www.pmi.org/standards/work-breakdown-structures-third-edition) | Deliverable orientation, mutually exclusive elements, single work-package responsibility, WBS dictionary, baseline/change control |
| [GAO-20-195G Cost Estimating and Assessment Guide](https://www.gao.gov/assets/gao-20-195g.pdf) | WBS traceable to scope, appropriate level of detail, no omitted or double-counted work |
| [DOE WBS Handbook](https://www.energy.gov/projectmanagement/articles/department-energy-work-breakdown-structure-handbook) | 100% rule and bounded "other" categories |
| [AACE International RP 33R-15](https://web.aacei.org/docs/default-source/toc/toc_33r-15.pdf) | WBS is not a schedule, activity list, chronological list, or organizational hierarchy |
| [CDC UP WBS Practice Guide](https://www2.cdc.gov/cdcup/library/practices_guides/cdc_up_wbs_practices_guide.pdf) | Noun-oriented element names, work packages that can be managed, estimated, and measured |

The checklist rules below are a synthesis. The source mapping at the end
of each category shows which authority drives the rule. Rules marked
**Skill convention** are specific to this toolkit; all other rules trace
to the cited external standard.

---

## WBS-1 — Scope & Structure

| # | Rule | What to check | Source |
|---|---|---|---|
| WBS-1.1 | **100% rule** | The WBS contains 100% of the in-scope work, and no work outside the approved scope. For every decomposed element, the child elements aggregate to exactly the parent. | MIL-STD-881F; NASA/SP-3404; ISO 21511; PMI |
| WBS-1.2 | **Mutually exclusive** | No two branches overlap, duplicate, or double-count work. A deliverable belongs to exactly one WBS element. | PMI; ISO 21511; GAO-20-195G |
| WBS-1.3 | **Deliverable-oriented** | Elements are products, services, data, or results — not activities, phases, functions, skills, or organizational units. Node labels should be noun-oriented. | MIL-STD-881F; NASA/SP-3404; AACE 33R-15; CDC UP |
| WBS-1.4 | **Unique hierarchical identifiers** | Every element has a unique ID that exposes its parent-child position (e.g. `1`, `1.2`, `1.2.3`; leaves `WP-1.2.3.1`). IDs are stable across revisions. | ISO 21511; NASA/SP-3404 |
| WBS-1.5 | **Parent-child integrity** | Every child has exactly one parent; no orphan elements. Single-child chains are avoided unless there is a documented reason. | ISO 21511; MIL-STD-881F |
| WBS-1.6 | **Appropriate decomposition depth** | At least two levels. Decomposed far enough to manage, estimate, and verify the work, but not so far that the WBS becomes a task list. Depth is balanced across branches. | NASA/SP-3404; PMI; CDC UP |
| WBS-1.7 | **No schedule content in the hierarchy** | Dependencies, durations, dates, milestones, critical path, and sequencing live in the companion dependency matrix/diagram — never inside the WBS tree. | AACE 33R-15; ISO 21511 |
| WBS-1.8 | **No organizational hierarchy** | Roles and owners are metadata on elements, not WBS nodes. The WBS is not an Organizational Breakdown Structure. | MIL-STD-881F; NASA/SP-3404; AACE 33R-15 |
| WBS-1.9 | **Bounded "other" categories** | `Other`, `Miscellaneous`, and similar catch-all elements are last resorts, clearly defined, and represent less than 10% of the parent's work (measured by estimated effort, not element count). | DOE WBS Handbook; MIL-STD-881F |
| WBS-1.10 | **Explicit exclusions** | Out-of-scope work is recorded in the document, with a horizon tag (`Not V1` or `Never`) when relevant. | GAO-20-195G; PMI |

## WBS-2 — Work Package Quality

| # | Rule | What to check | Source |
|---|---|---|---|
| WBS-2.1 | **Single deliverable** | Each leaf is a work package with one clear deliverable or outcome, clearly distinguishable from every other work package. | NASA/SP-3404; PMI; ISO 21511 |
| WBS-2.2 | **Independently verifiable** | Each work package states measurable acceptance criteria and a verification method (unit test, integration test, contract test, inspection, analysis, or manual check). | NASA/SP-3404; PMI; GAO-20-195G |
| WBS-2.3 | **Single responsible owner** | Each work package has one accountable owner role, even if several roles contribute. | PMI; ISO 21511; NASA/SP-3404 |
| WBS-2.4 | **Inputs, outputs, and interfaces defined** | The WBS dictionary states what the work package consumes, produces, and exposes to other work packages. | MIL-STD-881F; NASA/SP-3404 |
| WBS-2.5 | **TDD-atomic size** | A leaf is the smallest independently verifiable increment that still delivers meaningful behavior. It fits one iteration subagent cycle: one test surface or verification method, one owner, bounded scope. | **Skill convention**; informed by NASA/SP-3404 work-package characteristics |
| WBS-2.6 | **Estimable and measurable** | Each work package has an estimate (at minimum `XS`/`S`/`M`) and progress can be measured. `L` leaves are invalid and must be decomposed. | **Skill convention**; informed by PMI; GAO-20-195G; CDC UP |
| WBS-2.7 | **Complete WBS dictionary entry** | Every work package has: description, deliverable, acceptance criteria, verification method, dependencies, owner/role, inputs/outputs/interfaces, estimate, status, and trace links. Every summary element has a description, child roll-up, and trace links. | MIL-STD-881F; NASA/SP-3404; PMI |
| WBS-2.8 | **No task-list leakage** | The WBS does not enumerate low-level tasks or activity sequences. Schedule tasks are derived later by the iteration plan. | AACE 33R-15; CDC UP |

## WBS-3 — Dependency & Sequencing

| # | Rule | What to check | Source |
|---|---|---|---|
| WBS-3.1 | **Explicit dependencies** | Every WBS-to-WBS dependency names predecessor and successor WBS IDs, a type (FS/SS/FF/SF), and a rationale. External prerequisites are recorded separately as `EXT-` entries in §6.1. | MIL-STD-881F; GAO-20-195G; PMI |
| WBS-3.2 | **Acyclic graph** | The dependency graph is a DAG. No cycles, self-links, or circular chains. | PMI; scheduling best practice |
| WBS-3.3 | **Technical rationale** | Dependencies are driven by architecture, data, interfaces, or verified constraints — not preference, habit, or organizational convenience. | ISO 21511; GAO-20-195G |
| WBS-3.4 | **External dependencies identified** | Third-party APIs, credentials, approvals, environments, vendor deliverables, and other external prerequisites are explicit as `EXT-` entries in §6.1. | GAO-20-195G; MIL-STD-881F |
| WBS-3.5 | **Shared schema/state serialized** | Work packages that share a schema, migration, generated artifact, or mutable state are ordered or explicitly serialized. | **Skill convention**; informed by MIL-STD-881F interface/control-account guidance |
| WBS-3.6 | **Architecture constraints respected** | Dependencies do not violate layer, call-graph, import, or service-boundary constraints from the architecture matrix. | MIL-STD-881F; GAO-20-195G |
| WBS-3.7 | **Critical path and parallel batches** | The document identifies the approximate critical path using a stated nominal-duration convention, and groups independent work into parallelizable iteration waves. | PMI; NASA/SP-3404 |
| WBS-3.8 | **No dependency on unplanned work** | Every predecessor exists in the WBS, or the external prerequisite is recorded as an `EXT-` entry. No dependency points to a missing element. | GAO-20-195G; ISO 21511 |
| WBS-3.9 | **Reference integrity** | Dependency matrix references, WBS IDs, and PlantUML node labels/aliases resolve to the same elements. | **Skill convention** |

## WBS-4 — Coverage & Traceability

| # | Rule | What to check | Source |
|---|---|---|---|
| WBS-4.1 | **Source coverage** | Every in-scope requirement, use case, and architecture element maps to at least one WBS element. | GAO-20-195G; MIL-STD-881F |
| WBS-4.2 | **WBS justification** | Every WBS element traces to a source or is explicitly justified as enabling work (build, test, deploy, document, secure, migrate). | GAO-20-195G; PMI |
| WBS-4.3 | **Non-functional work included** | Security, performance, reliability, observability, accessibility, and compliance work appear when in scope. | NASA/SP-3404; GAO-20-195G |
| WBS-4.4 | **Quality engineering included** | Test harness, fixtures, unit/integration/end-to-end tests, and verification work appear when in scope. | PMI; NASA/SP-3404 |
| WBS-4.5 | **Enabling work included** | Repository setup, CI/CD, environments, codegen, migrations, and tooling appear when in scope. | MIL-STD-881F; NASA/SP-3404 |
| WBS-4.6 | **Release and support work included** | Deployment, release, documentation, training, and handover appear when in scope. | MIL-STD-881F; NASA/SP-3404 |
| WBS-4.7 | **No orphan or invented work** | No WBS element lacks a source or enabling justification. No work appears that the user did not approve. | GAO-20-195G; PMI |
| WBS-4.8 | **Completed work handled consistently** | In delta mode, completed work is excluded from the plan and recorded in the current-state inventory. In full-program mode, completed work is included and marked `Done`. | **Skill convention** |

## WBS-5 — Consistency, Feasibility & Maintainability

| # | Rule | What to check | Source |
|---|---|---|---|
| WBS-5.1 | **Terminology consistency** | WBS terms match the requirements, use cases, and architecture glossary. No synonym drift. | ISO 21511; PMI |
| WBS-5.2 | **No contradictions** | WBS elements, dependencies, acceptance criteria, and trace links do not contradict each other or the source documents. | GAO-20-195G; PMI |
| WBS-5.3 | **Technical feasibility** | Work packages are achievable with the stated architecture, technology, skills, and constraints. | GAO-20-195G; MIL-STD-881F |
| WBS-5.4 | **Realistic estimates** | Estimates and atomicity are defensible. No work package is obviously too large, too trivial, or mis-sized relative to its branch. | GAO-20-195G; PMI |
| WBS-5.5 | **Implementation-agnostic hierarchy** | The hierarchy states WHAT is delivered, not HOW. Implementation detail is limited to acceptance criteria and verification notes. | MIL-STD-881F; NASA/SP-3404 |
| WBS-5.6 | **Verification strategy aligned** | Each work package's verification method matches its type (code, test, docs, infrastructure, release). | NASA/SP-3404; PMI |
| WBS-5.7 | **Versioned and change-controlled** | The document has a version, status, change log, and a baseline/change-control statement. | PMI; NASA/SP-3404 |
| WBS-5.8 | **Assumptions and TBRs explicit** | Assumptions are stated. Every unresolved decision is a TBR with owner, target date, and best estimate — never a bare TBD. | NASA/SP-3404; PMI |

---

## Focus Area Mapping

The red-teamer maps its assigned focus area(s) to these checklist sections:

| Focus Area | Primary Rules | Additional Cross-Checks |
|---|---|---|
| `coverage` | WBS-1.1, 1.2, 1.5, 1.10; WBS-4.1 through 4.8; WBS-5.7, 5.8 | WBS-5.1, 5.2 |
| `decomposition` | WBS-1.3, 1.6, 1.8, 1.9; WBS-2.1, 2.5, 2.6, 2.8; WBS-5.4 | WBS-1.4, 2.3 |
| `dependencies` | WBS-1.7; WBS-3.1 through 3.9 | WBS-5.2, 5.3 |
| `verifiability` | WBS-2.2, 2.4, 2.7; WBS-5.5, 5.6 | WBS-5.1, 5.2 |
| `consistency` (optional) | WBS-1.4; WBS-5.1 through 5.8 | WBS-3.9 |
| `traceability` (optional) | WBS-4.1, 4.2, 5.1 | WBS-5.2 |

---

## Severity Guidance

| Severity | Use when |
|---|---|
| **Blocking** | The finding would cause missing scope, wrong scope, double-counted work, an unbuildable sequence, an unverifiable work package, a broken trace, or a contradictory plan. Examples: 100% rule violation, dependency cycle, leaf with no acceptance criteria, orphan work, missing requirement coverage. |
| **Risky** | The finding could cause rework, confusion, or poor iteration sizing but is recoverable. Examples: unbalanced decomposition, weak owner assignment, ambiguous dependency rationale, missing external dependency detail. |
| **Trivial** | The finding is cosmetic or stylistic. Examples: inconsistent capitalization, non-uniform label phrasing, formatting. |

A red-teamer must cite the specific rule ID and the specific WBS ID (or
section) for every finding. Findings without evidence are invalid.

---

## Standard-Specific Notes

### MIL-STD-881F

- The WBS is a product-oriented family tree of hardware, software,
  services, data, and facilities.
- The WBS dictionary defines each element and its hierarchical
  relationship.
- Avoid non-product elements such as functions, organizations, phases,
  skill types, or labor categories.
- High-cost, high-risk, or high-interest elements may need deeper
  decomposition than the rest of the tree.

### NASA/SP-3404

- A WBS identifies all deliverables required to achieve the project
  objective. Work not in the WBS is not in the project.
- Work packages are units of work at the level where work is performed:
  clearly distinguished, assigned to one organizational element,
  scheduled, budgeted, and measured.
- The WBS checklist (NASA/SP-3404, Figure 3-14 in the 2019 revision)
  covers product orientation, 100% scope, dictionary completeness, and
  non-product-element pitfalls.
- Do not use `Design`, `Engineering`, `Manufacturing`, `Phase A`,
  `Pipe Fitters`, `Direct Labor`, `Rework`, `Retesting`, or
  `Refurbishing` as WBS elements — they are functions, organizations,
  time frames, skills, or labor categories.

### ISO 21511:2018

- The 100% rule applies at every parent-child boundary.
- Every element has a unique identifier.
- The structure may use product, deliverable, result, phase, discipline,
  or location-oriented parent-child relationships, but the choice must
  be explicit and consistent.
- Progressive elaboration is allowed: the WBS represents 100% of the
  scope known at the time it is developed.

### PMI Practice Standard for WBS

- Deliverable-oriented, not activity-oriented.
- 100% rule and mutually exclusive elements.
- Every work package has a single point of responsibility.
- The WBS dictionary defines what each element includes.
- The WBS is baselined and change-controlled.

### GAO-20-195G

- The WBS must be product-oriented, traceable to the statement of work,
  and at an appropriate level of detail so cost elements are neither
  omitted nor double-counted.
- The WBS dictionary defines what each element includes and how it
  relates to the rest of the hierarchy.

### AACE International RP 33R-15

The WBS should be unique, contain all scope, establish the performance
measurement baseline, and serve as a common reference. It should **not**
be a comprehensive activity list, a chronological listing, a description
of planned activities, or an organizational hierarchy.

### CDC UP WBS Practice Guide

- Use nouns and adjectives, not verbs.
- Work packages must be manageable, estimable, and measurable.
- Three levels are often enough unless an element is high-cost or
  high-risk.
- Excessive decomposition turns the WBS into an ineffective to-do list.

---

## Red-Team Discipline

- Check every rule in your assigned focus area(s) against every
  applicable element.
- Build explicit coverage and dependency maps; do not rely on memory.
- Report pass and fail for each rule, not just failures.
- Do not report a finding you cannot justify with a rule ID and a
  specific WBS ID.
- Do not check outside your assigned focus area(s). Note out-of-scope
  observations as `out of scope` and exclude them from the scored report.
- Do not demand implementation details. The WBS states WHAT is
  delivered, not HOW it is built.
- Do not treat the WBS as a schedule. Dependencies belong in the
  companion matrix/diagram, not the tree.
