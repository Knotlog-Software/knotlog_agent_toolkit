---
name: data-pipelines
description: >
  Design, build, debug, and optimize data pipelines and ETL/ELT workflows.
  Project-agnostic skill for a 2-person full-stack team working with any data
  stack (SQL, Python, dbt, Airflow, Spark, Fivetran, custom). Covers five
  workflows: pipeline design (requirements to validation), pipeline
  implementation (scaffold to test), data quality (profiling to remediation),
  pipeline debugging (reproduce to verify), and pipeline optimization (measure
  to verify). Adapts to whatever languages, frameworks, and tools the project
  already uses. Use when: "design a pipeline for X", "build an ETL", "check
  data quality", "debug this pipeline", "optimize pipeline Y", "add a data
  transformation", "fix failing data job", or any ETL/data engineering task.
  Skip for: pure SQL queries, BI dashboard configuration, ML model training,
  or one-off ad-hoc data exploration.
license: MIT
---

# Data Pipelines

A skill for the full lifecycle of data pipelines: design, implement, quality
assurance, debugging, and optimization. Built for a 2-person team that needs
to ship reliable data workflows without a dedicated data engineering org.

The skill is project-agnostic. It discovers the existing data stack
(languages, frameworks, orchestration, storage) and adapts all recommendations
to what is already in place. No forced tool choices.

## Pre-flight (run before every workflow)

The pre-flight runs before all five workflows. It takes 30-60 seconds and
prevents the most expensive class of mistakes: building on wrong assumptions
about the data stack.

**Step 1. Discover the data stack.**

Scan the project for data-related files, configs, and dependencies:

| Artifact | Scan patterns | What it reveals |
|---|---|---|
| Python deps | `requirements*.txt`, `pyproject.toml`, `setup.cfg`, `Pipfile` | dbt, pandas, airflow, great_expectations, etc. |
| Node deps | `package.json`, `yarn.lock` | Node-based ETL tools, custom runners |
| dbt project | `dbt_project.yml`, `**/models/**/*.sql`, `**/snapshots/` | dbt as transformation layer |
| Airflow | `dags/**/*.py`, `airflow.cfg`, `docker-compose*.yml` | Airflow orchestration |
| Config files | `*.yaml`, `*.yml`, `*.toml`, `*.json` in project root | Pipeline configs, connection strings |
| Docker | `Dockerfile*`, `docker-compose*`, `*.dockerfile` | Containerized pipeline infrastructure |
| SQL files | `**/*.sql` | Direct SQL transformations, schemas |
| Shell scripts | `**/*.sh` | Legacy or ad-hoc pipeline scripts |
| CI/CD | `.github/workflows/*`, `.gitlab-ci*`, `Jenkinsfile` | Pipeline CI/CD patterns |
| Tests | `**/test_*`, `**/*_test.*`, `**/tests/*` | Testing patterns and frameworks |
| Documentation | `README*`, `docs/**/*.md`, `AGENTS.md` | Pipeline documentation, conventions |

Record a stack profile:

```json
{
  "languages": ["python", "sql"],
  "transformation": "dbt",
  "orchestration": "airflow",
  "storage": {"raw": "postgres", "warehouse": "bigquery"},
  "testing": "pytest",
  "quality": "great_expectations",
  "scheduling": "cron",
  "ci_cd": "github_actions"
}
```

**Step 2. Discover existing pipelines.**

Find all existing pipeline artifacts to understand conventions, naming, and
structure:

| Artifact | Scan patterns | What to extract |
|---|---|---|
| Pipeline definitions | `**/dags/**/*.py`, `**/pipelines/**`, `**/etl/**` | Naming conventions, structure, patterns |
| Transform scripts | `**/transform*.py`, `**/models/**/*.sql` | Transformation patterns, naming |
| Schema files | `**/schema*.py`, `**/schema*.yaml`, `**/migrations/**` | Data models, column naming |
| Config | `**/config*.yaml`, `**/settings*.py` | Connection patterns, environment handling |
| Tests | `**/test_*pipeline*`, `**/test_*etl*`, `**/test_*transform*` | Testing conventions, fixtures |

Extract conventions:
- File naming: snake_case, camelCase, kebab-case?
- Module structure: flat, nested packages, one-file-per-pipeline?
- Config format: YAML, TOML, env vars, hardcoded?
- Error handling: try/catch, Result types, logging?
- Testing: unit tests, integration tests, data tests?

**Step 3. Discover data sources and schemas.**

Map the data landscape:

| Source type | What to find | What to extract |
|---|---|---|
| Database connections | Connection strings, client libs | Source systems, credentials pattern |
| API sources | HTTP client configs, endpoint definitions | External data providers |
| File sources | CSV/JSON/Parquet references | File-based inputs, formats |
| Schema definitions | DDL, ORM models, Avro/Protobuf schemas | Column names, types, constraints |
| Existing data models | dbt models, warehouse schemas | Current data shape, naming |

**Step 4. Abort gate.**

If no data pipeline infrastructure exists (no SQL, no Python data libs, no
orchestration), and the user is asking to design/build a pipeline, proceed
with a greenfield recommendation. If the user is asking to debug or optimize
something that does not exist yet, abort and explain.

**Output:** Stack profile + conventions + data landscape summary. Present
briefly (3-5 lines) before starting the requested workflow.

---

## Workflow 1 — Pipeline Design

**Invoke:** "design a pipeline for X", "plan an ETL for orders data",
"architect a data flow from API to warehouse", "what should our pipeline
look like for X?"

**Pre-flight:** Run the full pre-flight above.

### Phase 1 — Requirements

**Step 1.1 — Identify the data domain.**

Pinpoint exactly what data is moving and why:

| Question | Why it matters |
|---|---|
| What is the source? | API, database, file, stream — determines extract strategy |
| What is the destination? | Warehouse, data lake, API, flat file — determines load strategy |
| Who consumes the output? | Analysts, applications, ML models — determines format and freshness |
| What is the SLA? | Latency tolerance, freshness requirements, business hours |
| What is the volume? | Rows/day, growth rate — determines infrastructure tier |
| What is the cadence? | Real-time, hourly, daily, weekly — determines orchestration |

**Step 1.2 — Classify the pipeline.**

Use this decision table:

| Pattern | When | Architecture |
|---|---|---|
| **ELT** | Warehouse handles transforms; source data loads raw; transforms in SQL/dbt | Extract → Load (raw) → Transform (in warehouse) |
| **ETL** | Source data must be cleaned before loading; compliance constraints; limited warehouse compute | Extract → Transform → Load |
| **Streaming** | Sub-minute latency; event-driven; unbounded data | Source → Stream processor → Sink |
| **Reverse ETL** | Warehouse data pushed to operational systems | Warehouse → Transform → API/DB |
| **Federation** | Virtual integration; no materialization; queries across sources | Query engine → Virtual views |
| **CDC** | Incremental sync from OLTP databases; minimal source impact | Debezium/binlog → Stream → Sink |

