---
name: software-dev
description: >
  General-purpose software development workflows for a small full-stack
  team. Covers five core workflows: systematic debugging (reproduce →
  isolate → diagnose → fix → verify), safe refactoring (identify → plan
  → implement → verify with zero behavior change), structured code review
  (correctness → architecture → readability → testing → security), test
  strategy planning (what to test, how to test, test pyramid, coverage
  decisions), and performance investigation (measure → profile → identify
  bottleneck → optimize → verify). Each workflow has pre-flight discovery,
  phased procedures with decision points, output report formats, and
  anti-patterns. Project-agnostic: works with any language, framework, or
  team size. Invoke by natural language ("help me debug X", "refactor this
  module", "review my code", "plan tests for X", "optimize Y").
license: MIT
---

# Software Development Workflows

Five structured workflows for day-to-day software engineering. Each
workflow enforces a repeatable process so nothing is skipped under
pressure. All workflows are project-agnostic — they discover the language,
framework, and tooling at runtime.

Use when: "help me debug X", "this is broken", "refactor this", "clean up
this code", "review my PR", "review this file", "plan tests for X", "what
should I test", "this is slow", "optimize Y", "performance is bad", or
any natural-language expression of these intents.

Skip when: the user wants a quick factual answer (language syntax, API
lookup), is asking about documentation consistency (use doc-consistency),
or wants to generate diagrams (use generate-sequence).

## Pre-flight (all workflows)

Every workflow starts here. These steps discover the project's environment
so the workflow can adapt.

**Step 1. Discover project shape.**

Scan the project root and report what you find:

| What to discover | Scan patterns | Why it matters |
|---|---|---|
| Language | `**/*.py`, `**/*.ts`, `**/*.rs`, `**/*.go`, `**/*.java`, `**/*.kt`, `**/*.cs`, `**/*.rb`, `**/*.swift` | Determines test framework, linter, profiler |
| Framework | `package.json`, `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`, `Gemfile`, `requirements.txt`, `pyproject.toml`, `*.csproj` | Determines conventions, test runners |
| Test framework | `pytest.ini`, `jest.config.*`, `vitest.config.*`, `*_test.go`, `*.test.*`, `*.spec.*`, `Cargo.toml` (dev-dependencies), `.rspec` | Determines how to run/write tests |
| Linter / formatter | `.eslintrc*`, `.prettierrc*`, `ruff.toml`, `pyproject.toml` (ruff section), `.golangci.yml`, `rustfmt.toml` | Determines style enforcement |
| Build system | `Makefile`, `justfile`, `Taskfile.yml`, `package.json` scripts, `Cargo.toml`, `CMakeLists.txt` | Determines build/test commands |
| CI config | `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, `bitbucket-pipelines.yml` | Determines what checks run in CI |
| Version control | `.git/`, `.hg/`, `.svn/` | Confirms repo context |
| Existing tests | `**/test_*`, `**/*_test.*`, `**/*.test.*`, `**/*.spec.*`, `**/tests/**`, `**/test/**` | Baseline for test strategy |
| AGENTS.md / README | `AGENTS.md`, `CLAUDE.md`, `README.md`, `CONTRIBUTING.md` | Project conventions, rules |

**Step 2. Determine run commands.**

From the discovered shape, determine these commands and store them:

| Command | Source |
|---|---|
| `test` | `package.json` scripts.test, `pytest`, `cargo test`, `go test ./...`, `make test` |
| `lint` | `package.json` scripts.lint, `ruff check`, `cargo clippy`, `golangci-lint run`, `make lint` |
| `format` | `package.json` scripts.format, `ruff format`, `cargo fmt`, `gofmt`, `make fmt` |
| `typecheck` | `tsc --noEmit`, `mypy`, `cargo check`, `go vet` |
| `build` | `package.json` scripts.build, `cargo build`, `go build`, `make build` |

If you cannot determine a command, ask the user. Do not guess.

**Step 3. Verify the baseline passes.**

Before any workflow begins, confirm the project compiles/lints cleanly:

1. Run the linter. If it fails, report the failures and ask whether to fix
   them first or proceed despite lint noise.
2. Run the type checker (if available). Same decision.
3. Run the existing test suite. Record pass/fail counts. If tests fail
   before you start, that is baseline — note it but do not block.

**Step 4. Load project conventions.**

Read `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, or any coding standards
document. Extract:

- Naming conventions (camelCase, snake_case, PascalCase)
- File organization pattern (feature-first, layer-first, etc.)
- Commit message format
- Branch naming
- PR description template
- Test file naming and location conventions

If no conventions document exists, infer from existing code: read 3-5
representative files and note the patterns.

---

## Workflow 1 — Debugging

Systematic debugging: reproduce → isolate → diagnose → fix → verify.
Follows the scientific method — form hypotheses, test them, never skip to
"looks like the fix."

### When to use

"help me debug X", "this is broken", "getting error Y", "something is
wrong with Z", "it worked before but now it doesn't", any bug report.

### Pre-flight

Complete the all-workflows pre-flight (above), then:

**Step D0. Classify the bug.**

| Type | Signal | First move |
|---|---|---|
| **Reproducible crash** | Stack trace, error message, segfault | Read the stack trace bottom-up |
| **Incorrect output** | Expected X, got Y | Write an assertion that captures expected vs actual |
| **Intermittent failure** | Fails sometimes, passes sometimes | Check race conditions, timing, shared state |
| **Regression** | Worked in version N, broken in N+1 | `git bisect` between known-good and known-bad |
| **Environment-specific** | Works on machine A, fails on machine B | Compare environment variables, OS, dependency versions |
| **Performance degradation** | Was fast, now slow | Compare profiles between versions |
| **Silent failure** | No error, but data/state is wrong | Add assertions and logging, trace data flow |

### Phase 1 — Reproduce

**Step D1.1. Establish the minimal reproduction.**

The goal is the smallest set of inputs and actions that triggers the bug.
Never debug a large system when a 10-line script can reproduce it.

| Approach | When to use |
|---|---|
| **Write a failing test** | Bug has clear expected/actual behavior |
| **Write a script** | Bug involves environment, configuration, or data |
| **Manual steps** | Bug requires UI interaction or multi-system coordination |
| **Bisect** | Regression with unknown cause |

**Step D1.2. Capture the reproduction.**

Document in a structured format:

```
Bug: [one-line description]
Reproduction:
  1. [step]
  2. [step]
  3. [step]
Expected: [what should happen]
Actual: [what actually happens]
Environment: [language version, OS, relevant config]
Error output: [exact error, if any]
```

**Decision point:** If you cannot reproduce the bug, do not proceed.
Common reasons and fixes:

| Cannot reproduce because | Fix |
|---|---|
| Race condition | Add synchronization, increase sample size, run in loop |
| Environment mismatch | `docker run` with the same image, or match exact versions |
| Data-dependent | Get the exact data that triggers it (copy from prod/staging) |
| Timing-dependent | Slow down the system (delays, throttling) or speed it up (batching) |

### Phase 2 — Isolate

**Step D2.1. Binary search the problem space.**

Narrow the scope systematically. Never guess.

| Strategy | How |
|---|---|
| **Divide and conquer** | Comment out half the code path. Does the bug still appear? Binary search until you find the region. |
| **Git bisect** | `git bisect start`, `git bisect bad`, `git bisect good <commit>`, let it find the introducing commit. |
| **Input bisection** | Simplify inputs until the bug disappears. The last change that removed it is the trigger. |
| **Dependency isolation** | Remove/disable dependencies one at a time. |
| **Flag diacritics** | Add feature flags to toggle code paths. |

**Step D2.2. Form hypotheses.**

After narrowing to a region, form exactly 3 hypotheses about the root
cause. For each:

1. State the hypothesis in one sentence
2. State the test that would confirm or refute it
3. State the expected outcome of the test

| Hypothesis | Test | Expected if true |
|---|---|---|
| Null pointer in `parse()` | Add null check before line 42 | Error moves or disappears |
| Race condition in cache | Add mutex around cache access | Bug disappears |
| Wrong enum value | Log the enum value at entry | Value is unexpected member |

**Step D2.3. Add diagnostic instrumentation.**

Before fixing, add targeted logging or assertions to confirm the
hypothesis:

- Log the value of key variables at decision points
- Add assertions for invariants that should hold
- Use `console.log`, `println!`, `print()`, `fmt.Println()`, or the
  project's logging framework
- Prefer structured logging (key=value) over free-text

**Decision point:** After instrumentation, re-run the reproduction. If the
hypothesis is confirmed, proceed to Phase 3. If all 3 hypotheses are
refuted, return to Phase 2 with new hypotheses. If the bug disappears
after adding logging, it is likely a race condition or memory issue.

### Phase 3 — Diagnose

**Step D3.1. Trace the root cause.**

Follow the evidence from Phase 2 to the exact line(s) of code:

1. Identify the first point where the state diverges from expected
2. Trace backward: what set that state? What called that function?
3. Trace forward: what does this corrupt state affect?

**Step D3.2. Understand the "why."**

The bug is not just the wrong line — it is the condition that allowed the
wrong line to execute:

| Root cause category | Example | Fix pattern |
|---|---|---|
| **Missing null check** | Input can be null, code assumes non-null | Add guard clause |
| **Race condition** | Shared mutable state without synchronization | Add lock, use immutable data, or restructure |
| **Off-by-one** | Array index, loop bound, range | Fix the boundary |
| **Incorrect assumption** | Code assumes input is sorted, it is not | Validate assumption or handle unsorted case |
| **State leak** | Previous operation's state bleeds into next | Reset state, use fresh instances |
| **Configuration error** | Default value wrong, env var missing | Fix config, add validation |
| **Dependency version mismatch** | API changed between versions | Pin version, update code for new API |
| **Concurrency bug** | Multiple threads/goroutines corrupt shared state | Synchronize, isolate, or redesign |

### Phase 4 — Fix

**Step D4.1. Write the minimal fix.**

The fix should be as small as possible. Prefer adding a guard clause over
rewriting a function. Prefer fixing the input over restructuring the logic.

**Step D4.2. Check for the fix being worse than the bug.**

| Risk | Check |
|---|---|
| Fix introduces new edge case | Does the fix handle null, empty, negative, boundary values? |
| Fix breaks other code paths | Are there callers that depend on the current (broken) behavior? |
| Fix masks the symptom not the cause | Does the fix prevent the error, or just suppress it? |
| Fix has performance implications | Is the fix adding a lock, copy, or allocation in a hot path? |

**Step D4.3. Write a regression test.**

Before applying the fix, ensure you have a test that fails. After applying
the fix, ensure it passes. The test should:

1. Capture the exact reproduction from Phase 1
2. Assert the expected (correct) behavior
3. Be named descriptively: `test_<what>_does_not_<the_bug>`

### Phase 5 — Verify

**Step D5.1. Run the full test suite.**

```
<test_command>
```

All existing tests must still pass. If any fail, the fix has a regression.

**Step D5.2. Run the linter and type checker.**

```
<lint_command>
<typecheck_command>
```

**Step D5.3. Verify the original reproduction no longer triggers the bug.**

Re-run the minimal reproduction from Phase 1. Confirm the bug is gone.

**Step D5.4. Manual smoke test (if applicable).**

If the bug was in a UI path or integration point, manually verify the fix
in the affected area.

### Debugging output

```markdown
# Debug Report

**Bug:** [one-line description]
**Severity:** [Critical / High / Medium / Low]
**Root cause category:** [from Phase 3 table]

## Reproduction
[Structured reproduction from Phase 1]

## Root cause
[Exact file(s) and line(s)]
[Why the bug occurred — the condition, not just the line]

## Fix
[What was changed and why]
[Regression test added]

## Verification
- [ ] Reproduction no longer triggers bug
- [ ] Full test suite passes
- [ ] Linter passes
- [ ] Type checker passes

## Risk assessment
- Other code paths affected: [yes/no, which ones]
- Edge cases covered: [list]
- Performance impact: [none / measured / concern]
```

### Debugging anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Skipping reproduction** | You cannot verify a fix for a problem you cannot reproduce. Always reproduce first. |
| **Guessing without evidence** | Changing random lines "because it might be there" wastes time and introduces regressions. Form hypotheses and test them. |
| **Fixing the symptom** | Adding a `try/catch` that swallows the error does not fix the cause. Trace to the root. |
| **Not writing a regression test** | The bug will return. A regression test is the cheapest insurance. |
| **Debugging in production** | Add logging and assertions in a dev environment first. Production debugging is a last resort. |
| **Ignoring the error message** | The error message is the first clue. Read it. Follow the stack trace. |
| **Changing multiple things at once** | If you change 3 lines and the bug is gone, you do not know which change fixed it — or if you introduced a new bug that coincidentally masks the old one. One change at a time. |
| **Not checking git history** | `git log`, `git blame`, `git bisect` exist. Use them. The introducing commit often makes the cause obvious. |

---

## Workflow 2 — Refactoring

Safe refactoring: identify → plan → implement → verify. Zero behavior
change — the code does exactly what it did before, just structured
differently.

### When to use

"refactor this", "clean up this code", "extract this into a function",
"this function is too long", "move this class", "rename this", "this is
hard to read", any structural improvement that does not change behavior.

### Pre-flight

Complete the all-workflows pre-flight, then:

**Step R0. Confirm the baseline.**

1. Run the full test suite. Record pass/fail counts.
2. If test coverage is low (< 60% on the target code), STOP. Tell the
   user: "This code has insufficient test coverage for safe refactoring.
   Write tests first (use the Test Strategy workflow), then refactor."
3. If no tests exist for the target code, STOP. Same message.

### Phase 1 — Identify

**Step R1.1. Scan the target for refactoring signals.**

| Signal | Meaning | Refactoring type |
|---|---|---|
| Function > 30 lines | Does too much | Extract function |
| Function > 3 parameters | Hard to call correctly | Introduce parameter object |
| Nested conditionals (> 2 levels) | Hard to follow | Decompose conditional, early return |
| Duplicated code (> 3 instances) | Maintenance burden | Extract function / Extract class |
| God class (> 200 lines) | Too many responsibilities | Extract class |
| Long chain: `a.b().c().d()` | Tight coupling | Move method, introduce facade |
| Magic numbers / strings | Unclear meaning | Extract constant |
| Dead code | Noise | Delete |
| Primitive obsession | Using primitives where a type would clarify | Introduce value object |
| Feature envy | Method uses another class's data more than its own | Move method |

**Step R1.2. Prioritize by impact.**

For each identified signal, rate:

| Criterion | Weight | Score (1-5) |
|---|---|---|
| Readability improvement | 0.3 | How much clearer will the code be? |
| Bug risk reduction | 0.3 | How much does this reduce the chance of future bugs? |
| Testability improvement | 0.2 | Does this make the code easier to test? |
| Effort | 0.2 | How much work is this? (inverse: 5 = trivial, 1 = massive) |

Compute weighted score. Rank. Top 3 are candidates.

### Phase 2 — Plan

**Step R2.1. For each candidate, define the refactoring recipe.**

| Step | What to document |
|---|---|
| **Before** | Current structure (function signature, class shape, code snippet) |
| **After** | Target structure |
| **Steps** | Numbered sequence of atomic moves (each one compiles and passes tests) |
| **Files touched** | Every file that changes |
| **Risk** | What could go wrong |

**Step R2.2. Verify atomicity.**

Each step in the recipe must:

1. Compile / type-check cleanly
2. Pass all existing tests
3. Be reversible (you can undo it without affecting other steps)

If a step fails any of these, split it into smaller steps.

**Decision point:** Present the plan to the user. The user may:

- **Approve:** Proceed to Phase 3.
- **Modify:** Change scope, reorder steps, or split into multiple PRs.
- **Defer:** Not now — record the refactoring as tech debt with priority.

### Phase 3 — Implement

**Step R3.1. Apply changes atomically.**

Work through the plan step by step. After each step:

1. Run the linter
2. Run the type checker
3. Run the test suite

If any step fails, revert it immediately. Do not accumulate failures.

**Step R3.2. Handle common refactoring patterns.**

**Extract function:**
1. Identify the block to extract
2. Determine inputs (parameters) and outputs (return value)
3. Create the new function with a clear name
4. Replace the block with a call to the new function
5. Run tests

**Extract class:**
1. Identify the responsibilities to extract
2. Create the new class
3. Move the methods and their data
4. Update the original class to delegate to the new one
5. Run tests

**Rename:**
1. Ensure the rename is safe (no string interpolation, reflection, dynamic dispatch)
2. Use IDE/tool rename if available
3. Rename at all call sites simultaneously
4. Run tests

**Introduce parameter object:**
1. Create the parameter class/struct
2. Change the function signature to accept it
3. Update all callers to construct the parameter
4. Run tests

**Step R3.3. Preserve the public interface.**

The refactoring must not change:

- Function/method signatures visible to callers
- Return types
- Exception/error types thrown
- Observable side effects (file I/O, network calls, logging)
- Public class API

If you need to change a public interface, that is not refactoring — that
is a redesign. Stop and discuss with the user.

### Phase 4 — Verify

**Step R4.1. Full regression check.**

1. Run the complete test suite — must pass with identical results to
   pre-refactoring baseline
2. Run the linter — no new warnings
3. Run the type checker — no new errors
4. Verify no new files were added (unless the plan called for it)
5. Verify no files were deleted (unless the plan called for it)

**Step R4.2. Diff review.**

Review the diff to confirm:

- No behavior changes (no new `if` branches, no changed logic, no
  altered control flow)
- No accidental inclusion of unrelated changes
- Comments and documentation updated to reflect new structure
- Naming is clear and consistent

**Step R4.3. Confirm test coverage maintained.**

If the project has coverage reporting, run it and compare before/after.
Coverage should be identical or improved. If coverage dropped, add tests
for the newly extracted functions.

### Refactoring output

```markdown
# Refactoring Report

**Target:** [file/module name]
**Refactoring type:** [from Phase 1 table]
**Impact score:** [weighted score from prioritization]

## Plan
[Numbered steps from Phase 2]

## Changes
| File | Lines changed | Description |
|---|---|---|
| file.ts:10-25 | 15 lines → 3 lines (original) + 12 lines (new function) | Extracted `parseConfig()` |

## Verification
- [ ] All tests pass (N/N)
- [ ] Linter passes
- [ ] Type checker passes
- [ ] No behavior change (diff review)
- [ ] Coverage maintained (X% before → Y% after)
```

### Refactoring anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Refactoring without tests** | You have no safety net. A test suite that covers the target code is the minimum viable safety net. Without it, you are guessing. |
| **Refactoring and fixing a bug at the same time** | If the code still breaks after your refactor, you do not know if you introduced a new bug or if the old bug persists. Refactor first, fix second. Two commits, two PRs. |
| **Refactoring with behavior changes** | If the code does something different after, it is not refactoring — it is a feature change. Call it what it is. |
| **Big-bang refactoring** | Rewriting an entire module in one shot has no rollback path. Break it into small, independently verifiable steps. |
| **Premature abstraction** | Extracting a reusable function from two call sites is too early. Wait for three instances before abstracting. Two is coincidence; three is a pattern. |
| **Renaming without tooling** | Manual rename across a codebase is error-prone. Use IDE rename, `rg` + `sed`, or AST-aware tools. |
| **Ignoring the diff** | After refactoring, review the diff line by line. Accidental behavior changes hide in refactors. |

---

## Workflow 3 — Code Review

Structured review: correctness → architecture → readability → testing →
security. Review the code, not the coder.

### When to use

"review my code", "review this PR", "look at this file", "what do you
think of this change", "review my changes", any code review request.

### Pre-flight

Complete the all-workflows pre-flight, then:

**Step CR0. Understand the change.**

1. Read the PR description / commit message
2. Identify the files changed
3. Identify the type of change (feature, bugfix, refactor, test, config)

### Phase 1 — Correctness

Does the code do what it claims to do?

**Step CR1.1. Verify against the stated goal.**

| Check | What to look for |
|---|---|
| **Goal match** | Does the code accomplish the stated objective in the PR/commit? |
| **Logic correctness** | Are conditionals correct? Are edge cases handled? |
| **Boundary conditions** | Off-by-one, empty arrays, null values, zero divisions |
| **Error handling** | Are errors caught, logged, and handled (not swallowed)? |
| **State management** | Is state initialized correctly? Are mutations intentional? |
| **Concurrency** | Are shared resources accessed safely? Races, deadlocks? |
| **Resource management** | Are files, connections, locks released? Defers, try/finally? |

**Step CR1.2. Trace the critical path.**

For the main code path the change affects:

1. What are the inputs?
2. What transformations happen?
3. What are the outputs?
4. What happens on each error path?

Walk through with concrete values. If a path is hard to trace, flag it.

### Phase 2 — Architecture

Does the code fit the project's architecture?

**Step CR2.1. Check layer boundaries.**

| Violation | Example | Severity |
|---|---|---|
| Presentation calls infrastructure directly | UI component imports database module | Blocking |
| Domain depends on framework | Entity imports ORM decorator | Blocking |
| Feature A imports feature B internals | Feature module imports another feature's private function | Risky |
| Circular dependency | Module A imports B, B imports A | Blocking |

**Step CR2.2. Check design patterns.**

| Pattern | Check |
|---|---|
| Dependency injection | Are dependencies passed in, not created internally? |
| Single responsibility | Does the module/class do one thing? |
| Interface segregation | Are interfaces minimal and focused? |
| Composition over inheritance | Is composition used where inheritance is not necessary? |

**Step CR2.3. Check consistency with existing patterns.**

Does the new code follow the same patterns as the surrounding code?

- Same error handling pattern (Result types, exceptions, error codes)
- Same logging pattern (same logger, same level conventions)
- Same naming pattern (same verb prefixes, same casing)
- Same file organization (same directory, same module structure)

### Phase 3 — Readability

Can a new team member understand this code in one read?

**Step CR3.1. Assess naming.**

| Check | Standard |
|---|---|
| Variable names describe contents | No `d`, `tmp`, `x`, `data` unless scope is tiny |
| Function names describe action | Verb + noun: `parseConfig`, `validateInput`, `sendAlert` |
| Boolean names are predicates | `isActive`, `hasPermission`, `canExport` — not `active`, `permission`, `export` |
| No magic numbers or strings | Constants with meaningful names |
| Consistent naming within the file | Not `getConfig` in one place and `fetchConfig` in another for the same operation |

**Step CR3.2. Assess structure.**

| Check | Standard |
|---|---|
| Functions are short | < 30 lines preferred, < 50 lines acceptable |
| Functions do one thing | If you need "and" to describe what a function does, split it |
| Nesting depth | < 3 levels. Flatten with early returns or extraction |
| Comments explain "why" not "what" | Code should be self-documenting. Comments explain non-obvious decisions |
| No dead code | Unused variables, unreachable branches, commented-out code |

**Step CR3.3. Assess documentation.**

| Element | Required? |
|---|---|
| Function docstring/JSDoc | Required for public API, optional for private |
| Complex algorithm explanation | Required — do not leave algorithms undocumented |
| TODO with issue link | Required for known shortcuts |
| README update | Required if the change affects usage or setup |

### Phase 4 — Testing

Is the change adequately tested?

**Step CR4.1. Check test coverage of the change.**

| Check | Standard |
|---|---|
| New code has tests | Every new function/method has at least one test |
| Edge cases tested | Null, empty, boundary, error paths |
| Existing tests updated | If existing behavior changed, tests were updated |
| Test names are descriptive | `test_parseConfig_returnsError_onInvalidJson` not `test_parse` |

**Step CR4.2. Check test quality.**

| Check | What to look for |
|---|---|
| **Arrange-Act-Assert** | Each test has clear setup, execution, and assertion phases |
| **One assertion per concept** | Tests do not assert 10 unrelated things |
| **No test interdependence** | Tests pass in any order, do not share mutable state |
| **No flaky assertions** | No timing-dependent, order-dependent, or environment-dependent assertions |
| **Mocking is minimal** | Mock the boundary (network, database), not internal functions |

### Phase 5 — Security

Does the change introduce security risks?

**Step CR5.1. Check common vulnerability patterns.**

| Vulnerability | Check |
|---|---|
| **Injection** | Is user input interpolated into queries, commands, or HTML without escaping? |
| **Authentication bypass** | Are auth checks present on all protected endpoints? |
| **Authorization bypass** | Does the code check permissions, not just authentication? |
| **Secrets in code** | Are API keys, passwords, tokens hardcoded? Should be env vars or secret manager. |
| **Dependency risk** | Are new dependencies reputable? Pinned versions? |
| **Data exposure** | Are sensitive fields logged, returned in API responses, or stored unencrypted? |
| **CSRF / XSS** | Are user inputs sanitized before rendering? Are CSRF tokens validated? |
| **Path traversal** | Are file paths validated against directory boundaries? |

**Step CR5.2. Check data handling.**

| Check | What to look for |
|---|---|
| Input validation | All external inputs validated at the boundary |
| Output encoding | All output encoded for the target context (HTML, SQL, shell) |
| Secrets rotation | No hardcoded secrets; env vars or vault |
| Logging safety | No secrets, PII, or tokens in logs |

### Code review output

```markdown
# Code Review Report

**Change:** [PR title / commit message]
**Files reviewed:** [count]
**Lines changed:** [+N / -M]

## Summary

| Category | Verdict |
|---|---|
| Correctness | Pass / Changes requested |
| Architecture | Pass / Changes requested |
| Readability | Pass / Changes requested |
| Testing | Pass / Changes requested |
| Security | Pass / Changes requested |

## Findings

### [BLOCKING] Short description

- **File:** `path/to/file.ext:42`
- **Issue:** [what is wrong]
- **Fix:** [how to fix it]

### [RISKY] Short description

- **File:** `path/to/file.ext:87`
- **Issue:** [what might be wrong]
- **Suggestion:** [alternative approach]

### [NITS] Short description

- **File:** `path/to/file.ext:12`
- **Issue:** [minor style/readability concern]

## Approval

- [ ] Approved (no blocking issues)
- [ ] Approved with suggestions (risky issues noted, not blocking)
- [ ] Changes requested (blocking issues must be addressed)
```

### Code review anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Rubber-stamping** | Approving without reading. The review exists to catch issues. Read every line. |
| **Style-only reviews** | Catching whitespace and naming while missing logic bugs. Correctness first, style last. |
| **Reviewing the coder** | "You always do X" is not a review comment. Review the code, not the person. |
| **Nitpicking trivial issues on large PRs** | If a PR is 500+ lines, focus on correctness and architecture. Nits can be addressed with a formatter. |
| **Not testing locally** | If the PR adds a CLI command or API endpoint, run it. Do not review blind. |
| **Blocking on preferences** | "I would have named it differently" is not a blocking issue unless the naming violates project conventions. |
| **Reviewing too late** | Review within 24 hours. Stale reviews waste everyone's time. |
| **Scope creep in review** | Review the change as presented. Do not demand architectural rewrites in a bugfix PR. |

---

## Workflow 4 — Test Strategy

Test planning: what to test, how to test, test pyramid, coverage decisions.
Every codebase has different risk profiles — the test strategy reflects that.

### When to use

"plan tests for X", "what should I test", "how should I test this",
"write a test plan", "review my test coverage", any test planning intent.

### Pre-flight

Complete the all-workflows pre-flight, then:

**Step TS0. Assess the current test state.**

| Metric | How to determine | Why it matters |
|---|---|---|
| Test count | `find . -name "*.test.*" \| wc -l` or equivalent | Baseline volume |
| Coverage percentage | Project coverage tool output | Current safety net |
| Test types present | Scan test files for unit, integration, e2e patterns | What layer is covered |
| Test framework | From pre-flight | Determines syntax and capabilities |
| Untested areas | Coverage gaps, files with no corresponding test file | Target prioritization |

### Phase 1 — Analyze the target

**Step TS1.1. Identify the code to be tested.**

| Element | What to extract |
|---|---|
| Public API surface | All exported functions, classes, methods |
| Data transformations | Functions that take input and produce output |
| Side effects | Functions that modify external state (DB, files, network) |
| Business rules | Domain logic, validations, calculations |
| Error paths | What can fail, how it fails, what the caller should do |
| Edge cases | Null, empty, boundary, concurrent, large inputs |

**Step TS1.2. Classify by risk.**

| Risk level | Characteristics | Test priority |
|---|---|---|
| **Critical** | Financial transactions, auth, data integrity, safety | Highest — comprehensive tests |
| **High** | Core business logic, data transformations, API contracts | High — thorough unit + integration |
| **Medium** | UI components, reporting, non-critical features | Medium — key paths |
| **Low** | Utilities, helpers, logging, config | Low — happy path + key edge cases |

### Phase 2 — Design the test plan

**Step TS2.1. Apply the test pyramid.**

For the target module, determine the right mix:

```
         /\
        / E2E \         Few: critical user journeys only
       /--------\
      / Integration \    Moderate: API contracts, DB queries, service boundaries
     /----------------\
    /    Unit Tests     \  Many: pure logic, data transformations, edge cases
   /--------------------\
```

| Layer | What to test | Quantity | Speed |
|---|---|---|---|
| **Unit** | Individual functions/methods in isolation | Many (60-70% of tests) | Fast (< 10ms each) |
| **Integration** | Multiple components working together | Moderate (20-30%) | Medium (< 1s each) |
| **End-to-end** | Full user journey through the system | Few (5-10%) | Slow (seconds to minutes) |

**Decision point:** Adjust the pyramid based on the project:

| If the project is... | Then shift toward... |
|---|---|
| Library / SDK | More unit tests, fewer integration tests |
| API service | More integration tests (API contract tests), moderate unit |
| Frontend application | More integration tests (component tests), moderate unit |
| Data pipeline | More unit tests on transformations, integration tests on E2E data flow |
| Infrastructure / DevOps | More integration tests (Terraform plan, Docker build), fewer unit |

**Step TS2.2. Design unit test cases.**

For each public function/method, design tests covering:

| Test category | Example |
|---|---|
| **Happy path** | Normal inputs produce expected output |
| **Edge cases** | Empty input, zero, null, max value, min value |
| **Boundary conditions** | Off-by-one, overflow, underflow |
| **Error cases** | Invalid input types, missing required fields, out of range |
| **State transitions** | If the function modifies state, test before/after |
| **Idempotency** | If calling twice should produce the same result, test it |
| **Concurrency** | If shared state is involved, test concurrent access |

For each test case, document:

```
Test: [descriptive name]
Input: [concrete input values]
Expected output: [concrete expected output]
Preconditions: [any setup required]
Category: [happy path / edge case / error case / ...]
```

**Step TS2.3. Design integration test cases.**

| Integration boundary | What to test |
|---|---|
| **API endpoint → handler → DB** | Request produces correct DB state and response |
| **Service → external API** | Correct request format, handles response/errors |
| **Module A → Module B** | Contract between modules: A sends what B expects |
| **DB query → result mapping** | Query returns expected data, mapping handles nulls |

Use test doubles (mocks, stubs) at system boundaries (network, filesystem,
clock). Do not mock internal module boundaries — that defeats the purpose
of integration tests.

**Step TS2.4. Design E2E test cases (if applicable).**

Limit E2E to critical user journeys:

| Journey | What to cover |
|---|---|
| **Create flow** | User creates a new entity end-to-end |
| **Read flow** | User retrieves and views data |
| **Update flow** | User modifies existing data |
| **Delete flow** | User removes data |
| **Error recovery** | User encounters an error and recovers |

### Phase 3 — Coverage decisions

**Step TS3.1. Set coverage targets.**

| Area | Target | Rationale |
|---|---|---|
| **Critical paths** | 90%+ | Cannot afford regressions in core logic |
| **Business logic** | 80%+ | Domain correctness matters |
| **API layer** | 70%+ | Contract correctness |
| **UI components** | 60%+ | Key interactions, not every pixel |
| **Utilities** | 50%+ | Lower risk, simpler code |

**Step TS3.2. Decide what NOT to test.**

| Skip testing | Why |
|---|---|
| Framework internals | Trust the framework; test your code's use of it |
| Simple getters/setters | No logic to test |
| Third-party library behavior | Tested by the library maintainers |
| Configuration files | Unless they contain logic |
| Exact formatting of logs | Unless log format is a contract |

### Phase 4 — Output the test plan

**Step TS4.1. Generate the test plan document.**

```markdown
# Test Plan — [module/feature name]

## Scope
[What is being tested]
[What is explicitly NOT being tested]

## Test Pyramid
| Layer | Count | Coverage target |
|---|---|---|
| Unit | ~N | X% |
| Integration | ~M | Y% |
| E2E | ~K | Z% |

## Unit Tests

### [function_name_1]
| # | Test name | Category | Input | Expected |
|---|---|---|---|---|
| 1 | test_normal_input | happy path | `{"key": "value"}` | `Result.ok(parsed)` |
| 2 | test_empty_input | edge case | `{}` | `Result.err(ValidationError)` |
| 3 | test_null_field | error | `{"key": null}` | `Result.err(ValidationError)` |

### [function_name_2]
...

## Integration Tests

### [boundary_1]
| # | Test name | What it tests | Setup |
|---|---|---|---|
| 1 | test_create_via_api | POST creates DB record | Empty DB |
| 2 | test_concurrent_create | Two POSTs do not duplicate | Empty DB |

## E2E Tests (if applicable)

### [journey_1]
| # | Test name | Steps | Expected |
|---|---|---|---|
| 1 | test_full_create_flow | login → create → verify | Entity visible in list |

## Test Infrastructure
| Tool | Purpose |
|---|---|
| [framework] | Test runner |
| [mock library] | Test doubles |
| [coverage tool] | Coverage reporting |

## Risks
| Risk | Mitigation |
|---|---|
| Flaky external API in integration tests | Use test doubles at API boundary |
| Slow E2E tests | Run in CI only, parallelize |
| Low coverage on legacy code | Incremental: cover new changes first |
```

### Test strategy anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Testing implementation details** | Tests that assert internal method calls break when you refactor. Test outputs, not internals. |
| **100% coverage obsession** | Chasing the last 10% tests trivia while core logic may be under-tested. Target coverage by risk, not by percentage. |
| **Tests that depend on execution order** | Tests must be independent. Shared mutable state between tests creates invisible coupling. |
| **Assertion-free tests** | Tests that run code but do not assert anything test nothing. Every test must assert an expected outcome. |
| **Testing the framework** | Writing tests that verify React renders a div, or that Express routes to a handler. Test your logic, not the framework's. |
| **Snapshot tests for everything** | Snapshots catch any change, not just wrong changes. Use targeted assertions for business logic. |
| **Ignoring error paths** | Happy path tests give false confidence. The most important bugs live in error handling. |
| **Test-after-only** | Writing tests only after code is "done" means the tests confirm the current behavior, not the intended behavior. Write tests before or alongside. |
| **Too many mocks** | Mocking everything isolates the test from reality. The test passes but the integration is untested. Mock boundaries, not internals. |

---

## Workflow 5 — Performance

Performance investigation: measure → profile → identify bottleneck →
optimize → verify. Never optimize without measuring first.

### When to use

"this is slow", "optimize Y", "performance is bad", "response time is
high", "memory usage is high", "CPU is pegged", any performance concern.

### Pre-flight

Complete the all-workflows pre-flight, then:

**Step P0. Define "slow."**

| Metric | Target | Measurement |
|---|---|---|
| **Latency** | [e.g., < 200ms p95] | Time from request to response |
| **Throughput** | [e.g., > 1000 req/s] | Requests processed per second |
| **Memory** | [e.g., < 512MB RSS] | Resident set size |
| **CPU** | [e.g., < 80% sustained] | CPU utilization |
| **Startup time** | [e.g., < 2s] | Time from launch to ready |
| **Bundle size** | [e.g., < 200KB gzip] | Download size for web assets |
| **Disk I/O** | [e.g., < 10ms write] | Write latency |

If the user cannot quantify "slow," help them measure before proceeding.

### Phase 1 — Measure

**Step P1.1. Establish a baseline.**

Before optimizing, capture the current state:

1. Run the target operation with realistic inputs
2. Measure the metric (latency, memory, CPU)
3. Record: input size, measurement method, result
4. Repeat 5 times and take the median (eliminate outliers)

**Step P1.2. Set up measurement infrastructure.**

| Tool category | Examples by language |
|---|---|
| **Built-in profiler** | `go tool pprof`, `cargo profiler`, `python -m cProfile`, `node --prof`, `jprof`, `dotnet-trace` |
| **Benchmark framework** | `cargo bench`, `go test -bench`, `pytest-benchmark`, `vitest bench`, `JMH` |
| **Memory profiler** | `valgrind`, `heaptrack`, `trufflehog`, `memray`, `dotnet-memory` |
| **Flame graph generator** | `go tool pprof -http`, `cargo-flamegraph`, `py-spy`, `0x` |
| **Application APM** | `dd-trace`, `newrelic`, `opentelemetry`, `perfetto` |
| **Simple timing** | `console.time()`, `time.perf_counter()`, `Instant::now()`, `System.nanoTime()` |

**Step P1.3. Create a repeatable benchmark.**

The benchmark must be:

- **Repeatable:** Same inputs, same result (within noise)
- **Realistic:** Use production-like data volumes and patterns
- **Isolated:** No external dependencies (network, DB) unless those are
  what you are measuring
- **Automated:** Script it so you can re-run after optimization

```
Benchmark: [operation name]
Input: [size, shape, characteristics]
Environment: [machine spec, OS, language version]
Metric: [what is being measured]
Baseline: [median of 5 runs]
```

### Phase 2 — Profile

**Step P2.1. Run the profiler.**

| If the bottleneck is suspected in... | Use |
|---|---|
| **CPU-bound code** | CPU profiler, flame graph |
| **Memory allocation** | Memory profiler, allocation tracing |
| **I/O (disk, network)** | I/O profiler, strace/dtrace, network trace |
| **Concurrency** | Lock contention profiler, thread analyzer |
| **Startup** | Startup profiler, lazy loading analysis |

**Step P2.2. Read the profile.**

From the profiler output, extract:

| Metric | What it tells you |
|---|---|
| **Hot path** | The function(s) consuming the most CPU time |
| **Allocation hotspots** | Where the most memory is allocated |
| **Lock contention** | Where threads are waiting on each other |
| **I/O wait** | Where the program is blocked on I/O |
| **Call count** | Which functions are called most often |

### Phase 3 — Identify bottleneck

**Step P3.1. Apply the 80/20 rule.**

Find the 20% of code causing 80% of the slowness. Focus there first.

| Bottleneck type | Signature | Common cause |
|---|---|---|
| **Algorithmic** | CPU time grows faster than linear with input size | O(n²) or worse algorithm on large data |
| **N+1 query** | Many database/API calls in a loop | Missing batch loading, no eager loading |
| **Unnecessary allocation** | Memory profile shows large transient allocations | Creating objects in hot paths, string concatenation |
| **Lock contention** | Thread profiler shows threads waiting | Too-fine locking, shared lock in concurrent path |
| **I/O in critical path** | High I/O wait time | Synchronous I/O that could be async or batched |
| **Redundant computation** | Same expensive calculation repeated | Missing memoization/caching |
| **Large payload** | Network transfer is slow | Sending too much data, no pagination, no compression |
| **Cold cache** | First request slow, subsequent requests fast | Cache not warmed, no default cache |

**Step P3.2. Quantify the bottleneck.**

For the identified bottleneck:

1. Measure its contribution to total time (e.g., "70% of request time is
   in `parseCSV()`")
2. Measure its frequency (e.g., "called 500 times per request")
3. Calculate the theoretical speedup (e.g., "if we halve its cost, total
   time drops 35%")

**Decision point:** Is the bottleneck worth optimizing?

| If the bottleneck is... | Then... |
|---|---|
| < 5% of total time | Not worth optimizing. Move on. |
| 5-20% of total time | Worth it if the fix is simple. |
| 20-50% of total time | Definitely worth optimizing. |
| > 50% of total time | Critical. Must fix. |

### Phase 4 — Optimize

**Step P4.1. Choose the optimization strategy.**

| Bottleneck type | Strategy | Example |
|---|---|---|
| **Algorithmic** | Replace with a more efficient algorithm | O(n²) sort → O(n log n) sort |
| **N+1 query** | Batch the queries, use eager loading | 100 queries → 1 query with JOIN |
| **Unnecessary allocation** | Reuse objects, use builders, reduce copies | String concat → StringBuilder |
| **Lock contention** | Reduce lock scope, use lock-free structures | Coarse lock → fine lock → lock-free |
| **I/O in critical path** | Async I/O, batching, caching, pipelining | Synchronous DB call → async with pipeline |
| **Redundant computation** | Memoize, cache, precompute | Recompute → LRU cache |
| **Large payload** | Paginate, compress, field selection | Return all fields → return requested fields |
| **Cold cache** | Cache warming, preloading, default values | Cache warming on startup |

**Step P4.2. Apply one optimization at a time.**

1. Make one change
2. Re-run the benchmark
3. Record the improvement (or regression)
4. If improved, keep it. If not, revert.
5. Repeat

**Step P4.3. Check for trade-offs.**

| Optimization | Common trade-off |
|---|---|
| Caching | Memory usage increases, stale data risk |
| Batching | Latency may increase (waiting for batch), throughput increases |
| Async | Complexity increases, error handling harder |
| Compression | CPU cost of compression, decompression latency |
| Indexing | Write performance decreases, storage increases |
| Lazy loading | First access latency increases |

Document the trade-off and ensure the user is aware.

### Phase 5 — Verify

**Step P5.1. Re-run the benchmark.**

Compare before and after:

```
Benchmark: [operation name]
Before: [median] ms (p50: [X], p95: [Y], p99: [Z])
After:  [median] ms (p50: [X], p95: [Y], p95: [Z])
Improvement: [N]% faster
```

**Step P5.2. Verify correctness.**

The optimization must not change behavior:

1. Run the full test suite — must pass
2. Run the linter — must pass
3. Verify edge cases still handled correctly
4. If the optimization changed the algorithm, verify with additional
   property-based tests or fuzzing

**Step P5.3. Verify no regressions elsewhere.**

| Check | Why |
|---|---|
| Other operations not slower | Optimization in one place can hurt another (cache eviction, lock contention shift) |
| Memory usage acceptable | Caching or batching may increase memory |
| Concurrency behavior unchanged | Lock changes can introduce deadlocks or starvation |

**Step P5.4. Profile again.**

Re-run the profiler on the optimized code. Confirm the bottleneck has
shifted or disappeared. If a new bottleneck appeared (sometimes optimizing
one layer reveals the next), repeat from Phase 2.

### Performance output

```markdown
# Performance Report

**Target:** [operation/module name]
**Metric:** [latency / memory / throughput / ...]
**Target:** [goal, e.g., < 200ms p95]

## Baseline
| Measurement | Value |
|---|---|
| Median | X ms |
| p50 | X ms |
| p95 | Y ms |
| p99 | Z ms |
| Memory peak | M MB |
| Environment | [machine, OS, versions] |

## Profile
[Bottleneck identification]
[Flame graph or profiler output summary]

## Optimization applied
| # | Change | Expected impact |
|---|---|---|
| 1 | [description] | [expected improvement] |
| 2 | [description] | [expected improvement] |

## Results
| Measurement | Before | After | Change |
|---|---|---|---|
| Median | X ms | Y ms | -N% |
| p95 | X ms | Y ms | -N% |
| p99 | X ms | Y ms | -N% |
| Memory peak | X MB | Y MB | -N% |

## Trade-offs
[What was sacrificed for the improvement]

## Verification
- [ ] All tests pass
- [ ] Linter passes
- [ ] No regressions in other operations
- [ ] Profiler confirms bottleneck resolved
```

### Performance anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Optimizing without measuring** | You might optimize the wrong thing, or make it worse. Always measure first. |
| **Premature optimization** | Writing complex code for a performance problem you have not confirmed exists. Measure, confirm the bottleneck, then optimize. |
| **Micro-optimizing the wrong layer** | Spending days on a 2% improvement in a cold path while the hot path has a 50% improvement available. Profile to find the hot path. |
| **Benchmarking with unrealistic data** | Testing with 10 records when production has 10 million. Use realistic data volumes. |
| **Single-run benchmarking** | One measurement is noise. Run 5+ times, take median, report variance. |
| **Ignoring algorithmic complexity** | Caching an O(n²) function is a bandaid. Fix the algorithm first, cache second. |
| **Optimizing for peak at the expense of average** | Making the p99 faster at the cost of the p50 being slower. Optimize for the metric that matters to users. |
| **Not verifying correctness after optimization** | The optimized code might return wrong results. Always run the test suite. |
| **Optimizing shared code without understanding callers** | Making a shared utility faster for one caller may break or slow down other callers. Understand the impact surface. |

---

## Edge Cases (all workflows)

| Scenario | Handling |
|---|---|
| **Project has no tests** | Debugging: proceed with caution. Refactoring: STOP — write tests first. Code review: flag as risk. Test strategy: this is the primary deliverable. Performance: proceed but verify correctness manually. |
| **Project has no linter/formatter** | Use language defaults. Suggest adding one as part of the workflow output. |
| **Project uses multiple languages** | Discover all languages in pre-flight. Apply the appropriate conventions for each language within the same workflow. |
| **User cannot articulate the problem** | Help them measure first. For debugging: "what do you see vs. what do you expect?" For performance: "how slow is it, and what is 'fast enough'?" |
| **The fix is in a dependency** | Document the issue, propose a workaround, suggest filing upstream. Do not patch dependencies directly. |
| **Change requires a database migration** | Treat migration as a separate step. Review migration separately from code. Ensure rollback is possible. |
| **The change is in generated code** | Do not review/debug/refactor generated code directly. Fix the generator. |
| **Emergency hotfix** | Compress the workflow: reproduce → fix → verify. Skip documentation, skip refactoring. Create a follow-up task to do it properly. |
| **The user disagrees with your finding** | Present your evidence. If they still disagree, document their rationale and move on. The review is advisory. |
| **Multiple viable approaches** | Present options with trade-offs. Let the user choose. Do not pick for them when the choice is value-based, not fact-based. |

---

## Calibration

Scale effort to the change size and risk.

| Change size | Debugging | Refactoring | Code review | Test strategy | Performance |
|---|---|---|---|---|---|
| **Tiny (< 20 lines)** | Quick reproduce + fix. 1 hypothesis. 1 regression test. | Skip pre-flight if covered by existing tests. Single-step plan. | Correctness + readability only. No architecture check. | Extend existing tests. No new test plan needed. | Timing only. No profiler. |
| **Small (20-100 lines)** | Full workflow. 2-3 hypotheses. Regression test + edge cases. | Full pre-flight. 1-2 refactoring candidates. | Full review. | Targeted test plan for new logic. | Benchmark + simple profiler. |
| **Medium (100-500 lines)** | Full workflow. May need bisect. Multiple regression tests. | Full workflow. Multiple refactoring candidates. May need to split into PRs. | Full review. May need multiple passes. | Full test plan. Test pyramid analysis. | Full profiling. Multiple optimization passes. |
| **Large (500+ lines)** | Full workflow. May need to decompose into sub-bugs. | DO NOT refactor a 500+ line change. Split first, then refactor each piece. | Request the PR be split. Review in pieces. | Full test plan. Coverage gap analysis. | Full profiling. Architecture-level optimization may be needed. |

---

## Portability

This skill works with any language, framework, and team size. It adapts by
discovery, not by configuration.

**What it needs:**
- Source code files (to discover language and framework)
- A way to run tests (any test framework)
- A way to run a linter (any linter)

**What it does NOT need:**
- Hardcoded file paths
- Project-specific configuration
- Specific frameworks or languages
- CI/CD setup (nice to have, not required)

**Adaptation rules:**
- If no test framework is found, use inline assertions or simple scripts
- If no linter is found, skip lint checks and note it in the report
- If no coverage tool is found, estimate coverage by manual inspection
- If no profiler is found, use timing-based measurement
- The workflow structure (measure → act → verify) is universal regardless of the technology stack
