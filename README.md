# knotlog-agent-toolkit

Shared agent skills, definitions, and configurations for the Knotlog team.

## What's Inside

| Directory | Contents | Install Method |
|---|---|---|
| `skills/` | Agent skills (requirements-gatherer, generate-usecases, doc-consistency, generate-sequence, iteration, etc.) | Symlinks into `~/.agents/skills/` |
| `agents/` | Agent definitions (iteration-tester/writer/verifier, requirements drafter/red-teamer/questioner, usecase drafter/reviewer) | Symlinks to `~/.config/opencode/agents/` |
| `mcp/` | MCP server configurations | Merged into `opencode.jsonc` |
| `templates/` | Project config templates | Copy as needed |
| `examples/` | Reference documents used for skill calibration and testing | Read-only reference |

## Requirements Pipeline

The skills chain into a documentation pipeline:

```
requirements-gatherer → docs/requirements/requirements.md
generate-usecases     → docs/use-cases/*.md + docs/uml/use-cases/*.puml
[future skill]        → activity diagrams per use case
generate-sequence     → docs/uml/sequences/*.puml (also needs a component diagram)
```

## Quick Start

```bash
git clone https://github.com/Knotlog-Software/knotlog_agent_toolkit.git ~/knotlog-agent-toolkit
cd ~/knotlog-agent-toolkit
./install.sh
```

The installer will:
1. Symlink skill directories into `~/.agents/skills/` (opencode discovers skills only from fixed locations)
2. Symlink agent definitions to `~/.config/opencode/agents/`
3. Optionally merge MCP server configs

## Skills

### requirements-gatherer
Interactive requirements engineering using NASA Appendix C standards. Q&A loop → draft → parallel red-team review until zero blocking issues. Produces `docs/requirements/requirements.md`.

### generate-usecases
Generates use case specifications (one doc per domain) and PlantUML use case diagrams from a finalized requirements document. Drafter/reviewer loop with requirement-coverage checks. Output formatted for generate-sequence.

### doc-consistency
Analyzes architecture documentation for internal inconsistencies, contradictions, and generation readiness. Pre-implementation quality gate.

### generate-sequence
Generates PlantUML sequence diagrams from use case specifications, activity diagrams, and component diagrams.

### iteration
TDD pipeline orchestrator. Plans iterations, then builds via tester → writer → verifier subagents. Project-adaptive — discovers gate commands, file paths, and conventions from the target project.

### software-dev
General-purpose coding workflows: debugging, refactoring, code review, test strategy.

### devops-infra
Deployment, CI/CD, monitoring, and infrastructure management.

### data-pipelines
ETL design, pipeline building, and data quality workflows.

### documentation
Documentation generation, maintenance, review, and knowledge management.

## Uninstall

```bash
./uninstall.sh
```

Removes symlinks and config entries added by the installer. Does not delete the repo.
