# Esp32Agent — IA agentes para programação ESP32 com OpenCode

> 🧠 **Seu assistente de IA para programar ESP32 com FreeRTOS.**  
> Código, debug e documentação guiados por agentes — direto no terminal.

---

## ⚠️ Esta pasta não está vazia!

Se você deu `ls` e viu só `install.sh`, `LICENSE` e `README.md`, é porque os arquivos importantes são **ocultos** (começam com `.`).  
Use `ls -la` para ver tudo:

```
.agents/          ← Skills ESP32 (conhecimento técnico)
.opencode/        ← Agentes OpenCode (cérebro do projeto)
.gitignore
install.sh
LICENSE
README.md
```

---

## O que é isso?

**Esp32Agent** é um conjunto de **agentes de IA** para o [OpenCode](https://opencode.ai) que ajudam você a criar, revisar, depurar e documentar projetos ESP32 com FreeRTOS. Os agentes conversam entre si para garantir qualidade em cada etapa.

---

## Como usar

### 1. Instale o OpenCode

```bash
npm install -g opencode-ai
```

> Ou siga o guia oficial: https://opencode.ai/docs/installation

### 2. Instale o Esp32Agent no seu projeto

```bash
cd Esp32Agent
./install.sh /caminho/do/seu/projeto-esp32
```

Isso copia os agentes (`.opencode/`) e skills (`.agents/`) para dentro do seu projeto.

### 3. Entre no seu projeto e comece

```bash
cd /caminho/do/seu/projeto-esp32
opencode
```

Dentro do OpenCode, use o agente **orchestra-leader**:

```
Use orchestra-leader. Build the agent-orchestrator project: generate all files, then build with idf.py build. Do not flash hardware.
```

---

## O que cada agente faz?

| Se você pedir... | O agente que executa |
|---|---|
| "Cria um novo projeto" | **Architect** — planeja a estrutura |
| "Implementa o código" | **Implements** — escreve C, headers, CMake |
| "Verifica se está certo" | **Verify** — revisão de olhos frescos |
| "Revisa a qualidade" | **Reviewer** — checa arquitetura e estilo |
| "Compila e testa" | **Debugger** — build + flash + debug |
| "Gera documentação" | **Documenter** — README, API docs |

Tudo começa pelo **orchestra-leader**, que coordena os demais em sequência.

---

## Estrutura de arquivos

Depois da instalação, seu projeto ESP32 vai ter pastas ocultas com os agentes:

```
.projeto-esp32/
├── .opencode/         ← Agentes OpenCode (cérebro)
│   └── agent/         ← Configuração de cada agente
├── .agents/           ← Skills (conhecimento ESP32)
│   └── skills/esp32-hobby/
├── .espagent/         ← Scripts auxiliares
│   ├── check.sh       → Verifica se tudo está pronto
│   ├── build.sh       → Compila com idf.py
│   └── run-opencode.sh → Inicia o OpenCode
├── main/              ← Seu código fonte
├── CMakeLists.txt
└── sdkconfig
```

---

## Comandos úteis

```bash
# Verificar instalação
.espagent/check.sh

# Abrir OpenCode
.espagent/run-opencode.sh

# Compilar manualmente
.espagent/build.sh build

# Flash na placa
.espagent/build.sh flash
```

---

## Primeiros passos com OpenCode

1. Digite `opencode` no terminal dentro do seu projeto
2. Escreva em linguagem natural o que você quer fazer
3. Os agentes trabalham em sequência e mostram o progresso
4. Você revisa e aprova cada etapa

**Exemplo de prompt inicial:**

```
Use orchestra-leader. I want to create a FreeRTOS project with 3 tasks: 
one reading a temperature sensor, one blinking an LED, and one sending 
data via UART. Build it but do not flash.
```

---

## Licença

MIT — veja [LICENSE](LICENSE).
