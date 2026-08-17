#!/usr/bin/env bash
set -euo pipefail

# knotlog-agent-toolkit uninstaller
# Removes symlinks and config entries added by install.sh.

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"
OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR}/opencode.jsonc"
AGENTS_DIR="${OPENCODE_CONFIG_DIR}/agents"
MANIFEST="${TOOLKIT_DIR}/.install-manifest.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[info]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*"; }

# ─── Remove Skills Path ────────────────────────────────────────────

uninstall_skills_path() {
  info "Skills: removing toolkit path from opencode config..."

  if [[ ! -f "${OPENCODE_CONFIG}" ]]; then
    info "No opencode config found. Nothing to remove."
    return
  fi

  if command -v node &>/dev/null; then
    node -e "
      const fs = require('fs');
      const content = fs.readFileSync('${OPENCODE_CONFIG}', 'utf8');
      const stripped = content.replace(/\/\/.*$/gm, '').replace(/\/\*[\s\S]*?\*\//g, '');

      let config;
      try {
        config = JSON.parse(stripped);
      } catch (e) {
        console.log('  Config parse failed. Nothing to remove.');
        process.exit(0);
      }

      if (!config.skills || !config.skills.paths) {
        console.log('  No skills.paths found. Nothing to remove.');
        process.exit(0);
      }

      const before = config.skills.paths.length;
      config.skills.paths = config.skills.paths.filter(p => p !== '${TOOLKIT_DIR}/skills');
      const after = config.skills.paths.length;

      if (before === after) {
        console.log('  Toolkit path not found in config. Nothing to remove.');
      } else {
        fs.writeFileSync('${OPENCODE_CONFIG}', JSON.stringify(config, null, 2) + '\n');
        console.log('  Removed ' + (before - after) + ' path(s).');
      }
    "
  else
    warn "Node.js not found. Please manually remove '${TOOLKIT_DIR}/skills' from your opencode.jsonc skills.paths array."
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

  uninstall_skills_path
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
