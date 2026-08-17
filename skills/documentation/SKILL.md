---
name: documentation
description: >
  Full documentation lifecycle for a 2-person full-stack team. Covers
  five workflows: Documentation Audit (assess current state, find gaps,
  prioritize), Doc Generation (discover, outline, draft, review, publish),
  Architecture Documentation (capture decisions, diagram, validate),
  API Documentation (discover endpoints, describe, add examples, validate),
  and Knowledge Management (organize, link, update, archive). Project-agnostic
  — adapts to any doc format (markdown, PlantUML, AsciiDoc, etc.) by
  discovery. Invoke via "audit my docs", "write docs for X", "document
  this API", "create architecture docs", or "organize our knowledge base".
license: MIT
---

# Documentation Lifecycle

A skill for managing the full documentation lifecycle on a small full-stack
team. Five workflows, each with phased procedures, decision points, and
anti-patterns. The skill discovers your existing docs, formats, and tools —
it does not require project-specific configuration.

## Pre-flight (run before any workflow)

**Step 1. Discover documentation landscape.**

Scan the project to understand what exists:

| Artifact type | Scan patterns | What to note |
|---|---|---|
| Markdown docs | `docs/**/*.md`, `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md` | Depth, freshness, structure |
| Diagrams | `**/*.puml`, `**/*.plantuml`, `docs/**/*.svg`, `docs/**/*.png` | Format, coverage, staleness |
| API specs | `**/*swagger*`, `**/*openapi*`, `**/api/**/*.yaml`, `**/*.openapi.json` | Version, completeness |
| Config files | `mkdocs.yml`, `docusaurus.config.*`, `conf.py`, `_config.yml` | Doc tooling in use |
| Knowledge base | `docs/knowledge/**`, `docs/adr/**`, `docs/decisions/**` | Structure, linking |
| Code-generated | `**/docs-gen/**`, `target/docs/**`, `build/docs/**` | Build pipeline exists? |

Record findings as a landscape summary:

```
Documentation Landscape:
  Format:      markdown (primary), PlantUML (diagrams)
  Tooling:     none detected (raw markdown)
  Structure:   docs/ with 14 files, 3 subdirectories
  Diagrams:    6 .puml files in docs/uml/
  API specs:   none
  Freshness:   8 files modified > 90 days ago
```

**Step 2. Detect conventions.**

For each documentation file found, note:

- Heading style (`#` vs `===` underline)
- Table format (markdown vs HTML)
- Diagram conventions (PlantUML theme, alias style)
- Link style (relative vs absolute, file extension)
- Naming convention (kebab-case, snake_case, CamelCase)

If the project has a style guide or `.editorconfig` with doc rules, load
those. Store detected conventions as the **style reference** for any
generation workflows.

**Step 3. Identify doc owners (if available).**

Check git log for recent doc changes:

```
git log --diff-filter=M --name-only --pretty=format:"%ai %an" -- "*.md"
```

Note who last touched each file. On a 2-person team, this helps route
review requests and spot abandoned files.

**Step 4. Abort check.**

If the project has fewer than 3 documentation files AND no diagram files,
abort and tell the user there is insufficient documentation to work with.
Recommend starting with Workflow 2 (Doc Generation) for core files first.

## Workflow 1 — Documentation Audit

Assess the current state of documentation. Produce a prioritized inventory
with gap analysis and actionable recommendations.

**Invoke:** "audit my docs", "doc audit", "review my documentation",
"what documentation am I missing?", "check my docs"

### Phase 1 — Inventory

**Step 1.1. Catalog every documentation artifact.**

For each file discovered in pre-flight, record:

| Field | Source |
|---|---|
| File path | Scan result |
| File size | `wc -l` equivalent |
| Last modified | Git log or filesystem timestamp |
| Last author | Git log |
| Doc type | Heading analysis, content classification |
| Topics covered | Extract from headings and content |

**Step 1.2. Build the inventory table.**

```
| File | Type | Lines | Last Modified | Topics |
|------|------|-------|---------------|--------|
| docs/architecture.md | Architecture overview | 142 | 2025-11-03 | system design, layers |
| docs/api/auth.md | API reference | 67 | 2026-01-15 | authentication, JWT |
| docs/guides/setup.md | Tutorial | 89 | 2025-08-20 | local dev, prerequisites |
| README.md | Project overview | 34 | 2026-03-01 | description, install |
```

### Phase 2 — Classify

**Step 2.1. Classify each doc by type.**

| Doc type | Signal | Example |
|---|---|---|
| **Overview** | README, project description, introduction | `README.md`, `docs/index.md` |
| **Architecture** | System design, diagrams, component relationships | `docs/architecture.md`, `*.puml` |
| **Tutorial** | Step-by-step instructions, "how to", getting started | `docs/guides/setup.md` |
| **Reference** | API docs, config reference, schema docs | `docs/api/*.md`, `openapi.yaml` |
| **Decision record** | ADR format, "decision", "context", "consequences" | `docs/adr/001-use-postgres.md` |
| **Operational** | Runbooks, incident response, deployment guides | `docs/runbooks/*.md` |
| **Conceptual** | Explainers, domain model, glossary | `docs/concepts/*.md` |

