---
name: requirements-gatherer
description: >
  Interactive requirements engineering skill using NASA Appendix C
  standards. Gathers requirements through a conversational Q&A loop,
  drafts a structured document with shall/will/should terminology,
  then spawns parallel red-team sub-agents to find gaps. Loops until
  red-team agents find zero blocking issues. Produces a NASA-compliant
  requirements document at docs/requirements/requirements.md. Use when
  the user wants to define requirements for a new system, feature, or
  product. Covers software features, system architecture, user stories,
  and general product requirements. Skip for: code implementation,
  debugging, single-file changes, or tasks that don't need structured
  requirements.
license: MIT
---

# Requirements Gatherer

An interactive requirements engineering skill that transforms a user's
idea into a NASA Appendix C-compliant requirements document through a
conversational Q&A loop with parallel red-team validation. The skill
orchestrates three sub-agents: a drafter (writes requirements), N
red-teamers (find gaps), and a questioner (generates follow-up
questions). The loop continues until red-team agents find zero blocking
issues.

## Pre-flight

Run before Phase 1. Minimal discovery — this skill works from the
user's idea, not from existing project artifacts.

**Step 1. Check for existing requirements.**

Scan the project for an existing requirements document:

| Scan pattern | What it means |
|---|---|
| `docs/requirements/requirements.md` | Previous requirements exist — load as baseline |
| `**/requirements*.md` | Requirements in non-standard location — confirm with user |
| None found | Fresh start — no baseline |

If a previous requirements document exists, ask the user:
- "Should I revise the existing requirements, or start fresh?"

If revising, load the existing document as context for the drafter.
If starting fresh, ignore the existing document.

**Step 2. Configure red-team.**

Ask the user (or use defaults):

| Setting | Default | Options |
|---|---|---|
| Number of red-teamers | 2 | 1-6 |
| Focus areas | `completeness` + `clarity` | `completeness`, `clarity`, `verifiability`, `consistency`, `feasibility`, `edge-cases` |
| Convergence mode | Red team finds nothing blocking | Also accept: user declares done |

If the user provides no preference, use defaults.

**Step 3. Set output path.**

Determine where to write the requirements document:

| Priority | Path |
|---|---|
| User-specified | Use the path the user provides |
| Existing doc found | Overwrite the existing document |
| Default | `docs/requirements/requirements.md` |

Create the directory if it does not exist.

## Phase 1 — Initial Q&A

Start the conversation. The goal is to understand the user's idea
well enough to draft a first version of the requirements.

**Step 1.1 — Ask the big question.**

Start with a single open-ended question:

> "Tell me about what you want to build. What problem does it solve,
> who is it for, and what should it do at a high level?"

**Step 1.2 — Ask 3-5 clarifying questions.**

Based on the user's initial description, ask targeted questions.
Choose from these categories based on what information is missing:

| Category | Example Questions |
|---|---|
| **Actors & Users** | "Who will use this system? Are there different user roles?" |
| **Scope** | "What is definitely NOT part of this system?" |
| **Core behavior** | "What happens when [edge case X]?" |
| **Performance** | "Are there speed, capacity, or reliability expectations?" |
| **Interfaces** | "Does this need to connect to any existing systems or APIs?" |
| **Constraints** | "Are there technology, regulatory, or timeline constraints?" |
| **Success criteria** | "How will you know this system is successful?" |

Do NOT ask more than 7 total questions in this phase. The goal is
sufficient context to draft, not exhaustive detail — gaps will be
found by the red team.

**Step 1.3 — Confirm understanding.**

Before moving to drafting, paraphrase the user's answers back:

> "Let me confirm my understanding: [2-3 sentence summary].
> Is that right, or did I miss anything?"

Wait for confirmation before proceeding.

## Phase 2 — Draft Requirements

Spawn the `requirements-drafter` sub-agent with the full context.

**Step 2.1 — Build the drafter's context.**

Pass the drafter:
- The Project Context block (if available from the project)
- The complete Q&A transcript (initial idea + all clarifying Q&A)
- The requirements template from `skills/requirements-gatherer/template.md`
- The NASA checklist from `skills/requirements-gatherer/nasa-checklist.md`
- The output file path
- Any existing requirements document (if revising)

**Step 2.2 — Spawn the drafter.**

Invoke the `requirements-drafter` sub-agent. It will:
1. Draft all 12 sections of the requirements document
2. Apply NASA writing rules (shall/will/should, active voice, etc.)
3. Run a self-check against C.1-C.3
4. Write the document to the output path
5. Return a summary with requirement counts and confidence level

**Step 2.3 — Acknowledge and proceed.**

When the drafter returns, summarize for the user:
- Number of requirements drafted (by type)
- Number of TBR items (unresolved)
- Confidence level
- Note that red-team review is starting

Do NOT wait for user approval before proceeding to Phase 3. The red
team will catch issues — the user will be asked questions in Phase 5.

## Phase 3 — Red Team (Parallel Sub-agents)

Spawn N red-teamer sub-agents in parallel, each with a different focus
area. This is the core validation loop.

**Step 3.1 — Prepare red-teamer prompts.**

