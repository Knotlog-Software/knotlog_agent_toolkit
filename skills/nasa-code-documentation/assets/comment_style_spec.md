# Comment Style Specification

The canonical comment/doc-comment style used by the nasa-code-documentation
skill. Extends `agent-context-kit/assets/class_comment_specification.md`
(class header + Properties + Methods) with file headers, module-level
functions, optional sections, and per-language doc-comment syntax.

NASA basis: NPR 7150.2D SWE-061 (coding standards; comments explain why the
code exists and what a maintainer must know) and SWE-060 (implementation
includes code, data, and documentation). The SWEHB guidance is explicit:
comments should explain *why*, not narrate *how*; quality code is
self-documenting by default and comments add the intent, constraints, and
non-obvious consequences that code cannot carry.

## Principles

1. **Why, not how.** Code shows how. Comments carry intent, constraints,
   invariants, units, protocol assumptions, and consequences of change.
2. **No parroting.** Never restate what the next line obviously does
   (`// increment i`). If a comment only echoes the code, delete it
   instead of upgrading it.
3. **Every documented claim is true.** A comment must describe actual
   behavior. If the code's behavior looks wrong, flag it in the report;
   do not document the wrong behavior as if intended.
4. **Self-contained.** A maintainer reading the comment plus the
   signature should not need to read the body to use the entity
   correctly.
5. **Stable language.** Use the repository's established comment
   language (default English). Do not mix languages within a file.
6. **Declarative present tense.** "Returns the decoded payload." Not
   "Will return..." or "This function is used to...".

## Documented entities

| Entity | Required for | Format section |
|---|---|---|
| File / module | All hand-written source files in coverage | File header |
| Class / type | All public types in coverage | Class header |
| Method / function | All public functions in coverage; private helpers get a one-line why | Method header |
| Property / field | Public properties whose meaning is not obvious from name+type | Property comment |
| Constant / enum value | Values where the number/string itself is meaningless | Constant comment |

## File / module header

Place at the top of the file, before imports, unless the language's
tooling requires a specific position (e.g., after a license header).

```
Purpose:    One sentence: what this file is responsible for.
Contains:   The main entities (optional, for large files).
Constraints: Non-obvious rules that apply to everything in the file
             (threading, lifecycle, units, platform limitations).
Owner:      Owning component/team or domain (optional; only if the repo
             records ownership).
```

Omit any field that would be empty or invented. A file containing noise
from a mandatory empty template is worse than a two-line header.

## Class / type header

Extend the house format from `class_comment_specification.md` verbatim.
The examples below use language-neutral pseudo-comments; emit them with
the language's syntax from the mapping table further down.

```
// Comment block describing the Class
//
// ## Properties
// * Property Name: Property Type. Description of Property
//
// ## Methods
// * Method Name(Parameter, Parameter): Return Type. Description of Method
```

Rules:
- The first line is the class's single-sentence purpose (capped at one
  sentence).
- `Properties` lists every public property; `Methods` lists every public
  method. Private members are omitted unless their semantics are
  surprising.
- Descriptions state behavior or meaning, not types again
  (`// ## Properties` already carries the type).

## Method / function header

```
/// Comment describing the Method
///
/// ## Parameters
/// * Parameter Name: Type. Parameter Description
///
/// ## Returns
/// * Return Type. Return Type Description
```

Add these optional sections only when they apply:

| Section | Include when |
|---|---|
| `## Errors` | The function raises/throws/returns errors a caller must handle; enumerate the failure modes |
| `## Side effects` | The function mutates external state (I/O, files, network, shared state, global config) |
| `## Invariants` | Preconditions the caller must satisfy or postconditions callers may rely on |
| `## Thread safety` | The function/type is shared across threads or is deliberately not |
| `## Units` | Numeric parameters/returns carry units or ranges |
| `## See also` | A directly related function/type that a maintainer must read |

