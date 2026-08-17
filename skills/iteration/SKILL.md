---
name: iteration
description: >
  TDD pipeline orchestrator for iterative development. Plans work units,
  then builds via tester → writer → verifier subagents. Adapts to any
  project by discovering gate commands, file paths, and conventions from
  the target project's configuration. Use when the user asks to run an
  iteration, build a feature increment, or execute a TDD cycle. Requires
  a project config file (AGENTS.md, CLAUDE.md, or equivalent) for
  project-specific rules. Skip for single-file changes, quick fixes,
  or tasks that don't need the full TDD pipeline.
license: MIT
---

# Iteration Pipeline

A TDD orchestrator that plans work units and builds them through a
three-phase subagent pipeline: tester writes tests first (red), writer
implements to pass (green), verifier gates the result (quality). The
orchestrator never writes code — it plans, delegates, and routes.

## Pre-flight

**Step 1. Discover project configuration.**

Scan the project for a configuration file that defines architecture rules,
testing conventions, and gate commands:

| Config file | What it provides |
|---|---|
| `AGENTS.md` | Architecture rules, testing conventions, layer constraints, gate commands |
| `CLAUDE.md` | Same role, different naming convention |
| `*.md` in project root with architecture/testing sections | Fallback |

If no project config exists, abort and tell the user to create one. The
skill needs at least architecture rules and testing conventions to function.

**Step 2. Discover gate commands.**

From the project config, extract the canonical quality gate commands:

| Command type | What to look for | Common examples |
|---|---|---|
| Lint/analyze | Static analysis command | `flutter analyze`, `npm run lint`, `cargo clippy`, `ruff check`, `eslint .` |
| Test | Targeted test command (per-file) | `flutter test`, `npm test`, `cargo test --lib`, `pytest` |
| Full test | Full test suite command | `flutter test`, `npm test`, `cargo test`, `pytest` |
| Codegen (if any) | Code generation command | `dart run build_runner build`, `orval`, `openapi-generator-cli generate` |
| Structure checks | Import/dependency verification | `tool/verify_presentation_imports.sh`, custom scripts |

Record each command. If a command type is not documented in the project
config, check for common project markers:

| Marker file | Likely toolchain | Default commands |
|---|---|---|
| `pubspec.yaml` | Dart/Flutter | `flutter analyze`, `flutter test` |
| `package.json` | Node.js | `npm run lint`, `npm test` |
| `Cargo.toml` | Rust | `cargo clippy`, `cargo test` |
| `pyproject.toml` | Python | `ruff check`, `pytest` |
| `go.mod` | Go | `go vet`, `go test ./...` |

**Step 3. Discover iteration source.**

Determine how the project tracks iterations:

| Source pattern | What to look for |
|---|---|
| `agents/iteration_history.md` | Tabular iteration history with status, deliverables, and "What Has Been Built" |
| `docs/iterations*.md` | Iteration tracking in docs directory |
| `AGENTS.md` iterations section | Inline iteration tracking |
| `sprints/` or `iterations/` directory | Dedicated iteration directories |

If no iteration source exists, the skill can still operate — the user
provides the iteration target directly (e.g., "build feature X" or
"implement UC-2.4").

**Step 4. Discover architecture constraints.**

Scan for architecture constraint files:

| File | What it provides |
|---|---|
| `ARCHITECTURE_MATRIX.yaml` | Service call graph constraints (may_call / must_not_call) |
| Architecture section in project config | Layer dependency rules |
| `docs/architecture.md` | Architecture narrative |

If an architecture matrix exists, record the constraint set. The
orchestrator will verify that planned work does not violate call graph
constraints. If no matrix exists, skip architecture-gate validation.

## Phase 0 — Prepare (read-only)

1. Read the iteration source to find the target iteration. If the user
   provided an iteration number or feature name, use that. If not, find
   the first iteration marked "Not started" (or equivalent).
2. Read the project config for architecture rules, testing conventions,
   and codegen commands.
3. If an architecture matrix exists, read it and record constraint pairs.
   Flag any planned work that touches cloud services and confirm the
   notification/API routing constraints.
4. Read relevant use-case specs and design docs referenced by the
   iteration deliverables (search `docs/` as needed).

## Phase 1 — Plan, then STOP for approval (no building)