**Step 2.2. Classify depth.**

For each doc, rate depth:

| Depth | Criteria |
|---|---|
| **Sufficient** | Covers topic completely, has examples, current |
| **Shallow** | Covers topic but lacks detail or examples |
| **Stub** | Outline only, no real content |
| **Stale** | Was sufficient but now outdated (verify against code) |

### Phase 3 — Gap Analysis

**Step 3.1. Map coverage matrix.**

Cross-reference doc types against project areas:

```
                Overview  Architecture  Tutorial  Reference  Decision  Operational
Core             ✓         ✓             ✓         —          ✓         —
Auth             —         partial       —         ✓          —         —
Database         —         ✓             —         —          ✓         ✓
Deployment       —         —             —         —          —         stub
Testing          —         —             ✓         —          —         —
```

**Step 3.2. Identify gaps.**

Common gaps for a full-stack team:

| Gap type | Signal | Priority |
|---|---|---|
| **Missing reference** | API endpoints with no documentation | High |
| **Missing tutorial** | Complex setup with no guide | High |
| **Missing architecture** | Multiple services with no system diagram | High |
| **Missing decisions** | Architecture choices with no ADR | Medium |
| **Missing operational** | No deployment or incident runbooks | Medium |
| **Missing changelog** | No CHANGELOG.md or release notes | Low |
| **Stale content** | Docs not updated in > 90 days while code changed | Medium |
| **Shallow content** | Stub docs for important topics | Medium |

**Step 3.3. Cross-reference docs vs. code.**

For each API endpoint in the codebase, check if docs exist. For each
service/module, check if architecture docs exist. This is a lightweight
consistency check — not the full doc-consistency skill.

```
Endpoints found: 23
Documented:      14 (61%)
Undocumented:    9

Modules found:   8
Documented:      5 (63%)
Undocumented:    3
```

### Phase 4 — Prioritize

**Step 4.1. Score each gap.**

| Gap | Impact (1-5) | Effort (1-5) | Score (Impact/Effort) |
|---|---|---|---|
| Undocumented auth endpoints | 5 | 2 | 2.5 |
| Missing deployment runbook | 4 | 3 | 1.3 |
| Stale architecture diagram | 4 | 2 | 2.0 |
| Missing ADR for DB choice | 3 | 1 | 3.0 |

**Step 4.2. Produce recommended action plan.**

Ordered by score, grouped by effort tier:

```
Quick wins (effort ≤ 2):
  1. Add ADR for database decision — 15 min
  2. Document 9 undocumented auth endpoints — 1 hour
  3. Update stale architecture diagram — 1 hour

Medium effort (effort 3):
  4. Write deployment runbook — 2 hours
  5. Add examples to shallow API docs — 1 hour

Large effort (effort 4+):
  6. Write onboarding tutorial — half day
```

### Output

The audit produces a single report with: inventory table, coverage matrix,
gap list with scores, and prioritized action plan.

```
# Documentation Audit Report

**Date:** 2026-08-17
**Files analyzed:** 14
**Coverage:** 62% of project areas documented
**Staleness:** 5 files > 90 days old

## Coverage Matrix
[rendered table]

## Gaps
[ranked list with scores]

## Recommended Actions
[prioritized by impact/effort]
```

### Workflow-specific Anti-patterns

| Anti-pattern | Problem |
|---|---|
| **Auditing without acting** | Producing a report nobody reads. Always end with a concrete action plan, not just findings. |
| **Treating all gaps equally** | A missing API reference for a public endpoint is not the same as a missing changelog. Score by impact. |
| **Ignoring staleness** | A doc that exists but is wrong is worse than no doc. Always check last-modified dates against code changes. |
| **Over-auditing** | On a 2-person team, a 50-page audit report is waste. Keep the report to 2-3 pages max with clear next steps. |

## Workflow 2 — Doc Generation

Create new documentation from scratch or fill identified gaps. Discover
what exists, outline the structure, draft content, get review, and publish.

**Invoke:** "write docs for X", "create documentation for Y", "document
this module", "add docs for the auth flow", "write a getting started guide"

### Pre-flight

**Step 1. Identify what to document.**

Parse the user's request for:
- **Topic** — What is being documented? (module, feature, API, flow)
- **Audience** — Who reads this? (new dev, API consumer, ops team)
- **Doc type** — What kind of doc? (tutorial, reference, architecture, runbook)
- **Scope** — How deep? (overview, complete guide, quick reference)

If the user's request is ambiguous, ask:

```
What should this doc cover?
  1. Overview — high-level summary for orientation
  2. Tutorial — step-by-step walkthrough for learning
  3. Reference — detailed specs for looking things up
  4. How-to guide — task-oriented instructions for doing
```

**Step 2. Discover source material.**

Scan for existing content related to the topic:

| Source | What to extract |
|---|---|
| Code files for the module | Function signatures, class names, comments |
| Existing partial docs | Any fragments that can be expanded |
| Tests | Behavior specs, edge cases, expected inputs/outputs |
| Related docs | Cross-reference points, linking opportunities |
| Git history | Design decisions, rationale from commit messages |

