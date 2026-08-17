---
name: doc-consistency
description: >
  Analyze architecture documentation for internal inconsistencies,
  contradictions, inference-forcing gaps, and generation readiness.
  Finds where docs disagree with OTHER docs (not code). Also checks
  whether use case specs and activity diagrams are complete enough
  to serve as inputs to downstream generators (e.g., sequence diagram
  generation). Includes a reusable completeness checklist (auto-extracted
  via ADHD deep-dive on first run) and optional adversarial deep-dive
  analysis for specific use cases. Pre-implementation quality gate: run
  before writing code or generating diagrams. Works with PlantUML diagrams,
  markdown narratives, AGENTS.md, and use case specs. Portable across any
  project with structured documentation.
license: MIT
---

# Documentation Consistency Analyzer

A pre-implementation quality gate that analyzes architecture documentation
against itself. Finds inconsistencies, contradictions, and gaps that would
force an implementer to guess. This skill does NOT compare docs to code — it
checks docs against other docs.

Use when: "check my docs", "find inconsistencies in my architecture docs",
"are my docs consistent", "doc audit", "documentation review", "are my docs
ready to generate sequence diagrams", "check generation readiness", or the
user is about to start implementation and wants to validate their specs first.

Skip when: comparing docs to code (use a different approach), syntax questions,
or the user wants a quick answer about a specific doc.

## Pre-flight

**Step 1. Discover documentation artifacts.**

Scan the project for documentation files. The skill adapts to whatever it finds.

| Artifact type | Scan patterns | Role |
|---|---|---|
| Project tracking | `AGENTS.md`, `CLAUDE.md`, `*.md` in root | Decisions, rules, iteration status |
| PlantUML diagrams | `**/*.puml` | Structural specs (class, sequence, use case, activity, component) |
| Markdown narratives | `docs/**/*.md` | Domain model, architecture, use case specs |
| Use case specs | `**/use_cases.md`, `**/use_case*.md`, `**/use-cases*.md` | Behavioral specifications |
| Architecture matrix | `ARCHITECTURE_MATRIX.yaml`, `**/architecture_matrix*` | Service call graph constraints (may_call / must_not_call) |
| Antipattern catalog | `**/architecture_antipatterns*`, `**/antipatterns*` | Known wrong patterns and their violated rules |

**Step 2. Classify each artifact.**

For each discovered file, determine its role:

- **Decision source** — Contains binding architectural decisions (e.g., AGENTS.md Section 2)
- **Rule source** — Contains enforceable constraints (e.g., AGENTS.md Section 4 architecture rules)
- **Structural spec** — PlantUML diagrams defining entities, relationships, components
- **Behavioral spec** — Use case diagrams, sequence diagrams, activity diagrams
- **Narrative spec** — Markdown prose describing domain model, architecture
- **Tracking doc** — Iteration plans, delivery status, correction trackers

**Step 3. Abort if insufficient artifacts.**

The skill needs at least 2 documentation artifacts to cross-reference. If the project has only a single README, abort and tell the user there's nothing to cross-check.

## Phase 1 — Name Graph

Build a cross-reference map of every entity, class, interface, enum, and
concept name across all documentation files. This is the structural
backbone every later check plugs into.

### Step 1.1 — Extract names from PlantUML diagrams

For each `.puml` file, extract declarations:

```
class <Name>
interface <Name>
enum <Name>
abstract class <Name>
component <Name>
actor <Name>
usecase <Name>
```

Also extract names from PlantUML relationship lines:

```
<Source> <arrow> <Target> : <label>
```

Record: `{name, source_file, declaration_type}`

### Step 1.2 — Extract names from markdown

For each `.md` file, extract:

- Backtick-quoted names: `` `FloatPlan` ``
- Bold names in table cells: `| **FloatPlan** |`
- Heading-level names: `### FloatPlan`
- PascalCase words in list items under entity/component sections

Record: `{name, source_file, context}`

### Step 1.3 — Build the graph

For each unique name, record which files mention it:

```json
{
  "FloatPlan": ["AGENTS.md", "domain_model.puml", "domain_model.md", "architecture.md"],
  "Sailor": ["AGENTS.md", "use_cases.puml", "use_cases.md"],
  "SomeOrphan": ["domain_model.md"]
}
```

### Step 1.4 — Flag anomalies

| Anomaly | Meaning | Severity |
|---|---|---|
| **Singleton** — name appears in only 1 file | Orphaned concept, or naming inconsistency | Risky |
| **Missing from authority** — name in diagrams but not in tracking doc (or vice versa) | Structural mismatch between spec layers | Blocking |
| **Count mismatch** — entity count differs between sources | One source is stale or incomplete | Blocking |
| **Naming drift** — same concept with slightly different names across files | Inconsistent terminology, will cause confusion | Risky |

### Step 1.5 — Special checks

**Entity list comparison:** If the project has a "Core Entities" list (e.g., AGENTS.md Section 3) and a domain model diagram, compare them set-by-set. Every entity in one should be in the other.

**Relationship count comparison:** If the project has a "Key Relationships" list and a domain model diagram with relationship lines, compare counts. Missing or extra relationships are contradictions.

**Actor comparison:** Compare actors in use case diagrams against actors named in use case specs. Actor drift is a free contradiction.

**Use case comparison:** Compare use case IDs/names in use case diagrams against use case specs and sequence diagrams. Missing coverage is a gap.

## Phase 2 — Claim Extraction

Extract structured claims from documentation that can be verified against
other docs. Focus on three claim sources.

### Step 2.1 — Extract decisions

Scan decision-source files (typically AGENTS.md "Decisions" sections) for
binding architectural decisions. Each decision becomes a claim triple:

```
{subject, predicate, constraint}
```

Example: "ShoreContact is a standalone aggregate with its own repository"
becomes `{ShoreContact, is, standalone aggregate with own repository}`

Rules for extraction:
- Each bullet point or numbered item in a decisions section is one claim
- Claims about entity nature (standalone, owned, value object) are high-priority
- Claims about behavior constraints ("never calls DateTime.now()") are high-priority
- Claims about scope ("out of scope") are medium-priority

### Step 2.2 — Extract architecture rules

Scan rule-source files (typically AGENTS.md "Architecture Rules" sections) for
binary constraints. Each rule becomes a predicate:

```
{layer_A, must_not_depend_on, layer_B}
{domain_layer, must_be_testable_without, framework_dependencies}
```

### Step 2.3 — Extract domain model claims

Scan domain model narratives for structural claims:

- Entity/value object classifications
- Ownership vs. association vs. aggregation relationships
- Status lifecycle transitions
- What is deliberately excluded

### Step 2.4 — Extract use case claims

Scan use case specs for behavioral claims:

- Actor assignments (who triggers each use case)
- Precondition/postcondition pairs
- Inter-use-case relationships (extends, includes, triggers)
- System boundary (in scope vs. out of scope)

## Phase 3 — Cross-Artifact Contradiction Detection

For each extracted claim, scan all OTHER docs for contradictions, gaps,
and ambiguity.

### Step 3.1 — Direct contradiction scan

For each claim, check if any other doc asserts the opposite:

| Claim type | What to check | Example |
|---|---|---|
| Entity is standalone | Diagram shows it inside another's composition boundary | "ShoreContact standalone" vs. composition arrow from FloatPlan |
| Entity has own repository | Diagram shows no repository interface for it | "CrewMember has ICrewMemberRepository" — verify diagram includes it |
| Relationship type (aggregation vs. association) | Diagram uses different arrow type | "FloatPlan references ShoreContact" — verify `o--` not `*--` |
| Status lifecycle | Diagram or spec shows different transitions | "Active → SOS → Completed" — verify enum matches |
| Use case actor | Different actor assigned in diagram vs. spec | Spec says "Sailor" triggers, diagram shows "Shore Support" |
| Out of scope | Any doc includes what should be excluded | "GPS tracking out of scope" — check no diagram models it |

### Step 3.2 — Silent reversal detection

This catches the most dangerous class of doc drift: a decision from iteration N
that is contradicted by a doc written in iteration N+1 without acknowledgement.

