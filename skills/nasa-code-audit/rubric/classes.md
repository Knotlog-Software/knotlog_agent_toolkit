# NASA Software Classes — Maturity Verdict Rubric

Definitions from NPR 7150.2D, Appendix D ("Software Classifications"),
condensed. The five underlying factors NASA uses: (1) usage of the
software with or within a NASA system, (2) criticality to NASA major
programs/projects, (3) extent to which humans depend upon the system,
(4) developmental and operational complexity, (5) extent of the
Agency's investment.

This file supports two judgments at audit time:

1. **Classification inference** — Which class does this codebase's
   *intended use* correspond to?
2. **Maturity verdict** — To what class's *actual requirements practice*
   does this codebase rise?

The verdict sentence of an audit compares fact (present practice) to
aspiration (target class the user names, or inferred), and produces:

- "This codebase currently evidences Class <X> practice" — the highest
  class whose requirement suite the codebase would pass
- "Largest gaps to reach target Class <Y>: ..." — top 3–5 Blocking
  items whose remediation would raise the verdict

---

## Class definitions (condensed from Appendix D, NPR 7150.2D)

| Class | Name | Kind of software |
|---|---|---|
| A | Human-rated space software systems | Ground and flight software needed for a primary mission objective of human space flight and directly interacting with human space flight systems |
| B | High-priority / primary mission space systems | Primary mission-essential space systems, or systems whose anomalous behavior could cause significant harm or loss; includes test/demonstration vehicles meeting Class A/B levels |
| C | Mission support / aeronautics / major facilities | Flight or ground software for non-primary science return, aeronautics vehicle software, software operating a major engineering/research facility, airborne vehicle software |
| D | Subsystem or component level flight/ground software | Software supporting a single subsystem or component; modest complexity, limited personnel exposure, analog to DO-178/DO-254 "Class D" (no system-function failure) |
| E | Design concept, research, technology, general purpose | Hypothesis-exploring or general purpose software (word processors, spreadsheets, presentation apps); not used for operational Class A–C decisions |
| F | (NPR 7120.7 domain) Business and IT software | Highest-risk business/IT software |

Notes:
- Classes F/G/H cover business/IT software in decreasing order of
  applicability under the companion NPR — for practical auditing treat
  G/H as "Class E-like" general purpose. The audit harness expresses
  the verdict in the A–F letter set.
- Safety-critical vs not-safety-critical is an *independent*
  designation (NASA-STD-8739.8, Appendix A hazard criteria). The audit
  asks the user about it in pre-flight but never infers it.

## Applicability weights (rubric items per class)

| Rubric layer | A | B | C | D | E | F/G/H |
|---|---|---|---|---|---|---|
| Power of Ten (POT-1..10) | Full | Full | Full | Core-4 + POT-2, POT-5 | Core-4 only | Core-4 only |
| CQ-1 through CQ-9 (discipline/robustness/data) | Full | Full | Full | Core, style-lax | Core-3 (CQ-2, CQ-7, CQ-9) | Core-3 |
| CQ-10 testing | Full | Full | Core | Core, scope-lax | Advisory | Advisory |
| CQ-11 CI-run tests | Full | Full | Core | Advisory | Advisory | Advisory |
| CQ-12 traceability | Full | Full | Core | Applicable | Advisory | Advisory |
| DOC-1..DOC-9 (documentation.md minimum set table) | Full | Full | Full per its table | D row of its table | E/G row of its table | E-like |

Where "Core-4" means: POT-1 (control flow), POT-3 (resource growth),
POT-7 (return/param checking), POT-10 (static analysis). "Core-3"
means: CQ-2 (no unintended functions), CQ-7 (boundary validation),
CQ-9 (secrets).

## Verdict computation

1. Score every rubric item for the **target** class (user-specified or
   inferred), ignoring items marked N/A. Verdict per item:
   Pass = full credit, Partial = half credit, Fail = zero.
2. **Current-practice class** = highest class X where the class-X
   core set would score ≥ 85% and no core Failure exists.
3. **Verdict sentence** = "currently evidences Class X practice";
   then the gap list toward the target class: all target-core items
   scoring below Pass, ordered Blocking → Risky → Trivial, take top 5.
4. If the codebase fails even the Core-4 items of a below-E class
   practice level, state that candidly: "below Class E practice; the
   following fundamentals are missing: ..." — this is a valid, useful
   audit outcome and a normal starting point.

## Classification inference guide

When the user does not name a target class, infer one from the repo
evidence (deployment target, domain language, docs) using:

| Repo evidence suggests | Candidate class |
|---|---|
| Aviation/aerospace/medical flown or human-safety-critical code | A–B |
| Real spacecraft/major instrument/flight control participation | B–C |
| Operator-facing tooling for critical ops, major facility control | C–D |
| Component library / driver subsystem feeding such systems | D |
| Business/production web app, internal tooling, research prototype | E |

Always present the inference as a question for the user to confirm in
the report header; the audit measures against the confirmed target,
not the inference itself.
