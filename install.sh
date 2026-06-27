#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Esp32Agent installer — install agent orchestra + ESP32 skill into any ESP-IDF project.

Usage:
  ./install.sh <esp32-project-dir> [options]

One-command:
  ./install.sh /path/to/esp32-project --force

Options:
  --copy            Copy .opencode and .agents into the target. Default.
  --symlink         Symlink instead (shared updates, but OpenCode may reject external reads).
  --force           Replace existing .opencode/.agents after timestamped backup.
  --dry-run         Print actions without changing anything.
  --model MODEL     Set OpenCode model in all agent files. Default: auto-detect.
  --no-model-patch  Keep shipped model lines.
  --check           Run post-install checks (default).
  --no-check        Skip post-install checks.
  -h,--help         Show this help.

Examples:
  ./install.sh /path/to/esp32-project --force
  ./install.sh /path/to/esp32-project --symlink --no-model-patch
USAGE
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
MODE="copy"
FORCE=0
DRY_RUN=0
TARGET=""
MODEL="auto"
PATCH_MODEL=1
RUN_CHECK=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy) MODE="copy" ;;
    --symlink) MODE="symlink" ;;
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --model) shift; MODEL="$1"; PATCH_MODEL=1 ;;
    --no-model-patch) PATCH_MODEL=0 ;;
    --check) RUN_CHECK=1 ;;
    --no-check) RUN_CHECK=0 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      [[ -n "$TARGET" ]] && { echo "Unexpected: $1" >&2; usage >&2; exit 2; }
      TARGET="$1"
      ;;
  esac
  shift
done

[[ -z "$TARGET" ]] && { echo "Missing target project directory." >&2; usage >&2; exit 2; }
[[ -d "$TARGET" ]] || { echo "Not a directory: $TARGET" >&2; exit 1; }
TARGET="$(cd -- "$TARGET" && pwd -P)"
[[ "$TARGET" == "$SCRIPT_DIR" ]] && { echo "Target is Esp32Agent itself; point to an ESP32 project." >&2; exit 1; }
[[ ! -d "$SCRIPT_DIR/.opencode/agent" ]] && { echo "Missing $SCRIPT_DIR/.opencode/agent" >&2; exit 1; }
[[ ! -d "$SCRIPT_DIR/.agents/skills/esp32-hobby" ]] && { echo "Missing $SCRIPT_DIR/.agents/skills" >&2; exit 1; }

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then printf 'DRY-RUN: '; printf '%q ' "$@"; printf '\n'
  else "$@"; fi
}

backup_or_remove() {
  local dest="$1"
  if [[ -e "$dest" || -L "$dest" ]]; then
    [[ "$FORCE" -ne 1 ]] && { echo "Refusing to overwrite $dest — use --force" >&2; exit 1; }
    local backup="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
    echo "Backing up $dest -> $backup"
    run mv "$dest" "$backup"
  fi
}

install_one() {
  local name="$1"
  local src="$SCRIPT_DIR/$name"
  local dest="$TARGET/$name"
  backup_or_remove "$dest"
  if [[ "$MODE" == "symlink" ]]; then
    echo "Linking $dest -> $src"
    run ln -s "$src" "$dest"
  else
    echo "Copying $src -> $dest"
    run cp -R "$src" "$dest"
    run rm -rf "$dest/node_modules" "$dest/package.json" "$dest/package-lock.json" 2>/dev/null || true
  fi
}

resolve_opencode() {
  if command -v opencode >/dev/null 2>&1; then echo 'opencode'
  elif command -v npm >/dev/null 2>&1; then echo 'npm exec --yes opencode-ai --'
  else return 1; fi
}

choose_model() {
  local oc="$1"
  local avail
  avail="$(cd "$TARGET" && bash -lc "$oc models 2>/dev/null" || true)"
  for m in \
    deepseek-v4-flash-free\
    opencode/big-pickle \
    opencode/north-mini-code-free \
    opencode/mimo-v2.5-free \
    opencode/nemotron-3-ultra-free
  do grep -Fxq "$m" <<<"$avail" && { echo "$m"; return 0; }; done
  return 1
}

patch_agent_models() {
  local model="$1" dir="$TARGET/.opencode/agent"
  [[ -d "$dir" ]] || return 0
  echo "Setting OpenCode model: $model"
  [[ "$DRY_RUN" -eq 1 ]] && return 0
  python3 - "$dir" "$model" <<'PY'
import re, sys
from pathlib import Path
d = Path(sys.argv[1])
m = sys.argv[2]
for p in sorted(d.glob('*.md')):
    t = p.read_text()
    t, n = re.subn(r'^model:\s*.+$', f'model: {m}', t, count=1, flags=re.M)
    if n == 0: t = t.replace('---\n', f'---\nmodel: {m}\n', 1)
    p.write_text(t)
PY
}

install_helpers() {
  local dir="$TARGET/.espagent"
  echo "Installing helpers -> $dir"
  [[ "$DRY_RUN" -eq 1 ]] && return 0
  mkdir -p "$dir"

  cat > "$dir/check.sh" <<'SHEOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "== Esp32Agent check =="
echo "project: $(pwd)"
echo
if oc="$(command -v opencode || echo npm)"; then
  echo "OpenCode: $oc"
  $oc models 2>/dev/null | sed -n '1,10p' || true
else
  echo "MISSING: opencode"
fi
echo
idf.py --version 2>/dev/null || echo "MISSING: idf.py not in PATH"
echo
python3 -m serial.tools.list_ports 2>/dev/null || echo "serial tools unavailable"
SHEOF
  chmod +x "$dir/check.sh"

  cat > "$dir/build.sh" <<'SHEOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source "${IDF_PATH:-$HOME/esp/esp-idf}/export.sh" >/dev/null 2>&1 || {
  echo "Source ESP-IDF first or set IDF_PATH" >&2; exit 1
}
exec idf.py "$@"
SHEOF
  chmod +x "$dir/build.sh"

  cat > "$dir/run-opencode.sh" <<'SHEOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if command -v opencode >/dev/null 2>&1; then exec opencode "$@"
elif command -v npm >/dev/null 2>&1; then exec npm exec --yes opencode-ai -- "$@"
else echo "OpenCode not found" >&2; exit 127; fi
SHEOF
  chmod +x "$dir/run-opencode.sh"
}

install_one ".opencode"
install_one ".agents"

if [[ "$PATCH_MODEL" -eq 1 ]]; then
  if [[ "$MODEL" == "auto" ]]; then
    if oc="$(resolve_opencode)" && m="$(choose_model "$oc")"; then
      patch_agent_models "$m"
    else
      echo "Warning: could not auto-detect model; leaving unchanged." >&2
    fi
  else
    patch_agent_models "$MODEL"
  fi
fi

install_helpers

cat <<EOF

Esp32Agent installed.

Target: $TARGET
Mode:   $MODE

Next:
  cd "$TARGET"
  .espagent/check.sh
  .espagent/run-opencode.sh
EOF

if [[ "$RUN_CHECK" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
  echo; echo "Post-install check:"; "$TARGET/.espagent/check.sh" || true
fi
