---
name: nasa-code-audit
description: >
  Scan an existing codebase and judge it against NASA software quality
  and documentation standards: JPL Power of Ten rules, NPR 7150.2D
  coding/testing/documentation requirements, and the NASA software
  classification (Class A–F) maturity model. Scores every rubric item
  pass/partial/fail, rolls domain scorecards, and produces a class
  maturity verdict ("currently evidences Class E practice") plus a
  prioritized gap list to a target class. Outputs a human-readable
  report and a machine-readable scores.json consumed by downstream
  remediation skills. Read-only audit: never modifies code, installs
  tools, or generates docs. Use when: "audit this codebase against
  NASA standards", "NASA code quality audit", "how NASA-compliant is
  this repo", "grade this codebase", "bring code up to NASA quality
  (audit first)". Skip for: writing/upgrading documentation (that is
  the paired remediation skill), running tests or linters as part of a
  build, and general code review without a standards rubric.
license: MIT
---

# NASA Code Audit

A read-only audit that judges an existing codebase against NASA
software quality and documentation standards. It scores the codebase
rubric by rubric, states what class of NASA software practice the
codebase actually evidences, and produces a prioritized, file-cited
finding list for remediation.

This skill does NOT fix anything. It observes, judges, and reports. A
paired remediation skill consumes the report + scores.json afterward.

Standards sources used by this skill (all public):

| Source | Role |
|---|---|
| JPL Power of Ten (Holzmann, 2006) | Code-level quality rules |
| NPR 7150.2D Chapter 3 (coding/testing SWEs) | Coding + testing discipline items |
| NPR 7150.2D Chapter 6 | Required documentation set |
| NPR 7150.2D Appendix D | Class A–F definitions + maturity model |
| NASA-STD-8739.8B | Secure coding / assurance context |

Rule files live next to this file in `rubric/`:

| File | Contents |
|---|---|
| `rubric/power-of-ten.md` | POT-1..POT-10 with per-language adaptations |
| `rubric/code-quality.md` | CQ-1..CQ-12 derived from NPR SWEs |
| `rubric/documentation.md` | DOC-1..DOC-9 documentation set + drift |
| `rubric/classes.md` | Class definitions, weights, verdict computation |

Invocation switches (all optional):

```
--target-class=A|B|C|D|E|F   audit against a named class (otherwise inferred)
--depth=sampled|full         sampling strategy (default: sampled)
--domain=code|docs|testing   audit one layer only (default: all)
```

## Pre-flight

**Step 1. Discover the codebase.**

Scan the target repository and record:

| Fact | Where to look |
|---|---|
| Languages + rough LOC per language | File extensions, `cloc`-style counting by extension |
| Module/package layout | Top-level dirs, manifests (`package.json`, `go.mod`, `Cargo.toml`, `composer.json`, `pyproject.toml`, `pubspec.yaml`, ...) |
| Test framework + test locations | Manifest devDependencies, `test/`, `*_test.*`, `*_spec.*`, CI configs |
| Static analysis / lint setup | Linter configs, `tsc --strict`, `flutter analyze`, CI steps |
| CI configuration | `.github/workflows/`, other CI dirs |
| Doc artifacts | `README*`, `docs/**`, `AGENTS.md`/`CLAUDE.md`, ARCHITECTURE files |
| Existing audit artifacts | Prior `docs/audit/*` reports (for trend comparison) |

**Step 2. Resolve the target class.**

If `--target-class` is given, use it. Otherwise, infer a candidate
class from repo evidence using the inference table in
`rubric/classes.md` and confirm with the user before scoring (one
sentence: "I inferred Class E — production web app. Audit against
that?"). If the user cannot be asked (batch/non-interactive run), audit
against the inference and label the verdict "inferred target" in the
report header.

**Step 3. Select rubric items.**

Load the four rule files. From `rubric/classes.md` applicability
weights, mark each item as core, scaled, or advisory for the target
class. Items N/A for the codebase's language or domain (e.g., POT-8
with zero codegen surface) are marked N/A with one-line justification —
they do not count against scores.

