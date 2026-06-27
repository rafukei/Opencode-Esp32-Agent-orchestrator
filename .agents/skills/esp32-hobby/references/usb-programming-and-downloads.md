# USB Programming, Firmware Delivery, OTA, and Tool Downloads

## Ownership

USB programming, flashing, serial monitor, OTA upload, and ESP-IDF/tool download/install details belong in this skill reference, not scattered through project README files.

## Repository Safety

Do not commit:
- ESP-IDF source tree
- `.espressif/`
- Python virtualenvs
- build folders
- downloaded tool archives
- hardcoded user home paths
- Wi-Fi credentials or tokens

Use placeholders:
- `<repo>`
- `/path/to/esp-idf`
- `$IDF_PATH`
- `$IDF_TOOLS_PATH`
- `<esp32-ip>`

## ESP-IDF Setup Pattern

```sh
mkdir -p "$HOME/esp"
cd "$HOME/esp"
git clone --recursive https://github.com/espressif/esp-idf.git esp-idf
cd esp-idf
git checkout v5.3.2
git submodule update --init --recursive
./install.sh esp32
```

```sh
cd <repo>
export IDF_PATH="$HOME/esp/esp-idf"
source "$IDF_PATH/export.sh"
idf.py --version
```

## USB Flash Workflow

```sh
idf.py build
idf.py -p /dev/ttyUSB0 flash
```

Detect the real port:
```sh
python3 -m serial.tools.list_ports
```

## Bounded Serial Monitor

```sh
timeout 20s idf.py -p /dev/ttyUSB0 monitor | tee /tmp/esp32-monitor.log
```

## Flash/OTA Safety

Before flashing or OTA:
- know what firmware will do on boot;
- stop competing command sources;
- have a stop/neutral action;
- preserve rollback/reflash path.
