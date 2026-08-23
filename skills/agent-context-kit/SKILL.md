---
name: agent-context-kit
description: >
  Scaffold AGENTS.md + agents/ knowledge base into a project. Auto-detects
  test/lint/codegen commands from project markers, fills placeholders,
  then drafts Architecture Gate / Domain Model / Commands TODOs by exploring
  the repo (with approval). Use when the user asks to initialize/set up
  agent context, create AGENTS.md, bootstrap a new repo for coding agents,
  or set up iteration planning files.
license: MIT
---

# Agent Context Kit

Bootstraps the **agent context kit** — `AGENTS.md` (agent instructions:
commands, gates, rules, constraints) plus `agents/` (knowledge base:
methodology, decisions, iteration history, plans) — into a target
directory. Adapts to the project by discovering conventions from
existing config files, then guides completion of every `<!-- TODO -->`
block before declaring the scaffold done.

The kit originates from the VoyageWatch (SailSafe) repo, extracted as
opinionated house style with project-specific content replaced by
placeholders. `methodology.md` and `class_comment_specification.md` are
kept opinionated on purpose; project-specific sections are marked with
`<!-- TODO -->` guidance comments.

## Pre-flight

### 1. Determine target directory

Ask the user for the target path (default: current working directory).
If the target exists and is non-empty, confirm `--merge` mode (copy
only missing files, never overwrite). If fresh target, proceed with
full copy.

### 2. Discover project conventions (auto-detect)

Scan the target (or current directory if fresh) for marker files and
extract canonical gate commands. Reuse the same marker table as the
`iteration` skill:

| Marker file | Likely toolchain | Test command | Lint command | Codegen | Import check |
|---|---|---|---|---|---|
| `pubspec.yaml` | Dart/Flutter | `flutter test` | `flutter analyze` | `dart run build_runner build` | `tool/verify_presentation_imports.sh` (if exists) |
| `package.json` | Node.js | `npm test` | `npm run lint` | (check scripts) | (check scripts) |
| `Cargo.toml` | Rust | `cargo test` | `cargo clippy` | `cargo generate` | (cargo check) |
| `pyproject.toml` | Python | `pytest` | `ruff check` | (check scripts) | (check scripts) |
| `go.mod` | Go | `go test ./...` | `go vet` | `go generate` | (go vet) |

Also check for:
- `ARCHITECTURE_MATRIX.yaml` — call-graph constraints for Architecture Gate
- Existing `AGENTS.md`, `CLAUDE.md` — may already have commands/architecture
- `docs/architecture.md`, `docs/uml/` — architecture narrative

Record each discovered command. If a command type is not documented in
project config and no marker matches, leave as `{{PLACEHOLDER}}` — the
skill will report it for manual entry.

### 3. Gather remaining values

Ask the user only for values that cannot be inferred:

| Value | Source if not auto-detected |
|---|---|
| `PROJECT_NAME` (display name) | Required — ask |
| `PROJECT_SLUG` (package slug) | Derive from name (snake_case) |
| `APP_TITLE` | Default to project name |
| `ITERATION_NUMBER` | Default `1` |
| `ITERATION_TITLE` | Optional — ask |
| `ITERATION_PLAN_FILE` | Default `iteration_<N>_plan.md` |

Use the question tool for interactive prompts. All values passed as
flags to `init.sh -y` (non-interactive).

## Phase 1 — Scaffold

Run the bundled script with all gathered values:

```bash
bash "${SKILL_DIR}/scripts/init.sh" -y [--merge] \
  -n "${PROJECT_NAME}" \
  -a "${APP_TITLE}" \
  -s "${PROJECT_SLUG}" \
  -t "${TEST_COMMAND}" \
  -l "${LINT_COMMAND}" \
  -g "${CODEGEN_COMMAND}" \
  -c "${IMPORT_CHECK_COMMAND}" \
  -i "${ITERATION_NUMBER}" \
  -T "${ITERATION_TITLE}" \
  -p "${ITERATION_PLAN_FILE}" \
  "${TARGET_DIR}"
```

The script:
- Copies templates from `assets/`
- Strips `.template` suffixes
- Replaces every `{{TOKEN}}` with provided values
- Leaves missing values as `{{PLACEHOLDER}}`
- Prints a file tree and a grep report of remaining placeholders/TODOs

## Phase 2 — Draft TODOs with approval

For each `<!-- TODO -->` block in the generated files, explore the
repo and propose a draft. **Never invent architecture rules or domain
entities — ask the user.**

### 2.1 Architecture Gate (`AGENTS.md`)

- If `ARCHITECTURE_MATRIX.yaml` exists: read it, extract call-graph
  invariants (may_call / must_not_call), format per the template's
  example shape.
- If architecture section exists in `AGENTS.md`/`CLAUDE.md`/`docs/architecture.md`: summarize the hard invariants.
- If nothing exists: propose a starter shape based on the four-layer
  architecture in the template, but mark as "needs your architecture
  rules" — do not commit to specific flows without user input.