Description rules:
- First line: verb-led one sentence ("Returns ...", "Appends ...",
  "Computes ...").
- Parameter descriptions state *constraints and meaning*, not types
  ("must belong to the same voyage", "0-based index into the plan").
- Return description states the value's meaning and the error/edge
  convention ("-1 when the plan is closed").
- Document every parameter or none; partially documented parameter
  lists mislead.

## Property / field comment

One line above the declaration:

```
// Stable identifier assigned at creation; never reused.
String id;
```

Only required when the name + type do not already carry the meaning.

## Constant / enum value comment

```
// Upper bound on retry attempts before the operation is treated as failed.
const maxRetries = 3;
```

## Per-language syntax mapping

Same structure, emitted in the language's tooling-visible doc-comment
syntax:

| Language | Syntax | Notes |
|---|---|---|
| Dart | `///` | dartdoc; sections carried as markdown headings |
| TypeScript / JavaScript | `/** ... */` | JSDoc `@param` / `@returns` preferred over `##` sections |
| Python | `""" ... """` | Docstring; keep `##` sections inside; Google-style is acceptable if the repo already uses it |
| Go | `//` above the declaration | godoc; first sentence must start with the symbol name |
| PHP | `/** ... */` | PHPDoc `@param` / `@return` |
| Rust | `///` | rustdoc markdown; `# Errors` / `# Panics` sections are idiomatic |
| Java / Kotlin | `/** ... */` | Javadoc `@param` / `@return` / `@throws` |
| C / C++ | `/* ... */` or `///` | File header with the project's banner convention if one exists |
| Shell | `#` | Header block at top only; functions get a one-line why |

Adaptation rules:
- Prefer the language's native annotation tags (`@param`, `@returns`,
  `@throws`) over reproducing `## Parameters` in JSDoc/PHPDoc/Javadoc.
  The *content requirements* stay the same; only the container changes.
- Never introduce doc-tool annotations into a repo that does not use
  them, unless the repo has the corresponding doc generator configured.
  In that case use the generator's conventions exactly.
- Markdown in comments is allowed; keep headings (`##`) so the house
  structure survives plain-text rendering.

## Worked examples

Dart (dartdoc):

```dart
/// A float plan owned by one sailor.
///
/// ## Properties
/// * `id`: String. Stable identifier assigned at creation.
///
/// ## Methods
/// * `close()`: void. Marks the plan completed.
class FloatPlan {
  /// Appends a waypoint to the plan.
  ///
  /// ## Parameters
  /// * `waypoint`: Waypoint. Position to append; must belong to this
  ///   voyage.
  ///
  /// ## Returns
  /// * `int`. Index of the appended waypoint, or -1 when the plan is
  ///   closed.
  ///
  /// ## Side effects
  /// Emits a `planUpdated` event.
  int addWaypoint(Waypoint waypoint) { ... }
}
```

TypeScript (JSDoc):

```ts
/**
 * Appends a waypoint to the plan.
 *
 * @param waypoint Position to append; must belong to this voyage.
 * @returns Index of the appended waypoint, or -1 when the plan is closed.
 */
addWaypoint(waypoint: Waypoint): number { ... }
```

## Exclusion rules

Never modify comments in:

- Generated files (`*.g.dart`, `*.pb.go`, `*_generated.*`, `dist/`,
  `build/`, `target/`, `node_modules/`, `vendor/`).
- Third-party or vendored source.
- Lockfiles and machine-maintained manifests.
- Files marked `@generated` / `DO NOT EDIT` in their header.

The report lists skipped files with the reason.

## Staleness rules

- If an existing comment is correct, leave it alone (upgrade only
  missing or wrong content).
- If an existing comment contradicts the code, do not silently rewrite
  it: fix it *and* add a report entry under "Contradictions fixed",
  quoting both sides.
- If the code's intent cannot be determined from code, tests, call
  sites, and docs, do not guess: mark the entity "comment-blocked" in
  the report with what is needed to resolve it.
