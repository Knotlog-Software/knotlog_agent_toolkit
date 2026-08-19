# NASA Appendix C — How to Write a Good Requirement

Extracted from [NASA SE Handbook, Appendix C](https://www.nasa.gov/reference/appendix-c-how-to-write-a-good-requirement/).
Used by the requirements-gatherer skill to validate requirements documents.

## C.1 — Use of Correct Terms

| Term | Meaning | Usage |
|------|---------|-------|
| **shall** | Requirement (mandatory) | Every binding requirement uses "shall" |
| **will** | Facts or declaration of purpose | "The system will be deployed to AWS" (fact) |
| **should** | Goal (recommended, not mandatory) | "The interface should be intuitive" (goal) |

**Rule:** Never interchange these terms. A requirement that uses "should" is not mandatory. If it is mandatory, it must use "shall."

## C.2 — Editorial Checklist

### Personnel Requirement Format
- State: "responsible party shall perform such and such"
- Use active voice, not passive voice

### Product Requirement Format
- State: "The [product] shall [verb] [what]"
- Example: "The system shall operate at a power level of..."
- Example: "The software shall acquire data from the..."
- Example: "The structure shall withstand loads of..."
- Example: "The hardware shall have a mass of..."

### Editorial Rules
| Rule | Check |
|------|-------|
| Consistent terminology | Product and its entities referred to consistently throughout |
| Complete with tolerances | Qualitative/performance values include bounds (less than, greater than or equal to, plus or minus, 3-sigma RSS) |
| Free of implementation | States WHAT is needed, NOT HOW to provide it |
| Free of operations descriptions | Not describing activities involving the product ("The operator shall..." is an operational statement, not a requirement) |

## C.3 — General Goodness Checklist

| # | Rule | What to check |
|---|------|---------------|
| G-1 | Grammatically correct | No grammar errors in requirement statements |
| G-2 | No typos | Free of misspellings and punctuation errors |
| G-3 | Template compliance | Follows the project's template and style rules |
| G-4 | Positive statement | Stated positively, not negatively (prefer "shall" over "shall not") |
| G-5 | TBD minimization | TBD values replaced with best estimates marked TBR (To Be Resolved) with rationale, owner, and deadline |
| G-6 | Rationale present | Each requirement accompanied by intelligible rationale including assumptions |
| G-7 | Assumptions confirmed | Assumptions validated before baselining |
| G-8 | Proper location | Requirement in the correct document section |

## C.4 — Requirements Validation Checklist

### Clarity (C.4.1)

| # | Rule | What to check |
|---|------|---------------|
| CL-1 | Unambiguous | All aspects understandable, not subject to misinterpretation |
| CL-2 | No indefinite pronouns | Free of "this", "these" without clear antecedent |
| CL-3 | No ambiguous terms | Free of "as appropriate", "etc.", "and/or", "but not limited to" |
| CL-4 | Concise and simple | Requirement is not unnecessarily complex |
| CL-5 | Single thought | One requirement per statement, one subject and one predicate |
| CL-6 | Stand-alone | No combining multiple requirements in one statement |

### Completeness (C.4.2)

| # | Rule | What to check |
|---|------|---------------|
| CO-1 | Stated completely | All incomplete requirements captured as TBD/TBR |
| CO-2 | No missing areas | Functional, performance, interface, environment, facility, transportation, training, personnel, operability, safety, security, appearance, design |
| CO-3 | Assumptions stated | All assumptions explicitly documented |

### Compliance (C.4.3)

| # | Rule | What to check |
|---|------|---------------|
| CP-1 | Correct level | Requirements at the right level (system, segment, element, subsystem) |
| CP-2 | No implementation | Free of implementation specifics |
| CP-3 | No operations | Free of descriptions of operations |
| CP-4 | No personnel assignments | Free of personnel or task assignments |

### Consistency (C.4.4)

| # | Rule | What to check |
|---|------|---------------|
| CS-1 | No contradictions | Requirements do not contradict themselves or related systems |
| CS-2 | Consistent terminology | Matches user/sponsor terminology and project glossary |
| CS-3 | Terminology uniform | Key terms consistently used and included in glossary |

### Traceability (C.4.5)

| # | Rule | What to check |
|---|------|---------------|
| TR-1 | Necessary | Each requirement is needed — ask "what is the worst that could happen if omitted?" |
| TR-2 | Bidirectional trace | Traceable to higher-level requirements, needs, goals, objectives, constraints, or ConOps |
| TR-3 | Unique reference | Each requirement uniquely numbered for subordinate document reference |

### Correctness (C.4.6)

| # | Rule | What to check |
|---|------|---------------|
| CR-1 | Factually correct | Each requirement is accurate |
| CR-2 | Assumptions correct | Each stated assumption is valid |
| CR-3 | Technically feasible | Requirements can be implemented with available technology |

### Functionality (C.4.7)

| # | Rule | What to check |
|---|------|---------------|
| FN-1 | Sufficient | All described functions necessary and together sufficient to meet goals |

### Performance (C.4.8)

| # | Rule | What to check |
|---|------|---------------|
| PF-1 | Performance specs listed | Timing, throughput, storage, latency, accuracy, precision with margins |
| PF-2 | Realistic | Each performance requirement is achievable |
| PF-3 | Tolerances defendable | Not overly tight — ask "what if tolerance was doubled or tripled?" |

### Interfaces (C.4.9)

| # | Rule | What to check |
|---|------|---------------|
| IF-1 | External interfaces defined | All external interfaces clearly specified |
| IF-2 | Internal interfaces defined | All internal interfaces clearly specified |
| IF-3 | Interfaces sufficient | All interfaces necessary, sufficient, and consistent |

### Maintainability (C.4.10)

| # | Rule | What to check |
|---|------|---------------|
| MT-1 | Measurable | Maintainability specified in measurable, verifiable manner |
| MT-2 | Weakly coupled | Requirements minimize ripple effects from changes |

### Reliability (C.4.11)

| # | Rule | What to check |
|---|------|---------------|
| RL-1 | Measurable reliability | Clearly defined, measurable, verifiable reliability requirements |
| RL-2 | Error handling | Error detection, reporting, handling, and recovery requirements |
| RL-3 | Undesired events | Single-event upset, data loss, operator error considered with required responses |
| RL-4 | Sequence assumptions | Assumptions about intended function sequences stated and verified |
| RL-5 | Fault survivability | Survivability after software/hardware faults addressed for hardware, software, operations, personnel, and procedures |

### Verifiability / Testability (C.4.12)

| # | Rule | What to check |
|---|------|---------------|
| VT-1 | Testable | System can be tested, demonstrated, inspected, or analyzed to show compliance |
| VT-2 | Level-appropriate | Verification can be done at the level the requirement is stated |
| VT-3 | Measurable criteria | Means exist to measure accomplishment; verification criteria can be stated |
| VT-4 | Precise statements | Requirements stated precisely enough for test success criteria |
| VT-5 | No unverifiable terms | Free of: flexible, easy, sufficient, safe, ad hoc, adequate, accommodate, user-friendly, usable, when required, if required, appropriate, fast, portable, light-weight, small, large, maximize, minimize, robust, quickly, easily, clearly, other "-ly" words, other "-ize" words |

### Data Usage (C.4.13)

| # | Rule | What to check |
|---|------|---------------|
| DU-1 | Don't care conditions | Where "don't care" conditions exist, verify they are truly irrelevant and explicitly stated |

## Focus Area Mapping

The red-teamer maps focus areas to NASA checklist sections:

| Focus Area | Primary NASA Sections | Additional Sections |
|------------|----------------------|---------------------|
| `completeness` | CO-1, CO-2, CO-3, TR-1, TR-2 | FN-1, IF-1, IF-2 |
| `clarity` | CL-1 through CL-6, G-1 through G-4 | CS-2, CS-3 |
| `verifiability` | VT-1 through VT-5, PF-1 through PF-3 | MT-1 |
| `consistency` | CS-1, CS-2, CS-3, C.1 terminology | TR-3 |
| `feasibility` | CR-1, CR-2, CR-3, FN-1 | PF-2, PF-3 |
| `edge-cases` | RL-1 through RL-5, IF-1 through IF-3 | DU-1, MT-2 |
