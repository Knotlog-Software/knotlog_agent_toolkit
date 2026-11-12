---
name: nasa-code-documentation
description: >
  Document an existing codebase to NASA code documentation standards by
  adding and repairing in-code doc comments. Applies the house comment
  style (extended from agent-context-kit's class comment specification)
  in each language's idiomatic doc-comment syntax: file/module headers,
  class/type headers, function headers with parameters/returns/errors/
  side effects/invariants, constants and properties. Coverage is
  class-scaled using the nasa-code-audit class model, can consume
  nasa-code-audit scores.json DOC-8 findings as its work list, and
  applies upgrades in verified, comment-only batches. Repairs stale or
  wrong comments and flags contradictions instead of documenting them.
  Use when: "document this codebase", "add NASA-style comments",
  "upgrade doc comments", "make the code NASA-documentation compliant",
  "fix DOC-8 findings". Skip for: generating the external documentation
  set (README, architecture docs — that is the documentation skill),
  auditing quality without editing (use nasa-code-audit), and
  documenting code you are simultaneously changing semantically.
license: MIT
---

# NASA Code Documentation

Adds and repairs in-code documentation on an existing codebase so it
meets the NASA-derived comment standard. Writes doc comments in the
repository's languages, in each language's idiomatic doc-comment syntax,
without changing program behavior.

This skill is the write-side partner of `nasa-code-audit`:

```
nasa-code-audit  → docs/audit/nasa-code-audit-scores.json  (DOC-8 gaps)
nasa-code-documentation → code with NASA-style doc comments
                        → docs/audit/nasa-doc-comments-report.md
```

Its canonical style is `assets/comment_style_spec.md`, which extends the
class-comment format in `agent-context-kit/assets/class_comment_specification.md`.
Read that spec before writing a single comment.

In scope: comments, doc comments, file/class/function headers.
Out of scope: the documentation set (README, architecture, operations,
interface docs), refactoring, renaming, type changes, bug fixes,
generated/vendored files.

Invocation switches (all optional):

```
--target-class=A|B|C|D|E|F   coverage per class (otherwise inferred or read from audit)
--modules=path[,path]        restrict to named modules/packages
--files=path[,path]          restrict to named files
--batch-size=N               files per batch (default 8)
--dry-run                    produce the plan and coverage gap census only; no edits
--auto-confirm               skip per-batch confirmation (never default; not advised for A/B)
```

## Pre-flight

**Step 1. Discover the codebase and its comment tooling.**

Record:
- Languages and file counts in scope.
- Doc-comment syntax/tooling per language (dartdoc, JSDoc, docstrings,
  godoc, PHPDoc, rustdoc, Javadoc) and whether a doc generator exists.
- Module layout, entrypoints, and test locations (tests are intent
  evidence for Phase 2).
- Verification commands available: compile/analyze/lint/type-check.
  Record exact commands and whether they run without installing
  dependencies.
- Generated and vendored file patterns already present in the repo.

**Step 2. Resolve the target class and coverage set.**

Target class resolution order:
1. `--target-class` if given.
2. `target_class` from `docs/audit/nasa-code-audit-scores.json` if present.
3. Inference using `nasa-code-audit/rubric/classes.md`, confirmed with
   the user before writing.

Coverage set by class:

| Class | Coverage set |
|---|---|
| A / B | Every hand-written source file in scope |
| C | All public API surface of the package/app + core modules |
| D | Core modules + public API of internally consumed packages |
| E / F | Core modules only (E-like: general purpose, business/IT; G/H audited as E) |

"Core modules" = entrypoints plus modules with high import centrality or
security/data roles (auth, payment, parsing, protocol, persistence).

**Step 3. Read the audit work list, if available.**

If `docs/audit/nasa-code-audit-scores.json` exists:
- Validate it is this toolkit's audit output (`skill` ==
  `"nasa-code-audit"`, `rubric_version` present).
- Select items where `layer == "docs"` and `verdict` is `"Partial"` or
  `"Fail"`. DOC-8 (module-level intent documentation) is the primary
  work list; DOC-9 findings that concern in-code comments are secondary.
