# knotlog-agent-toolkit

Shared agent skills, definitions, and configurations for the Knotlog team.

## What's Inside

| Directory | Contents | Install Method |
|---|---|---|
| `skills/` | Agent skills (doc-consistency, generate-sequence, iteration, etc.) | `skills.paths` in opencode config |
| `agents/` | Agent definitions (iteration-tester, iteration-writer, iteration-verifier) | Symlinks to `~/.config/opencode/agents/` |
| `mcp/` | MCP server configurations | Merged into `opencode.jsonc` |
| `templates/` | Project config templates | Copy as needed |

## Quick Start

```bash
git clone <repo-url> ~/knotlog-agent-toolkit
cd ~/knotlog-agent-toolkit
./install.sh
```

The installer will:
1. Add `skills/` to your opencode `skills.paths` config
2. Symlink agent definitions to `~/.config/opencode/agents/`
3. Optionally merge MCP server configs

## Skills

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