Default for most 2-person teams: **ELT with dbt** (or equivalent SQL-based
transforms). It is the simplest to maintain, debug, and hand off.

**Step 1.3 — Schema design.**

Design the schema contract for the pipeline's output:

| Layer | Naming | Content |
|---|---|---|
| **Raw/Staging** | `stg_*` | 1:1 with source; rename, retype; no business logic |
| **Intermediate** | `int_*` | Joins, aggregations, business rules applied |
| **Marts** | `fct_*`, `dim_*` | Star schema or wide tables for consumption |

For each target table, define:
- Column names (snake_case, no abbreviations, consistent with existing)
- Data types (match warehouse conventions)
- Primary key / natural key
- Partitioning key (if applicable)
- Freshness requirement

**Step 1.4 — Define the SLA.**

| SLA component | Example | How to enforce |
|---|---|---|
| **Freshness** | "Data available by 6am UTC" | Orchestration schedule + alert on lateness |
| **Completeness** | "All records from source present" | Row count reconciliation |
| **Accuracy** | "Values match source within tolerance" | Checksum/hash comparison |
| **Idempotency** | "Re-running produces same result" | Upsert logic, deduplication |
| **Backfill** | "Can reprocess last 90 days" | Parameterized date range, full reload capability |

### Phase 2 — Design the Transformations

**Step 2.1 — Map source → target.**

For each source table/file/API endpoint:
1. List every source column/field
2. Map to target column (direct, computed, or dropped)
3. Note the transformation: rename, retype, filter, aggregate, join, enrich
4. Flag columns that need special handling: nulls, timestamps, nested JSON

Output format:

| Source Column | Target Column | Transformation | Notes |
|---|---|---|---|
| `ord_id` | `order_id` | Rename | Direct map |
| `created_at` | `created_at` | Cast to UTC timestamp | Source is naive datetime |
| `line_items` | (explode) | JSON array → rows | One row per line item |
| `total_cents` | `order_total` | Divide by 100, cast to decimal | Source in cents |

**Step 2.2 — Define joins and dependencies.**

Map the dependency graph:

```
stg_orders ─┐
             ├─ int_order_details ─── fct_orders
stg_line_items ┘
                                      
stg_customers ── dim_customers
```

For each join:
- Join type (inner, left, full outer)
- Join key(s)
- Conflict resolution (which table wins on duplicate columns)
- Cardinality (1:1, 1:N, M:N)

**Step 2.3 — Handle edge cases.**

| Edge case | Decision required | Default approach |
|---|---|---|
| **Late-arriving data** | How far back to look? | Window: last 7 days of partitions |
| **Duplicate records** | Dedup key? | Latest by `_updated_at` timestamp |
| **NULL handling** | Fill, drop, or pass through? | Pass through at staging; fill/COALESCE at marts |
| **Schema evolution** | Additive vs. breaking? | Additive columns: auto-extend. Breaking: version the pipeline |
| **Time zones** | Source TZ vs. target TZ? | Normalize all to UTC at staging |
| **Nested/semi-structured** | Flatten fully or preserve hierarchy? | Flatten at staging; keep nested in dedicated columns if queried |
| **Pii/sensitive data** | Mask, hash, or strip? | Hash at staging; never load raw PII to warehouse unless required |

### Phase 3 — Design the Load

**Step 3.1 — Choose the load strategy.**

| Strategy | When | Trade-off |
|---|---|---|
| **Full refresh** | Small tables (<1M rows); simple; low frequency | Simple but slow; wastes compute on large tables |
| **Incremental** | Large tables; daily/hourly runs | Fast; requires a reliable watermark column |
| **CDC** | OLTP sources; zero-downtime sync | Most accurate; highest complexity |

Default: **Full refresh for small tables, incremental for everything else.**

**Step 3.2 — Define the watermark.**

For incremental loads:
- Which column tracks recency? (`_updated_at`, `_inserted_at`, `modified_date`)
- What is the lookback window? (overlap to catch edge cases)
- Is the watermark column indexed on the source? (performance gate)

**Step 3.3 — Design the error handling.**

| Failure mode | Response | Alert |
|---|---|---|
| Source unavailable | Retry with backoff (3 attempts, then fail) | Alert immediately |
| Schema mismatch | Halt pipeline, do not load partial data | Alert with schema diff |
| Row count anomaly | Continue but flag | Alert if >20% deviation from expected |
| Transform error | Halt pipeline at failing step | Alert with error context |
| Timeout | Kill and retry from last checkpoint | Alert after 2nd timeout |

### Phase 4 — Design Validation

**Step 4.1 — Define the validation plan.**

For each output table:

| Check type | What to verify | How |
|---|---|---|
| **Row count** | No unexpected data loss | Compare source count vs. target count |
| **Null checks** | Key columns are never NULL | Assert NOT NULL on PK, FK, required fields |
| **Uniqueness** | Primary keys are unique | Assert DISTINCT count = COUNT |
| **Referential integrity** | FKs point to existing records | Left join against dimension, check for orphans |
| **Range checks** | Numeric values in expected range | min/max bounds from business rules |
| **Freshness** | Data is not stale | Max `_updated_at` < threshold |
| **Checksum** | Aggregate numeric fields match | SUM(amount) within tolerance |
| **Schema drift** | No unexpected column changes | Compare schema snapshot |

**Step 4.2 — Define the acceptance criteria.**

The pipeline is "done" when:
- [ ] All validation checks pass
- [ ] SLA is met (freshness, completeness)
- [ ] Idempotency verified (re-run produces same result)
- [ ] Backfill tested (at least 30 days)
- [ ] Alerting configured for all failure modes
- [ ] Documentation covers the pipeline

### Output — Design Document

```markdown
# Pipeline Design: [Name]

## Overview
- Source: [description]
- Destination: [description]
- Pattern: [ELT/ETL/Streaming]
- Cadence: [schedule]
- SLA: [freshness, completeness targets]

## Schema
### [table_name]
| Column | Type | Description | Constraints |
|---|---|---|---|
| ... | ... | ... | PK, NOT NULL, etc. |

## Transformations
[Source → Target mapping table from Phase 2]

## Dependencies
[DAG diagram]

## Validation Plan
[Checks from Phase 4]

## Error Handling
[Table from Phase 3, Step 3.3]

## Edge Cases
[Handling decisions from Phase 2, Step 2.3]

## Open Questions
[Items that need stakeholder input]
```

