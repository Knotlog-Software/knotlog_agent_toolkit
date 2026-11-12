# Power of Ten — Code-Level Rubric

Rules from G.J. Holzmann, "The Power of 10: Rules for Developing
Safety-Critical Code", IEEE Computer 39(6), 2006 (NASA/JPL Laboratory for
Reliable Software). These are the code-quality layer's core rules: they are
the most directly extractable from NASA practice for static, read-only
auditing of an existing codebase.

## How to use

Each rule has:
- **ID:** Stable identifier for reporting (`POT-N`)
- **Original rule:** The rule as published (C-oriented)
- **Check:** What to verify in this codebase
- **Verdict signals:** What Pass / Partial / Fail look like
- **Adaptation:** Language-neutral interpretation. The rule is written for
  safety-critical C; for managed languages map intent, not mechanism.

Default verdict thresholds are guidance. The auditor adjusts confidence
1–10 using the confidence model in SKILL.md.

---

## POT-1: Simple control flow only
- **Original rule:** Do not use `goto`, `setjmp`/`longjmp`, or direct or
  indirect recursion.
- **Check:** Search for `goto`, equivalents of non-local jumps
  (exceptions used for control flow, `eval`, label loops), and recursion
  in non-trivial call graphs. Recursion depth bounded by explicit guard
  counts as partial.
- **Pass:** No unstructured jumps; recursion absent or trivially shallow
  with explicit depth guard.
- **Partial:** Recursion present but bounded with documented guard;
  or rare justified uses with comments.
- **Fail:** `goto`-style control flow or unbounded recursion in core
  logic paths.
- **Adaptation:**
  - Exceptions as normal control flow = Partial (exceptions are the
    managed-world `goto`), exceptions reserved for exceptional states
    = Pass.
  - `Promise`/`async` chains are not jumps; don't flag them.
- **Default severity:** Blocking (core quality floor).

## POT-2: Loops have fixed upper bounds
- **Original rule:** All loops must have a statically provable iteration
  bound. If a checker cannot prove the bound, the rule is violated.
- **Check:** For loops over collections and index loops, verify
  termination is obvious: iterating a finite collection, scripted bound,
  or condition tied to a monotonically changing value.
- **Pass:** All loops iterate finite data or have explicit bounds.
- **Partial:** Some loops (`while (true)` with break, condition-driven
  loops) but no evidence of runaway in core paths; retry loops capped.
- **Fail:** Unbounded `while` loops in critical paths (pollers, workers)
  with no timeout/exit condition.
- **Adaptation:** In event-driven frameworks (React, Flutter), "loops"
  includes render/refresh cycles: look for missing debounce/cancel
  mechanisms, not `for` syntax.
- **Default severity:** Risky (Blocking if found in a failure-prone
  path such as network retry, polling, parsing).

## POT-3: No dynamic resource growth after initialization
- **Original rule:** No dynamic memory allocation after initialization.
- **Check:** Look for unbounded resource growth: caches and registries
  that grow without eviction, collections that only ever append,
  uncapped buffers, missing `finally`/deferred disposal of OS-level
  resources (files, sockets, streams, connections).
- **Pass:** All long-lived allocations bounded at init (pools, caches
  with eviction/size limits); all resources deterministically released.
- **Partial:** Growth bounded by external limits (dataset size, user
  config) but not enforced in code.
- **Fail:** Unbounded caches, leaked connections/streams, append-only
  structures in long-running processes.
- **Adaptation:** In GC languages the hazard shifts from memory leaks to
  reference leaks (listeners, closures, timers holding objects) and
  unbounded data structures. In Rust it is mostly about unbounded
  `Vec`/`String` growth in loops.
- **Default severity:** Blocking (leaks are the classic latent failure).

## POT-4: Function length limit
- **Original rule:** No function longer than fits one printed page
  (~60 lines).
- **Check:** Measure function lengths in the sampled files. Do not flag
  declarative/boilerplate-heavy code that stays readable, but do flag
  multi-responsibility monsters.
- **Pass:** 95%+ of functions ≤ 60 lines; none > 120 lines.
- **Partial:** Most functions reasonable, a small set (≤ 5%) of long
  functions, each with a single dominant responsibility.
- **Fail:** Many > 60-line functions, or any function > ~200 lines with
  mixed responsibilities.
- **Adaptation:** Config definitions, data tables, and JSX/UI trees may
  legitimately be long — judge by responsibility, not line count alone.
- **Default severity:** Risky.

## POT-5: Assertion / invariant density
- **Original rule:** At minimum two assertions per function on average,
  used for impossible-condition checks, side-effect free, with explicit
  failure recovery.
- **Check:** Look for defensive checks of "cannot happen" conditions,
  invariant checks, exhaustive `switch` fallbacks (`default: -> never`),
  result-type checks. Count ratio of assertions to functions in sampled
  files.
- **Pass:** Average ≥ 2 invariant checks per complex function; failures
  handled (error type returned, logged, escalated), never ignored.
- **Partial:** Invariants checked in critical modules only; some
  functions trust inputs blindly.
- **Fail:** Core logic assumes success everywhere; no invariant /
  exhaustive-case checks found.
- **Adaptation:** Python idioms: `assert` in code paths, `raise` for
  invalid states, exhaustive match. TS: `never` exhaustiveness checks,
  discriminated unions. Go: `if err != nil` density. Java/Dart: Objects
  requireNonNull, sealed types + switch completeness. Languages with
  static exhaustiveness checking get partial credit automatically;
  audit runtime checks at boundaries (I/O, parsing, external APIs).
- **Default severity:** Risky (Blocking if parse/format/decode of
  external data never validated).