For each red-teamer, build a prompt containing:
- The requirements document path
- The assigned focus area (e.g., `completeness`, `clarity`)
- The relevant NASA checklist sections (from `nasa-checklist.md`)
- The document version number

**Step 3.2 — Spawn red-teamers in parallel.**

Spawn all red-teamers simultaneously. Each is isolated — they do not
see each other's output. This prevents anchoring.

```
For each focus_area in [configured focus areas]:
  spawn requirements-red-teamer with:
    - document path
    - focus area
    - NASA checklist sections for this focus area
```

**Step 3.3 — Collect reports.**

Wait for all red-teamers to complete. Collect their reports. Each
report contains:
- Blocking issues (with requirement IDs and NASA rule references)
- Risky issues
- Trivial issues
- Passed checks
- Overall verdict (PASS/FAIL)

## Phase 4 — Evaluate Convergence

Analyze the red-team reports to determine if the requirements are
complete enough to finalize.

**Step 4.1 — Aggregate findings.**

Combine all red-team reports into a single summary:

| Metric | Value |
|---|---|
| Total blocking issues | N |
| Total risky issues | N |
| Total trivial issues | N |
| Requirements reviewed | N |
| Passed checks | N |

**Step 4.2 — Check convergence criteria.**

| Condition | Result |
|---|---|
| Zero blocking issues | **CONVERGED** — proceed to Phase 6 (Finalize) |
| Blocking issues exist, but user said "done enough" | **CONVERGED BY USER OVERRIDE** — proceed to Phase 6 |
| Blocking issues exist | **NOT CONVERGED** — proceed to Phase 5 (Questions) |

**Step 4.3 — Present the red-team summary to the user.**

Show the user a concise summary:

```
Red Team Review — Iteration [N]

Found: [X] blocking, [Y] risky, [Z] trivial issues.

Blocking issues:
- [FR-003]: [one-line description]
- [PR-001]: [one-line description]
...

Risky issues:
- [FR-007]: [one-line description]
...

The document needs revision. I'll generate questions to resolve the
blocking issues.
```

## Phase 5 — Generate Questions and Loop

If not converged, generate questions from the red-team findings and
ask the user.

**Step 5.1 — Spawn the questioner.**

Pass the questioner:
- The requirements document path
- All red-team reports (from Phase 3)
- The Q&A history (all prior questions and answers)
- The current document version

The questioner will:
1. Deduplicate findings across reports
2. Filter out questions already answered in prior Q&A
3. Generate targeted questions framed in NASA terminology
4. Prioritize by severity (blocking first)
5. Add a catch-all question

**Step 5.2 — Present questions to the user.**

Show the questions to the user. Group by priority:

```
I found [N] issues that need your input:

**Must resolve:**
1. [Question about FR-003] — this requirement uses "user-friendly"
   which is unverifiable. What measurable criterion should replace it?
   - Suggested: "complete task in under 3 clicks"
   - Or: "achieve SUS score above 80"
   ...

**Should resolve:**
2. [Question about FR-007] — ...

**Anything else?**
3. Is there anything else about this system we haven't covered?
```

**Step 5.3 — Collect user answers.**

Wait for the user to respond. Capture all answers.

**Step 5.4 — Loop back to Phase 2.**

With the new answers, go back to Phase 2 (Draft Requirements).
The drafter will receive:
- The full Q&A history (original + all revisions)
- The existing requirements document (to revise, not rewrite)
- All red-team reports from prior iterations
- The questioner's question set (with user's new answers)

The drafter updates the document in-place, addressing the findings.
The document version increments (0.1 → 0.2 → 0.3 → ...).

**Step 5.5 — Repeat Phases 3-5.**

After the drafter revises, re-run the red team (Phase 3), evaluate
(Phase 4), and generate questions if needed (Phase 5).

## Phase 6 — Finalize

When convergence is reached (zero blocking issues or user override).

**Step 6.1 — Final document polish.**

Ensure the document has:
- Correct version number (incremented through iterations)
- Status set to "Under Review" (or "Baselined" if user approves)
- All TBR items listed in Section 10 with best estimates
- Complete traceability matrix in Section 11
- Change log updated with all iterations

**Step 6.2 — Present final summary.**

Show the user:

```
Requirements Document Complete

**File:** docs/requirements/requirements.md
**Version:** 0.N
**Iterations:** [count]

**Requirements summary:**
- Functional (FR): [count]
- Performance (PR): [count]
- Interfaces (IF/II): [count]
- Non-functional (NF): [count]

**Quality:**
- Blocking issues: 0
- Risky issues: [N] (not blocking)
- Trivial issues: [N]
- Traceability coverage: [X]%

**Open items (TBR):**
- [count] items marked To Be Resolved
- See Section 10 for details

Next steps:
- Review the document at docs/requirements/requirements.md
- Resolve TBR items by their target dates
- When ready, set status to "Baselined"
```

**Step 6.3 — Optionally spawn final validation.**

If the user wants extra confidence, offer to run one more red-team
pass focused on `consistency` to verify the final document has no
internal contradictions.

## Ground rules