**Step 3. Detect existing conventions.**

Load the style reference from pre-flight. If writing into an existing
directory with other docs, match their:
- Heading depth (h2 vs h3 for subsections)
- Code block formatting (fenced vs indented, language tags)
- Table style (markdown tables, alignment)
- Link conventions (relative paths, anchors)

### Phase 1 — Discover

**Step 1.1. Map the topic's surface area.**

For the topic to document, identify:
- Entry points (where do users/developers interact with this?)
- Key abstractions (classes, functions, concepts)
- Common workflows (what do people typically do with this?)
- Configuration points (env vars, config files, flags)
- Error scenarios (what can go wrong?)
- Dependencies (what does this rely on? what relies on this?)

**Step 1.2. Identify cross-references.**

Find all existing docs that mention this topic. Note where this new doc
should link to existing docs, and where existing docs should be updated
to link to this new doc.

### Phase 2 — Outline

**Step 2.1. Propose document structure.**

Based on doc type, generate an outline:

**For a Tutorial:**
```
1. What you'll build/learn
2. Prerequisites
3. Step-by-step instructions
4. Expected results
5. Troubleshooting
6. Next steps
```

**For a Reference:**
```
1. Overview (one paragraph)
2. Quick reference table
3. Detailed sections per entity/endpoint/concept
4. Examples
5. Common patterns
6. Error codes / troubleshooting
```

**For an Architecture doc:**
```
1. System overview
2. Component diagram
3. Data flow
4. Key decisions (links to ADRs)
5. Trade-offs and constraints
6. Scaling considerations
```

**For a How-to guide:**
```
1. Goal (what you'll accomplish)
2. Prerequisites
3. Steps
4. Verification
5. Next steps
```

**Step 2.2. Present outline for approval.**

Show the outline to the user. Wait for approval or edits before drafting.

### Phase 3 — Draft

**Step 3.1. Write the document.**

Following the approved outline and matched conventions:

- Write for the stated audience (technical depth varies)
- Include code examples where they add clarity
- Use concrete values over placeholders ("user@example.com" not "xxx")
- Keep paragraphs short (3-5 sentences max)
- Use lists for enumerated items, tables for structured data
- Cross-reference related docs with relative links

**Step 3.2. Add diagrams if needed.**

If the doc would benefit from a diagram:
- Use the project's existing diagram format (PlantUML, Mermaid, etc.)
- Place diagram files in the project's diagram directory
- Reference with relative path from the markdown doc
- Follow existing diagram conventions (theme, alias style)

**Step 3.3. Validate internal consistency.**

Check that the new doc:
- Does not contradict any existing doc on the same topic
- Uses the same terminology as other docs (entity names, concept names)
- Links to existing docs using correct relative paths
- Has no broken internal references

### Phase 4 — Review

**Step 4.1. Self-review checklist.**

Before presenting to the user:

| Check | What to verify |
|---|---|
| Accuracy | Code examples compile/run, facts match source material |
| Completeness | All outline sections filled, no stubs |
| Clarity | No unexplained jargon, acronyms defined on first use |
| Consistency | Matches project conventions, terminology aligned |
| Links | All cross-references resolve, no broken links |
| Length | Appropriate depth for the doc type and audience |

**Step 4.2. Present for review.**

Show the draft to the user with specific questions:

```
Draft complete. Please review:

  docs/guides/authentication.md (147 lines)

  Questions:
  1. Is the scope right, or should I cover [X]?
  2. Are the code examples using your preferred patterns?
  3. Should I add a section on [common gap]?
```

### Phase 5 — Publish

**Step 5.1. Write the file.**

Write to the appropriate location following the project's doc directory
structure. If the directory does not exist, create it with a note that
this is a new section.

**Step 5.2. Update cross-references.**

- Add links from related docs to this new doc
- Update any index or table of contents
- If the doc fills a gap identified in an audit, note that in the report

**Step 5.3. Confirm to user.**

```
Published: docs/guides/authentication.md
  Type:     Tutorial
  Lines:    147
  Diagrams: 2 (inline)
  Links to: docs/api/auth.md, docs/architecture.md
  Updated:  docs/README.md (added link in Guides section)
```

### Workflow-specific Anti-patterns

| Anti-pattern | Problem |
|---|---|
| **Writing without source material** | Produces docs that sound plausible but are wrong. Always extract from code, tests, or existing specs first. |
| **Placeholder text** | "TBD", "TODO", "[insert example here]" — worse than no doc. Write real content or do not publish. |
| **Documenting the obvious** | "Open the file. Edit the file. Save the file." — adds noise. Focus on decisions and non-obvious steps. |
| **Writing for yourself, not the audience** | An expert writing a tutorial skips steps they find obvious. Write for someone who has never seen this code. |
| **Ignoring existing docs** | Duplicating content that already exists elsewhere. Link instead. Single source of truth. |
| **No review step** | Publishing without any review catches zero errors. At minimum, self-review with the checklist. |

## Workflow 3 — Architecture Documentation

Record architectural decisions, create system diagrams, and maintain a
living architecture record. Handles ADRs, component diagrams, data flow
diagrams, and architecture decision records.