Process:
1. For each decision, note its iteration/timestamp
2. Scan all docs that were written *after* that decision
3. Flag any doc that asserts the opposite without an explicit override note

A "silent reversal" is severity: blocking. It creates an irresolvable
contradiction for implementers — two authoritative instructions that cannot
both be true.

### Step 3.3 — Ambiguity gap detection

Scan for vague language that forces implementers to guess:

| Pattern | Problem |
|---|---|
| "optional" without specifying default behavior | Implementer must guess what happens when omitted |
| "may" without specifying the alternative | Two valid implementations, no way to choose |
| "should" without specifying "must" vs. "recommended" | Unclear if this is enforceable |
| "etc." or "and so on" | Incomplete enumeration, gaps hidden |
| Unlabeled PlantUML relationships | Arrow exists but no verb phrase — semantics unclear |
| Missing multiplicities on associations | Composition vs. aggregation vs. reference ambiguous |

### Step 3.4 — Coverage gap detection

Check that every artifact has a counterpart:

| If this exists... | This should also exist... | Gap type |
|---|---|---|
| Use case spec | Sequence diagram for that UC | Missing behavioral spec |
| Sequence diagram | Use case spec for that UC | Missing behavioral spec |
| Activity diagram | Use case spec for that UC | Missing behavioral spec |
| Entity in domain model diagram | Entity description in domain model narrative | Missing documentation |
| Entity in domain model narrative | Entity in domain model diagram | Missing structural spec |
| Planned feature in tracking doc | Use case spec or diagram | Underspecified plan |
| Architecture rule | Test or enforcement mechanism | Unenforceable rule |

## Phase 4 — Generation Readiness

Check whether use case specs and activity diagrams are complete enough
to serve as inputs to downstream generators (e.g., the generate-sequence
skill). This phase answers: "If I tried to generate sequence diagrams from
these inputs right now, would they be detailed enough?"

This phase is **optional** — run it when the user asks about generation
readiness, or when the skill detects that sequence diagrams are a planned
output. Skip it for pure consistency audits.

### Step 4.1 — Build UC inventory

For each use case found in the use case spec file, create a readiness
record:

```json
{
  "uc_id": "UC-2.4",
  "uc_name": "Trigger SOS",
  "spec_file": "docs/use_cases.md",
  "activity_file": "docs/uml/activity_diagrams/UC-2.4_TriggerSOS_Activity.puml",
  "sequence_file": "docs/uml/sequences/UC-2.4_TriggerSOS.puml"
}
```

Match UCs to their activity diagrams by UC number (e.g., `UC-2.4` →
`UC-2.4_*_Activity.puml`). Report UCs with no activity diagram as
**missing** (readiness: none).

### Step 4.2 — Check use case spec completeness

For each UC, verify the spec contains all required fields:

| Field | Required | What "sufficient" means |
|---|---|---|
| Actor | Yes | Non-empty string identifying the primary actor |
| Goal | Yes | One sentence describing the objective |
| Precondition | Yes | Either a stated condition or explicit "None" |
| Main flow | Yes | Numbered list with ≥ 2 steps |
| Postcondition | Yes | Stated outcome after main flow completes |
| Alternate flow | No | If the UC has branching behavior, an alternate flow must be described |

Flag missing fields as **partial** readiness. A UC with no main flow
steps is **missing** readiness.

### Step 4.2a — Apply completeness checklist

Load the reusable checklist from the skill directory:

```
<skill_dir>/checklist.md
```

Where `<skill_dir>` is the directory containing this SKILL.md file
(e.g., `~/.agents/skills/doc-consistency/`).

If the checklist does not exist, trigger auto-extraction (see Step 4.6).

For each rule in the checklist, check whether the UC's spec and
associated diagrams violate it. Skip rules where the UC has no
relevant surface area (e.g., skip IC-1 if the UC does not touch a
new aggregate).

Append checklist findings to the readiness report under a
"Checklist Findings" subsection, grouped by category:

