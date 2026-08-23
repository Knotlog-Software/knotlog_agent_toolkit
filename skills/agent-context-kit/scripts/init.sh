#!/usr/bin/env bash
#
# Instantiate the agent-context kit into a target directory.
# Fills known {{PLACEHOLDER}} tokens, strips .template suffixes, then reports
# anything that still needs manual editing.
#
# macOS/BSD sed assumed (darwin). Run from anywhere:
#   ./init.sh [-y] [--merge] [-n Name] [-a AppTitle] [-s slug] [-t test] [-l lint] \
#             [-g codegen] [-c importcheck] [-i iteration_num] [-T iteration_title] \
#             [-p plan_file] TARGET_DIR
set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../assets" && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] TARGET_DIR

Instantiate the agent context kit into TARGET_DIR. Any value not supplied via
a flag is left as a {{PLACEHOLDER}} token for later manual editing.

  -y                      Non-interactive: never prompt, leave blanks as placeholders
  --merge                 Allow non-empty target; copy only missing files (never overwrite)
  -n PROJECT_NAME         display name            (e.g. VoyageWatch)
  -a APP_TITLE            app title               (default: project name)
  -s PROJECT_SLUG         package/repo slug       (default: snake_case of name)
  -t TEST_COMMAND         canonical test command
  -l LINT_COMMAND         canonical lint command
  -g CODEGEN_COMMAND      codegen command, if any
  -c IMPORT_CHECK_CMD     layer/import verifier, if any
  -i ITERATION_NUMBER     current iteration number
  -T ITERATION_TITLE      current iteration title
  -p ITERATION_PLAN_FILE  iteration plan filename in agents/plans/
  -h                      this help
EOF
}

ask() {
  # ask CURRENT_VALUE PROMPT [DEFAULT] -> prints chosen value
  # Returns empty string if non-interactive and no current/default
  local current="$1" prompt="$2" default="${3:-}" answer
  if [[ -n "$current" ]]; then printf '%s\n' "$current"; return; fi
  if [[ "$NON_INTERACTIVE" == "1" ]]; then
    printf '%s\n' "$default"
    return
  fi
  if [[ -n "$default" ]]; then
    read -r -p "$prompt [$default]: " answer
    printf '%s\n' "${answer:-$default}"
  else
    read -r -p "$prompt: " answer
    printf '%s\n' "$answer"
  fi
}

NON_INTERACTIVE=0
MERGE_MODE=0
NAME="" APP_TITLE="" SLUG=""
TEST_CMD="" LINT_CMD="" CODEGEN_CMD="" IMPORT_CMD=""
ITERATION_NUMBER="" ITERATION_TITLE="" ITERATION_PLAN_FILE=""

while (( $# )); do
  case "$1" in
    -y) NON_INTERACTIVE=1 ;;
    --merge) MERGE_MODE=1 ;;
    -n) NAME="$2"; shift ;;
    -a) APP_TITLE="$2"; shift ;;
    -s) SLUG="$2"; shift ;;
    -t) TEST_CMD="$2"; shift ;;
    -l) LINT_CMD="$2"; shift ;;
    -g) CODEGEN_CMD="$2"; shift ;;
    -c) IMPORT_CMD="$2"; shift ;;
    -i) ITERATION_NUMBER="$2"; shift ;;
    -T) ITERATION_TITLE="$2"; shift ;;
    -p) ITERATION_PLAN_FILE="$2"; shift ;;
    -h) usage; exit 0 ;;
    --) shift; break ;;
    -*) usage >&2; exit 1 ;;
    *) break ;;
  esac
  shift
done

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  usage >&2
  exit 1
fi
TARGET="${TARGET%/}"

if [[ -e "$TARGET" && -n "$(ls -A "$TARGET" 2>/dev/null)" ]]; then
  if [[ "$MERGE_MODE" == "1" ]]; then
    echo "Merge mode: target exists and is not empty. Copying missing files only."
  else
    echo "error: '$TARGET' exists and is not empty (use --merge to allow)" >&2
    exit 1
  fi
fi

mkdir -p "$TARGET"

# Copy template files
if [[ "$MERGE_MODE" == "1" ]]; then
  # Copy only missing files
  find "$TEMPLATE_DIR" -type f -name '*.template' | while IFS= read -r f; do
    rel="${f#$TEMPLATE_DIR/}"
    dest="$TARGET/${rel%.template}"
    if [[ ! -e "$dest" ]]; then
      mkdir -p "$(dirname "$dest")"
      cp "$f" "$dest"
      echo "  Created: $dest"
    else
      echo "  Kept existing: $dest"
    fi
  done