**Invoke:** "create architecture docs", "document this design decision",
"write an ADR", "create a system diagram", "add architecture documentation"

### Pre-flight

**Step 1. Discover existing architecture artifacts.**

| Artifact | Scan patterns | What to extract |
|---|---|---|
| ADRs | `docs/adr/**/*.md`, `docs/decisions/**/*.md` | Existing decisions, format, numbering |
| Architecture docs | `docs/architecture*.md`, `ARCHITECTURE.md` | System overview, conventions |
| Diagrams | `docs/uml/**/*.puml`, `docs/diagrams/**` | Existing diagrams, format, style |
| AGENTS.md | `AGENTS.md`, `CLAUDE.md` | Project rules, constraints |
| Code structure | `src/**/`, `lib/**/` | Actual architecture to document |

**Step 2. Detect ADR format.**

If ADRs exist, note their format (standard ADR template, Nygard format,
custom). If no ADRs exist, default to the standard format:

```markdown
# ADR-{NNN}: {Title}

**Status:** {Proposed | Accepted | Deprecated | Superseded by ADR-XXX}
**Date:** {YYYY-MM-DD}
**Deciders:** {names}

## Context

{What is the issue motivating this decision?}

## Decision

{What is the change being proposed or decided?}

## Consequences

{What becomes easier or harder as a result?}
```

### Phase 1 — Capture

**Step 1.1. Identify decisions to record.**

Scan for architectural decisions in:
- Commit messages (especially "refactor", "replace", "migrate", "switch")
- Code comments with "NOTE:", "IMPORTANT:", "by design"
- Existing architecture docs (decisions embedded in prose)
- Test files (behavioral constraints as test names)
- Configuration (choices visible in config files)

**Step 1.2. Classify each decision.**

| Decision type | Examples | Typical format |
|---|---|---|
| **Structural** | Service boundaries, layer architecture | ADR + diagram |
| **Technology** | Database choice, framework selection | ADR |
| **Pattern** | CQRS, event sourcing, adapter pattern | ADR + code example |
| **Convention** | Naming, folder structure, branching model | ADR or policy doc |
| **Trade-off** | Consistency vs availability, complexity vs speed | ADR with alternatives |

**Step 1.3. Determine what is missing.**

Compare discovered decisions against documented ones. Every significant
architectural choice should have a record. Flag undocumented decisions:

```
Decisions detected in code/commits: 12
Documented in ADRs:               7
Undocumented:                      5
  - Switch from REST to GraphQL (commit abc123)
  - Use Redis for session store (config evidence)
  ...
```

### Phase 2 — Diagram

**Step 2.1. Choose diagram type.**

| Diagram type | When to use | PlantUML type |
|---|---|---|
| **Component** | Show system components and relationships | `component` |
| **Deployment** | Show infrastructure topology | `node` |
| **Data flow** | Show how data moves through the system | activity or component |
| **Context** | Show system boundaries and external actors | `usecase` or component |
| **Sequence** | Show interaction flow for a specific scenario | sequence (use generate-sequence skill) |

**Step 2.2. Extract architecture from code.**

Before drawing diagrams, extract the actual architecture:
- Entry points (main files, server startup, route registration)
- Module boundaries (packages, namespaces, directories)
- External integrations (API clients, database connections, message queues)
- Data stores (databases, file systems, caches)

**Step 2.3. Create or update diagrams.**

Follow existing diagram conventions. If no conventions exist, use:
- `!theme plain` for PlantUML
- Short aliases (`App`, `API`, `DB`, `Cache`)
- Layer tags in brackets: `[presentation]`, `[application]`, `[domain]`
- One diagram per concern (do not overload)

### Phase 3 — Document

**Step 3.1. Write the architecture narrative.**

For each significant architectural element, write prose that explains:
- **What** it is (one sentence)
- **Why** it exists (the problem it solves)
- **How** it works (mechanism, not implementation detail)
- **Trade-offs** (what was sacrificed and why)

**Step 3.2. Record decisions as ADRs.**

For each undocumented decision identified in Phase 1, write an ADR.
Use the detected format. Each ADR should be self-contained — a reader
should understand the decision without reading other ADRs.

**Step 3.3. Link decisions to diagrams.**

Every ADR that affects structure should reference the relevant diagram.
Every diagram should reference the ADR(s) that justify its structure.

```
ADR-003 references:
  docs/uml/components/architecture.puml (component layout)
  docs/architecture.md (System Overview section)

architecture.puml references:
  ADR-003 (for the service boundary decision)
  ADR-007 (for the data flow pattern)
```

### Phase 4 — Validate

**Step 4.1. Consistency check.**

- Do all diagrams match the stated architecture in prose?
- Do all ADRs reference each other correctly (supersedes chains)?
- Do diagram component names match code module names?
- Are there decisions in code that contradict documented decisions?

**Step 4.2. Completeness check.**

- Does every major component have at least one diagram?
- Does every ADR have Context, Decision, and Consequences?
- Are all status fields current (no "Proposed" decisions that were actually decided)?

**Step 4.3. Present findings.**

