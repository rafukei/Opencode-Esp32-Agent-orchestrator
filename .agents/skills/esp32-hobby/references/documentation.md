# Documentation Rules

## Style

Write concrete command-first docs. Prefer short sections and runnable examples.

## Portability

Use placeholders:
```text
<repo>
/path/to/esp-idf
$IDF_PATH
<esp32-ip>
/dev/ttyUSB0
```

Do not write private local paths into committed documentation.

## Good Docs Include

- chip/board assumptions
- pin map
- build command
- flash/OTA entry point
- monitor/log capture guidance
- API endpoints
- safety notes
- troubleshooting table

## Verification

```sh
grep -R "$(whoami)\|\.hermes/profiles\|esp-idf-v" -n . --include='*.md'
```