- Use the `evidence[].file` paths and `recommendation` fields to seed
  the plan. Do not blindly trust the audit: re-check each file before
  writing.
- If the file is absent or unparseable, fall back to the Phase 1 census
  and say so in the report.

**Step 4. Safety gate (mandatory before any edit).**

- Require a clean Git working tree: `git status --porcelain` must be
  empty except for `docs/audit/` artifacts produced by the audit run.
  If anything else is dirty, stop and ask the user to commit or stash. A
  dirty tree makes "comment-only" verification impossible to trust.
- Record baseline: `git rev-parse --short HEAD` and the result of the
  project's compile/lint/type-check command(s).
- If the directory is not a Git repository: require explicit user
  confirmation, and copy each file to a `.bak` beside it before the
  first edit (delete the backups after the report is written, on user
  confirmation). State the reduced safety in the report.

## Phase 1 — Gap Census and Plan

For every file in the coverage set, census the comment state:

| Gap | Detection |
|---|---|
| Missing file/module header | No header block in the first ~20 lines |
| Missing class/type doc | Type declaration with no doc comment above it |
| Missing method doc | Public method with no doc comment above it |
| Incomplete method doc | Header exists but lacks parameters/returns sections, or documents some parameters only |
| Stale / contradicting comment | Header claims behavior the code no longer has |
| Noise comment | Comment restates the code line-for-line |

Exclusions: generated/vendored files, lockfiles, `DO NOT EDIT` files
(report them under "Skipped").

Produce a batched plan: group files by module, ~`--batch-size` files per
batch, ordered so shared/base modules come first (their vocabulary is
reused by later batches). Estimate effort and show the plan to the user.

With `--dry-run`, stop here and print the census + plan. No edits.

If `--files` or `--modules` matches nothing in the coverage set, stop
before any edit and report the empty selection.

## Phase 2 — Comment Synthesis Rules

Before writing any comment for an entity, gather intent evidence:

1. Read the declaration and body.
2. Read the entity's tests — they encode expected behavior precisely.
3. Read call sites — they reveal the contract callers rely on.
4. Read existing docs that mention the entity (README, architecture).
5. Check the entity's history only if needed to explain a surprising
   constraint.

Write comments that satisfy `assets/comment_style_spec.md`:

- First line: one sentence, verb-led for functions, purpose for types
  and files.
- Parameters: constraints and meaning, not type restatement. Document
  every parameter or none.
- Returns: meaning plus edge/error convention.
- Optional sections (`Errors`, `Side effects`, `Invariants`,
  `Thread safety`, `Units`, `See also`) only when the entity has that
  concern.
- Use the language's native doc-comment syntax and annotation tags where
  they exist; see the mapping table in the style spec.
- Match the repository's existing comment language.

Do not write a comment you cannot verify against the code. If behavior
is unclear after steps 1–5, mark the entity `comment-blocked` with what
would resolve it, and move on.

## Phase 3 — Batch Application Loop

For each batch:

1. **Apply comments only.** Every edited line must be a comment line or
   inside a comment block. No signature, type, formatting, import, or
   logic changes.
2. **Check syntax.** Run the project's compile/analyze/lint/type-check
   command(s) in their read-only modes. If no tooling exists, use the
   language's lightest parser check (`php -l`, `python -m py_compile`,
   `node --check`, etc.) and note reduced assurance. Never run
   formatters in write mode.
3. **Enforce the comment-only diff.** Inspect
   `git diff --unified=0` for the batch. If any changed line is not a
   comment, abort the batch, restore with `git checkout -- <files>`, and
   report the violation.
4. **Show the summary.** Present `git diff --stat`, the verification
   result, and a compact excerpt of the comment changes.
5. **Confirm.** Ask the user to continue to the next batch (unless
   `--auto-confirm`). On stop, keep applied batches and go to Phase 4.

On any failure (syntax, diff gate, unexpected behavior in checks): do
not "work around" it. Revert the batch, record it in the report under
"Failed batches", and continue only if the user directs.

## Phase 4 — Verification and Report

1. Re-census the coverage set. Compare documented-before vs
   documented-after per scope.