```markdown
## Checklist Findings

| Rule | Category | Severity | Finding |
|------|----------|----------|---------|
| EC-1 | Entity Classification | BLOCKING | CrewMember classified as entity in domain_model.md but value object in domain_model.puml |
| SC-1 | Scope Change | BLOCKING | ActiveTripScreen listed as planned in architecture.md but dropped in AGENTS.md |
```

### Step 4.3 — Check activity diagram coverage

For each UC that has an activity diagram:

1. **Step coverage:** Count the action nodes in the activity diagram.
   Compare against the number of main flow steps in the use case spec.
   Report the ratio (e.g., "6 activity nodes vs. 8 spec steps").
   A ratio below 0.75 is **partial** readiness. Below 0.5 is **missing**.

2. **Branch presence:** Check whether the activity diagram contains at
   least one conditional construct (`if`, `switch`, `repeat`). A UC with
   alternate flows in the spec but no branches in the activity diagram
   is **partial** readiness.

3. **Specificity level:** Check whether activity diagram action nodes
   name concrete classes or just say "System". Nodes that say "System does
   X" without implying a specific class are **generic**. Nodes that name
   a class (e.g., "AlertService sends alert") are **concrete**. A diagram
   that is entirely generic is **partial** readiness — the generate-sequence
   skill can still work (it uses the component diagram for mapping), but
   the mapping is less certain.

### Step 4.4 — Check component diagram coverage (if available)

If a component or architecture diagram exists:

1. For each "System does X" step in the activity diagram, attempt to
   identify a plausible owning class from the component diagram using
   naming heuristics (e.g., "persists" → repository, "sends" → notification
   service).

2. Report the mappability ratio: steps with a plausible owner vs. total
   system steps. A ratio below 0.75 is **partial** readiness.

3. Report any steps with no plausible owner — these are the steps most
   likely to produce incorrect sequence diagrams.

### Step 4.5 — Emit readiness table

For each UC, emit a readiness verdict:

| Verdict | Meaning |
|---|---|
| **Complete** | All spec fields present, activity diagram covers main flow, branches modeled, component diagram sufficient |
| **Partial** | Some fields missing, or activity diagram coverage < 75%, or component diagram gaps |
| **Missing** | No activity diagram, or spec has no main flow, or critical inputs absent |

The readiness table is appended to the consistency report as a new section.

### Step 4.6 — Deep-dive analysis (optional, on demand)

This step runs ADHD divergent thinking to find design holes that
structural checks miss. It is expensive (~10 agent calls per invocation)
and runs on-demand, not by default.

**Auto-extraction on first run:**

If the checklist file does not exist at `<skill_dir>/checklist.md`,
automatically run extraction mode before proceeding with any other
phase. Extraction runs ADHD on one representative UC per aggregate
cluster to produce the initial checklist. See "Extraction mode" below.

**Three invocation modes:**

| Mode | Trigger | Cost | Output |
|---|---|---|---|
| `--deep-dive UC-X.Y, UC-A.B` | User specifies UCs | ~10 calls per UC | Design-hole findings appended to report |
| `--deep-dive-all` | User requests full audit | ~10 calls × N UCs | Design-hole findings for all UCs |
| (auto-extract) | Checklist missing | ~60 calls (one-time) | New checklist.md file |

**Deep-dive mode:**

For each specified UC, run the ADHD skill with a tailored prompt:

> You are analyzing a use case specification for design holes — things
> the spec assumes but never states, error paths it ignores, preconditions
> it leaves implicit, and integration gaps with other use cases.
>
> UC spec: [paste spec]
> Activity diagram: [paste activity diagram]
> Adjacent UCs: [list UCs that share entities with this UC]
>
> Generate 6 design holes this spec would cause an implementer to guess
> about. Each hole is one sentence. Focus on: missing error paths,
> implicit preconditions, ambiguous state transitions, unenumerated side
> effects, cross-UC integration gaps, and entity lifecycle holes.

Collect findings from all frames, deduplicate, and append to the
consistency report under a "Deep-Dive Findings" section:

```markdown
## Deep-Dive Findings

| UC | Finding | Category | Severity | Confidence |
|----|---------|----------|----------|------------|
| UC-2.4 | Spec does not define behavior when notification service is unavailable | Error Path | Risky | 7/10 |
| UC-2.4 | SOS trigger does not specify whether pending waypoint check-ins are cancelled | Side Effect | Risky | 6/10 |
```

**Extraction mode (`--extract-checklist`):**

1. Identify all aggregate clusters in the domain model (entities with
   `*--` composition arrows are cluster roots).
2. Pick one representative UC per cluster (the most complex UC that
   touches that aggregate).
3. Run ADHD on each representative UC using the deep-dive prompt above.
4. Collect all findings across clusters.
5. Group findings by category (Entity Classification, Scope Change,
   Cross-UC Integration, Spec Depth, etc.).
6. For each category, produce 1–3 structural rules that would catch
   similar findings automatically. Write rules in the checklist format:
   ```
   ### CATEGORY-N: Rule name
   - **Check:** What to verify
   - **Fail signal:** What the user sees
   ```
7. Write the rules to `<skill_dir>/checklist.md` (create or overwrite).
8. Report to the user: "Checklist extracted with N rules from M
   representative UCs. Future runs will apply these rules automatically."

## Phase 5 — Architecture Gate

Validate all documentation against the project's architecture rules and
constraints. This phase catches docs that describe patterns violating the
stated architecture — layer violations, forbidden call paths, and
antipattern endorsements.

This phase is **optional** — run it when the user asks about architecture
validity, or when the project has architecture rules (AGENTS.md Section 4)
and/or an architecture matrix (ARCHITECTURE_MATRIX.yaml). Skip it for
pure naming/consistency audits.

### Step 5.1 — Extract architecture rules

Scan for architecture rule sources and build a constraint set:

| Source | What to extract |
|---|---|
| AGENTS.md "Architecture Rules" | Layer dependency rules, golden rule, platform adapter constraints |
| `ARCHITECTURE_MATRIX.yaml` (if exists) | Per-service `may_call` / `must_not_call` constraints |
| `docs/architecture_antipatterns.md` (if exists) | Known antipattern signatures (wrong patterns) |
| `docs/architecture.md` | Narrative description of layers, services, patterns |

For each rule, record:

```json
{
  "rule_id": "AR-1",
  "description": "presentation/ depends on application/ only",
  "source_file": "AGENTS.md",
  "constraint_type": "layer_dependency",
  "forbidden_violation": "presentation/ importing from domain/"
}
```

If no architecture rules are found in any source, skip Phase 5 entirely
and report: "No architecture rules found — architecture gate skipped."

### Step 5.2 — Validate layer dependency consistency

For each layer dependency rule extracted in Step 5.1:

1. **Cross-doc check:** Verify architecture.md states the same rule. If
   AGENTS.md says "presentation/ depends on application/ only" but
   architecture.md says "presentation/ depends on application/ and
   domain/", flag as a blocking contradiction.

2. **Diagram check:** Scan all sequence diagrams for forbidden cross-layer
   calls. A sequence diagram showing presentation → domain (bypassing
   application) violates the layer rule. Use participant labels to
   identify layers.

3. **Component diagram check:** If a component diagram exists, verify that
   dependency arrows between layers match the stated rules. A
   presentation → domain arrow violates the rule.

### Step 5.3 — Validate call graph consistency

If ARCHITECTURE_MATRIX.yaml exists:

1. **Service coverage:** Every service in YAML should appear in
   architecture.md. Services in YAML but absent from architecture.md
   mean the narrative is stale.

2. **Constraint coverage:** Every `must_not_call` constraint in YAML should
   be acknowledged in at least one doc (architecture.md, AGENTS.md, or
   antipatterns doc). Unacknowledged constraints are hidden rules.

3. **Forbidden path detection:** Check if any doc (narrative, sequence
   diagram, use case spec) describes or implies a direct call that
   violates a `must_not_call` constraint. For example, if YAML says
   `FlutterApp must_not_call SMSProvider` but architecture.md describes
   "Flutter app sends SMS via Twilio", that is a contradiction.

### Step 5.4 — Validate golden rule propagation

