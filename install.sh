#!/usr/bin/env bash
set -euo pipefail

# knotlog-agent-toolkit installer
# Adds shared skills, agents, and MCP configs to your opencode setup.

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

# Initialize manifest
init_manifest() {
  # Preserve previously merged MCP entries: they stay in the user's config
  # even though the skills/agents lists are rebuilt on every install.
  local previous_mcp="[]"
  if [[ -f "${MANIFEST}" ]] && command -v node &>/dev/null; then
    previous_mcp="$(node -e "
      try {
        const fs = require('fs');
        const m = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
        process.stdout.write(JSON.stringify(m.mcp_entries_merged || []));
      } catch (e) {
        process.stdout.write('[]');
      }
    " "${MANIFEST}")"
  fi

  cat > "${MANIFEST}" << 'EOF'
{
  "version": 2,
  "installed_at": "",
  "toolkit_dir": "",
  "skills_symlinked": [],
  "agents_symlinked": [],
  "mcp_entries_merged": []
}
EOF
  # Set timestamps and toolkit dir
  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  if command -v node &>/dev/null; then
    PREVIOUS_MCP="${previous_mcp}" node -e "
      const fs = require('fs');
      const m = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
      m.installed_at = process.argv[2];
      m.toolkit_dir = process.argv[3];
      m.mcp_entries_merged = JSON.parse(process.env.PREVIOUS_MCP || '[]');
      fs.writeFileSync(process.argv[1], JSON.stringify(m, null, 2));
    " "${MANIFEST}" "${now}" "${TOOLKIT_DIR}"
  fi
}

update_manifest() {
  local key="$1" value="$2"
  if command -v node &>/dev/null; then
    node -e "
      const fs = require('fs');
      const m = JSON.parse(fs.readFileSync('${MANIFEST}', 'utf8'));
      const keys = '${key}'.split('.');
      let obj = m;
      for (let i = 0; i < keys.length - 1; i++) obj = obj[keys[i]];
      obj[keys[keys.length - 1]] = ${value};
      fs.writeFileSync('${MANIFEST}', JSON.stringify(m, null, 2));
    "
  fi
}

add_to_manifest_list() {
  local key="$1" value="$2"
  if command -v node &>/dev/null; then
    node -e "
      const fs = require('fs');
      const m = JSON.parse(fs.readFileSync('${MANIFEST}', 'utf8'));
      const keys = '${key}'.split('.');
      let obj = m;
      for (let i = 0; i < keys.length - 1; i++) obj = obj[keys[i]];
      const arr = obj[keys[keys.length - 1]] || [];
      if (!arr.includes('${value}')) arr.push('${value}');
      obj[keys[keys.length - 1]] = arr;
      fs.writeFileSync('${MANIFEST}', JSON.stringify(m, null, 2));
    "
  fi
}

# ─── Skill Directories ─────────────────────────────────────────────
# opencode discovers skills only from fixed locations (e.g.
# ~/.agents/skills/<name>/SKILL.md) — there is no configurable path list.