2. Write `docs/audit/nasa-doc-comments-report.md` using the Output
   Format below.
3. Print the summary: files touched, entities documented, contradictions
   fixed, comment-blocked count, skipped count.
4. Recommend re-running `nasa-code-audit` to re-measure DOC-8.
5. Leave the working tree with the applied edits uncommitted unless the
   user asks for a commit.

## Output Format

```markdown
# NASA Code Documentation Report

**Project:** [name]
**Date:** [date]
**Target class:** [class] ([user-specified | audit-sourced | inferred])
**Coverage set:** [scope description]
**Input:** [audit scores.json (N DOC-8 findings) | discovery census]
**Baseline commit:** [short sha]
**Verification tooling:** [exact commands, or "none found"]

## Coverage

| Scope | Files | Documented before | Documented after | Entities added | Stale fixed |
|---|---|---|---|---|---|
| [module] | | | | | |
| **Total** | | | | | |

## Batches Applied

| # | Files | Comment changes | Verification | Result |
|---|---|---|---|---|
| 1 | 8 | 41 doc blocks + 12 headers | flutter analyze | pass |

## Contradictions Fixed

- `file:line` — comment said "[quote]"; code does "[actual]". Corrected
  the comment / flagged instead: [what was done].

## Comment-Blocked Entities

| Entity | File | What is needed to document it |
|---|---|---|
| `SomeService` | `src/services/some_service.dart` | Confirm intended retry semantics (tests disagree with implementation) |

## Design Observations (not fixed)

- `file:line` — [naming/signature/design issue noticed while documenting;
  this skill does not fix code].

## Skipped Files

| File | Reason |
|---|---|
| `lib/generated/api.g.dart` | Generated |

## Failed Batches

| # | Reason | State |
|---|---|---|
| — | none | — |

## Next Step

Run `nasa-code-audit` again to re-measure DOC-8 and update the audit
report and scores.json.
```

## Anti-patterns

**Comment-only, always.** Never rename, re-type, reorder, reformat, or
"tidy while here". A signature that needs a better name gets a line in
"Design Observations", not an edit.

**No invented facts.** Every parameter, error, side effect, and
invariant you document must be evidenced by code, tests, call sites, or
repo docs. Unchecked claims become lies for the next maintainer.

**No parroting.** `// Increment i` is noise; delete it rather than
upgrade it. If a comment adds nothing beyond the code, it is not
documentation.

**Never document wrong behavior as intended.** If code contradicts its
obvious intent, fix the comment only when the code is clearly right;
otherwise flag the contradiction and record it in the report.

**Never touch generated, vendored, or `DO NOT EDIT` files.** They are
regenerated and/or owned elsewhere.

**Never run mutating tools.** Check-only lint/type-check/analyze
variants only; no `--fix`, no write-mode formatters, no codegen.

**Never commit unless asked.** Stop at a clean report; the user reviews
the diff.

**Do not expand scope into the doc set.** README, architecture,
operations, and interface docs are the `documentation` skill's job, not
this one's.

## Calibration

**Small (< 5k LOC):** one census, one or two batches, one confirmation.
Full coverage set per class. ~20 min.

**Medium (5k–50k LOC):** batch per module (6–10 files). Census all
files; only comment the coverage set. ~1–2 hours.

**Large (> 50k LOC):** work module-by-module using `--modules`; document
entrypoints and core modules first. State coverage honestly in the
report; do not claim whole-repo coverage when batches were scoped.
Consider separate runs per package in a monorepo, one report each.

## Portability

Works on any hand-written source tree with a checker or parser.

- No lint/type-check tooling: fall back to per-file syntax checks and
  reduced-assurance wording in the report.
- No tests and no call sites (leaf prototype): synthesize conservatively
  from code and docs; expect more `comment-blocked` entries.
- Non-Git directory: backup-copy protocol in Pre-flight Step 4.
- Docs already generated from comments (dartdoc/typedoc/rustdoc
  pipelines): emit syntax that the generator consumes; do not introduce
  a second comment dialect into the same file.
- Repo comments in a non-English language: follow the repo's language;
  note the choice in the report header.
