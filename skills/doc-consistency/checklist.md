# Documentation Completeness Checklist

Structural validation rules derived from ADHD deep-dive analysis. These
catch design holes that basic field-presence and step-count checks miss.
Load this file in Phase 4.2 (spec completeness) and Pre-flight Step 4
(input validation) of generate-sequence.

## How to use

Each rule has:
- **ID:** Stable identifier for reporting
- **Category:** Grouping for batch analysis
- **Severity:** blocking | risky | trivial
- **Check:** What to verify
- **Fail signal:** What the user sees when the rule is violated

Rules are checked against use case specs, activity diagrams, and cross-
artifact references. Not every rule applies to every UC — skip rules
where the UC has no relevant surface area.

---

## Entity Classification Consistency

### EC-1: Entity vs Value Object agreement
- **Check:** Every entity named in the domain model narrative must have
  the same classification (entity vs value object) in the domain model
  diagram. If one says "entity" and the other says "value object", that
  is a contradiction.
- **Fail signal:** "[BLOCKING] EntityName classified as <X> in
  domain_model.md but <Y> in domain_model.puml"

### EC-2: Aggregate owner consistency
- **Check:** Every entity that is an aggregate root in the domain model
  diagram must have a corresponding repository interface in the domain
  model narrative. If the diagram shows `*--` (composition) from A to B,
  and B is standalone elsewhere, the relationship type is contradictory.
- **Fail signal:** "[BLOCKING] EntityName is composed inside Parent in
  diagram but described as standalone aggregate in narrative"

### EC-3: Deleted/renamed entity propagation
- **Check:** If a decision says an entity was renamed, deleted, or
  merged, verify that NO other doc still references the old name without
  an explicit "formerly known as" note.
- **Fail signal:** "[BLOCKING] OldEntityName still referenced in
  file.md despite being renamed to NewEntityName in AGENTS.md"

---

## Scope Change Propagation

### SC-1: Dropped feature cleanup
- **Check:** If a decision says a feature or use case was "dropped" or
  "deferred", verify that no other doc still lists it as "planned" or
  "in progress" without acknowledging the drop.
- **Fail signal:** "[BLOCKING] FeatureName listed as 'planned' in
  architecture.md but 'dropped' in AGENTS.md Section 2"

### SC-2: Out-of-scope enforcement
- **Check:** If a decision says something is "out of scope", verify that
  no diagram models it as an active component or relationship.
- **Fail signal:** "[RISKY] OutOfScopeFeature modeled in diagram despite
  being out of scope per AGENTS.md"

### SC-3: Scope addition without decision
- **Check:** If a new entity, relationship, or component appears in a
  diagram that was not in the previous iteration's docs, there should be
  a corresponding decision or iteration note acknowledging the addition.
- **Fail signal:** "[RISKY] NewEntity appears in diagram without
  corresponding decision or iteration note"

---

## Interface Completeness

### IC-1: Repository interface for every aggregate
- **Check:** Every aggregate root in the domain model must have a
  repository interface declared in the domain/repositories/ layer. If
  the domain model shows an aggregate but no repository interface exists
  for it, the architecture is incomplete.
- **Fail signal:** "[RISKY] AggregateRoot has no repository interface
  in domain/repositories/"

### IC-2: Service interface for every domain service
- **Check:** Every domain service described in the domain model narrative
  should have a corresponding interface. If the narrative describes a
  service but no interface exists, the architecture is incomplete.
- **Fail signal:** "[RISKY] ServiceName described in narrative but no
  interface found in domain/services/"

### IC-3: Diagram includes all declared interfaces
- **Check:** If the domain model diagram lists repository or service
  interfaces, verify that every interface declared in the narrative
  appears in the diagram. Missing interfaces mean the diagram is stale.
- **Fail signal:** "[RISKY] IInterfaceName declared in narrative but
  absent from domain model diagram"

---

## Cross-UC Integration

### IU-1: UC trigger chain completeness
- **Check:** If UC-A's spec says it "triggers" or "extends" UC-B, then
  UC-B's spec should acknowledge the relationship. Unidirectional
  triggers are a gap — the implementer cannot know what UC-B must
  prepare for.
- **Fail signal:** "[RISKY] UC-A triggers UC-B but UC-B spec has no
  mention of incoming trigger"

### IU-2: Shared entity state handoff
- **Check:** If two UCs both mutate the same entity (e.g., FloatPlan),
  verify that the entity's state transitions are defined in a single
  authoritative source (e.g., domain model or state diagram). If UC-A
  says status goes Active→SOS and UC-B says Active→Completed, there
  must be an explicit state machine that reconciles both.
- **Fail signal:** "[RISKY] UC-A and UC-B define conflicting status
  transitions for EntityName"

### IU-3: Postcondition-to-precondition chain
- **Check:** If UC-A's postcondition is the precondition for UC-B (i.e.,
  UC-B cannot start unless UC-A has completed), verify that UC-B's
  precondition explicitly states this dependency. Implicit chains force
  the implementer to guess ordering.
- **Fail signal:** "[RISKY] UC-B requires UC-A to have completed but
  its precondition does not state this"

### IU-4: Error propagation across UCs
- **Check:** If UC-A triggers UC-B and UC-B can fail, UC-A's alternate
  flow should describe what happens when UC-B fails. Silent failures
  across UC boundaries are the hardest bugs to find.
- **Fail signal:** "[RISKY] UC-A triggers UC-B but has no alternate flow
  for UC-B failure"

---

## Spec Depth