Present the draft. On approval, write to `AGENTS.md` (replacing the
`<!-- TODO -->` block).

### 2.2 Commands table (`AGENTS.md`)

Fill the Commands table with discovered commands. Add rows for
build/run/format/db-migrate if the project has them (check `package.json`
scripts, `Makefile`, `justfile`, `Taskfile.yml`, etc.). Ask before
adding non-canonical commands.

### 2.3 Code Generation (`AGENTS.md`)

If codegen markers exist (e.g., `build_runner`, `orval`, `openapi-generator`,
`sqlc`, `protobuf`), list each generator, what triggers a rerun, and
where generated files are excluded from analysis. If none, note "None
configured" or leave as TODO.

### 2.4 Domain Model (`AGENTS.md`)

Scan domain layer files (`domain/`, `lib/domain/`, `src/domain/`,
`models/`, `entities/` — adapt to project structure) for core entities.
Propose a one-line-per-entity glossary (name, role, key relationships).
Present for approval.

### 2.5 Current Iteration (`AGENTS.md`)

If `agents/iteration_history.md` exists and has a "Not started" or "In
progress" iteration, use that. Otherwise, ask the user for the active
iteration goal and title. Update the Current Iteration block.

### 2.6 Iteration Plan (`agents/plans/`)

If the iteration plan file exists and is a template, draft the
Executive Summary, Units of Work, and Verification Strategy by reading
`agents/iteration_history.md` for the iteration's declared
deliverables. Present for approval.

## Phase 3 — Verify

Re-run the leftover-token check across the generated files:

```bash
grep -rnE --include='*.md' -e '\{\{[A-Z_]+\}\}' -e '<!-- TODO' "${TARGET_DIR}"
```

Report any remaining placeholders or TODOs. If zero, scaffold is
complete.

## Phase 4 — Follow-ups

Print the update-cadence table from the kit's README:

| File | Update cadence |
|---|---|
| `AGENTS.md` → Current Iteration | start of every session |
| `agents/decisions.md` | at the moment a decision or answer happens |
| `agents/iteration_history.md` | when planning, and again at iteration end |
| `agents/plans/*.md` | one per iteration/track before build starts |

Suggest next steps:
- "Run the `iteration` skill to plan and execute the first iteration" (since AGENTS.md now exists)
- "Run `doc-consistency` to validate architecture docs against each other"
- "Port any project-specific rules that emerge back into this skill's assets for future projects"

## Configuration

The skill adapts to the project. Key configuration points:

| Setting | Source | Default |
|---|---|---|
| Project config file | `AGENTS.md`, `CLAUDE.md` | Auto-discovered |
| Iteration source | `agents/iteration_history.md` | Auto-discovered |
| Gate commands | Project config + marker table | Auto-detected |
| Architecture matrix | `ARCHITECTURE_MATRIX.yaml` | Optional |
| Plan output directory | `agents/plans/` | Created if needed |

## Calibration

**Fresh repo (no AGENTS.md):** Full scaffold + all TODO drafting. Estimated
time: 3–5 minutes (mostly user approval cycles).

**Existing repo with partial AGENTS.md:** Merge mode + only missing
sections. Estimated time: 1–2 minutes.

**Large existing codebase (many domain entities):** Domain Model
discovery takes longer — batch entity extraction and present in groups.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Inventing architecture rules** | The kit's Architecture Gate must reflect the project's actual invariants. Made-up rules cause false violations. Always ask. |
| **Overwriting existing AGENTS.md in merge mode** | Destroys project-specific customizations. Merge mode copies missing files only — never overwrites. |
| **Leaving placeholders silently** | Agents read AGENTS.md at session start. `{{TEST_COMMAND}}` breaks gates. Verify phase catches this. |
| **Skipping TODO drafting** | Empty Architecture Gate / Domain Model = agents operate blind. Every TODO must be resolved or explicitly deferred. |
| **Not chaining to iteration skill** | The iteration skill aborts without AGENTS.md. This skill exists to unblock it. Always suggest the next step. |

## Ground rules

- **Context injection over discovery.** The scaffolded `AGENTS.md` becomes the project config. Subsequent skills (iteration, doc-consistency) read it — they do NOT re-discover conventions.
- **House style is opinionated.** `methodology.md` and `class_comment_specification.md` are carried verbatim between projects (per their own headers). Only project-specific artifact paths may need adjusting.
- **User approval for every TODO write.** The skill proposes drafts; the user confirms. No silent writes to architectural sections.
- **Non-interactive script, interactive skill.** `init.sh -y` runs without prompts. The skill gathers values via the question tool, then passes flags. This works in agent-driven flows.
- **Keep the kit alive.** When a project evolves a rule that helps every future project, update the assets in this skill (and the skill itself if the workflow changes).