- **Context injection over discovery.** Subagents receive everything
  they need in the task prompt. They do not read `AGENTS.md` or
  re-discover project conventions. The orchestrator passes the NASA
  checklist, template, and full Q&A history.
- **Thinking budget.** Each subagent has a limited number of file reads.
  Drafter: 5 reads. Red-teamer: 3 reads. Questioner: 3 reads. If a
  subagent needs more, it stops and reports the blocker.
- **Fresh context per subagent.** Every subagent invocation receives
  the complete context for that iteration. No subagent relies on prior
  conversation turns.
- **Each subagent returns one report.** The orchestrator captures it
  and routes it forward.
- **NASA terminology is mandatory.** All requirements use shall/will/should
  per Appendix C. The drafter enforces this; the red-teamer validates it.
- **No implementation in requirements.** Requirements state WHAT, not HOW.
  The drafter is instructed to avoid this. The red-teamer catches violations.
- **TBR over TBD.** Per NASA guidance, unresolved values use TBR (To Be
  Resolved) with rationale, owner, and target date — never bare TBD.
- **Parallel red-teamers are isolated.** Each red-teamer sees only the
  requirements document and its own focus area. No cross-contamination.
- **User controls convergence.** The default is zero blocking issues, but
  the user can force convergence at any point.

## Configuration

The skill adapts to the user's needs. Key configuration points:

| Setting | Source | Default |
|---|---|---|
| Number of red-teamers | User preference | 2 |
| Focus areas | User preference | `completeness` + `clarity` |
| Convergence mode | User preference | Zero blocking issues |
| Output path | User-specified or auto | `docs/requirements/requirements.md` |
| Existing requirements | Auto-discovered | Revisions if found, fresh if not |

## Calibration

**Simple feature (1-3 actors, straightforward behavior):**
Initial Q&A: 3 questions. Draft: ~20 requirements. Red team: 2 agents.
Estimated time: 5-10 minutes total.

**Moderate system (3-7 actors, multiple interfaces):**
Initial Q&A: 5 questions. Draft: ~50 requirements. Red team: 3 agents.
Estimated time: 10-20 minutes total.

**Complex system (7+ actors, external integrations, regulatory):**
Initial Q&A: 7 questions. Draft: ~100+ requirements. Red team: 4-6 agents.
Multiple iterations likely. Estimated time: 20-40 minutes total.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| **Skipping the initial Q&A** | The drafter has no context and produces generic, useless requirements |
| **Asking too many initial questions** | Overwhelms the user before any value is delivered — cap at 7 |
| **Drafting without NASA self-check** | Low-hanging fruit (grammar, terminology) wastes red-team cycles |
| **Running red-teamers sequentially** | Slower with no quality benefit — parallelize all red-teamers |
| **Red-teamers with overlapping focus** | Causes duplicate findings and wastes sub-agent cycles — each gets one focus |
| **Not deduplicating red-team findings** | Multiple agents flagging the same issue creates confusion — questioner deduplicates |
| **Ignoring risky findings** | Risky issues become blocking issues in later iterations — address them early |
| **Reaching for implementation details** | Requirements describe WHAT, not HOW — never ask or answer technology questions |
| **Not tracking the change log** | User loses visibility into what changed between iterations — always update |
| **Letting the loop run forever** | Diminishing returns after 3-4 iterations — escalate to user if stuck |

## Edge Cases

| Scenario | Handling |
|---|---|
| **User provides a one-sentence idea** | Accept it. Start with Phase 1.1 to get more detail. Do not assume or invent. |
| **User says "just write what you think"** | Refuse. The skill requires user input to produce valid requirements. Ask at minimum 3 questions. |
| **Existing requirements document is stale** | Ask user: revise or start fresh. If revising, load as context but do not treat as authoritative. |
| **User wants to add a requirement mid-loop** | Accept it. Pass to the drafter in the next iteration. Assign ID and trace it. |
| **Red team finds zero issues on first pass** | Rare but valid. Finalize immediately. Show the user the clean report. |
| **Same blocking issue persists across 3+ iterations** | Stop looping. Surface the issue to the user with full context and ask for a decision. |
| **User wants fewer red-teamers** | Respect the preference. Even 1 red-teamer is better than none. |
| **User wants to change focus areas mid-loop** | Accept it. Adjust the focus areas for the next red-team iteration. |
| **Requirements document exceeds 200 requirements** | Suggest splitting into multiple documents by subsystem or feature area. |
| **User asks for a specific NASA section not in checklist** | Load the full NASA Appendix C from the checklist file and apply the requested section. |

## Invocation

The skill is invoked by the user asking to define requirements.
Recognized invocation patterns:

```
# Direct requests
gather requirements for my app
write requirements for [project name]
I need to define requirements for [feature]
let's spec out the requirements

# Specific types
write software requirements for [description]
define system requirements for [description]
create a requirements document for [description]

# Revision requests
revise the existing requirements
update the requirements document
review and improve our requirements
```

When the user's intent is ambiguous, ask clarifying questions:
- "Are you defining requirements for a new system, or revising existing ones?"
- "Is this a software feature, a full system, or a product requirement set?"