### Anti-patterns — Design

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| **Designing for current data only** | Breaks on growth, new sources, edge cases | Design for 10x volume and schema evolution |
| **Skipping the SLA definition** | No way to measure success; silent failures | Define SLA before writing code |
| **Over-engineering on day one** | Premature optimization wastes a 2-person team's time | Start with simplest viable design; evolve |
| **Hardcoding business logic in load** | Transformations buried in load step; untestable | Separate extract, transform, load into distinct steps |
| **No idempotency plan** | Re-running corrupts data or duplicates records | Design for re-runs from the start |
| **Ignoring late-arriving data** | Missing data silently; no backfill strategy | Define lookback window and backfill capability |

---

## Workflow 2 — Pipeline Implementation

**Invoke:** "build this pipeline", "implement the orders ETL", "write the
pipeline code", "create the dbt models", "set up the data sync"

**Pre-flight:** Run the full pre-flight above.

### Phase 1 — Scaffold

**Step 1.1 — Create the directory structure.**

Adapt to the project's existing conventions. If the project already has a
pipeline directory, match its structure exactly. If greenfield, use:

| Pattern | Use when |
|---|---|
| `pipelines/{pipeline_name}/` | Python-based pipelines |
| `dbt/models/{staging,marts}/` | dbt projects |
| `dags/` | Airflow DAGs |
| `sql/transforms/` | Raw SQL transforms |
| `src/etl/{pipeline_name}.py` | Monorepo, flat structure |

**Step 1.2 — Set up configuration.**

Create the pipeline config. Match the project's existing config pattern:

| Config pattern | Example |
|---|---|
| YAML file | `pipelines/{name}/config.yaml` |
| Environment variables | `PIPELINE_{NAME}_SOURCE=...` |
| Secrets manager | Reference to vault/SSM for credentials |
| dbt profiles | `profiles.yml` with target-specific overrides |

Required config items:
- Source connection (host, port, credentials reference)
- Target connection
- Schedule / trigger
- Log level
- Retry configuration

**Step 1.3 — Set up the test harness.**

Create the test scaffold in the project's existing test pattern:

| Framework | Setup |
|---|---|
| pytest | `tests/pipelines/test_{pipeline_name}.py` with fixtures |
| dbt tests | `tests/` directory with schema.yml assertions |
| Airflow test | `tests/dags/test_{dag_name}.py` with DAG parse test |

### Phase 2 — Extract

**Step 2.1 — Implement the extract layer.**

The extract layer reads from the source and produces a raw, unmodified
dataset. No business logic here.

| Source type | Implementation |
|---|---|
| **Database** | Parameterized SQL query with connection pooling; paginated if large |
| **API** | HTTP client with retry, rate limiting, pagination; raw JSON/CSV to disk |
| **File (CSV/JSON/Parquet)** | File reader with encoding detection; validate schema on read |
| **Stream** | Consumer with offset management; checkpoint periodically |

Key implementation rules:
- Log the row count and bytes extracted
- Handle connection failures with retries (exponential backoff)
- Never modify data in the extract layer
- Write raw data to a staging area (S3, temp table, local buffer)
- Make extraction idempotent (same input → same output)

**Step 2.2 — Implement schema validation at extract time.**

Compare extracted data schema against expected schema:

```python
# Pseudocode — adapt to project's stack
expected_schema = load_schema("schemas/source_orders.yaml")
actual_schema = infer_schema(extracted_data)
diff = schema_diff(expected_schema, actual_schema)

if diff.has_breaking_changes():
    raise SchemaError(f"Breaking schema change: {diff.breaking}")
if diff.has_warnings():
    log.warning(f"Schema drift detected: {diff.warnings}")
```

Breaking changes: column removed, column type changed, column renamed.
Warning changes: new column added, nullable changed.

**Step 2.3 — Write the raw data.**

| Target | Write strategy |
|---|---|
| Staging table | `TRUNCATE + INSERT` or `DROP + CREATE + INSERT` |
| S3/GCS | Write partitioned files; atomic rename on completion |
| Local buffer | Write to temp file; atomic move on success |

### Phase 3 — Transform

**Step 3.1 — Implement staging transforms.**

One model/script per source table. Responsibilities:
- Rename columns to target naming convention
- Cast data types
- Handle NULLs (pass through or flag)
- Deduplicate (if source has duplicates)
- Add metadata columns (`_loaded_at`, `_source_file`)

Rules:
- No business logic in staging
- No joins in staging
- Every staging model has a test that asserts row count ≈ source row count
- Staging output is 1:1 with source (same rows, different column names/types)

**Step 3.2 — Implement intermediate transforms.**

Join, aggregate, and apply business rules:

- Each intermediate model has a single responsibility
- Document the business rule it implements
- Use CTEs or subqueries for readability (not nested subqueries)
- Name intermediate models with their purpose: `int_orders_enriched`,
  `int_orders_deduped`, `int_orders_aggregated_daily`

**Step 3.3 — Implement mart models.**

Final output tables for consumption:

- `fct_*` for fact tables (events, transactions, metrics)
- `dim_*` for dimension tables (entities, lookups, configs)
- Wide tables for analyst consumption (denormalized, pre-joined)
- Document every column in the mart's schema definition

**Step 3.4 — Implement incremental logic (if applicable).**

| Incremental strategy | When | Implementation |
|---|---|---|
| **dbt `is_incremental`** | dbt projects | Use `is_incremental()` macro with `updated_at` filter |
| **Merge/Upsert** | Custom SQL or Python | `MERGE INTO` or `INSERT ... ON CONFLICT DO UPDATE` |
| **Partition overwrite** | Date-partitioned targets | `INSERT OVERWRITE PARTITION (dt=...)` |
| **Append + dedup** | Append-only logs | Insert all; deduplicate in a downstream view |

### Phase 4 — Load

**Step 4.1 — Implement the load layer.**

| Load pattern | Implementation |
|---|---|
| **Full refresh** | Drop and recreate; or truncate + insert |
| **Incremental merge** | `MERGE INTO` on natural key; update existing, insert new |
| **Partition swap** | Build new partition in temp table; atomic swap |
| **Append** | `INSERT INTO` with no conflict handling (logs, events) |

**Step 4.2 — Implement transaction safety.**

For databases that support transactions:
- Wrap load in a transaction
- Commit only after all validations pass
- Rollback on any failure

For systems without transactions (S3, BigQuery):
- Write to a staging location
- Validate
- Atomically move/copy to final location

**Step 4.3 — Implement the orchestration.**

Wire extract → transform → load into the project's orchestration layer:

| Orchestrator | Implementation |
|---|---|
| **Airflow** | DAG with `PythonOperator` or `BashOperator` tasks; dependencies set via `>>` |
| **dbt + cron** | Shell script: `dbt deps && dbt seed && dbt run && dbt test` |
| **Prefect / Dagster** | Flow/asset definitions with retries and caching |
| **GitHub Actions** | Workflow triggered on schedule + manual dispatch |
| **Custom** | Python script with `if __name__ == "__main__"` entry point |

### Phase 5 — Test

**Step 5.1 — Unit tests.**

Test individual transformation functions:

- Pure function tests (input → output, no side effects)
- Edge cases: empty input, NULL values, single row, maximum row count
- Type coercion tests (string → date, int → decimal)

**Step 5.2 — Integration tests.**

Test the full pipeline end-to-end:

- Use a small fixture dataset (10-100 rows) that covers all code paths
- Assert output schema matches expected schema
- Assert row counts match expected (after dedup, after filter)
- Assert specific values for known inputs
- Assert idempotency: run twice, same output

**Step 5.3 — Data quality tests.**

Run the validation checks from the design phase:

- Null checks on required columns
- Uniqueness on primary keys
- Referential integrity on foreign keys
- Range checks on numeric fields
- Freshness check on timestamp fields

**Step 5.4 — Load and performance tests.**

- Time the pipeline with production-scale data
- Verify it completes within the SLA
- Test with concurrent runs (if applicable)
- Test failure and recovery scenarios

### Output — Implementation Checklist

```markdown
## Implementation: [Pipeline Name]

- [ ] Directory structure created
- [ ] Configuration file created with all required settings
- [ ] Extract layer implemented with retry and logging
- [ ] Schema validation at extract time
- [ ] Staging transforms: one model per source table
- [ ] Intermediate transforms: business logic separated
- [ ] Mart models: fct/dim tables with documentation
- [ ] Incremental logic (if applicable)
- [ ] Load layer with transaction safety
- [ ] Orchestration wired and tested
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Data quality tests passing
- [ ] Performance within SLA
- [ ] Documentation complete
- [ ] Alerting configured
```

### Anti-patterns — Implementation

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| **Monolithic pipeline script** | One 500-line file impossible to test, debug, or hand off | Separate extract, transform, load into distinct modules |
| **No logging or observability** | Failures are silent; debugging requires reading source code | Log row counts, timing, and key metrics at every step |
| **Hardcoded credentials** | Security risk; cannot rotate secrets; blocks CI/CD | Use environment variables or secrets manager |
| **Skipping the staging layer** | Business logic mixed with source mapping; impossible to change source without rewriting transforms | Staging = pure mapping; business logic lives in intermediate/mart |
| **No test data fixtures** | Cannot test locally; pipeline breaks in production | Maintain a small, version-controlled fixture dataset |
| **Premature optimization** | Wasted time on bottlenecks that do not exist yet | Build correct first; optimize when profiling shows a problem |
| **No idempotency** | Re-running after failure produces duplicate or corrupt data | Design every step for re-runs from the start |
| **Catch-all exception handling** | Hides real errors; pipeline appears to succeed when it fails | Catch specific exceptions; fail loudly on unexpected errors |

---

## Workflow 3 — Data Quality

**Invoke:** "check data quality", "validate the orders table", "run data
tests", "is our data clean?", "add quality checks to the pipeline"

**Pre-flight:** Run the full pre-flight above.

### Phase 1 — Profile

Before writing quality rules, understand what the data actually looks like.
Profiling answers: "what does the data contain right now?"

**Step 1.1 — Schema profiling.**

For each table in scope:

| Metric | What to check |
|---|---|
| Column count | Matches expected schema |
| Column names | Match naming convention |
| Column types | Match expected types (no implicit coercion) |
| Primary key | Defined, unique, non-null |
| Foreign keys | All defined, referential integrity holds |
| Indexes | Present on frequently queried/joined columns |

**Step 1.2 — Data profiling.**

For each column:

| Metric | Why | Threshold |
|---|---|---|
| **Null percentage** | Unexpected missing data | >5% on required column = alert |
| **Distinct count** | Cardinality anomalies | Sudden drop = data issue |
| **Min / Max** | Range violations | Value outside expected bounds |
| **Mean / Median** | Distribution shifts | >2σ from baseline = investigate |
| **Top values** | Distribution shape | Unexpected dominant value = pipeline bug |
| **String length distribution** | Truncation or padding issues | Lengths outside expected range |
| **Pattern match** | Format violations | Email/phone/ID format deviations |

**Step 1.3 — Volume profiling.**

| Metric | How to use |
|---|---|
| Row count today | Baseline for anomaly detection |
| Row count same day last week | Day-of-week pattern check |
| Row count same day last year | Year-over-year pattern check |
| Growth rate | Expected row count range |
| Null row ratio | Rows that are entirely NULL |

**Step 1.4 — Relationship profiling.**

| Check | Method |
|---|---|
| Join key coverage | % of FK values that match a PK in the referenced table |
| Orphan records | Records with no matching parent |
| Fan-out ratio | Average child count per parent (detect unexpected many-to-many) |
| Temporal coverage | Gap detection in time series (missing dates, hours) |

### Phase 2 — Define Rules

**Step 2.1 — Choose a quality framework.**

Adapt to what the project already uses:

| Framework | Integration | Use when |
|---|---|---|
| **dbt tests** | Built-in `schema.yml` assertions | dbt projects; simplest option |
| **Great Expectations** | Python library; extensive expectation library | Python pipelines; rich reporting |
| **Soda** | YAML-based; multiple source support | Multi-source environments |
| **Custom SQL assertions** | Raw SQL; no framework dependency | Lightweight; full control |
| **Pandera** | Python dataframe validation | Pandas/Polars pipelines |

**Step 2.2 — Define the rule set.**

For each table, define rules at three severity levels:

**Critical (pipeline halts on failure):**
| Rule | Implementation |
|---|---|
| Primary key uniqueness | `SELECT COUNT(DISTINCT pk) = COUNT(*)` |
| Not-null on required columns | `SELECT COUNT(*) WHERE col IS NULL = 0` |
| Referential integrity | `SELECT COUNT(*) WHERE fk NOT IN (SELECT pk FROM parent) = 0` |
| Row count within range | `COUNT(*) BETWEEN expected_min AND expected_max` |
| Freshness | `MAX(updated_at) > NOW() - INTERVAL '2 hours'` |

**Warning (alert but do not halt):**
| Rule | Implementation |
|---|---|
| Null percentage drift | `NULL% today vs. 7-day average` |
| Column value distribution shift | `chi-squared test vs. baseline` |
| Numeric range drift | `MIN/MAX within 3σ of baseline` |
| Schema drift (new columns) | Schema comparison |
| Join coverage degradation | FK coverage < baseline |

