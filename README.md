# Esp32Agent — AI agents for ESP32 programming with OpenCode

> 🧠 **Your AI assistant for ESP32 FreeRTOS programming.**  
> Code, debug, and documentation guided by agents — right from the terminal.

---

## ⚠️ This folder is not empty!

If you ran `ls` and only saw `install.sh`, `LICENSE` and `README.md`, that's because the important files are **hidden** (start with `.`).  
Run `ls -la` to see everything:

```
.agents/          ← ESP32 skills (technical knowledge)
.opencode/        ← OpenCode agents (project brain)
.gitignore
install.sh
LICENSE
README.md
```

---

## What is this?

**Esp32Agent** is a set of **AI agents** for [OpenCode](https://opencode.ai) that help you create, review, debug, and document ESP32 FreeRTOS projects. Agents talk to each other to ensure quality at every step.

---

## How to use

### 1. Install OpenCode

```bash
npm install -g opencode-ai
```

> Or follow the official guide: https://opencode.ai/docs/installation

### 2. Install Esp32Agent into your project

```bash
cd Esp32Agent
./install.sh /path/to/your/esp32-project
```

This copies the agents (`.opencode/`) and skills (`.agents/`) into your project.

### 3. Enter your project and start

```bash
cd /path/to/your/esp32-project
opencode
```

Inside OpenCode, use the **orchestra-leader** agent:

```
Use orchestra-leader. Build the agent-orchestrator project: generate all files, then build with idf.py build. Do not flash hardware.
```

---

## Agent pipeline

The `orchestra-leader` agent drives a strict sequential pipeline with quality gates:

```
stat->[architect]->[implements]->is ok->[verify]-->is ok->[reviewer]->is ok-> [debugger]->is ok->[documenter]->end
                        ^__________|________ ________|___________________|__________________|
```

1. **Architect** — receives user request, produces system plan + `todo.md`
2. **Implements** — writes C code, headers, CMake for each task
3. **Verify** — fresh-eyes review, scenario testing; 🔴 critical bugs send it back to implements
4. **Reviewer** — checks architecture, code quality, feature completeness
5. **Debugger** — builds, flashes, runs on hardware; runtime failures loop back
6. **Documenter** — updates README, API docs, changelog

Each gate must pass before the next opens. Any failure loops back to **implements** and re-enters from **verify** (to catch regressions).

## What each agent does

| If you ask... | The agent that runs |
|---|---|
| "Create a new project" | **Architect** — plans the structure |
| "Implement the code" | **Implements** — writes C, headers, CMake |
| "Check if it's correct" | **Verify** — fresh-eyes review |
| "Review the quality" | **Reviewer** — checks architecture and style |
| "Build and test" | **Debugger** — build + flash + debug |
| "Generate documentation" | **Documenter** — README, API docs |

Everything starts with **orchestra-leader**, which coordinates the others in sequence.

---

## File structure

After installation, your ESP32 project will have hidden folders with the agents:

```
your-esp32-project/
├── .opencode/         ← OpenCode agents (brain)
│   └── agent/         ← Agent configurations
├── .agents/           ← Skills (ESP32 knowledge)
│   └── skills/esp32-hobby/
├── .espagent/         ← Helper scripts
│   ├── check.sh       → Check if everything is ready
│   ├── build.sh       → Build with idf.py
│   └── run-opencode.sh → Start OpenCode
├── main/              ← Your source code
├── CMakeLists.txt
└── sdkconfig
```

---

## Useful commands

```bash
# Check installation
.espagent/check.sh

# Open OpenCode
.espagent/run-opencode.sh

# Build manually
.espagent/build.sh build

# Flash to board
.espagent/build.sh flash
```

---

## First steps with OpenCode

1. Type `opencode` in your project's terminal
2. Write in natural language what you want to do
3. The agents work in sequence and show progress
4. You review and approve each step

**Example initial prompt:**

```
Use orchestra-leader. I want to create a FreeRTOS project with 3 tasks: 
one reading a temperature sensor, one blinking an LED, and one sending 
data via UART. Build it but do not flash.
```

---

## License

MIT — see [LICENSE](LICENSE).