**Step 4. Choose sampling strategy.**

| Repository size | Sampling (unless `--depth=full`) |
|---|---|
| < 5k LOC | Audit all modules (no sampling). |
| 5k–50k LOC | Top 10 modules by size/centrality, plus 5 random core-logic files, plus every file matching safety-ish patterns (`auth`, `payment`, `parsing`, `driver`, `flight`, `protocol`). |
| > 50k LOC | Per top-level module: 3 representative files (largest, most-imported, most-recently-changed) + the safety-ish patterns above. State the sampling frame in the report. |

Sampling coverage is reported honestly: "audited 14 of 63 modules,
78% of core-logic LOC."

**Step 5. Abort conditions.**

Abort (report, don't score) when:
- The directory contains no readable source code (empty/docs-only repo).
- More than one independent product lives in the repo and the user has
  not said which to audit — offer to audit each independently.

## Phase 1 — Codebase Inventory

Record, for the report:

- Languages, LOC counts, module map (one line per module with
  responsibility guess).
- Third-party dependency count, manifest/lockfile status.
- Tooling present: test framework, lint/type-check, CI jobs, with the
  exact commands found.
- Module centrality estimate: which modules are imported most (these
  are the audit's gravity wells; one failure there outweighs ten in
  leaf modules).

No findings are produced in this phase — it builds the audit surface.

## Phase 2 — Code Quality Scan

Judge `rubric/power-of-ten.md` (POT-1..POT-10) and `rubric/code-quality.md`
items CQ-1..CQ-9 against the sampled modules.

**Step 2.1 — Evidence gathering.** For each rule, gather concrete
evidence before judging: targeted searches (e.g., `goto`, `except:
pass`, empty `catch`, `while (true)`, collection `.append`-only
caches), reading named hot spots, and reading linter/type-check
configs. A rule is never judged from a single grep miss alone — grep
misses are *supporting* evidence, not proof of absence; corroborate
with at least one read of a representative file.

**Step 2.2 — Run available tools (only what is configured).** If the
repo already has lint/type-check commands configured, run the read-only
ones (linters, type-checkers) to corroborate POT-10/CQ-3. Never install
dependencies, never run commands that mutate state (formatters with
write flags, migrations, codegen). If tooling is unconfigured, note
that as the finding itself (that is CQ-3/POT-10 evidence).

**Step 2.3 — Judge and record.** For each item produce:

```json
{
  "id": "POT-3",
  "verdict": "Partial",
  "confidence": 7,
  "severity": "Blocking",
  "finding": "Cache eviction found in web/API layer but SSE notification registry grows unbounded",
  "evidence": [{"file": "server/events/registry.ts", "line": 88, "quote": "addClient(x) { this.clients.push(x); }"}],
  "recommendation": "Cap and evict the SSE client registry; add a leak test",
  "class_core": true
}
```

(Evidence quotes must be verbatim code snippets from the file cited;
"quote" fields must NEVER be paraphrased or invented.)

**Step 2.4 — Cross-layer corroboration.** Where two items would be
judged on the same evidence (POT-7 vs CQ-7, POT-10 vs CQ-3), judge each
on its own rubric criteria; a Fail in one does not copy to the other.

## Phase 3 — Testing Discipline Scan

Judge CQ-10..CQ-12.

- Census test files vs source modules; map which core modules have
  direct tests.
- Verify the run path: documented command → CI execution. Run tests
  only if configured, safe, and quick (< 2 min) — otherwise judge from
  configuration alone and say so in the report.
- Check assertion quality in a sample of tests: do they assert on
  behavior outcomes or merely execute code without asserting outcomes
  (smoke-only tests)?
- Traceability per class scaling (A–C mandatory, D applicable).

## Phase 4 — Documentation Audit

Judge DOC-1..DOC-9 from `rubric/documentation.md`.

- Presence pass: which of the minimum-viable-set products exist for the
  target class (documentation.md table), locating each artifact.
- Truth pass (DOC-9): for each located doc, verify a sample of concrete
  claims against code (module names, config defaults, commands,
  interface shapes). Quote both sides of any contradiction.
- Intent pass (DOC-8): sample core modules for purpose-stating docs
  (doc comments on modules, header contracts) that state intent,
  not mere restatement of what the code already says.
- Do NOT do full doc-consistency checks (cross-doc contradictions,
  generation readiness) — that is a different skill. If you notice doc
  internal contradictions incidentally, append them to the report as
  "incidental observations", one line each, without a rubric score.

## Phase 5 — Verdict and Report

**Step 5.1 — Compute the verdict** per `rubric/classes.md`:

- Current-practice class: highest class X whose core set scores ≥ 85%
  with no core Fail.
- Gap list: target-core items below Pass, ordered Blocking → Risky →
  Trivial, top 5, each with its recommendation.
- If even below-E practice, say so candidly with the missing
  fundamentals list.

**Step 5.2 — Render the report** to `docs/audit/nasa-code-audit-report.md`
in the exact Output Format below, and `docs/audit/nasa-code-audit-scores.json`
in the machine schema below. Overwrite both on each run (the report is
a snapshot; history lives in git). Print the verdict sentence and gap
counts to the conversation when done.

## Output Format

```markdown
# NASA Code Audit Report

**Project:** [name]
**Date:** [date]
**Target class:** [class] (user-specified | inferred — basis: [one line])
**Depth:** sampled | full
**Sampling coverage:** [N of M modules, % core-logic LOC]
**Standards:** Power of Ten, NPR 7150.2D Ch.3/Ch.6/App.D (rubric v1)

## Verdict

This codebase currently evidences Class [X] practice.
Largest gaps to reach target Class [Y]:
1. [Blocking] [ITEM-ID] — [one line] — [one-line recommendation]
2. ...
(≤ 5 items)

## Scorecard

| Layer | Items scored | Pass | Partial | Fail | N/A | Score |
|---|---|---|---|---|---|---|
| Code quality (POT+CQ) | | | | | | [%, current class core items bolded] |
| Testing | | | | | | |
| Documentation | | | | | | |

## Findings

### [SEVERITY] [ITEM-ID] — short title
- **Item:** [id] ([layer], [category]; core/scaled/advisory for target class)
- **Verdict:** [Pass/Partial/Fail] — Confidence [N]/10
- **Evidence:** `file:line` — verbatim quote
- **Why it matters:** [one sentence tied to the NASA item's intent]
- **Recommendation:** [specific, file-scoped]

(Repeat per open finding; Pass items with notable evidence may be listed
as "clean observations" in a collapsed appendix. Below, examples show
dummy values.)

## Advisory findings (below-class items)

| Item | Verdict | Note |
|---|---|---|

## Incidental observations

[One-line doc-internal oddities noticed but not scored; could feed
doc-consistency skill runs.]

## Appendix — Evaluated items

| Item | Class status | Verdict | Score | Notes |
|---|---|---|---|---|
| POT-1 | core | Pass | 1.0 | |
| POT-8 | N/A | N/A | — | no codegen surface |
| ... | | | | |
```

### Confidence scoring

Each finding carries 1–10 confidence:

| Score | Meaning |
|---|---|
| 9–10 | Direct code evidence (quote shows the pattern) plus config corroboration |
| 7–8 | Strong sample evidence but not exhaustive (sampling caveat) |
| 5–6 | Judged from structure/config without runtime corroboration |
| 3–4 | Inference from indirect signals — flagged for human confirmation |
| 1–2 | Speculative — do not report as a scored finding at this level |

Start at 5, apply the modifiers, and clamp to 1–10. Boosters: +2 verbatim
code quote, +1 tool output corroborates, +1 multi-file pattern. Reducers:
-1 sampled-only, -2 inferred from an absence (grep miss without
corroboration).

## scores.json contract — docs/audit/nasa-code-audit-scores.json

Written to `docs/audit/nasa-code-audit-scores.json`.

```json
{
  "skill": "nasa-code-audit",
  "rubric_version": 1,
  "generated": "2026-11-09",
  "project": "project-name",
  "target_class": "C",
  "target_class_basis": "user-specified",
  "current_practice_class": "D",
  "verdict_sentence": "This codebase currently evidences Class D practice.",
  "sampling_coverage": {"modules_audited": 14, "modules_total": 63, "core_loc_pct": 78},
  "domains": {
    "code": {"score": 0.71, "items_scored": 18},
    "testing": {"score": 0.45, "items_scored": 3},
    "docs": {"score": 0.58, "items_scored": 9}
  },
  "items": [
    {
      "id": "POT-3",
      "layer": "code",
      "category": "Power of Ten",
      "verdict": "Partial",
      "score": 0.5,
      "severity": "Blocking",
      "confidence": 7,
      "class_status": "core",
      "finding": "...",
      "evidence": [{"file": "server/events/registry.ts", "line": 88, "quote": "addClient(x) { this.clients.push(x); }"}],
      "recommendation": "..."
    }
  ],
  "gaps_to_target": ["POT-3", "CQ-10", "DOC-3", "DOC-7"]
}
```

`score` (and `confidence`) is `null` for items whose verdict is `N/A`;
domain averages exclude those items. This is valid at
`rubric_version: 1` — nullability is additive, not a schema break.

**Downstream contract (partner remediation skill):** items with
`layer === "docs"` and `verdict in ["Partial","Fail"]` are the input
surface for a documentation-upgrade skill; every such item must have a
non-empty `recommendation`. Keep field names frozen across rubric
versions; bump `rubric_version` and append new fields rather than
reusing them.

## Anti-patterns

**Read-only.** Never modify code, never write to source files, never
install deps, never run mutating commands. The only artifacts written
are the two audit files, and only into `docs/audit/`.

**No checklist theater.** Don't grade a Class E web app against Class B
rigor — the class scaling exists so the audit says something true at
the right level. Conversely, never soften a mandatory-class Fail into
Pass because "this isn't really Class B" — report instead that the
codebase does not evidence the discipline the target class requires.

**No hallucinated findings.** Every finding cites file:line with a
verbatim quote you actually saw. Grep misses are absence-of-evidence —
they need corroboration before becoming findings.

**Never grade taste as substance.** The judge is the NASA intent
(reliability, reviewability, verify-ability), not house style beyond
what the repo itself declares.

**Don't run the paired skills.** This audit stops at the report. Even
when the gap list is obvious, generating docs or fixing code is the
next skill's job.

**Don't infer safety-criticality.** Ask or note it unanswered — never
mark it.

## Calibration

**Small (< 5k LOC):** full audit, no sampling. Report in one pass; ~15
min. All phases required.

**Medium (5k–50k LOC):** sampling frame as specified. Phase 2 sampled;
run Phase 3/4 across the whole repo (tests/docs census is cheap). ~45
min.

**Large (> 50k LOC):** per-module representative sampling weighted toward
module centrality. Consider splitting into per-domain runs
(--domain). Explicitly state limitations in the report header; aim for
a class-verdict with reduced precision, not an exhaustive item sweep —
note items with insufficient evidence as "not evaluable" rather than
guessing.

## Portability

Works on any repository with readable source. Adapts by discovery:

- No linter config → that absence IS the POT-10/CQ-3 finding.
- No test framework → CQ-10/11 fail for target classes where core.
- No docs beyond README → documentation.md per-class minimum decides
  whether that's Partial (honest about gaps) or Fail (silence).
- Monorepo → audit each package independently when surfaces differ;
  one verdict per package, no cross-package averaging.
- Non-NASA-context code (mundane web app) → measure against inferred
  general-purpose (Class E) practice, always preferring honest "not
  Class-X because the work was never asked for" over shaming language.