### SD-1: Alternate flow completeness
- **Check:** If the main flow has a validation step (e.g., "System
  validates X"), there should be an alternate flow describing what
  happens when validation fails. A validation step without a failure
  path forces the implementer to invent error behavior.
- **Fail signal:** "[RISKY] Main flow step N validates X but no
  alternate flow handles validation failure"

### SD-2: Side effect enumeration
- **Check:** If the main flow includes steps that have side effects
  (sending notifications, updating other entities, scheduling jobs),
  those side effects should be explicitly listed. Steps that say "System
  processes X" without specifying the side effects are ambiguous.
- **Fail signal:** "[TRIVIAL] Main flow step N has unenumerated side
  effects"

### SD-3: Actor specificity
- **Check:** Every step in the main flow should identify which actor or
  system component performs it. Steps that say "System does X" without
  implying a specific component are generic — acceptable for high-level
  specs but insufficient for generation.
- **Fail signal:** "[TRIVIAL] Step N uses generic 'System' without
  implying a specific component"

### SD-4: Precondition sufficiency
- **Check:** The precondition should be strong enough that if it holds,
  the main flow can execute without unexpected blocks. If the main flow
  has a step that could fail for reasons not covered by the precondition,
  the precondition is insufficient.
- **Fail signal:** "[RISKY] Precondition does not cover failure mode
  encountered in main flow step N"

---

## Diagram Specificity

### DS-1: Activity diagram branch coverage
- **Check:** If the use case spec has alternate flows, the activity
  diagram must model at least one branch per alternate flow. An activity
  diagram that is purely linear when the spec has branches is incomplete.
- **Fail signal:** "[RISKY] Spec has N alternate flows but activity
  diagram has 0 branches"

### DS-2: Activity diagram action specificity
- **Check:** Activity diagram action nodes should name concrete
  components or at least imply them (e.g., "AlertService sends alert"
  is concrete, "System handles alert" is generic). Diagrams that are
  entirely generic reduce the confidence of downstream generation.
- **Fail signal:** "[TRIVIAL] Activity diagram is entirely generic —
  all nodes say 'System does X'"

### DS-3: Component diagram method visibility
- **Check:** If a sequence diagram is being generated, the component
  diagram should show method signatures (or at least method names) for
  the classes involved. Component diagrams with only class names force
  the generator to invent method names.
- **Fail signal:** "[TRIVIAL] Component diagram shows class names but
  no method signatures"

---

## Naming Drift

### ND-1: Cross-artifact name consistency
- **Check:** The same concept must use the same name across all docs.
  "Sailor" in AGENTS.md must not become "User" in use case specs or
  "BoatOwner" in diagrams without an explicit alias declaration.
- **Fail signal:** "[RISKY] ConceptName appears as NameA in file1 and
  NameB in file2"

### ND-2: Interface naming convention
- **Check:** Repository and service interfaces should follow a consistent
  naming convention (e.g., `I` prefix, `Repository` suffix). If some
  interfaces use `I` prefix and others don't, that is naming drift.
- **Fail signal:** "[TRIVIAL] Interface naming convention inconsistent:
  some use I prefix, others don't"

---

## Architecture Rule Consistency

### AR-1: Layer dependency rule propagation
- **Check:** Every architecture rule about layer dependencies in AGENTS.md
  must be stated consistently in architecture.md. If AGENTS.md says
  "presentation/ depends on application/ only" but architecture.md says
  "presentation/ depends on application/ and domain/", that is a
  contradiction.
- **Fail signal:** "[BLOCKING] Layer dependency rule differs between
  AGENTS.md and architecture.md"

### AR-2: Call graph consistency with ARCHITECTURE_MATRIX
- **Check:** If ARCHITECTURE_MATRIX.yaml exists, every service and its
  `may_call`/`must_not_call` constraints must be reflected in
  architecture.md. Services or constraints in YAML but absent from
  architecture.md mean the narrative is stale.
- **Fail signal:** "[BLOCKING] ServiceName has must_not_call constraint in
  ARCHITECTURE_MATRIX.yaml but architecture.md does not document this
  restriction"

### AR-3: Golden rule documentation
- **Check:** The rule "domain layer has zero framework dependencies" must
  appear in both AGENTS.md and architecture.md. If either doc is silent or
  contradicts this, the architecture gate fails.
- **Fail signal:** "[BLOCKING] Golden rule (domain zero dependencies)
  missing or contradicted in architecture.md"

### AR-4: Forbidden call path in diagrams
- **Check:** Sequence diagrams and component diagrams must not depict call
  paths that violate ARCHITECTURE_MATRIX.yaml `must_not_call` constraints.
  For example, a sequence diagram showing FlutterApp → SMSProvider
  violates the matrix.
- **Fail signal:** "[BLOCKING] SequenceDiagramName shows forbidden call
  path: ServiceA → ServiceB (must_not_call per ARCHITECTURE_MATRIX.yaml)"

### AR-5: Antipattern acknowledgment
- **Check:** If architecture_antipatterns.md documents known antipatterns,
  no other doc should describe the same pattern as the "correct" approach
  without acknowledging the antipattern doc.
- **Fail signal:** "[RISKY] DocName describes pattern that matches
  antipattern N in architecture_antipatterns.md"

### AR-6: Platform adapter consistency
- **Check:** If AGENTS.md or architecture.md says infrastructure uses
  "Adapter" pattern (thin wrappers), verify that no doc describes
  infrastructure implementations as thick orchestration layers. The
  adapter pattern constraint should propagate.
- **Fail signal:** "[RISKY] Infrastructure implementation described as
  thick orchestrator in DocName, contradicting Adapter pattern rule in
  AGENTS.md"

---

## Extraction Metadata

When running `--extract-checklist`, the following fields are added to
each rule to track when it was extracted and from which analysis:

```yaml
extracted_from: "adhd-deep-dive"
extracted_date: "2026-07-23"
extraction_run_id: "<uuid>"
```

This metadata is not checked during validation — it is for auditability.