```
Architecture Documentation Status:

  ADRs:        12 total (10 accepted, 1 proposed, 1 deprecated)
  Diagrams:     5 (component, deployment, 3 data flow)
  Coverage:     8 of 10 services documented
  Gaps:
    - UserService has no architecture doc
    - ADR for caching strategy is missing
  Inconsistencies:
    - architecture.md says "4 services" but diagrams show 5
```

### Output

```
# Architecture Documentation Report

**Date:** 2026-08-17
**ADRs:** 12 (7 existing + 5 new)
**Diagrams:** 5 (3 existing + 2 new)
**Coverage:** 80% of services documented

## New ADRs Created
  ADR-008: Use Redis for session storage
  ADR-009: GraphQL over REST for mobile API
  ADR-010: Event-driven communication between services
  ADR-011: PostgreSQL for primary data store
  ADR-012: Docker Compose for local development

## New Diagrams Created
  docs/uml/components/architecture.puml (updated)
  docs/uml/deployment/infrastructure.puml (new)

## Remaining Gaps
  - UserService architecture documentation
  - Caching strategy ADR
```

### Workflow-specific Anti-patterns

| Anti-pattern | Problem |
|---|---|
| **Diagramming aspirational architecture** | Diagrams that show what you want, not what you have. Document the actual system first, then note desired changes separately. |
| **ADR without consequences** | An ADR with only "we chose X" is useless. The consequences (what got harder) are the valuable part. |
| **Diagram without narrative** | A diagram without accompanying prose is a Rorschach test. Every diagram needs a paragraph explaining what to notice. |
| **Decisions as code comments** | "By design" in a comment is not architecture documentation. Decisions need context and rationale in a discoverable location. |
| **Stale diagrams** | A diagram that shows 3 services when the system has 5 is actively misleading. Validate diagrams against code regularly. |
| **One monolithic diagram** | A single diagram showing everything is unreadable. Split by concern: component, deployment, data flow. |

## Workflow 4 — API Documentation

Document API endpoints, request/response formats, authentication, error
handling, and usage examples. Works with REST, GraphQL, gRPC, or any
HTTP-based API.

**Invoke:** "document this API", "add API docs for endpoints", "create
an API reference", "document the /users endpoint", "write API docs"

### Pre-flight

**Step 1. Discover API surface.**

| Source | What to extract |
|---|---|
| Route files | `**/routes.*`, `**/router.*`, `**/app.*` | Endpoint paths, HTTP methods, handlers |
| Controller files | `**/controller*.*`, `**/handler*.*` | Business logic, parameters |
| OpenAPI/Swagger | `**/openapi*.*`, `**/swagger*.*` | Existing spec |
| Existing docs | `docs/api/**/*.md` | Existing documentation |
| Type definitions | `**/types.*`, `**/schema.*`, `**/model.*` | Request/response shapes |
| Middleware | `**/middleware*.*` | Auth, validation, rate limiting |

**Step 2. Classify API type.**

| API type | Documentation format | Key differences |
|---|---|---|
| **REST** | Endpoint-per-section reference | Methods, paths, status codes |
| **GraphQL** | Schema-per-type reference | Types, queries, mutations, subscriptions |
| **gRPC** | Service-per-proto reference | Service definitions, message types, streaming |
| **Webhook** | Event-per-section reference | Event types, payloads, retry behavior |

**Step 3. Detect existing API doc conventions.**

If API docs already exist, note:
- Organization pattern (by resource? by version? by feature?)
- Parameter documentation style (table vs list vs code block)
- Example format (curl, SDK, both?)
- Authentication section placement

### Phase 1 — Discover Endpoints

**Step 1.1. Build endpoint inventory.**

For each endpoint found:

```
| Method | Path | Handler | Auth | Description |
|--------|------|---------|------|-------------|
| GET | /api/v1/users | UserController.list | JWT | List all users |
| POST | /api/v1/users | UserController.create | JWT + Admin | Create user |
| GET | /api/v1/users/:id | UserController.get | JWT | Get user by ID |
| PUT | /api/v1/users/:id | UserController.update | JWT + Owner | Update user |
| DELETE | /api/v1/users/:id | UserController.delete | JWT + Admin | Delete user |
```

**Step 1.2. Extract request/response shapes.**

For each endpoint, trace the handler to extract:
- Path parameters (type, constraints, description)
- Query parameters (type, default, description)
- Request body (schema, required fields, nested objects)
- Response body (success shape, error shapes)
- Status codes (which codes are returned and when)
- Headers (custom headers, rate limit headers)

**Step 1.3. Extract authentication and authorization.**

For each endpoint, identify:
- Authentication mechanism (JWT, API key, OAuth, none)
- Authorization rules (who can access: any authenticated user, admin only, resource owner)
- Required scopes or permissions

### Phase 2 — Describe

**Step 2.1. Write endpoint documentation.**

For each endpoint, write:

```markdown
## {Method} {Path}

{One-sentence description of what this endpoint does.}

### Authentication

{Authentication and authorization requirements.}

### Parameters

| Name | In | Type | Required | Description |
|------|-----|------|----------|-------------|
| id | path | string | yes | User ID (UUID) |
| include | query | string | no | Comma-separated related resources to include |

### Request Body

{Schema with types and descriptions.}

### Response

**{Status Code}** — {description}

{Response body schema.}

### Examples

{curl example, response example.}
```

