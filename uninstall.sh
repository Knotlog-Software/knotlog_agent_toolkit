#!/usr/bin/env bash
set -euo pipefail

# knotlog-agent-toolkit uninstaller
# Removes symlinks and config entries added by install.sh.

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="${HOME}/.config/opencode/agents"
MANIFEST="${TOOLKIT_DIR}/.install-manifest.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[info]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*"; }

# ─── Remove Skill Symlinks ─────────────────────────────────────────

uninstall_skills() {
  info "Skills: removing symlinks..."

  if [[ ! -f "${MANIFEST}" ]]; then
    warn "No manifest found. Cannot determine which skills to remove."
    warn "Manually check ${HOME}/.agents/skills for symlinks pointing to ${TOOLKIT_DIR}/skills/"
    return
  fi

  if command -v node &>/dev/null; then
    local skills
    skills=$(node -e "
      const fs = require('fs');
      const m = JSON.parse(fs.readFileSync('${MANIFEST}', 'utf8'));
      (m.skills_symlinked || []).forEach(s => console.log(s));
    ")

    local skills_home="${HOME}/.agents/skills"
    local count=0
    while IFS= read -r skill; do
      [[ -z "${skill}" ]] && continue
      local target="${skills_home}/${skill}"
      if [[ -L "${target}" ]]; then
        rm "${target}"
        info "  Removed: ${skill}"
        count=$((count + 1))
      elif [[ -d "${target}" ]]; then
        warn "  ${skill} is not a symlink. Skipping."
      fi
    done <<< "${skills}"

    info "Skills: ${count} symlink(s) removed."
  else
    warn "Node.js not found. Manually remove symlinks from ${HOME}/.agents/skills"
  fi
}

# ─── Remove Agent Symlinks ─────────────────────────────────────────

uninstall_agents() {
  info "Agents: removing symlinks..."

  if [[ ! -f "${MANIFEST}" ]]; then
    warn "No manifest found. Cannot determine which agents to remove."
    warn "Manually check ${AGENTS_DIR} for symlinks pointing to ${TOOLKIT_DIR}/agents/"
    return
  fi

  if command -v node &>/dev/null; then
    local agents
    agents=$(node -e "
      const fs = require('fs');
      const m = JSON.parse(fs.readFileSync('${MANIFEST}', 'utf8'));
      (m.agents_symlinked || []).forEach(a => console.log(a));
    ")

    local count=0
    while IFS= read -r agent; do
      [[ -z "${agent}" ]] && continue
      local target="${AGENTS_DIR}/${agent}"
      if [[ -L "${target}" ]]; then
        rm "${target}"
        info "  Removed: ${agent}"
        count=$((count + 1))
      elif [[ -f "${target}" ]]; then
        warn "  ${agent} is not a symlink. Skipping."
      fi
    done <<< "${agents}"

    info "Agents: ${count} symlink(s) removed."
  else
    warn "Node.js not found. Manually remove symlinks from ${AGENTS_DIR}"
  fi
}

# ─── Main ──────────────────────────────────────────────────────────

main() {
  echo ""
  echo "  knotlog-agent-toolkit uninstaller"
  echo "  ================================="
  echo ""

  if [[ ! -f "${MANIFEST}" ]]; then
    warn "No install manifest found at ${MANIFEST}"
    warn "This toolkit may not be installed, or was installed before"
    warn "the manifest system was added."
    echo ""
    read -rp "  Continue with removal anyway? [y/N] " answer
    if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
      info "Aborted."
      exit 0
    fi
  fi

  uninstall_skills
  echo ""
  uninstall_agents
  echo ""

  # Clean up manifest
  if [[ -f "${MANIFEST}" ]]; then
    rm "${MANIFEST}"
    info "Manifest removed."
  fi

  echo ""
  info "Uninstall complete."
  info "Restart opencode to apply changes."
  echo ""
}

main "$@"