**Informational (log for trending):**
| Rule | Implementation |
|---|---|
| Row count trend | Daily count logged for dashboards |
| Processing time trend | Pipeline duration logged |
| Data volume trend | Bytes processed logged |
| Error rate | Count of rejected/invalid records |

**Step 2.3 — Define baselines.**

Quality rules need baselines to compare against. Establish:

- **Static baselines:** Known good values (row count = 100,000, null% = 0)
- **Dynamic baselines:** Rolling averages (7-day, 30-day mean and std dev)
- **Business rules:** Domain-specific constraints (total revenue > 0, age between 0 and 120)

### Phase 3 — Monitor

**Step 3.1 — Instrument the pipeline.**

Add quality checks at each pipeline stage:

| Stage | What to check | When |
|---|---|---|
| **Extract** | Source row count, schema match, null rates | After extract completes |
| **Staging** | Rename/cast success, row count preservation | After staging models run |
| **Transform** | Business rule compliance, join coverage | After each transform step |
| **Load** | Target row count, load success, transaction commit | After load completes |

**Step 3.2 — Configure alerting.**

| Severity | Response | Channel |
|---|---|---|
| Critical | Page on-call; pipeline halted | PagerDuty / SMS |
| Warning | Slack/email notification; pipeline continues | Slack / email |
| Informational | Logged to dashboard; no notification | Data quality dashboard |

**Step 3.3 — Set up dashboards.**

Track these metrics over time:

| Dashboard panel | Source |
|---|---|
| Pipeline run status (pass/fail) per day | Orchestration logs |
| Row count trends per table | Quality check results |
| Null percentage trends per critical column | Quality check results |
| Freshness: time of availability per table | Pipeline completion timestamps |
| Error rate: failed records / total records | Transform error logs |
| Pipeline duration over time | Orchestration metrics |

### Phase 4 — Remediate

**Step 4.1 — Triage quality failures.**

When a quality check fails:

| Situation | Action |
|---|---|
| Source data changed (schema evolution) | Update schema expectations; notify stakeholders |
| Source data is genuinely bad | Log issue; do not load bad data; alert source system owner |
| Pipeline bug (transform error) | Fix pipeline; reprocess affected partitions |
| Transient failure (timeout, connection) | Retry; monitor for recurrence |
| Data is late (not bad, just delayed) | Extend lookback window; do not halt pipeline |

**Step 4.2 — Implement backfill for quality fixes.**

When a pipeline bug produces bad data:

1. Identify the affected time range
2. Fix the pipeline code
3. Re-run the pipeline for the affected range
4. Validate the reprocessed data passes all quality checks
5. Confirm downstream consumers see corrected data

**Step 4.3 — Update baselines.**

After legitimate data changes (new product, new market, schema evolution):
1. Review the quality rule baselines
2. Update static baselines if the new data shape is the new normal
3. Adjust dynamic baseline windows if needed
4. Document the baseline change

### Output — Quality Report

```markdown
# Data Quality Report: [Table Name]

**Profile Date:** [date]
**Records profiled:** [count]
**Columns profiled:** [count]

## Schema Summary
| Column | Type | Null% | Distinct | Min | Max | Status |
|---|---|---|---|---|---|---|
| ... | ... | ... | ... | ... | ... | OK/WARN |

## Volume Summary
| Period | Row Count | Δ vs. Prior | Status |
|---|---|---|---|
| Today | [n] | [+/- %] | OK/WARN |
| 7-day avg | [n] | — | — |

## Quality Rules
| Rule | Table | Column | Severity | Result | Details |
|---|---|---|---|---|---|
| Uniqueness | orders | order_id | Critical | PASS | 1,000,000 distinct = 1,000,000 total |
| Not-null | orders | customer_id | Critical | FAIL | 12 records with NULL customer_id |
| Range | orders | total | Warning | WARN | Max total is 999,999 (baseline max: 50,000) |

## Anomalies Detected
| Type | Table | Column | Detail |
|---|---|---|---|
| Null spike | orders | customer_id | 12 NULLs (baseline: 0) |
| Distribution shift | orders | status | 80% "completed" (baseline: 60%) |

## Recommendations
1. Investigate NULL customer_id records — possible upstream bug
2. Review "status" distribution shift — may indicate pipeline change
```

### Anti-patterns — Data Quality

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| **Checking quality after load only** | Bad data already in production tables; consumers see it first | Check at every stage; halt before loading bad data |
| **Static thresholds only** | Normal data variation triggers false alarms | Use dynamic baselines (rolling averages, percentile bounds) |
| **Too many checks, no triage** | Alert fatigue; real issues buried in noise | Three severity levels; critical checks halt pipeline; others alert |
| **No profiling before rules** | Quality rules based on assumptions, not data reality | Profile first; let data shape inform the rules |
| **Ignoring informational checks** | Lose trending data; cannot detect slow drifts | Log everything; build dashboards for long-term visibility |
| **Quality as an afterthought** | Bolted-on checks miss internal pipeline state | Instrument quality at every pipeline stage |
| **No backfill plan for fixes** | Fix is deployed but bad data remains in production | Always backfill affected data after fixing a pipeline bug |
| **One-size-fits-all thresholds** | Revenue table gets same null% threshold as reference table | Customize thresholds per table based on business criticality |

---

## Workflow 4 — Pipeline Debugging

**Invoke:** "debug this pipeline", "this pipeline is failing", "fix the
orders ETL", "why is the data wrong?", "the pipeline is slow/broken/stuck"

**Pre-flight:** Run the full pre-flight above.

### Phase 1 — Reproduce

You cannot fix what you cannot reproduce. Reproduce the failure before
touching any code.

**Step 1.1 — Gather failure context.**

| Source | What to extract |
|---|---|
| Error logs | Exact error message, stack trace, failing line |
| Orchestration logs | Which step failed, when, how long it ran |
| Monitoring/alerts | What metric triggered the alert |
| Recent changes | Git log — any recent deploys, config changes, schema changes |
| Data changes | Source system changes — new columns, new values, volume spike |

**Step 1.2 — Reproduce locally.**

| Failure type | Reproduction method |
|---|---|
| **Data-dependent failure** | Run with a small fixture dataset that triggers the same path |
| **Environment-dependent** | Run in a staging/test environment that mirrors production |
| **Timing-dependent** | Add logging to capture the state at the failing point |
| **Intermittent** | Run 5 times; check logs for pattern; narrow the trigger |
| **Volume-dependent** | Generate synthetic data at production scale; run locally |

**Step 1.3 — Classify the failure.**