**Step 2.2. Document error responses.**

For each endpoint, document all error responses:

```markdown
### Error Responses

| Status | Error Code | Description |
|--------|-----------|-------------|
| 400 | VALIDATION_ERROR | Invalid request body |
| 401 | UNAUTHORIZED | Missing or invalid auth token |
| 403 | FORBIDDEN | Insufficient permissions |
| 404 | NOT_FOUND | User does not exist |
| 429 | RATE_LIMITED | Too many requests |
```

**Step 2.3. Document rate limiting and pagination.**

If the API has rate limiting:
- State limits per endpoint or globally
- Describe rate limit headers
- Explain retry behavior

If the API has pagination:
- Describe pagination style (offset, cursor, page-based)
- Document pagination parameters
- Show pagination response envelope

### Phase 3 — Add Examples

**Step 3.1. Write curl examples for each endpoint.**

```bash
# Create a user
curl -X POST https://api.example.com/v1/users \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Jane Doe", "email": "jane@example.com"}'

# Response: 201 Created
{
  "id": "usr_abc123",
  "name": "Jane Doe",
  "email": "jane@example.com",
  "created_at": "2026-08-17T10:00:00Z"
}
```

**Step 3.2. Write SDK examples (if applicable).**

If the project has a client SDK, add examples in the SDK language:

```javascript
const user = await client.users.create({
  name: "Jane Doe",
  email: "jane@example.com"
});
```

**Step 3.3. Document common workflows.**

For multi-step operations, write a workflow example:

```markdown
### Creating and verifying a user

1. POST /api/v1/users (create user)
2. POST /api/v1/users/:id/verify-email (send verification)
3. POST /api/v1/verify (submit verification code)
```

### Phase 4 — Validate

**Step 4.1. Completeness check.**

```
Endpoints found:   23
Documented:        23 (100%)
With examples:     21 (91%)
With error docs:   18 (78%)
```

**Step 4.2. Accuracy check.**

For each documented endpoint:
- Does the documented method match the code?
- Does the path match (including version prefix)?
- Do the documented status codes match what the handler returns?
- Do the request/response schemas match the type definitions?

**Step 4.3. Consistency check.**

- Are all endpoints using the same documentation format?
- Are authentication descriptions consistent?
- Do error code names match across endpoints?
- Are examples using consistent sample data?

### Output

```
# API Documentation Report

**Date:** 2026-08-17
**API version:** v1
**Endpoints:** 23 (all documented)
**Format:** Markdown reference

## Documentation Status
| Resource | Endpoints | Docs | Examples | Errors |
|----------|-----------|------|----------|--------|
| Users | 5 | 5/5 | 5/5 | 4/5 |
| Projects | 8 | 8/8 | 7/8 | 6/8 |
| Auth | 4 | 4/4 | 4/4 | 4/4 |
| Webhooks | 6 | 6/6 | 5/6 | 4/6 |

## Gaps
  - Projects endpoint missing error example for 409 Conflict
  - Webhooks missing retry behavior documentation
```

### Workflow-specific Anti-patterns

| Anti-pattern | Problem |
|---|---|
| **Documenting from memory** | Endpoint docs written from what the developer remembers, not what the code does. Always extract from code or OpenAPI spec. |
| **Missing error responses** | Docs that show only the happy path leave API consumers guessing about errors. Document every status code the handler returns. |
| **Placeholder examples** | `curl -X POST /api/...` with no real payload. Examples must be copy-pasteable and produce real responses. |
| **Version drift** | API docs for v1 when the API is at v2. Always document the current version, note deprecated versions explicitly. |
| **Schema without types** | `{"name": "string"}` is useless. Use proper types, constraints (max length, pattern), and whether each field is required. |
| **No authentication section** | Every endpoint must state its auth requirements. "Requires auth" is insufficient — specify mechanism and required roles. |

## Workflow 5 — Knowledge Management

Organize, link, update, and archive the knowledge base. Maintains a
living index, ensures discoverability, and manages doc lifecycle.

**Invoke:** "organize our knowledge base", "clean up docs", "create a
docs index", "archive old docs", "link our documentation together"

### Pre-flight

**Step 1. Discover knowledge base structure.**

| Artifact | Scan patterns | What to note |
|---|---|---|
| Index files | `docs/README.md`, `docs/index.md`, `docs/SUMMARY.md` | Current TOC/index |
| Directory structure | `docs/**/` | Organization pattern |
| Cross-references | `grep -r "](.*\.md)" docs/` | Link density, orphaned files |
| Stale files | `find docs/ -mtime +90` | Files not updated recently |

**Step 2. Build link graph.**

For every markdown file, extract all outbound links:

```
docs/architecture.md
  → docs/guides/setup.md (2 links)
  → docs/api/auth.md (1 link)
  → docs/uml/components/architecture.puml (1 link)
  → docs/adr/003-service-boundaries.md (1 link)

docs/guides/setup.md
  → docs/architecture.md (1 link)
  → (no links to API docs)

docs/api/auth.md
  → (no outbound links)
```

