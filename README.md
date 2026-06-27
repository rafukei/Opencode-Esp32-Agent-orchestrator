# Esp32Agent — Agent orchestrator ESP32 FreeRTOS project generator

Reusable OpenCode agent orchestra and ESP32 skill pack for building an **agent-orchestrator** FreeRTOS firmware project — where FreeRTOS tasks are managed as agents with lifecycle, messaging, heartbeat monitoring, and CLI control.

## Install into any ESP32 project

```bash
cd Esp32Agent
./install.sh /path/to/your/esp32-project --force
```

This copies `.opencode/` (agents) and `.agents/` (ESP32 skill) into the target project.

## Agents

| Agent | Role |
|---|---|
| `orchestra-leader` | Primary coordinator — plans and delegates, never writes code directly |
| `architect` | Research, system design, and planning |
| `implements` | Writes all C source, headers, CMake, sdkconfig |
| `debugger` | Read-only root-cause analysis |
| `verify` | Build verification, flash (gated), serial boot check |
| `reviewer` | Gate for flash/OTA/GPIO output |
| `documenter` | README and portable docs |

## Skill

`.agents/skills/esp32-hobby/` — reusable skill pack with USB programming and documentation references.

## First prompt

```
Use orchestra-leader. Build the agent-orchestrator project: generate all files, then build with idf.py build. Do not flash hardware.
```

## Safety

Builds and read-only inspection are allowed. Flashing, OTA, erase, and GPIO output require explicit user confirmation and `reviewer` approval.