| Category | Symptoms | Starting point |
|---|---|---|
| **Source issue** | Extract fails; schema mismatch; connection error | Phase 1, Step 1.1 |
| **Transform issue** | Staging/intermediate fails; data type error; logic error | Phase 1, Step 1.1 |
| **Load issue** | Target rejected data; connection error; permission denied | Phase 1, Step 1.1 |
| **Data quality issue** | Pipeline succeeds but data is wrong; downstream complaints | Phase 1, Step 1.1 |
| **Infrastructure issue** | Timeout; OOM; disk full; network error | Phase 1, Step 1.1 |
| **Orchestration issue** | DAG not running; schedule wrong; dependency not met | Phase 1, Step 1.1 |

### Phase 2 — Isolate the Stage

**Step 2.1 — Binary search the pipeline.**

Run each pipeline stage independently to find where the failure begins:

1. Run extract only — does it succeed?
   - **Yes:** Transform or load is the problem. Proceed to step 2.
   - **No:** Extract is the problem. Fix extract first.

2. Run staging only (with extract output) — does it succeed?
   - **Yes:** Intermediate or mart is the problem. Proceed to step 3.
   - **No:** Staging is the problem.

3. Run each intermediate model individually — which one fails?
   - Identify the failing model.

4. Run load only (with transform output) — does it succeed?
   - **Yes:** Transform produces invalid data for load. Inspect transform output.
   - **No:** Load is the problem.

**Step 2.2 — Isolate data vs. code.**

| Check | Method |
|---|---|
| Does the same input produce different output? | Run pipeline with frozen input data |
| Does different input produce the same failure? | Run pipeline with different data subsets |
| Does the code produce the same failure on a different environment? | Run on staging vs. local vs. CI |

**Step 2.3 — Check for environmental factors.**

| Factor | How to check |
|---|---|
| Time of day | Does it fail at a specific time? Check source system maintenance windows |
| Concurrent runs | Are two instances running simultaneously? Check orchestration logs |
| Resource exhaustion | Check memory, CPU, disk, connection pool at failure time |
| Permission changes | Check if credentials were rotated; if IAM roles changed |
| Source system changes | Check if source schema, API version, or data format changed |

### Phase 3 — Diagnose

**Step 3.1 — Inspect the failing data.**

| Problem | Diagnostic query / check |
|---|---|
| **Wrong values** | `SELECT * FROM table WHERE column_value NOT IN expected_values` |
| **Missing rows** | Compare source count vs. target count per partition/date |
| **Duplicate rows** | `SELECT pk, COUNT(*) FROM table GROUP BY pk HAVING COUNT(*) > 1` |
| **NULL values** | `SELECT COUNT(*) FROM table WHERE required_col IS NULL` |
| **Type errors** | `SELECT * FROM table WHERE NOT REGEXP_LIKE(col, expected_pattern)` |
| **Truncated data** | Check max string lengths vs. schema; check source field lengths |
| **Stale data** | `SELECT MAX(updated_at) FROM table` vs. expected freshness |

**Step 3.2 — Trace the transformation.**

For the failing stage, trace through the logic:

1. Write the intermediate output to a temporary table/file
2. Manually apply the transform step by step
3. Identify where the output diverges from expected
4. Check for:
   - Incorrect join condition (missing join key, wrong join type)
   - Wrong filter logic (inclusive vs. exclusive boundary)
   - Incorrect aggregation (wrong GROUP BY, missing HAVING)
   - Off-by-one in date/time handling
   - NULL propagation (NULL in join key = no match)
   - Integer overflow, decimal precision loss

**Step 3.3 — Check for silent failures.**

| Silent failure | How it hides | How to find it |
|---|---|---|
| Try/except that logs and continues | Pipeline appears green; data is missing | Search for bare `except:` or `except Exception` |
| Default values masking errors | NULL → 0, empty string → "unknown" | Check WHERE clauses for sentinel values |
| Timeout with partial write | Some rows loaded, some not | Check row counts vs. expected |
| Schema evolution with defaults | New column gets default values | Compare schema before and after |

### Phase 4 — Fix

**Step 4.1 — Apply the minimal fix.**

| Root cause | Fix approach |
|---|---|
| Wrong logic | Fix the logic; add a test for the specific case |
| Missing edge case handling | Add handling; add a test for the edge case |
| Schema change | Update schema mapping; add migration if needed |
| Performance issue | Add index, optimize query, or increase resources |
| Configuration error | Fix config; add config validation |
| Permission issue | Fix permissions; add connection test step |

Rules for fixes:
- Fix the root cause, not the symptom
- Do not refactor unrelated code in the same change
- Add a test that would have caught this failure
- If the fix changes output, document the change

**Step 4.2 — Add a regression test.**

The test should:
1. Reproduce the specific failure scenario
2. Pass after the fix is applied
3. Fail if the fix is reverted

```python
def test_orders_handles_null_customer_id():
    """Regression: pipeline used to crash on NULL customer_id in orders."""
    input_data = [
        {"order_id": 1, "customer_id": None, "total": 50.00},
        {"order_id": 2, "customer_id": 1001, "total": 75.00},
    ]
    result = transform_orders(input_data)
    assert len(result) == 2
    assert result[0]["customer_id"] is None  # preserved, not crashed
```

### Phase 5 — Verify

**Step 5.1 — Verify the fix.**

| Verification | Method |
|---|---|
| Fix addresses root cause | Re-run the specific failing case |
| No regression | Run the full test suite |
| No side effects | Compare output of non-failing stages before and after fix |
| Data integrity | If data was affected, backfill and verify |

**Step 5.2 — Verify end-to-end.**

1. Run the full pipeline in staging
2. Verify all quality checks pass
3. Verify downstream consumers see correct data
4. Verify timing/performance is within SLA

**Step 5.3 — Document the incident.**

```markdown
## Incident: [Brief Description]

**Date:** [date]
**Pipeline:** [name]
**Duration:** [how long it was broken]
**Impact:** [what was affected]

### Root cause
[1-2 sentences]

### Timeline
- [time] Failure detected via [alert/logs/user report]
- [time] Investigation started
- [time] Root cause identified
- [time] Fix deployed
- [time] Verified and resolved

### Fix
[What was changed and why]

### Prevention
- [ ] Test added: [test name]
- [ ] Monitoring added: [what to monitor]
- [ ] Documentation updated: [what]
```

### Output — Debug Report

```markdown
# Debug Report: [Pipeline Name]

## Failure Summary
- **Symptom:** [what was observed]
- **Root cause:** [what is actually wrong]
- **Category:** [source/transform/load/quality/infra/orchestration]

## Reproduction
- **Steps to reproduce:** [numbered list]
- **Reproduction rate:** [100% / intermittent / % success]
- **Failing input:** [sample data that triggers the failure]

## Diagnosis
| Stage | Status | Notes |
|---|---|---|
| Extract | OK/FAIL | [details] |
| Staging | OK/FAIL | [details] |
| Transform | OK/FAIL | [details] |
| Load | OK/FAIL | [details] |

## Fix
- **Change:** [what was modified]
- **File(s):** [file paths and line numbers]
- **Regression test:** [test added]

## Verification
- [ ] Failing case now passes
- [ ] Full test suite passes
- [ ] Pipeline runs in staging
- [ ] Quality checks pass
- [ ] Backfill completed (if needed)
```