The "golden rule" (domain layer has zero framework, database, or network
dependencies) is the most critical architecture constraint.

1. Verify the golden rule is stated in both AGENTS.md and architecture.md.
2. If domain_model.md exists, verify it does not contradict the rule
   (e.g., by showing domain entities importing framework packages).
3. If any doc says domain depends on something external, flag as blocking.

### Step 5.5 — Detect antipattern references

If `docs/architecture_antipatterns.md` exists:

1. Extract each antipattern's signature: the wrong pattern, the violated
   rule, and the correct alternative.
2. For each antipattern, scan all other docs (sequence diagrams, use case
   specs, narratives, component diagrams) for descriptions matching the
   wrong pattern.
3. Flag as risky if a doc appears to endorse an antipattern as the correct
   approach. Flag as blocking if a diagram models the antipattern as the
   intended design.

### Step 5.6 — Emit architecture gate findings

Add findings to the report under the "Architecture Gate" section (see
Output Format below). Each finding includes the rule ID, source files,
constraint description, and whether the gate passed or failed.

## Output Format

Render the report in this exact structure:

```markdown
# Documentation Consistency Report

**Project:** [project name]
**Files analyzed:** [count]
**Entities cross-referenced:** [count]
**Date:** [date]

## Summary

| Severity | Count |
|---|---|
| Blocking | X |
| Risky | Y |
| Trivial | Z |

## Findings

### [SEVERITY] Short description

- **Source A:** `file.md` — exact quote or reference
- **Source B:** `other_file.puml` — exact quote or reference
- **Confidence:** [High/Medium/Low] ([N]/10) — reasoning
- **Type:** [contradiction | silent_reversal | ambiguity_gap | coverage_gap | naming_drift]
- **Recommendation:** What to fix and in which file

(Repeat for each finding)

## Name Graph Summary

| Name | Files | Status |
|---|---|---|
| EntityName | file1.md, file2.puml | Consistent |
| OrphanName | file1.md only | Singleton — verify intent |
| DriftName | file1.puml as "Foo", file2.md as "Bar" | Naming drift |

## Claims Extracted

| # | Source | Claim | Verified? |
|---|---|---|---|
| 1 | AGENTS.md Decision | "ShoreContact is standalone" | Contradicted by architecture.md |
| 2 | AGENTS.md Rule | "domain/ has no dependencies" | Consistent across all docs |
| ... | ... | ... | ... |

## Generation Readiness (if Phase 4 was run)

| UC ID | UC Name | Spec | Activity | Branches | Component | Verdict |
|---|---|---|---|---|---|---|
| UC-1.1 | Create Float Plan | Complete | 6/8 steps | Yes | 5/6 mappable | Partial |
| UC-2.4 | Trigger SOS | Complete | 7/7 steps | Yes | 8/8 mappable | Complete |
| UC-5.3 | Delete Crew Member | Complete | Missing | — | — | Missing |
| ... | ... | ... | ... | ... | ... | ... |

## Checklist Findings (if checklist loaded)

| Rule | Category | Severity | Finding |
|------|----------|----------|---------|
| EC-1 | Entity Classification | BLOCKING | ... |
| SC-1 | Scope Change | BLOCKING | ... |

## Deep-Dive Findings (if --deep-dive was used)

| UC | Finding | Category | Severity | Confidence |
|----|---------|----------|----------|------------|
| UC-2.4 | ... | Error Path | Risky | 7/10 |

## Architecture Gate (if Phase 5 was run)

| Rule | Source | Constraint | Status |
|------|--------|------------|--------|
| AR-1 | AGENTS.md + architecture.md | presentation/ → application/ only | Consistent |
| AR-2 | ARCHITECTURE_MATRIX.yaml + architecture.md | FlutterApp must_not_call SMSProvider | Missing from architecture.md |
| AR-3 | AGENTS.md + architecture.md | domain/ has zero dependencies | Consistent |
| AR-4 | ARCHITECTURE_MATRIX.yaml + sequence diagrams | No forbidden call paths | 2 violations found |
| AR-5 | architecture_antipatterns.md + other docs | No antipattern endorsement | Clean |
| AR-6 | AGENTS.md + architecture.md | Infrastructure uses Adapter pattern | Consistent |
```

