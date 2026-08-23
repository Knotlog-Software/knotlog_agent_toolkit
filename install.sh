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
    node -e "
      const fs = require('fs');
      const m = JSON.parse(fs.readFileSync('${MANIFEST}', 'utf8'));
      m.installed_at = '${now}';
      m.toolkit_dir = '${TOOLKIT_DIR}';
      fs.writeFileSync('${MANIFEST}', JSON.stringify(m, null, 2));
    "
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

  read -rp "  Merge MCP server configs from mcp/servers.jsonc? [y/N] " answer
  if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
    info "MCP: skipped."
    return
  fi

  # For MCP merge, we append entries to the existing config
  if command -v node &>/dev/null; then
    node -e "
      const fs = require('fs');

      // Read and strip comments from both files
      const stripJsonc = (s) => s.replace(/\/\/.*$/gm, '').replace(/\/\*[\s\S]*?\*\//g, '');

      let config;
      try {
        config = JSON.parse(stripJsonc(fs.readFileSync('${OPENCODE_CONFIG}', 'utf8')));
      } catch (e) {
        config = {};
      }

      let mcpConfig;
      try {
        mcpConfig = JSON.parse(stripJsonc(fs.readFileSync('${mcp_file}', 'utf8')));
      } catch (e) {
        console.error('Failed to parse mcp/servers.jsonc');
        process.exit(1);
      }

      if (!config.mcp) config.mcp = {};

      let merged = 0;
      for (const [name, server] of Object.entries(mcpConfig.mcp || {})) {
        if (!config.mcp[name]) {
          config.mcp[name] = server;
          merged++;
          console.log('  Added: ' + name);
        } else {
          console.log('  Skipped (exists): ' + name);
        }
      }

      fs.writeFileSync('${OPENCODE_CONFIG}', JSON.stringify(config, null, 2) + '\n');
      console.log('MCP: ' + merged + ' server(s) merged.');
    "
  else
    warn "Node.js not found. Please manually merge MCP configs from mcp/servers.jsonc"
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