### Anti-patterns — Debugging

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| **Fixing without reproducing** | You might fix the wrong thing; the fix might not work in production | Reproduce first; if you cannot reproduce, add logging until you can |
| **Changing multiple things at once** | Cannot tell which change fixed the problem; introduces new risks | One fix per attempt; verify between changes |
| **Blaming the source first** | Most pipeline bugs are in the transform, not the source | Systematically isolate the stage before assigning blame |
| **Ignoring intermittent failures** | They become frequent failures eventually | Add logging and retry; investigate the trigger |
| **No regression test** | Same failure happens again after someone changes the code | Every fix gets a test that reproduces the original failure |
| **Fixing symptoms, not root cause** | NULL handling mask hides a missing upstream record | Trace to the actual source of the problem |
| **Skipping verification** | Fix looks correct locally but fails in production | Verify end-to-end in staging with production-like data |
| **No incident documentation** | Next person hits the same issue with no context | Document the incident, root cause, and prevention |

---

## Workflow 5 — Pipeline Optimization

**Invoke:** "optimize this pipeline", "this pipeline is too slow", "reduce
pipeline cost", "the pipeline is timing out", "make the pipeline faster"

**Pre-flight:** Run the full pre-flight above.

### Phase 1 — Measure

Do not guess what is slow. Measure it.

**Step 1.1 — Establish the baseline.**

Run the pipeline with production-scale data and record:

| Metric | How to measure |
|---|---|
| Total wall clock time | Timer from start to finish |
| Time per stage | Timer on each stage boundary |
| Rows processed per stage | Row count at stage input/output |
| Bytes read/written per stage | I/O metrics from database or cloud |
| CPU utilization | Process monitor or cloud metrics |
| Memory peak usage | Process monitor or cloud metrics |
| Database queries | Query count per stage; slow query log |
| Network I/O | API calls, data transfer volume |

**Step 1.2 — Compare against SLA.**

| Metric | Current | SLA | Gap |
|---|---|---|---|
| Total time | [X min] | [Y min] | [Z min over] |
| Peak memory | [X GB] | [Y GB] | [Z GB over] |
| Query count | [X] | [Y] | [Z over] |

If the pipeline is within SLA, stop here. Optimization is only needed when
the pipeline fails to meet its SLA.

**Step 1.3 — Define the optimization target.**

| Target | When | Trade-off |
|---|---|---|
| **Reduce wall clock time** | Pipeline must finish before a deadline | May increase compute cost |
| **Reduce compute cost** | Budget constraint | May increase wall clock time |
| **Reduce memory usage** | OOM errors; resource constraints | May require streaming/chunking |
| **Reduce query count** | Database bottleneck; connection limits | May require batching |

### Phase 2 — Profile

**Step 2.1 — Find the bottleneck.**

The bottleneck is the stage that, if made infinite faster, would most reduce
total pipeline time. Identify it:

| Method | When to use |
|---|---|
| **Stage timing** | First pass; see which stage takes the most time |
| **Query plan analysis** | Database-heavy pipelines; check `EXPLAIN` on slow queries |
| **Python profiler** | Python-heavy pipelines; `cProfile` or `py-spy` |
| **I/O profiling** | File-heavy pipelines; check read/write throughput |
| **Memory profiler** | Memory issues; `memory_profiler` or cloud metrics |

**Step 2.2 — Classify the bottleneck.**

| Bottleneck type | Symptoms | Optimization path |
|---|---|---|
| **CPU-bound** | High CPU utilization; transform computation dominates | Parallelize, optimize algorithms, use compiled code |
| **I/O-bound (read)** | Low CPU; high disk/network read; waiting on source | Batch reads, parallelize extracts, cache |
| **I/O-bound (write)** | Low CPU; high disk/network write; load dominates | Batch writes, use bulk loading, optimize target |
| **Memory-bound** | OOM errors; swapping; memory usage grows with data | Stream processing, chunking, spill to disk |
| **Database-bound** | Slow queries; lock contention; connection pool exhaustion | Optimize queries, add indexes, use connection pooling |
| **Network-bound** | API rate limiting; high latency; low throughput | Batch API calls, parallel requests, cache responses |
| **Serialization-bound** | JSON parsing, CSV conversion, format conversion is slow | Use columnar formats (Parquet), binary protocols |

### Phase 3 — Optimize

**Step 3.1 — Apply the right optimization pattern.**

| Bottleneck | Optimization | Implementation |
|---|---|---|
| **Slow query** | Add index on filter/join columns | `CREATE INDEX idx_table_col ON table(col)` |
| **Slow query** | Rewrite to avoid full table scan | Use partition pruning; add WHERE clause on partition key |
| **Slow query** | Materialize expensive joins | Create intermediate materialized view |
| **I/O read** | Parallelize extraction | Multiple threads/processes reading different partitions |
| **I/O read** | Use columnar format | Convert CSV to Parquet; read only needed columns |
| **I/O write** | Bulk loading | Use `COPY` instead of `INSERT`; use bulk API |
| **I/O write** | Reduce transaction overhead | Batch commits (e.g., commit every 10K rows) |
| **Memory** | Stream processing | Process rows in chunks; use generators/iterators |
| **Memory** | Spill to disk | Use external sort/hash; write intermediate to disk |
| **CPU** | Vectorize operations | Use numpy/polars instead of Python loops |
| **CPU** | Parallelize | multiprocessing, Dask, or Ray for embarrassingly parallel work |
| **Network** | Cache API responses | Local cache with TTL; avoid re-fetching unchanged data |
| **Network** | Batch API calls | Combine multiple requests; use bulk API endpoints |
| **Serialization** | Use Parquet/Arrow | Replace CSV/JSON with columnar binary format |

**Step 3.2 — Apply pipeline-level optimizations.**

| Optimization | When | Implementation |
|---|---|---|
| **Skip unchanged data** | Source data has not changed for a partition | Checksum/hash before processing |
| **Incremental processing** | Only new data needs processing | Watermark-based; process only new partitions |
| **Dependency parallelization** | Independent stages can run concurrently | DAG-based execution; run independent branches in parallel |
| **Materialization** | Expensive intermediate results reused | Materialize intermediate tables; refresh incrementally |
| **Caching** | Same extract is used by multiple transforms | Extract once, share across transforms |