### Confidence scoring

Rate each finding on a 1–10 confidence scale:

| Score | Meaning |
|---|---|
| 9–10 | Direct textual contradiction between two structured sources (e.g., enum values differ) |
| 7–8 | Clear contradiction between a decision and a diagram relationship |
| 5–6 | Likely contradiction but could be intentional override or different abstraction level |
| 3–4 | Possible gap or ambiguity — needs human judgment to confirm |
| 1–2 | Speculative — the agent is uncertain whether this is a real issue |

**Confidence boosters:**
- Both sources are structured (PlantUML vs. PlantUML) → +2
- Claim comes from a binding decision (AGENTS.md Section 2) → +1
- Contradiction is direct (A says X, B says not-X) → +1

**Confidence reducers:**
- One source is prose (harder to extract precise claims) → -1
- The contradiction could be intentional (different abstraction levels) → -1
- The claim uses vague language itself → -2

## Anti-patterns

**Do not compare docs to code.** This skill checks docs against other docs.
If the user wants code-vs-doc comparison, that is a different skill.

**Do not flag intentional design choices as contradictions.** If AGENTS.md
says "Sailor is conceptual" and the diagram omits Sailor, that may be
deliberate. Flag it as a "needs clarification" finding, not a blocking
contradiction, unless the omission creates a real ambiguity for implementers.

**Do not over-report.** A finding that is trivially resolved by reading one
more paragraph is noise. Only report findings that would actually cause an
implementer to make a wrong assumption.

**Do not hallucinate claims.** Only extract claims that are explicitly stated.
Do not infer implicit claims from surrounding context. If a doc is silent on
a topic, that is a gap — not a claim that can be contradicted.

**Do not flag abstraction-level differences as contradictions.** AGENTS.md
rules are prescriptive ("must do X"), while architecture.md is descriptive
("the system does X"). If both say the same thing in different registers,
that is consistent. Only flag a contradiction when the meaning actually
differs.

**Do not treat architecture matrix constraints as doc contradictions.**
If a `must_not_call` constraint exists in ARCHITECTURE_MATRIX.yaml but is
not repeated in architecture.md, that is a coverage gap (risky) — not a
contradiction. A contradiction is when one doc says "may call" and another
says "must not call" for the same pair.

## Calibration

**Small project (< 10 doc files):** Run Phases 1–3. Add Phase 4 only if
the user asks about generation readiness. Add Phase 5 if architecture rules
exist (AGENTS.md Section 4 or ARCHITECTURE_MATRIX.yaml). Report should
take < 5 minutes.

**Medium project (10–50 doc files):** Run Phases 1–3. Phase 4 is cheap
per-UC (file existence + field presence checks) — run it if the project
has activity diagrams. Phase 5 is cheap if ARCHITECTURE_MATRIX.yaml exists
(structured YAML is easy to parse) — run it by default. Focus Phase 3 on
decision propagation (Step 3.2) first — highest signal per effort.

**Large project (50+ doc files):** Run Phase 1 (name graph) first as a
triage pass. Focus Phase 3 on the highest-risk claim sources only. Run
Phase 4 only for UCs the user plans to generate sequences for. Run Phase 5
if architecture rules are present — it is low cost and high value.

## Portability

This skill works with any project that has structured documentation. It
adapts by discovery, not by configuration.

**What it needs:**
- At least 2 documentation files to cross-reference
- Some form of entity/component naming (PlantUML, markdown tables, etc.)
- Some form of architectural decisions or rules (even if just a README)

**What it does NOT need:**
- Hardcoded file paths
- Project-specific configuration
- Code access (docs-only analysis)
- Specific frameworks or languages

**Adaptation rules:**
- If no AGENTS.md exists, scan for other decision-tracking files (DECISIONS.md, ADRs, etc.)
- If no PlantUML exists, extract names from markdown headings, tables, and code blocks
- If no explicit decisions section, extract claims from any structured list of architectural choices
- The analysis pattern (name graph → claim extraction → contradiction detection) is universal