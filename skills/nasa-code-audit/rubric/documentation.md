# Documentation Layer Rubric

Items derived from NPR 7150.2D Chapter 6 ("Software Engineering Products"
and their recommended contents) plus in-code documentation expectations
from the NASA Software Engineering Handbook. This layer answers:
"Does this codebase carry the documentation set NASA expects for its
class, and is that documentation true?"

Source verification: for precise wording of a Chapter 6 product list,
confirm at swehb.nasa.gov / nodis3.gsfc.nasa.gov before citing in a
report. Requirements applicability scales by class (see classes.md).

## How to use

Each item has:
- **ID:** Stable identifier for reporting (`DOC-N`)
- **Category:** Domain grouping for the scorecard
- **Source:** Derivation
- **Check:** What to verify
- **Verdict signals:** Pass / Partial / Fail
- **Class scaling:** Which target classes the item is core for

The "minimum viable documentation set (per class)" table at the bottom
of this file defines which DOC items are core for each target class;
items outside that set are advisory.

---

## Documentation set presence

### DOC-1: Project overview / purpose
- **Category:** Documentation set
- **Source:** NPR 7150.2D Ch.6 (concept/overview products)
- **Check:** README or equivalent states what the system is, who it is
  for, and its major capabilities in ≤ 2 minutes of reading.
- **Pass:** Clear purpose, scope, and capability summary.
- **Partial:** Exists but stale or assumes insider knowledge.
- **Fail:** No overview, or content contradicts the code.
- **Class scaling:** Core all classes. Default severity: Risky.

### DOC-2: Software requirements documented
- **Category:** Documentation set
- **Source:** NPR 7150.2D Ch.6 (SRS-family products)
- **Check:** Some form of requirements record exists: docs/requirements,
  issue tracker with requirements-level tickets, use case specs, feature
  specification documents. Content should be requirement-shaped WHAT,
  not design HOW.
- **Pass:** Requirements recorded, uniquely referenced, current enough
  that major features map to them.
- **Partial:** Requirements exist but incomplete or unlinked.
- **Fail:** No requirements record of any form.
- **Class scaling:** Core A–D; advisory E/G. Default severity: Risky
  (Blocking when core for target).

### DOC-3: Architecture / software design description
- **Category:** Documentation set
- **Source:** NPR 7150.2D Ch.6 (SDD-family products); echoes SWE-057
  family (recorded architecture)
- **Check:** Architecture record exists describing major components,
  their responsibilities, and interfaces/dependencies. Verify against
  the actual code at module level: named components should exist and
  major claims should hold.
- **Pass:** Architecture doc exists and module-level claims are true.
- **Partial:** Doc exists but drifted (modules renamed, layers missing),
  or architecture only described informally in scattered docs.
- **Fail:** No design description for a codebase large enough to have an
  architecture.
- **Class scaling:** Core B–D; advisory E/G. Default severity: Risky
  (Blocking when core).

### DOC-4: Test documentation
- **Category:** Documentation set
- **Source:** NPR 7150.2D Ch.6 (test plan / test report family)
- **Check:** Is there a record of what is tested and at what level:
  test plan, test matrix, CI-linked test report, or meaningful test
  file headers. For lower classes a scripted CI pipeline with named
  suite steps can fill this role.
- **Pass:** Test strategy visible; every core mode of use covered by a
  named suite.
- **Partial:** Tests exist with no recorded strategy or coverage intent.
- **Fail:** Nothing beyond bare test files that themselves are missing
  (cross-check CQ-10).
- **Class scaling:** Core A–C; advisory below. Default severity: Trivial
  below advisory classes.

### DOC-5: Operations / run documentation
- **Category:** Documentation set
- **Source:** NPR 7150.2D Ch.6 (operational/maintenance products)
- **Check:** How does somebody operate this system: build and run,
  configuration surface, deployment steps, backup/recovery if stateful.
  Entrypoint documentation, env var reference, runbook.
- **Pass:** A competent operator could run/upgrade it from the repo
  alone.
- **Partial:** Most things documented; gaps requiring archaeology
  (undocumented env vars, manual steps known to one person).
- **Fail:** Build/run knowledge lives only in people's heads.
- **Class scaling:** Core all classes for deployed systems; N/A for
  abandoned/pure-library targets (justify). Default severity: Risky.

### DOC-6: Interface documentation
- **Category:** Documentation set
- **Source:** NPR 7150.2D Ch.6 (ICD-family products)
- **Check:** Public interfaces (HTTP API, library API, IPC protocols,
  data schemas) documented enough that a consumer can use them without
  reading the implementation: endpoint/method references, schema docs,
  doc-gen output.
- **Pass:** Each exposed interface documented and current.
- **Partial:** Documented but drifted from code, or only partially
  covering the exposed surface.
- **Fail:** Interfaces only discoverable by reading source.
- **Class scaling:** Core all classes with external consumers.
  Default severity: Risky.

## Traceability

### DOC-7: Requirements-to-design-to-code traceability
- **Category:** Traceability
- **Source:** NPR 7150.2D — bi-directional traceability Table 1
  (Classes A–C mandatory, D applicable)
- **Check:** Can a requirement be followed into design elements and
  code/tests, and back? Any mechanism qualifies: numbered requirements,
  matching design section IDs, test names quoting requirement IDs.
- **Pass:** Mechanism present and exercised in both directions.
- **Partial:** One-directional or partially exercised.
- **Fail:** No mechanism for a class where it is mandatory.
- **Class scaling:** Mandatory A–C; applicable D. Default severity:
  Risky (Blocking when class-mandatory).

## In-code documentation

### DOC-8: Module-level intent documentation
- **Category:** In-code docs
- **Source:** NASA SWEHB documentation expectations ("Will future
  maintainers know why this exists?")
- **Check:** Sampled core modules carry docs that state purpose and
  non-obvious constraints (doc comments, module READMEs, type-level
  contracts): not the *what* (mostly visible in code), the *why*.
- **Pass:** Core modules each state purpose; naming carries intent.
- **Partial:** Some modules documented; docs repeated code, not intent.
- **Fail:** Core modules are self-comment only with no stated purpose.
- **Class scaling:** Advisory-to-core all classes. Default severity:
  Risky.

### DOC-9: Documentation-vs-code drift
- **Category:** In-code docs
- **Source:** NASA accuracy expectations for released documents
  (released docs must reflect delivered software)
- **Check:** In every doc artifact, verify a sample of concrete claims
  against code (module names, config defaults, commands). Flag
  contradicting claims (Blocking), stale-but-minor claims (Risky), and
  cosmetic drift (Trivial).
- **Pass:** Spot checks corroborate docs.
- **Partial:** Drift found in secondary claims or one secondary doc.
- **Fail:** Primary artifacts (README, architecture doc) contradict
  code behavior or structure.
- **Class scaling:** Core all classes. Default severity: Risky
  (Blocking when contradicted in primary artifact).

---

## Minimum viable documentation set (per class)

| Class | Expected minimum |
|---|---|
| A / B | DOC-1..DOC-9 all, full rigor |
| C | DOC-1, DOC-2, DOC-3, DOC-5, DOC-6, DOC-7, DOC-8, DOC-9 |
| D | DOC-1, DOC-3-lite, DOC-5, DOC-6, DOC-8, DOC-9 |
| E / G | DOC-1, DOC-5, DOC-8, DOC-9 (and honest self-marking of gaps) |

"E/G honest self-marking": a Class E project is not expected to carry a
full doc set; it is expected to be transparent about what is missing.
An "explicitly undocumented" state scores Partial, not Fail.
