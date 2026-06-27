# Esp32Agent — Agent orchestrator ESP32 FreeRTOS project generator

Reusable OpenCode agent orchestra and ESP32 skill pack for building an **agent-orchestrator** FreeRTOS firmware project — where FreeRTOS tasks are managed as agents with lifecycle, messaging, heartbeat monitoring, and CLI control.

## Install into any ESP32 project

```bash
cd Esp32Agent
./install.sh /path/to/your/esp32-project --force
```

This copies `.opencode/` (agents) and `.agents/` (ESP32 skill) into the target project.

## Agent pipeline

The `orchestra-leader` agent drives a strict sequential pipeline with quality gates:

```
start → [architect] → [implements] → [verify] → [reviewer] → [debugger] → [documenter] → end
                              ↑         |            |             |
                              |_________|____________|_____________|
                              (failure loops back to implements)
```

1. **Architect** — receives user request, produces system plan + `todo.md`
2. **Implements** — writes C code, headers, CMake for each task
3. **Verify** — fresh-eyes review, scenario testing; 🔴 critical bugs send back to implements
4. **Reviewer** — checks architecture, code quality, feature completeness; failures send back to implements
5. **Debugger** — builds, flashes, runs on hardware; runtime failures send back to implements
6. **Documenter** — updates README, API docs, changelog

Each gate must pass before the next opens. Any failure loops back to **implements** to fix and re-enter from **verify** (to catch regressions).

## Agents

| Agent | Role |
|---|---|
| `orchestra-leader` | Primary coordinator — plans and delegates, never writes code directly |
| `architect` | Research, system design, and planning |
| `implements` | Writes all C source, headers, CMake, sdkconfig |
| `verify` | Fresh-eyes code review and scenario testing |
| `reviewer` | Design quality, code quality, feature completeness |
| `debugger` | Build, flash, runtime debugging on real hardware |
| `documenter` | README and portable docs |

## Skill

`.agents/skills/esp32-hobby/` — reusable skill pack with USB programming and documentation references.

## First prompt

```
Use orchestra-leader. Build the agent-orchestrator project: generate all files, then build with idf.py build. Do not flash hardware.
```

## Safety

Builds and read-only inspection are allowed. Flashing, OTA, erase, and GPIO output require explicit user confirmation and `reviewer` approval.

## License

MIT License — see [LICENSE](LICENSE).