else
  # Fresh copy
  cp -R "$TEMPLATE_DIR/." "$TARGET/"
  find "$TARGET" -name '.DS_Store' -delete
  find "$TARGET" -type f -name '*.template' | while IFS= read -r f; do
    mv "$f" "${f%.template}"
  done
fi

# Non-interactive: if any required values still empty, leave as placeholders
if [[ "$NON_INTERACTIVE" == "1" ]]; then
  # Set defaults for derived values if still empty
  [[ -z "$SLUG" && -n "$NAME" ]] && SLUG="$(printf '%s' "$NAME" | tr '[:upper:] ' '[:lower:]_')"
  [[ -z "$APP_TITLE" && -n "$NAME" ]] && APP_TITLE="$NAME"
  [[ -z "$ITERATION_NUMBER" ]] && ITERATION_NUMBER="1"
  [[ -z "$ITERATION_PLAN_FILE" ]] && ITERATION_PLAN_FILE="iteration_${ITERATION_NUMBER}_plan.md"
else
  # Interactive prompts (original behavior)
  while [[ -z "$NAME" ]]; do
    NAME="$(ask "" "Project display name")"
  done

  derived_slug="$(printf '%s' "$NAME" | tr '[:upper:] ' '[:lower:]_')"
  APP_TITLE="$(ask "$APP_TITLE" "App title" "$NAME")"
  SLUG="$(ask "$SLUG" "Package/repo slug" "$derived_slug")"
  TEST_CMD="$(ask "$TEST_CMD" "Test command" "TODO-set-test-command")"
  LINT_CMD="$(ask "$LINT_CMD" "Lint command" "TODO-set-lint-command")"
  CODEGEN_CMD="$(ask "$CODEGEN_CMD" "Codegen command (blank to skip)")"
  IMPORT_CMD="$(ask "$IMPORT_CMD" "Import check command (blank to skip)")"
  ITERATION_NUMBER="$(ask "$ITERATION_NUMBER" "Current iteration number" "1")"
  ITERATION_TITLE="$(ask "$ITERATION_TITLE" "Current iteration title" "")"
  PLAN_FILE_DEFAULT="iteration_${ITERATION_NUMBER}_plan.md"
  ITERATION_PLAN_FILE="$(ask "$ITERATION_PLAN_FILE" "Iteration plan filename in agents/plans/" "$PLAN_FILE_DEFAULT")"
fi

TODAY="$(date +%Y-%m-%d)"

esc() {
  printf '%s' "$1" | sed -e 's/[\\/&|]/\\&/g'
}

apply() {
  # apply TOKEN VALUE — replace {{TOKEN}} in all files under TARGET.
  local key="$1" val="$2" repl f files
  [[ -z "$val" ]] && return 0
  repl="$(esc "$val")"
  files="$(grep -rlF -- "{{${key}}}" "$TARGET" 2>/dev/null || true)"
  [[ -z "$files" ]] && return 0
  printf '%s\n' "$files" | while IFS= read -r f; do
    sed -i '' "s|{{${key}}}|${repl}|g" "$f"
  done
}

apply PROJECT_NAME        "$NAME"
apply APP_TITLE           "$APP_TITLE"
apply PROJECT_SLUG        "$SLUG"
apply TEST_COMMAND        "$TEST_CMD"
apply LINT_COMMAND        "$LINT_CMD"
apply CODEGEN_COMMAND     "$CODEGEN_CMD"
apply IMPORT_CHECK_COMMAND "$IMPORT_CMD"
apply ITERATION_NUMBER    "$ITERATION_NUMBER"
apply ITERATION_TITLE     "$ITERATION_TITLE"
apply ITERATION_PLAN_FILE "$ITERATION_PLAN_FILE"
apply DATE                "$TODAY"

echo
echo "Created agent context kit in: $TARGET"
find "$TARGET" -type f | sort | sed 's/^/  /'
echo
echo "Manual follow-ups ({{PLACEHOLDER}} / <!-- TODO --> still present):"
if grep -rnE --include='*.md' -e '\{\{[A-Z_]+\}\}' -e '<!-- TODO' "$TARGET"; then
  :
else
  echo "  none"
fi