install_skills() {
  info "Skills: symlinking skill directories..."

  local skills_home="${HOME}/.agents/skills"
  mkdir -p "${skills_home}"

  local skills_dir="${TOOLKIT_DIR}/skills"
  local count=0

  for skill_dir in "${skills_dir}"/*/; do
    [[ -f "${skill_dir}/SKILL.md" ]] || continue
    local name
    name="$(basename "${skill_dir}")"
    local target="${skills_home}/${name}"

    if [[ -L "${target}" ]]; then
      # Already a symlink — update it
      ln -sfn "${skill_dir%/}" "${target}"
      info "  Updated symlink: ${name}"
    elif [[ -d "${target}" ]]; then
      # Real directory exists — never clobber user data
      warn "  ${name} already exists (not a symlink). Skipping."
      warn "  To use the toolkit version, move it aside and re-run install."
      continue
    else
      ln -s "${skill_dir%/}" "${target}"
      info "  Linked: ${name}"
    fi

    add_to_manifest_list "skills_symlinked" "${name}"
    count=$((count + 1))
  done

  info "Skills: ${count} skill(s) linked."
}

# ─── Agent Definitions ─────────────────────────────────────────────

install_agents() {
  info "Agents: symlinking agent definitions..."

  mkdir -p "${AGENTS_DIR}"

  local agents_dir="${TOOLKIT_DIR}/agents"
  local count=0

  for agent_file in "${agents_dir}"/*.md; do
    [[ -f "${agent_file}" ]] || continue
    local name
    name="$(basename "${agent_file}")"
    local target="${AGENTS_DIR}/${name}"

    if [[ -L "${target}" ]]; then
      # Already a symlink — update it
      ln -sfn "${agent_file}" "${target}"
      info "  Updated symlink: ${name}"
    elif [[ -f "${target}" ]]; then
      # File exists and is not a symlink
      warn "  ${name} already exists (not a symlink). Skipping."
      warn "  To override, remove it manually and re-run install."
      continue
    else
      ln -s "${agent_file}" "${target}"
      info "  Linked: ${name}"
    fi

    add_to_manifest_list "agents_symlinked" "${name}"
    count=$((count + 1))
  done

  info "Agents: ${count} definition(s) linked."
}

# ─── MCP Config Merge ──────────────────────────────────────────────

install_mcp() {
  local mcp_file="${TOOLKIT_DIR}/mcp/servers.jsonc"
  [[ -f "${mcp_file}" ]] || return 0

  info "MCP: checking for shared server configurations..."

  if [[ ! -f "${OPENCODE_CONFIG}" ]]; then
    warn "No opencode config found. Skipping MCP merge."
    return
  fi

  if ! command -v node &>/dev/null; then
    warn "Node.js not found. Please manually merge MCP configs from mcp/servers.jsonc"
    return
  fi

  read -rp "  Merge MCP server configs from mcp/servers.jsonc? [y/N] " answer
  if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
    info "MCP: skipped."
    return
  fi

  if ! node - "${OPENCODE_CONFIG}" "${mcp_file}" "${MANIFEST}" <<'NODE'
const fs = require('fs');

const [configPath, mcpPath, manifestPath] = process.argv.slice(2);

// String-aware JSONC comment stripper. A naive /\/\/.*$/ would also eat
// "//" inside string values (e.g. https://api.githubcopilot.com/mcp/).
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

// JSONC permits trailing commas; JSON.parse does not.
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

function readJsonc(path) {
  return JSON.parse(stripTrailingCommas(stripJsonc(fs.readFileSync(path, 'utf8'))));
}

let config;
try {
  config = readJsonc(configPath);
} catch (e) {
  console.error('  Failed to parse ' + configPath + ': ' + e.message);
  console.error('  Aborting without modifying the file.');
  process.exit(1);
}

let mcpConfig;
try {
  mcpConfig = readJsonc(mcpPath);
} catch (e) {
  console.error('  Failed to parse ' + mcpPath + ': ' + e.message);
  process.exit(1);
}

fs.copyFileSync(configPath, configPath + '.bak');

if (!config.mcp) config.mcp = {};

// Repair configs written with the legacy { "mcp": { "servers": { ... } } }
// shape, which opencode does not read.
if (config.mcp.servers && typeof config.mcp.servers === 'object') {
  for (const [name, server] of Object.entries(config.mcp.servers)) {
    if (!config.mcp[name]) config.mcp[name] = server;
  }
  delete config.mcp.servers;
  console.log('  Flattened legacy mcp.servers wrapper.');
}

const merged = [];
for (const [name, server] of Object.entries(mcpConfig.mcp || {})) {
  if (!config.mcp[name]) {
    config.mcp[name] = server;
    merged.push(name);
    console.log('  Added: ' + name);
  } else {
    console.log('  Skipped (exists): ' + name);
  }
}

if (merged.length && manifestPath && fs.existsSync(manifestPath)) {
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  manifest.mcp_entries_merged = manifest.mcp_entries_merged || [];
  for (const name of merged) {
    if (!manifest.mcp_entries_merged.includes(name)) manifest.mcp_entries_merged.push(name);
  }
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n');
}

fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
console.log('MCP: ' + merged.length + ' server(s) merged.');
NODE
  then
    error "MCP merge failed. ${OPENCODE_CONFIG} was not modified."
    return 0
  fi
}

# ─── Main ──────────────────────────────────────────────────────────

main() {
  echo ""
  echo "  knotlog-agent-toolkit installer"
  echo "  ==============================="
  echo ""
  echo "  Toolkit directory: ${TOOLKIT_DIR}"
  echo "  opencode config:   ${OPENCODE_CONFIG}"
  echo ""

  init_manifest

  install_skills
  echo ""
  install_agents
  echo ""
  install_mcp
  echo ""

  info "Installation complete."
  info "Manifest written to ${MANIFEST}"
  echo ""
  info "Restart opencode to pick up the new skills and agents."
  echo ""
}

main "$@"