**Step 3. Identify orphans.**

Files with zero inbound links from other docs:

```
Orphaned files (no inbound links):
  docs/guides/deployment.md
  docs/adr/005-logging-strategy.md
  docs/runbooks/incident-response.md
```

### Phase 1 — Organize

**Step 1.1. Propose directory structure.**

For a full-stack team, recommend:

```
docs/
  index.md              # Project overview and navigation
  architecture.md       # System architecture overview
  adr/                  # Architecture Decision Records
    index.md            # ADR table of contents
    001-*.md
    002-*.md
  api/                  # API reference
    index.md            # API overview
    auth.md
    users.md
  guides/               # Tutorials and how-to guides
    getting-started.md
    setup.md
    deployment.md
  concepts/             # Conceptual explanations
    domain-model.md
  runbooks/             # Operational procedures
    incident-response.md
  uml/                  # Diagrams
    components/
    sequences/
  reference/            # Reference material
    configuration.md
    environment-vars.md
```

**Step 1.2. Migrate files if needed.**

If the current structure does not match the recommended one, propose
migrations:

```
Migration plan:
  docs/deployment-guide.md → docs/guides/deployment.md
  docs/API.md → docs/api/index.md
  docs/decisions/ → docs/adr/
```

Ask the user before executing migrations.

### Phase 2 — Link

**Step 2.1. Create index files.**

For each directory, create or update an index file that lists and
describes every file in that directory:

```markdown
# API Documentation

| Endpoint | Description | Status |
|----------|-------------|--------|
| [Authentication](auth.md) | Login, registration, token refresh | Current |
| [Users](users.md) | User CRUD operations | Current |
| [Projects](projects.md) | Project management | Needs review |
```

**Step 2.2. Add cross-references.**

For each document, add "See also" sections that link to related docs:

```markdown
## See Also

- [Architecture overview](../architecture.md) — how this fits in the system
- [ADR-003](../adr/003-service-boundaries.md) — decision behind this design
- [API reference](../api/auth.md) — endpoint documentation
```

**Step 2.3. Fix orphaned files.**

For each orphaned file:
- Determine where it belongs in the navigation
- Add links to it from relevant parent/index pages
- Add outbound links from it to related docs

### Phase 3 — Update

**Step 3.1. Identify stale content.**

```
Stale files (last modified > 90 days, code has changed since):

| File | Last Modified | Code Changes Since | Staleness |
|------|---------------|-------------------|-----------|
| docs/api/users.md | 2025-12-01 | 23 commits | High |
| docs/architecture.md | 2026-01-15 | 8 commits | Medium |
| docs/guides/setup.md | 2025-09-03 | 31 commits | Critical |
```

**Step 3.2. Triage stale content.**

For each stale file, classify:

| Classification | Action |
|---|---|
| **Wrong** (contradicts current code) | Flag as priority update, note specific inaccuracies |
| **Incomplete** (missing new features) | Flag for additions, note what is missing |
| **Outdated but correct** (still valid, just old) | Lower priority, note for periodic review |
| **Obsolete** (feature no longer exists) | Archive or delete |

**Step 3.3. Generate update recommendations.**

```
Priority updates:
  1. docs/guides/setup.md — CRITICAL: setup instructions reference
     deprecated tool. 31 code changes since last update.
     Specific gaps: new dependency, changed config format, removed step 4.

  2. docs/api/users.md — HIGH: 2 new endpoints added, 1 endpoint
     removed, response schema changed for GET /users.

  3. docs/architecture.md — MEDIUM: new service added (NotificationService),
     not reflected in architecture diagram.
```

### Phase 4 — Archive

**Step 4.1. Identify candidates for archival.**

| Criterion | Example |
|---|---|
| Feature removed | Docs for deprecated API endpoints |
| Superseded | ADR replaced by a newer ADR |
| Historical only | Sprint planning docs from 6 months ago |
| Temporary | Migration guides for completed migrations |

**Step 4.2. Archive process.**

Do not delete — move to an archive:

```
Archive plan:
  docs/guides/v1-migration.md → docs/archive/v1-migration.md
  docs/adr/002-use-express.md → docs/archive/adr/002-use-express.md
    (superseded by ADR-007-use-fastify.md)
```

Add a note at the top of archived files:

```markdown
> **Archived:** This document is no longer current. It is preserved for
> historical reference. For current information, see [link to replacement].
```

**Step 4.3. Update index files.**

After archiving, update all index files and cross-references to point to
archive or replacement docs.

### Output

```
# Knowledge Management Report

**Date:** 2026-08-17
**Files in knowledge base:** 34
**Files archived:** 2
**Orphans linked:** 3
**Index files updated:** 5

## Structure Changes
  Created: docs/archive/ (2 files moved)
  Created: docs/adr/index.md (new index)
  Updated: docs/index.md (added Guides section)

## Link Health
  Total links: 87
  Valid:       84 (97%)
  Orphaned:    3 → now linked

## Staleness
  Critical: 1 (docs/guides/setup.md)
  High:     2
  Medium:   3
```