**Step 3.3 — Apply database-level optimizations.**

| Optimization | When | Implementation |
|---|---|---|
| **Partitioning** | Large tables scanned by date range | Partition by date; prune on query |
| **Clustering** | Large tables filtered by specific columns | Cluster on filter/join columns |
| **Materialized views** | Expensive queries run repeatedly | Create MV; refresh on schedule |
| **Connection pooling** | Many short-lived connections | Use pgBouncer, RDS Proxy, or application-level pool |
| **Read replicas** | Heavy read workload conflicts with writes | Route reads to replica |

### Phase 4 — Verify

**Step 4.1 — Verify the optimization.**

| Check | Method |
|---|---|
| **Speed improvement** | Re-run with production data; compare timing |
| **Cost impact** | Check compute costs before and after |
| **Data correctness** | Run full quality test suite; compare output to baseline |
| **No regressions** | Verify non-optimized stages still work correctly |
| **Memory usage** | Confirm memory usage is within limits |
| **SLA met** | Confirm pipeline now completes within SLA |

**Step 4.2 — Document the optimization.**

```markdown
## Optimization: [Pipeline Name]

**Date:** [date]
**Bottleneck identified:** [description]
**Optimization applied:** [description]
**Result:**
| Metric | Before | After | Improvement |
|---|---|---|---|
| Wall clock time | [X min] | [Y min] | [Z%] |
| Compute cost | [$X] | [$Y] | [Z%] |
| Memory peak | [X GB] | [Y GB] | [Z%] |

**Trade-off:** [what was sacrificed, if anything]
**Risk:** [new failure modes introduced, if any]
```

### Output — Optimization Report

```markdown
# Optimization Report: [Pipeline Name]

## Baseline
| Metric | Current | SLA | Status |
|---|---|---|---|
| Total time | [X min] | [Y min] | [OVER/OK] |
| Bottleneck stage | [stage] | — | — |
| Bottleneck type | [CPU/IO/Memory/DB/Network] | — | — |

## Bottleneck Analysis
| Stage | Time | % of Total | Rows | Rows/sec |
|---|---|---|---|---|
| Extract | [X min] | [X%] | [N] | [N/min] |
| Staging | [X min] | [X%] | [N] | [N/min] |
| Transform | [X min] | [X%] | [N] | [N/min] |
| Load | [X min] | [X%] | [N] | [N/min] |

## Optimizations Applied
| # | Bottleneck | Optimization | Expected Impact | Actual Impact |
|---|---|---|---|---|
| 1 | [description] | [what was done] | [% improvement] | [% actual] |
| 2 | ... | ... | ... | ... |

## Results
| Metric | Before | After | Improvement |
|---|---|---|---|
| Wall clock time | [X min] | [Y min] | [Z%] |
| Compute cost | [$X] | [$Y] | [Z%] |
| Memory peak | [X GB] | [Y GB] | [Z%] |

## Risks and Trade-offs
- [Any new failure modes introduced]
- [Any cost increases]
- [Any complexity added]

## Remaining Opportunities
- [Optimizations identified but not yet applied]
- [Future optimizations when volume grows]
```

### Anti-patterns — Optimization

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| **Optimizing without measuring** | You might optimize the wrong thing; waste time on non-bottlenecks | Measure first; identify the actual bottleneck |
| **Premature optimization** | The pipeline might not need it; your time is better spent elsewhere | Only optimize when the pipeline fails its SLA |
| **Optimizing for speed at the cost of correctness** | Faster is worthless if the data is wrong | Verify correctness after every optimization |
| **Optimizing at the wrong level** | Tuning a query when the bottleneck is network I/O | Profile to find the actual bottleneck type first |
| **Not measuring before and after** | Cannot prove the optimization worked | Always measure baseline before; compare after |
| **Over-optimizing stable pipelines** | Diminishing returns; added complexity | Optimize once; move on; revisit only when SLA changes |
| **Ignoring cost for speed** | 10x speed increase at 100x cost is a bad trade | Consider both time and cost; find the balance |
| **Hardcoding optimization parameters** | Works for current data size; breaks at 10x volume | Use adaptive parameters (chunk size, parallelism based on input size) |

---

## Edge Cases

Cross-workflow edge cases that do not fit neatly into a single workflow:

| Scenario | Handling |
|---|---|
| **Greenfield project, no existing data stack** | Use the design workflow; recommend the simplest viable stack (dbt + cron + postgres) |
| **Pipeline crosses team boundaries** | Design phase must include data contract with downstream teams; schema changes require coordination |
| **Multiple pipelines share a source** | Extract once, write to staging; each pipeline reads from staging, not directly from source |
| **Real-time + batch in same pipeline** | Separate into distinct pipelines; streaming handles real-time; batch handles backfill and reconciliation |
| **Pipeline depends on external API with rate limits** | Extract layer must handle rate limiting, pagination, and retry; cache aggressively; design for incremental sync |
| **Data warehouse migration** | Design phase should be storage-agnostic where possible; separate storage-specific logic into adapter layer |
| **Regulatory compliance (GDPR, CCPA)** | Design phase must identify PII columns; implement masking/hashing at staging; never log raw PII |
| **Pipeline runs in CI/CD** | Use ephemeral test databases; seed with fixture data; tear down after tests |
| **Backfill takes longer than SLA** | Design for incremental backfill (process N days at a time); prioritize current data over historical |
| **Source system is unreliable** | Implement circuit breaker pattern; alert after N consecutive failures; degrade gracefully |

## Cost

Each workflow has a different cost profile:

| Workflow | Typical duration | When to use |
|---|---|---|
| **Design** | 15-45 minutes | Before building any new pipeline; before major changes |
| **Implementation** | 30-120 minutes | When the design is complete and code is needed |
| **Data Quality** | 10-30 minutes | Before deploying; periodically; after incidents |
| **Debugging** | 15-60 minutes | When a pipeline fails or produces wrong data |
| **Optimization** | 20-60 minutes | When a pipeline fails its SLA; not before |

## Portability

This skill works with any data stack. It adapts by discovery.

**What it needs:**
- Some form of data pipeline code or infrastructure
- A data source and a data destination
- Some way to run the pipeline (orchestration, manual, CI/CD)

**What it does NOT need:**
- Specific tools or frameworks (it adapts to what exists)
- Cloud provider (works with on-prem, AWS, GCP, Azure, or local)
- Specific programming language (SQL, Python, Node, Spark, or shell)
- Team size constraints (works for 1 person or 10)

**Adaptation rules:**
- If no orchestration exists, recommend the simplest option for the team size
- If no quality framework exists, start with raw SQL assertions
- If no test infrastructure exists, start with a single integration test
- If no documentation exists, generate documentation as part of the design output
