# Code Quality Layer — SWE-Derived Rubric

Items derived from NPR 7150.2D coding and testing requirements (Chapter 3,
SWE-050 through SWE-090 range) as summarized in the NASA Software
Engineering Handbook. These complement the Power of Ten layer (power-of-ten.md)
with items NASA requires but Power of Ten does not cover.

Source verification: SWE numbers cited are from the published NPR/SWEHB;
when precision matters for a report, confirm the exact requirement text at
swehb.nasa.gov (SWE pages) or nodis3.gsfc.nasa.gov (NPR 7150.2D full text)
before citing chapter-and-verse.

## How to use

Each item has:
- **ID:** Stable identifier for reporting (`CQ-N`)
- **Category:** Domain grouping for the scorecard
- **Source:** NASA requirement family the item derives from
- **Check:** What to verify
- **Verdict signals:** What Pass / Partial / Fail look like
- **Class scaling:** Which target classes the item is core for (see classes.md)

Default severity is used when the item fails at a target class where it is
core; otherwise findings are reduced one level (Blocking → Risky → Trivial).

---

## Coding discipline

### CQ-1: Recorded architecture, code implementing it
- **Category:** Coding discipline
- **Source:** NPR 7150.2D — design requirements (recorded software
  architecture) + coding requirements (code implements design)
- **Check:** Does the codebase exhibit a recognizable architecture
  (layering, module boundaries, documented in repo docs), and does the
  code's actual structure match what is claimed?
- **Pass:** Architecture documented somewhere in the repo and code
  structure corroborates it at the module level.
- **Partial:** Observable architecture in the code but not documented, or
  documented but drifted from reality (flag drift).
- **Fail:** No discernible structure (monolithic scripts, root-level
  utility soup) and no documentation.
- **Class scaling:** Core C and above; advisory below (an undocumented
  but clearly structured architecture still earns Partial for a Class
  E target).

### CQ-2: No functionality beyond documented intent
- **Category:** Coding discipline
- **Source:** SWE-061 (safeguard against unintended functions)
- **Check:** Spot-search for dead modules, commented-out blocks, unused
  exports, `TODO` features enabled accidentally (missing feature flags),
  debug/test backdoors reachable in production paths.
- **Pass:** No dead/dupe code found in sampled modules; feature toggles
  explicit.
- **Partial:** Small amounts of dead code or commented-out legacy,
  clearly inert.
- **Fail:** Reachable logic that no document, plan, or test acknowledges
  (backdoors, debug endpoints, hidden modes).
- **Default severity:** Blocking.
- **Class scaling:** Core all classes.

### CQ-3: Coding standard conformance
- **Category:** Coding discipline
- **Source:** SWE-062 (coding standards)
- **Check:** Is a coding standard discoverable (lint config, style
  guide, AGENTS.md/CONTRIBUTING rules)? Is its enforcement real (see
  POT-10)? Sampled files should conform (formatting, naming, import
  hygiene) — verify what a formatter would/could already normalize
  without re-litigating taste.
- **Pass:** Standard documented + enforced + sampled code conforms.
- **Partial:** Standard enforced but not documented, or documented but
  enforcement absent; conforming except for accumulation spots.
- **Fail:** No standard, and samples show inconsistent conventions.
- **Default severity:** Risky.
- **Class scaling:** Core C and above.

### CQ-4: Cyclomatic complexity discipline
- **Category:** Coding discipline
- **Source:** NPR 7150.2D — software quality metrics
- **Check:** In sampled functions, estimate decision density (`if`,
  `switch` arms, boolean chains, nested loops). Flag extreme functions
  (roughly > 15 branches) that lack decomposition or test coverage.
- **Pass:** No extreme complexity hotspots in core logic.
- **Partial:** Few hotspots, mitigated by tests or isolation.
- **Fail:** Delegate/mega-modules with deep nesting throughout.
- **Default severity:** Risky.
- **Class scaling:** Core B and above; advisory below.

### CQ-5: Magic values and literals
- **Category:** Coding discipline
- **Source:** NPR 7150.2D — maintainability expectations
- **Check:** Sample core logic for bare literals governing behavior
  (timeouts, thresholds, protocol codes) not defined in named constants,
  enums, or config.
- **Pass:** Behavior-affecting values named/centralized.
- **Partial:** Mix; some values duplicated across files.
- **Fail:** Critical values scattered and correlated only by convention.
- **Default severity:** Trivial.
- **Class scaling:** Advisory all classes.

## Error handling and robustness

### CQ-6: Error taxonomy consistency
- **Category:** Robustness
- **Source:** NPR 7150.2D — error detection/reporting/handling (echoes
  the NASA requirements checklist RL-2)
