#!/usr/bin/env bash
set -euo pipefail

# knotlog-agent-toolkit uninstaller
# Removes symlinks and config entries added by install.sh.

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_CONFIG="${HOME}/.config/opencode/opencode.jsonc"
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

# ─── Remove MCP Config Entries ─────────────────────────────────────

uninstall_mcp() {
  info "MCP: removing merged server configs..."

  if [[ ! -f "${MANIFEST}" ]]; then
    warn "No manifest found. Cannot determine which MCP entries to remove."
    return
  fi

  if [[ ! -f "${OPENCODE_CONFIG}" ]]; then
    warn "No opencode config found at ${OPENCODE_CONFIG}. Skipping."
    return
  fi

  if ! command -v node &>/dev/null; then
    warn "Node.js not found. Manually remove merged entries from ${OPENCODE_CONFIG}"
    return
  fi

  if ! node - "${OPENCODE_CONFIG}" "${MANIFEST}" <<'NODE'
const fs = require('fs');

const [configPath, manifestPath] = process.argv.slice(2);

function stripJsonc(src) {
  let out = '';
  let inString = false;
  let escaped = false;
  let lineComment = false;
  let blockComment = false;

  for (let i = 0; i < src.length; i++) {
    const ch = src[i];
    const next = src[i + 1];

    if (lineComment) {
      if (ch === '\n') { lineComment = false; out += ch; }
      continue;
    }

    if (blockComment) {
      if (ch === '*' && next === '/') { blockComment = false; i++; }
      else if (ch === '\n') out += ch;
      continue;
    }

    if (inString) {
      out += ch;
      if (escaped) escaped = false;
      else if (ch === '\\') escaped = true;
      else if (ch === '"') inString = false;
      continue;
    }

    if (ch === '"') { inString = true; out += ch; }
    else if (ch === '/' && next === '/') { lineComment = true; i++; }
    else if (ch === '/' && next === '*') { blockComment = true; i++; }
    else out += ch;
  }

  return out;
}

function stripTrailingCommas(src) {
  let out = '';
  let inString = false;
  let escaped = false;

  for (let i = 0; i < src.length; i++) {
    const ch = src[i];

    if (inString) {
      out += ch;
      if (escaped) escaped = false;
      else if (ch === '\\') escaped = true;
      else if (ch === '"') inString = false;
      continue;
    }

    if (ch === '"') { inString = true; out += ch; continue; }

    if (ch === ',') {
      let j = i + 1;
      while (j < src.length && /\s/.test(src[j])) j++;
      if (src[j] === '}' || src[j] === ']') continue;
    }

    out += ch;
  }

  return out;
}

const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const names = manifest.mcp_entries_merged || [];
if (!names.length) {
  console.log('  None to remove.');
  process.exit(0);
}

let config;
try {
  const raw = fs.readFileSync(configPath, 'utf8');
  config = JSON.parse(stripTrailingCommas(stripJsonc(raw)));
} catch (e) {
  console.error('  Failed to parse ' + configPath + ': ' + e.message);
  console.error('  Leaving the file untouched.');
  process.exit(1);
}

fs.copyFileSync(configPath, configPath + '.bak');

let removed = 0;
for (const name of names) {
  if (config.mcp && Object.prototype.hasOwnProperty.call(config.mcp, name)) {
    delete config.mcp[name];
    console.log('  Removed: ' + name);
    removed++;
  }
}

fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
console.log('MCP: ' + removed + ' server(s) removed.');
NODE
  then
    warn "MCP: removal failed. ${OPENCODE_CONFIG} was not modified."
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
  uninstall_mcp
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
