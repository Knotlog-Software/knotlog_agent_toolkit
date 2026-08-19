# Requirements: [Project Name]

**Version:** 0.1 (DRAFT)
**Date:** [YYYY-MM-DD]
**Status:** Draft | Under Review | Baselined
**Author:** [name or "AI-assisted, pending human review"]

---

## 1. Purpose & Scope

<!-- Why does this system/product need to exist? What problem does it solve? -->
<!-- What is IN scope and what is OUT of scope? Be explicit about boundaries. -->

### 1.1 Problem Statement

[Describe the problem this system solves.]

### 1.2 Scope

**In Scope:**
- [What this system/product will do]

**Out of Scope:**
- [What this system/product will NOT do]

### 1.3 Purpose

[One paragraph: the purpose of this requirements document and what it governs.]

---

## 2. Stakeholders & Actors

<!-- Every person or system that interacts with or is affected by this product. -->

| ID | Name | Role | Relationship |
|----|------|------|-------------|
| ST-01 | [name] | [role] | [how they interact] |

---

## 3. Concepts of Operations (ConOps)

<!-- High-level user flows and operational scenarios. -->
<!-- Describe HOW the system will be used, not HOW it is built. -->

### 3.1 Operational Scenario 1: [Name]

[Describe the scenario from the user's perspective.]

### 3.2 Operational Scenario 2: [Name]

[Describe the scenario from the user's perspective.]

---

## 4. Functional Requirements

<!-- Format: FR-NNN: "The [product] shall [verb] [what] [tolerances]" -->
<!-- One requirement per row. Active voice. Positive statement. -->
<!-- Use "shall" for mandatory, "should" for goals, "will" for facts. -->

| ID | Requirement | Rationale | Priority |
|----|------------|-----------|----------|
| FR-001 | The system shall [verb] [what]. | Because [rationale]. | Must |
| FR-002 | The system shall [verb] [what]. | Because [rationale]. | Must |
| FR-003 | The system should [verb] [what]. | Because [rationale]. | Should |

---

## 5. Performance Requirements

<!-- Measurable performance specifications with tolerances. -->
<!-- Include: timing, throughput, capacity, accuracy, precision, latency. -->

| ID | Requirement | Metric | Tolerance | Rationale |
|----|------------|--------|-----------|-----------|
| PR-001 | The system shall [performance claim]. | [how measured] | [+/- tolerance] | Because [rationale] |

---

## 6. Interface Requirements

<!-- External and internal interfaces. -->
<!-- Define boundaries clearly — who/what connects to whom. -->

### 6.1 External Interfaces

| ID | Interface | Description | Protocol/Standard |
|----|-----------|-------------|-------------------|
| IF-001 | [name] | [what it connects] | [protocol] |

### 6.2 Internal Interfaces

| ID | Interface | Description | Protocol/Standard |
|----|-----------|-------------|-------------------|
| II-001 | [name] | [what it connects] | [protocol] |

---

## 7. Non-Functional Requirements

<!-- Reliability, maintainability, security, safety, usability, scalability. -->

| ID | Category | Requirement | Rationale |
|----|----------|------------|-----------|
| NF-001 | Reliability | The system shall [reliability claim]. | Because [rationale] |
| NF-002 | Security | The system shall [security claim]. | Because [rationale] |
| NF-003 | Usability | The system shall [usability claim]. | Because [rationale] |

---

## 8. Constraints & Assumptions

<!-- Design constraints, regulatory, technology, resource constraints. -->
<!-- Each assumption explicitly stated with rationale. -->

### 8.1 Constraints

| ID | Constraint | Source | Rationale |
|----|-----------|--------|-----------|
| CO-001 | [constraint] | [regulatory, technical, etc.] | [why] |

### 8.2 Assumptions

| ID | Assumption | Status | Confirmed By | Date |
|----|-----------|--------|-------------|------|
| AS-001 | [assumption] | Confirmed / Unconfirmed | [who] | [date] |

---

## 9. Glossary

<!-- Key terms defined to prevent ambiguity across all requirements. -->

| Term | Definition |
|------|-----------|
| [term] | [definition] |

---

## 10. Open Questions (TBR)

<!-- Each unresolved item captured as TBR with: what, who, by when. -->
<!-- Per NASA: prefer TBR over TBD. Include rationale for the best estimate. -->

| ID | Question | Owner | Target Date | Best Estimate |
|----|----------|-------|-------------|---------------|
| TBR-001 | [question] | [who] | [date] | [current best guess] |

---

## 11. Requirements Traceability

<!-- Each requirement traced to a purpose/goal from Section 1 or stakeholder need. -->
<!-- Ensures every requirement is necessary and justified. -->

| Requirement ID | Traced To | Justification |
|---------------|-----------|---------------|
| FR-001 | [Section 1.1 / ST-01 / ConOps scenario] | [why this requirement is needed] |

---

## 12. Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | [date] | [author] | Initial draft |