- **Check:** Is error handling consistent (single error type per layer,
  uniform logging levels, uniform user-facing messages)? Or a mix of
  raised errors, returned error codes, swallowed errors, print-based
  reporting?
- **Pass:** One dominant, layered error convention; logs structured.
- **Partial:** Mostly consistent; islands of ad-hoc handling.
- **Fail:** No convention; errors disappear silently in multiple
  sampled paths.
- **Default severity:** Blocking.
- **Class scaling:** Core all classes (style of convention laxer for E).

## Data and interface hygiene

### CQ-7: Boundary validation of external data
- **Category:** Robustness
- **Source:** NPR 7150.2D — input validation expectations; overlaps POT-7
- **Check:** All ingestion points (HTTP handlers, file parsers, CLI args,
  IPC, DB reads of untrusted data) validate shape/type/range before use.
  Schema validation libs or typed DTOs count.
- **Pass:** Every boundary parses via schema/model with failure path.
- **Partial:** Some boundaries validated; e.g., main API validated but
  background jobs/CLI not.
- **Fail:** Direct use of external payloads at any sampled boundary.
- **Default severity:** Blocking.
- **Class scaling:** Core all classes.

### CQ-8: Dependency hygiene
- **Category:** Data hygiene
- **Source:** NPR 7150.2D — acquisition/open-source practices; maps to
  reuse-requirements (SWE-092 range)
- **Check:** Manifests exist and are pinned/deterministic; lockfiles
  committed; no unexplained local-path dependencies; licenses recorded
  if the project ships third-party code.
- **Pass:** Manifest + lockfile present, consistent, no oddities.
- **Partial:** Manifest present but lockfile absent or suspected drift.
- **Fail:** Missing manifests or forked vendored code untracked.
- **Default severity:** Risky.
- **Class scaling:** Core all classes.

### CQ-9: Secrets and credentials
- **Category:** Data hygiene
- **Source:** NPR 7150.2D — secure coding practices (cybersecurity
  requirement family); NASA-STD-8739.8B secure coding
- **Check:** Search for hardcoded API keys, tokens, passwords, private
  IPs/credentials in code, tests, and scripts; `.gitignore` excludes
  secret files; secrets loaded via env/config.
- **Pass:** No plaintext secrets found in code, tests, or scripts.
- **Partial:** Secrets in test fixtures only, clearly fake values.
- **Fail:** Real-looking credentials in tracked files.
- **Default severity:** Blocking (report as immediate-remediation).
- **Class scaling:** Core all classes.

## Testing discipline

### CQ-10: Unit tests exist and target core logic
- **Category:** Testing
- **Source:** SWE-064/065 family (unit testing)
- **Check:** Test census: ratio of test files to source
  modules; do tests cover core logic modules (not just utils)?
- **Pass:** Majority of core modules have direct tests; tests assert
  behavior, not implementation trivia.
- **Partial:** Tests exist but entropy pockets (core modules untested,
  tests only over trivial helpers).
- **Fail:** No meaningful test suite for core logic.
- **Default severity:** Blocking.
- **Class scaling:** Core B and above; advisory-to-core for C/D.

### CQ-11: Tests runnable and run mechanically
- **Category:** Testing
- **Source:** SWE-066 family (test execution)
- **Check:** Is the test invocation documented (`npm test`, `make check`,
  CI workflow files)? Does CI actually run it? (Check `.github/workflows`
  / CI configs.) Run tests only if configured, safe, and quick; otherwise
  judge from configuration.
- **Pass:** One documented command runs tests; CI executes it.
- **Partial:** Tests locally runnable but not in CI.
- **Fail:** Tests present but invocation unclear/broken.
- **Default severity:** Risky.
- **Class scaling:** Core C and above.

### CQ-12: Requirements-to-test traceability
- **Category:** Testing
- **Source:** NPR 7150.2D — bi-directional traceability by class
  (Table 1: mandatory A–C, applicable D)
- **Check:** Is there any mechanism linking tests/features back to
  requirements or use cases (test names referencing requirement IDs,
  traceability docs, matrix files)? Judge per classes.md scaling: A–C
  must show it, D it is applicable, E/F advisory.
- **Pass:** Traceability mechanism present and current.
- **Partial:** Partial mapping, or mechanism present but stale.
- **Fail:** None for a class where mandatory.
- **Default severity:** Risky (Blocking for Class A–C targets).
- **Class scaling:** Core A–C; applicable D; advisory E/G.

---

## Class-scaling quick note

An advisory item can still produce findings, but such findings are
labeled Trivial by default and listed under "Advisory" in the report.
Core fails produce Blocking/Risky findings and weigh into the class
verdict (see SKILL.md Phase 5).