### Workflow-specific Anti-patterns

| Anti-pattern | Problem |
|---|---|
| **Index without links** | An index that lists files but does not link them is a phone book without phone numbers. Every index entry must be a clickable link. |
| **Link rot** | Links to files that no longer exist. Always validate links after restructuring. |
| **Archive without note** | Archived files without a "this is archived" notice mislead readers. Always add archival notice with pointer to current source. |
| **Over-organization** | 20 directories with 1 file each is worse than a flat structure. Organize when you have enough files to justify it. |
| **Never archiving** | A knowledge base that only grows becomes unusable. Archive aggressively — nothing is lost, it is just out of the navigation path. |
| **Updating without linking** | Fixing a doc but not updating the index or related docs leaves the knowledge base partially updated. Always update the link graph. |

## Cross-cutting Conventions

These conventions apply to all workflows.

### Document Structure

| Element | Convention |
|---|---|
| Title | H1, one per file, matches filename concept |
| Metadata | Optional YAML frontmatter for docs with status/date |
| Headings | H2 for major sections, H3 for subsections. Never skip levels. |
| Code blocks | Fenced with language tag. No indented code blocks. |
| Links | Relative paths. Include `.md` extension. |
| Images | Relative paths. Alt text required. Place in `docs/images/` or alongside doc. |

### Naming Conventions

| Type | Convention | Example |
|---|---|---|
| Guides | `kebab-case.md` | `getting-started.md` |
| ADRs | `{NNN}-kebab-case.md` | `003-use-postgres.md` |
| Diagrams | `{Type}_{Name}.puml` | `Component_Architecture.puml` |
| API docs | `{resource}.md` | `users.md` |
| Runbooks | `{event}.md` | `incident-response.md` |

### Diagram Conventions

| Element | Convention |
|---|---|
| Format | PlantUML (primary), Mermaid (fallback for GitHub rendering) |
| Theme | `!theme plain` |
| File location | `docs/uml/{type}/` |
| Naming | `{DiagramType}_{Name}.puml` |
| Aliases | Short (`App`, `API`, `DB`), consistent across diagrams |
| Layer tags | `[presentation]`, `[application]`, `[domain]`, `[infrastructure]` |

### Review Checklist

Before publishing any documentation:

| Check | Apply to |
|---|---|
| Accuracy | All workflows |
| Completeness | All workflows |
| Consistency with existing docs | All workflows |
| Audience-appropriate depth | Workflow 2 (Generation) |
| Code examples tested | Workflow 2, 4 |
| Diagrams match prose | Workflow 3 |
| Cross-references valid | Workflow 5 |
| No stale information | Workflow 1, 5 |

## Global Anti-patterns

| Anti-pattern | Problem |
|---|---|
| **Documentation as afterthought** | Writing docs "when we have time" means never. Treat doc PRs with the same priority as code PRs. |
| **Documentation debt spiral** | Skipping doc updates to ship faster creates compounding debt. One missed update becomes ten. |
| **Single-author knowledge** | If only one person understands the docs, the knowledge is fragile. Review each other's docs. |
| **Documentation theater** | Writing docs that look complete but contain no useful information. Every doc should answer a real question someone would ask. |
| **Format wars** | Arguing about markdown vs AsciiDoc vs RST instead of writing. Pick what the project uses and move on. |
| **Documenting implementation, not intent** | "This function calls that function" is noise. "This function exists because X" is signal. |

## Calibration

**Solo developer, small project (< 10 docs):**
Workflows 2 and 4 are most valuable. Skip Workflow 5 (overhead exceeds
benefit). Run Workflow 1 quarterly. Write ADRs only for decisions you
would forget in 6 months.

**2-person team, medium project (10-30 docs):**
All workflows apply. Workflow 5 becomes valuable. Run Workflow 1 monthly.
Rotate doc reviews between team members. ADRs for all architectural
decisions.

**Team, large project (30+ docs):**
Workflows 1 and 5 are critical. Consider doc-as-code CI checks (link
validation, staleness warnings). ADRs mandatory. Diagrams must be
validated against code quarterly.

**Time-constrained:**
Focus on Workflow 2 (write the docs that are most painful to not have)
and Workflow 4 (API docs have the highest reader count). Defer
architecture docs and knowledge management to when pressure eases.

## Portability

This skill works with any project that has or wants documentation. It
adapts by discovery, not by configuration.

**What it needs:**
- A project directory with code (for extraction workflows)
- Some existing documentation (for audit/management workflows)
- Or willingness to create documentation (for generation workflows)

**What it does NOT need:**
- Specific documentation tooling
- Specific diagram format
- Specific directory structure
- CI/CD integration (helpful but not required)

**Format support:**
- Markdown (primary)
- PlantUML diagrams
- Mermaid diagrams
- OpenAPI/Swagger specs
- AsciiDoc
- reStructuredText (limited — heading extraction only)

**Adaptation rules:**
- If no `docs/` directory exists, create one with recommended structure
- If no diagrams exist, use the project's existing format or default to PlantUML
- If no ADRs exist, start with standard Nygard format
- If API docs exist in OpenAPI format, use that as the source of truth instead of code extraction