## POT-6: Minimal data scope
- **Original rule:** Declare data at the smallest possible scope; avoid
  reusing variables across purposes.
- **Check:** Look for module-level mutable state, singletons holding
  mutable data, class fields used by one method only, global caches,
  variables reused for different meanings in one function.
- **Pass:** Mutable state localized; module state minimal and
  documented; controllers hold only lifecycle-scoped state.
- **Partial:** Some module-level state but written/read in a bounded
  set of locations; a few oddly scoped fields.
- **Fail:** Pervasive globals/singletons that many modules mutate.
- **Adaptation:** In frontend frameworks treat component/store state as
  the unit; flag cross-widget/module mutation through singletons.
- **Default severity:** Risky.

## POT-7: Check every return value; validate every parameter
- **Original rule:** Callers must check non-void return values; callees
  must validate caller-provided parameters.
- **Check:** Ratios of ignored results at API boundaries: file/HTTP I/O,
  JSON parsing, DB writes, external service calls. Check whether
  public/src entry points validate arguments (null/empty/range/type).
- **Pass:** Boundary calls checked or explicitly annotated as allowed to
  throw (documented convention); public functions validate inputs.
- **Partial:** Validation at boundaries but gaps in public API surface;
  some ignored error return values.
- **Fail:** Fire-and-forget I/O in core paths; public API trusting
  external data.
- **Adaptation:** In exceptions-based languages the rule applies to
  *catch-and-ignore* (`except: pass`, empty catch blocks, swallowed
  promise rejections). Treat unchecked promise chains and missing
  `catch` at call sites of async functions as ignored return values.
- **Default severity:** Blocking (top provenance of production crashes).

## POT-8: Metadata/code-generation discipline
- **Original rule:** Preprocessor limited to includes and simple macros;
  no token pasting, no variadic macros; minimal conditional compilation.
- **Check:** Assess code-generation and metaprogramming discipline:
  string-built code, eval, macro-heavy wrappers, preprocessor/config
  puzzles, excessive conditional compilation/platform directives.
- **Pass:** Metaprogramming limited to standard, reviewed mechanisms
  (generics, standard decorators); generated code committed with
  regeneration instructions.
- **Partial:** Some clever metaprogramming, used narrowly and named
  clearly; build-time codegen with checked-in outputs and docs.
- **Fail:** Opacity via evaluated string code, macro puzzles, or
  generated code nobody can regenerate.
- **Adaptation:** Generics, protocols, sealed types, and framework DTO
  codegen (GraphQL, gRPC, JSON serializers) are the managed equivalents
  of macros — fine when standard. Flag custom codegen without build
  documentation.
- **Default severity:** Trivial.

## POT-9: Restrict pointer power
- **Original rule:** No multi-level dereferences, no hidden dereferences
  in macros/typedefs, no function pointers.
- **Check:** Assess aliasing power the language exposes: mutable shared
  references escaping a module's control, callbacks/function values
  passed into core logic without ownership rules, mutation through
  multiple aliases of the same state, dynamic dispatch tables mutated
  at runtime.
- **Pass:** Ownership/mutation discipline clear (immutable by default,
  single-writer patterns, injected but fixed dependency graphs).
- **Partial:** Some shared mutable state via references/callbacks but
  controlled (documented, only injected at composition roots).
- **Fail:** Mutable stores/registries mutated from arbitrary call sites;
  callbacks swapped at runtime in core paths.
- **Adaptation:** For C/C++ audit the rule literally (`**`, function
  pointer tables). For Go audit pointer receivers escaping via
  interfaces. For GC languages the closest analog is aliasing through
  events/callbacks (see also POT-3).
- **Default severity:** Trivial.

## POT-10: Clean compile with warnings at maximum; strong static analysis
- **Original rule:** All code compiled from day one with most pedantic
  warnings, zero warnings, checked daily with at least one strong static
  analyzer passing with zero findings.
- **Check:** Read the project's lint/format/analyze configuration
  (linter configs, CI pipelines, scripts, type-checking strictness).
  Determine: Is a lint/type-check setup present? Is it strict? Is it run
  in CI? Would audit-time spot checks pass? Run the project's lint or
  type-check command only if it is already configured and safe
  (no dependencies installed).
- **Pass:** Strict static checking wired into CI; configuration tuned;
  spot checks corroborate cleanliness.
- **Partial:** Type checking/lint configured but not enforced in CI, or
  warnings suppressed wholesale, or spot checks show accumulated noise.
- **Fail:** No static analysis/type/lint enforcement at all.
- **Adaptation:** Equivalents per language: `tsc --strict` + `eslint` ++
  CI for TS, `ruff/mypy` for Python, `flutter analyze` for Dart,
  `go vet` for Go, `phpstan/psalm` for PHP, `cargo clippy` for Rust,
  `golangci-lint` etc. A project type-checked by the runtime only
  (plain JS) needs at least lint enforcement to reach Partial.
- **Default severity:** Risky.

---

## Scoring notes

- Verdicts average per rule; a rule with a single high-confidence Fail in
  a critical path should not be flattened into Partial by clean code
  elsewhere. Report the Fail on the path that caused it.
- Rules scale by target class (classes.md): for target Class E/G, POT-1,
  POT-3, POT-7, and POT-10 are the core four; POT-2 and POT-5 become
  consultative. For Class B and above, all ten apply at full rigor.
- Never fail a rule because the *language* makes it inapplicable; use the
  adaptation column and mark the item N/A with justification when the
  construct genuinely cannot occur (e.g., POT-8 in a project with no
  codegen/metaprogramming surface at all).
