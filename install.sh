#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Esp32Agent installer — install agent orchestra + ESP32 skill into any ESP-IDF project.

Usage:
  ./install.sh <esp32-project-dir>

Options:
  --force           Replace existing .opencode/.agents after timestamped backup.
  --model MODEL     Set model directly (skips interactive pick).
  --no-model-patch  Keep shipped model lines.
  --symlink         Symlink instead of copy.
  --dry-run         Print actions without changing anything.
  -h,--help         Show this help.

Examples:
  ./install.sh ./my-project
  ./install.sh /path/to/esp32-project --force
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
  [[ -z "$avail" ]] && return 1

  readarray -t all <<<"$avail"
  local models=()
  for m in "${all[@]}"; do
    [[ "$m" == *free* || "$m" == *Free* ]] && models+=("$m")
  done
  [[ ${#models[@]} -eq 0 ]] && { echo "No free models found." >&2; return 1; }
  [[ ${#models[@]} -eq 1 ]] && { echo "${models[0]}"; return 0; }

  echo "Select a free OpenCode model:" >&2
  for i in "${!models[@]}"; do
    printf "  %2d) %s\n" $((i+1)) "${models[$i]}" >&2
  done

  local choice
  while :; do
    read -p "Model [1-${#models[@]}]: " choice >&2
    [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#models[@]} )) && break
    echo "Invalid." >&2
  done
  echo "${models[$((choice-1))]}"
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

install_readme() {
  local dir="$TARGET"
  local readme="$dir/README.md"
  [[ -f "$readme" ]] && [[ "$FORCE" -ne 1 ]] && { echo "Skipping README.md — already exists (use --force to overwrite)"; return 0; }
  echo "Creating $readme"
  cat > "$readme" <<'READEOF'
# ESP32 Project — OpenCode Agents Installed

This project has **OpenCode AI agents** installed by [Esp32Agent](https://github.com/anomalyco/Esp32Agent).

## What was installed?

- `.opencode/` — AI agents (architect, implements, verify, reviewer, debugger, documenter)
- `.agents/` — ESP32 skill pack
- `.espagent/` — helper scripts

All agent files are **hidden** (dotfiles). Run `ls -la` to see them.

## How to start

```bash
# Open OpenCode in this project
opencode

# Or use the helper script
.espagent/run-opencode.sh
```

Then inside OpenCode, ask the agent:

```
Use orchestra-leader. I want to build a FreeRTOS project with 3 tasks. Build it but do not flash.
```

## Quick commands

| Command | What it does |
|---|---|
| `.espagent/check.sh` | Check installation |
| `.espagent/build.sh build` | Build with idf.py |
| `.espagent/build.sh flash` | Flash to board |
| `opencode` | Start OpenCode |

## Need help?

See the [Esp32Agent README](.opencode/README.md) for full documentation.
READEOF
}

install_readme

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