1. Decompose the iteration into ordered units of work. Each unit must
   be independently testable and buildable.
2. For each unit, specify:
   - Goal and deliverables (from iteration source)
   - Touchpoints: domain (entities/use cases/repos), application
     (providers/use cases/services), infrastructure (migrations, adapters),
     presentation (screens/view models)
   - Files to create or modify (names, not contents)
   - Test surface: the exact tests the tester writes FIRST
   - Verification criteria: how the verifier will gate this unit
   - Dependencies on other units; do units that share schema/state
     serialize?
   - Architecture-gate check result per unit (if architecture matrix exists)
3. Write the full plan to a plan file in the project (e.g.,
   `agents/plans/iteration_<N>_plan.md` or `docs/plans/iteration_<N>.md`).
   Structure it for human review: executive summary, unit-by-unit
   breakdown, dependency order, verification strategy, risks/open questions.
4. Present a concise summary in chat: iteration, number of units, unit
   list with one-line descriptions, verification strategy, and any open
   questions.
5. **STOP.** Wait for explicit approval. Do NOT spawn any subagent or
   write any code before approval. If the user requests plan changes,
   update the plan file and re-present.

## Phase 2 — Build (only after explicit approval)

1. Load the plan. Create a todo per unit via `todowrite` (one
   `in_progress` at a time).
2. For each unit, in dependency order:
   a. **Spawn `iteration-tester`** (the TDD red phase). Context to pass:
      unit description, spec references, files to target, verification
      criteria, and the project's targeted test command. Expect a
      structured red-baseline report.
   b. **Spawn `iteration-writer`** (the green phase). Context to pass:
      unit description, the tester's report, verification criteria,
      codegen command (if any), and targeted test command. Expect a
      structured completion report.
   c. **Spawn `iteration-verifier`** (the gate). Context to pass: unit
      description, files touched, and the canonical gate commands from
      the project config. Expect a PASS/FAIL report.
   d. **On FAIL**: route the report back — code/implementation issues
      → writer; test correctness issues → tester. Loop until PASS. If
      the same failure loops twice, stop and surface it to the user
      with context instead of burning more cycles.
   e. **On PASS**: mark the todo complete and proceed to the next unit.
3. When all units pass, deliver a final summary: units completed, totals
   (tests added, files created/modified), gate results, and anything
   deferred or flagged for the next iteration.
4. Never commit, push, or create a PR unless explicitly asked.

## Ground rules

- Subagents have fresh context; pass everything they need in each task
  prompt (never rely on them having seen prior turns).
- Each subagent returns one report — capture it and carry it forward.
- Respect the project's architecture rules strictly. If a test conflicts
  with the architecture, report it instead of violating it.
- Do not modify subagents' test files in the writer phase. If a test is
  wrong, route it back to the tester.

## Configuration

The skill adapts to the project. Key configuration points:

| Setting | Source | Default |
|---|---|---|
| Project config file | `AGENTS.md`, `CLAUDE.md` | Auto-discovered |
| Iteration source | `agents/iteration_history.md` | Auto-discovered |
| Gate commands | Project config | Auto-detected from project markers |
| Architecture matrix | `ARCHITECTURE_MATRIX.yaml` | Optional |
| Plan output directory | `agents/plans/` or `docs/plans/` | Created if needed |

## Calibration

**Small iteration (1–3 units):** Run the full pipeline. Estimated time:
5–15 minutes depending on project size and gate command speed.

**Medium iteration (4–8 units):** Run the full pipeline. Consider
running independent units in parallel if the project supports it.

**Large iteration (9+ units):** Break into sub-iterations. Each
sub-iteration should be 3–5 units. Run sub-iterations sequentially
to maintain context coherence.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Skipping the plan phase** | Units lack clear boundaries and verification criteria. The pipeline degenerates into ad-hoc coding. |
| **Building before approval** | The user loses control of what gets built. Always stop after planning. |
| **Not passing full context to subagents** | Subagents make wrong assumptions because they lack project context. Every subagent needs everything. |
| **Looping more than twice on the same failure** | Diminishing returns. Surface the issue to the human with full context. |
| **Ignoring architecture violations** | Technical debt compounds silently. Architecture violations must be reported, not worked around. |
| **Running the full gate from the writer** | Conflates roles. The writer runs targeted tests only. The verifier runs the full gate. |
